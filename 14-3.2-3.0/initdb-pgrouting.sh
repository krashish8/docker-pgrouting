#!/bin/bash

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

# Create the 'template_pgrouting' template db
"${psql[@]}" <<- 'EOSQL'
CREATE DATABASE template_pgrouting IS_TEMPLATE true;
EOSQL

# Load pgRouting into both template_database and $POSTGRES_DB
for DB in template_pgrouting "$POSTGRES_DB"; do
	echo "Loading pgRouting extensions into $DB"
	"${psql[@]}" --dbname="$DB" <<-'EOSQL'
		CREATE EXTENSION IF NOT EXISTS postgis;
		CREATE EXTENSION IF NOT EXISTS pgrouting;
EOSQL
done
