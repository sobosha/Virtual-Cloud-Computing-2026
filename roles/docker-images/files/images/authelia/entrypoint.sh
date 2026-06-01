#!/bin/sh
set -eu # fail on error

CONFIG="/config/configuration.yml"
DB_ADDRESS="db"
DB_PORT="5432"

# TODO wait until database is alive
# Authelia image comes with netcat (nc) installed and apt is not available
echo "waiting for the database ..."
while ! nc -z ${DB_ADDRESS} ${DB_PORT}; do # -z check port is open and database is alive
    sleep 1
done
echo "database is alive"

# TODO: check if Authelia has been configured before
if [ ! -f /config/.authelia-configured ]; then # -f means "file exist"
    echo "Initialize Authelia database schema"
    authelia storage migrate up -c "$CONFIG"
    # TODO: mark Authelia as configured
    touch /config/.authelia-configured # create empty marker file
fi

# TODO: Execute the original entrypoint
exec authelia --config "$CONFIG"