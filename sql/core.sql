CREATE OR REPLACE FUNCTION textarr(_js jsonb)
  RETURNS text[] AS $$
  SELECT ARRAY(SELECT jsonb_array_elements_text(_js));
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;

CREATE OR REPLACE FUNCTION array_idents(_js jsonb)
  RETURNS text AS $$
  SELECT string_agg(quote_ident(v),',') FROM jsonb_array_elements_text(_js) v;
$$ LANGUAGE sql IMMUTABLE PARALLEL SAFE;


/* configuration table */
CREATE TABLE configuration (
    key VARCHAR,
    val JSONB
);

INSERT INTO configuration VALUES
('sort_columns', '{"datetime":"datetime","eo:cloud_cover":"properties->>''eo:cloud_cover''"}'::jsonb)
;

CREATE OR REPLACE FUNCTION get_config(_config text) RETURNS JSONB AS $$
SELECT val FROM configuration WHERE key=_config;
$$ LANGUAGE SQL;
