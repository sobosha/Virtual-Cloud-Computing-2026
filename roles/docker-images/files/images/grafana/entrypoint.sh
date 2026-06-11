#!/bin/sh
set -eu # fail on error
DB_HOST="${GF_DATABASE_HOST}"
DB_PORT="${GF_DATABASE_PORT}"
# TODO[VCC-010]: Create entrypoint for grafana. It should support replicated deployments

# Wait until database is alive. Grafana image comes with netcat (nc)
while ! nc -z ${DB_HOST} ${DB_PORT}; do
    echo "Waiting for database to be alive..."
    sleep 1
done

exec /run.sh "$@"