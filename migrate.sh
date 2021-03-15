#!/bin/bash

set -e

MIGRA_IMAGE=$(docker build -q docker/)
echo $MIGRA_IMAGE
MIGRA_CONTAINER=$(docker run -d -p 5432 --rm -v $(pwd):/workspace/ -e PGUSER=postgres -e POSTGRES_HOST_AUTH_METHOD=trust $MIGRA_IMAGE)
echo $MIGRA_CONTAINER
docker exec $MIGRA_CONTAINER /workspaces/pgstac/docker/makemigration.sh $1
docker cp  $MIGRA_CONTAINER:/workspaces/pgstac/migration.sql .
docker kill $MIGRA_CONTAINER
