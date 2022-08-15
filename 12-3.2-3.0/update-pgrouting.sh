#!/bin/sh

set -e

# Perform all actions as $POSTGRES_USER
export PGUSER="$POSTGRES_USER"

PGROUTING_VERSION="${PGROUTING_VERSION%%+*}"

# Load pgRouting into both template_database and $POSTGRES_DB
for DB in template_pgrouting "$POSTGRES_DB" "${@}"; do
    echo "Updating pgRouting extensions '$DB' to $PGROUTING_VERSION"
    psql --dbname="$DB" -c "
        -- Upgrade pgRouting
        CREATE EXTENSION IF NOT EXISTS postgis;
        CREATE EXTENSION IF NOT EXISTS pgrouting VERSION '$PGROUTING_VERSION';
        ALTER EXTENSION pgrouting  UPDATE TO '$PGROUTING_VERSION';
    "
done
