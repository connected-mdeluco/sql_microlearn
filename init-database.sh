#!/bin/sh
set -e

cd /app

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" "$POSTGRES_DB" <<-EOSQL
    \set db_name $POSTGRES_DB
    \i init-database.sql
EOSQL