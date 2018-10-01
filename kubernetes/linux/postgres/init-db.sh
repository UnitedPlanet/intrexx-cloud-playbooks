#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" <<-EOSQL
    CREATE DATABASE ixcloud;
    GRANT ALL PRIVILEGES ON DATABASE ixcloud TO postgres;
EOSQL
