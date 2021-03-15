#!/bin/bash
cat test/testdata/collections.json | psql -c "copy pgstac.collections_staging FROM stdin"
cat test/testdata/stacitems.ndjson | psql -c "copy pgstac.items_staging FROM stdin"