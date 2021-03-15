CREATE TABLE IF NOT EXISTS collections (
    id VARCHAR GENERATED ALWAYS AS (content->>'id') STORED PRIMARY KEY,
    content JSONB
);

CREATE UNLOGGED TABLE IF NOT EXISTS collections_staging (data jsonb);

CREATE OR REPLACE FUNCTION create_collections(data jsonb) RETURNS VOID AS $$
    INSERT INTO collections (content)
    SELECT value FROM jsonb_array_elements('[]'::jsonb || data)
    ON CONFLICT (id) DO
    UPDATE
        SET content=EXCLUDED.content;
$$ LANGUAGE SQL SET SEARCH_PATH TO pgstac,public;

CREATE OR REPLACE FUNCTION collections_staging_trigger_func()
RETURNS TRIGGER AS $$
BEGIN
    RAISE NOTICE '%', NEW.data->>'id';
    PERFORM create_collections(NEW.data);
    RETURN NULL;
END;
$$ LANGUAGE PLPGSQL SET SEARCH_PATH TO pgstac,public;

CREATE TRIGGER collections_staging_trigger
BEFORE INSERT ON collections_staging
FOR EACH ROW EXECUTE PROCEDURE collections_staging_trigger_func();

CREATE OR REPLACE FUNCTION get_collections(_limit int = 10, _offset int = 0, _token varchar = NULL) RETURNS SETOF jsonb AS $$
SELECT content FROM collections
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