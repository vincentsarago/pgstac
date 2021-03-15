BEGIN;
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE SCHEMA pgstac;
SET SEARCH_PATH TO pgstac, public;
\i sql/core.sql
\i sql/collections.sql
\i sql/items.sql
\i sql/search.sql
COMMIT;