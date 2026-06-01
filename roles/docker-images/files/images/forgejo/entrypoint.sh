#!/bin/sh
set -eu # fail on error

# Make forgejo trust our TLS certificate
update-ca-certificates

# This helper allows to run stuff as the forgejo user
# TODO: looks like it's missing the `sudo` executable
forgejo_cli() { sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; }

# TODO wait until database is alive
#  - port alive                         (bad)
#  - a mock query like 'SELECT 1' works (better)
echo "Waiting for database..."
while ! psql "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -c "SELECT 1"; do
    sleep 1
done
echo "Database is up!"

# TODO: check if it's the first run (see if /data/gitea/conf/app.ini exists)
if [ ! -f /data/gitea/conf/app.ini ]; then
    echo "First run detected"
    mkdir -p /data/gitea
    mkdir -p /data/queues
    mkdir -p /data/gitea/conf
    cp /conf/app.ini /data/gitea/conf/app.ini
    # Fix permission for data directory
    chown -R git:git /data/gitea
    chown -R git:git /data/queues
fi

# DB migration
echo "Initialize forgejo database"
forgejo_cli migrate

# TODO create admin user (if it does not exists already)
# use `forgejo_cli admin user list` and `forgejo_cli admin user create`
if ! forgejo_cli admin user list | grep -q  "${FORGEJO_ADMIN_USER}"; then
      echo "Creating admin user..."
      forgejo_cli admin user create \
        --username "${FORGEJO_ADMIN_USER}" \
        --password "${FORGEJO_ADMIN_PASS}" \
        --email "${FORGEJO_ADMIN_EMAIL}" \
        --admin \
        --must-change-password=false
fi

# TODO wait until authentication server is alive
#  - port alive                         (bad)
#  - check that the web server responds (better)
#    Authelia exposes /api/health to check status
#    For example: curl -kfsS https://auth.vcc.local/api/health returns {"status":"OK"}
echo "Waiting for Authelia to be alive"
while ! curl -kfsS https://auth.vcc.local/api/health | grep -q '"status":"OK"'; do
    sleep 2
done
echo "Authelia is alive"

# TODO setup authentication (if it does not exist)
# use `forgejo_cli admin auth list` and `forgejo_cli admin auth add-oauth`
#   --auto-discover-url is `https://auth.{{domain_name}}/.well-known/openid-configuration`
#   --provider is openidConnect
if ! forgejo_cli admin auth list | grep -q "authelia"; then
    echo "Setting up OpenID Connect authentication..."
    forgejo_cli admin auth add-oauth \
    --name "authelia" \
    --provider "openidConnect" \
    --key "${FORGEJO_OIDC_CLIENT_ID}" \
    --secret "${FORGEJO_OIDC_CLIENT_SECRET}" \
    --auto-discover-url "https://auth.vcc.local/.well-known/openid-configuration"
fi

# TODO: Execute the original entrypoint
exec "$@"