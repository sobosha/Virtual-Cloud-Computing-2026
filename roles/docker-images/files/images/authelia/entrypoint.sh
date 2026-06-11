#!/bin/sh
set -eu # fail on error

CONFIG="/config/configuration.yml"
SECRET_FILE="/run/secrets/jwks_key"
DB_ADDRESS="db"
DB_PORT="5432"

# TODO[VCC-006]: Create entrypoint for authelia. It should support replicated deployments

# wait until database is alive
# Authelia image comes with netcat (nc) installed and apt is not available
# explain Why I change it from -z to -w
#The Authelia image uses BusyBox v1.37.0, and BusyBox nc does not support the -z flag. So the command fails every time, the loop runs forever, and the actual Authelia server never starts.
echo "waiting for database"
while ! nc -w 1 ${DB_ADDRESS} ${DB_PORT} < /dev/null; do sleep 1; done
echo "database is alive"

# Inject jwks key from secrets
echo "Injecting jwks key from secrets"
# keep space indentation for yaml (ugh!)
JWKS_KEY=$(sed 's/^/          /' "$SECRET_FILE")
sed -i '/JWKS_PRIVATE_KEY_CONTENT/{
    r /dev/stdin
    d
}' "$CONFIG" <<EOF
$JWKS_KEY
EOF
if [ ! -f /config/.authelia-configured ]; then
    echo "Initialize Authelia database schema"
    authelia storage migrate up -c "$CONFIG"
    # Mark Authelia as configured
    touch /config/.authelia-configured
else
    echo "Authelia database schema already initialized"
fi

# Execute the original entrypoint
exec authelia --config "$CONFIG"
# TODO fix: Original entrypoint is in the : app/entrypoint.sh -> exec /app/entrypoint.sh "$@"