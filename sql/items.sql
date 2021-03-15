CREATE TABLE IF NOT EXISTS items (
    id VARCHAR PRIMARY KEY,
    stac_version VARCHAR,
    stac_extensions VARCHAR[],
    geometry geometry NOT NULL,
    properties JSONB,
    assets JSONB,
    collection_id VARCHAR NOT NULL,
    datetime timestamptz
);


CREATE OR REPLACE FUNCTION get_items(content jsonb) RETURNS jsonb AS $$
    SELECT CASE
        WHEN jsonb_typeof(content) = 'array' THEN content
        WHEN content->>'type' = 'Feature' THEN '[]'::jsonb || content
        WHEN content->>'type' = 'FeatureCollection' THEN content->'features'
        ELSE NULL
    END;
$$ LANGUAGE SQL IMMUTABLE PARALLEL SAFE SET SEARCH_PATH TO pgstac,public;

CREATE OR REPLACE FUNCTION items(content jsonb) RETURNS SETOF items AS $$
    SELECT
        DISTINCT
        value->>'id' as id,
        value->>'stac_version' as stac_version,
        textarr(value->'stac_extensions') as stac_extensions,
        CASE
            WHEN value->>'geometry' IS NOT NULL THEN
                ST_GeomFromGeoJSON(value->>'geometry')
            WHEN content->>'bbox' IS NOT NULL THEN
                ST_MakeEnvelope(
                    (value->'bbox'->>0)::float,
                    (value->'bbox'->>1)::float,
                    (value->'bbox'->>2)::float,
                    (value->'bbox'->>3)::float,
                    4326
                )
            ELSE NULL
        END as geometry,
        value ->'properties' as properties,
        value->'assets' AS assets,
        value->>'collection' as collection_id,
        (value->>'datetime')::timestamptz as datetime
    FROM jsonb_array_elements(get_items(content))
;
$$ LANGUAGE SQL SET SEARCH_PATH TO pgstac,public;

CREATE OR REPLACE FUNCTION create_items(content jsonb) RETURNS VOID AS $$
    INSERT INTO items SELECT * FROM items(content)
    ON CONFLICT (id) DO
    UPDATE
        SET (
            id,
            stac_version,
            stac_extensions,
            geometry,
            properties,
            assets,
            collection_id,
            datetime
        ) = (
            EXCLUDED.id,
            EXCLUDED.stac_version,
            EXCLUDED.stac_extensions,
            EXCLUDED.geometry,
            EXCLUDED.properties,
            EXCLUDED.assets,
            EXCLUDED.collection_id,
            EXCLUDED.datetime
        );
$$ LANGUAGE SQL SET SEARCH_PATH TO pgstac,public;

CREATE UNLOGGED TABLE IF NOT EXISTS items_staging (data jsonb);

CREATE OR REPLACE FUNCTION items_staging_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM create_items(NEW.data);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SET SEARCH_PATH TO pgstac,public;

CREATE TRIGGER items_staging_trigger
BEFORE INSERT ON items_staging
FOR EACH ROW EXECUTE PROCEDURE items_staging_trigger_func();

CREATE OR REPLACE FUNCTION get_items(_limit int = 10, _offset int = 0, _token varchar = NULL) RETURNS SETOF jsonb AS $$
SELECT to_jsonb(items) FROM items
WHERE
    CASE
        WHEN _token is NULL THEN TRUE
        ELSE id > _token
    END
ORDER BY id ASC
OFFSET _offset
LIMIT _limit
;
$$ LANGUAGE SQL SET SEARCH_PATH TO pgstac,public;