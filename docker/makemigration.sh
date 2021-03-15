#!/bin/bash

set -e

FROMDB=$1

cd /workspaces/pgstac

TODBURL=postgresql://postgres@localhost:5432/migra_to
GITURL=https://github.com/stac-utils/pgstac.git

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# wait for pg_isready
RETRIES=10

until pg_isready || [ $RETRIES -eq 0 ]; do
  echo "Waiting for postgres server, $((RETRIES--)) remaining attempts..."
  sleep 1
done

psql <<-'EOSQL'
    DROP DATABASE IF EXISTS migra_from;
    CREATE DATABASE migra_from;
    DROP DATABASE IF EXISTS migra_to;
    CREATE DATABASE migra_to;
EOSQL

# Load current workspace into TODB
psql -f pgstac.sql $TODBURL

if [[ $FROMDB = postgresql* ]]
then
    echo "Comparing schema to existing PG instance $FROMDB"
    FROMDBURL=$FROMDB
else
    echo "Comparing schema to $FROMDB branch on github"
    FROMDBURL=postgresql://postgres@migra:5432/migra_from
    BRANCH=${1:-main}
    mkdir -p /workspaces/fromdb
    cd /workspaces/fromdb
    echo "$(pwd) $FROMDBURL $BRANCH $GITURL"
    git clone $GITURL --branch $BRANCH --single-branch /workspace/fromdb
    psql $FROMDBURL -f pgstac.sql
fi

migra --unsafe $FROMDBURL $TODBURL >migration.sql
