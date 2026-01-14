#!/bin/bash
export PGPORT=5432
export PGPASSWORD='password'

# create DATABASE
psql -U postgres -d postgres -f 01-database.sql

# create tables
psql -U media -d dbmedia -h localhost -f 02-tables.sql

# load data
export POSTGRES_USER=postgres
export POSTGRES_DB=dbmedia
export POSTGRES_SCHEMA=sc_media
./03-load-data.sh

# enable constraints
psql -U media -d dbmedia -h localhost -f 04-constraints.sql


