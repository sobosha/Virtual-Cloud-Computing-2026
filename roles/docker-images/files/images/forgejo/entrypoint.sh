#!/bin/sh
set -eu # fail on error

# Make forgejo trust our TLS certificate
update-ca-certificates

# TODO[VCC-008]: Create entrypoint for forgejo. It should support replicated deployments

# This helper allows to run stuff as the forgejo user
# Looks like it's missing the `sudo` executable
forgejo_cli() { sudo -u git forgejo --config /data/gitea/conf/app.ini "$@"; }

# Wait until database is alive
#  - port alive                         (bad)
#  - a mock query like 'SELECT 1' works (better)
echo "waiting for database"
while ! psql "postgresql://${DB_USER}:${DB_PASS}@${DB_HOST}:${DB_PORT}/${DB_NAME}" -c "SELECT 1"; do
    sleep 1
done
echo "database is alive"


# Check if it's the first run (see if /data/gitea/conf/app.ini exists)
if [ ! -f /data/gitea/conf/app.ini ]; then
    echo "First run detected"
    mkdir -p /data/gitea
    mkdir -p /data/queues
    mkdir -p /data/gitea/conf
    cp /conf/app.ini /data/gitea/conf/app.ini
else
    echo "Forgejo database schema already initialized"
fi
# Fix permission for data directory
chown -R git:git /data/gitea
chown -R git:git /data/queues

# DB migration
echo "Initialize forgejo database"
forgejo_cli migrate

# Create admin user (if it does not exists already)
# use `forgejo_cli admin user list` and `forgejo_cli admin user create`
if ! forgejo_cli admin user list | grep -q "${FORGEJO_ADMIN_USER}"; then
    echo "Creating admin user"
    forgejo_cli admin user create \
        --username "${FORGEJO_ADMIN_USER}" \
        --email "${FORGEJO_ADMIN_EMAIL}" \
        --admin \
        --password "${FORGEJO_ADMIN_PASSWORD}" \
        --must-change-password=false
fi


# Wait until authentication server is alive
#  - port alive                         (bad)
#  - check that the web server responds (better)
#    Authelia exposes /api/health to check status
#    For example: curl -kfsS https://auth.vcc.local/api/health returns {"status":"OK"}
# FORGEJO_AUTH_URL defined in docker-compose.yml
while ! curl -kfsS "${FORGEJO_AUTH_URL}/api/health" | grep -q '"status":"OK"'; do
    sleep 2
done

# Setup authentication (if it does not exist)
# use `forgejo_cli admin auth list` and `forgejo_cli admin auth add-oauth`
#   --auto-discover-url is `https://auth.{{domain_name}}/.well-known/openid-configuration`
#   --provider is openidConnect
if ! forgejo_cli admin auth list | grep -q "authelia"; then
    echo "Setting up authelia authentication"
    forgejo_cli admin auth add-oauth \
        --name "authelia" \
        --provider "openidConnect" \
        --key "${FORGEJO_OIDC_CLIENT_ID}" \
        --secret "${FORGEJO_OIDC_CLIENT_SECRET}" \
        --auto-discover-url "${FORGEJO_AUTH_URL}/.well-known/openid-configuration" \
        --scopes "openid profile email" #add it because the Forgejo doesnt get name and email
fi
# Execute the original entrypoint
exec /usr/bin/entrypoint "$@"