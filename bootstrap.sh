#!/usr/bin/env bash

# Initial Variables:

Host=${Host:-server.example.com}
SSHUser=${SSHUser:-username}
AdminEmail=${AdminEmail:-you@example.com}

# Derive Variables:

NetworkEmail="noreply@${Host}"
SSH=${SSHUser}@${Host}

# Generate variables if not already generated:

if [[ -f .generated ]]; then source .generated; fi

CookeyHashKey=${CookeyHashKey:-$(openssl rand -hex 64)}
CookeyBlockKey=${CookeyBlockKey:-$(openssl rand -hex 32)}
DebugPassword=${DebugPassword:-$(openssl rand -hex 16)}
ConsoleClientSecret=${ConsoleClientSecret:-$(openssl rand -hex 32)}

cat > .generated <<EOF
CookeyHashKey=${CookeyHashKey}
CookeyBlockKey=${CookeyBlockKey}
DebugPassword=${DebugPassword}
ConsoleClientSecret=${ConsoleClientSecret}
EOF

# Build .env file:

cat > .env <<EOF
TTN_LW_IS_DATABASE_URI=postgresql://root:root@postgres:5432/ttn_lorawan?sslmode=disable
TTN_LW_REDIS_ADDRESS=redis:6379

TTN_LW_CACHE_SERVICE=redis
TTN_LW_CACHE_REDIS_ADDRESS=redis:6379

TTN_LW_EVENTS_BACKEND=redis
TTN_LW_EVENTS_REDIS_ADDRESS=redis:6379

TTN_LW_TLS_SOURCE=acme
TTN_LW_TLS_ACME_DIR=/var/lib/acme
TTN_LW_TLS_ACME_EMAIL=${AdminEmail}
TTN_LW_TLS_ACME_HOSTS=${Host}
TTN_LW_TLS_ACME_DEFAULT_HOST=${Host}

TTN_LW_HTTP_COOKIE_HASH_KEY=${CookeyHashKey}
TTN_LW_HTTP_COOKIE_BLOCK_KEY=${CookeyBlockKey}
TTN_LW_HTTP_METRICS_PASSWORD=${DebugPassword}
TTN_LW_HTTP_PPROF_PASSWORD=${DebugPassword}

TTN_LW_IS_EMAIL_SENDER_NAME=The Things Stack
TTN_LW_IS_EMAIL_SENDER_ADDRESS=noreply@${Host}
TTN_LW_IS_EMAIL_NETWORK_CONSOLE_URL=https://${Host}/console
TTN_LW_IS_EMAIL_NETWORK_IDENTITY_SERVER_URL=https://${Host}/oauth

# Intentionally omitting email provider config

TTN_LW_IS_OAUTH_UI_CANONICAL_URL=https://${Host}/oauth
TTN_LW_IS_OAUTH_UI_IS_BASE_URL=https://${Host}/api/v3

TTN_LW_CONSOLE_OAUTH_AUTHORIZE_URL=https://${Host}/oauth/authorize
TTN_LW_CONSOLE_OAUTH_TOKEN_URL=https://${Host}/oauth/token

########## logout redirects - are those needed? ##############################
#This first one is needed - else we default to localhost for logout
TTN_LW_CONSOLE_OAUTH_LOGOUT_URL=https://${Host}/oauth/logout
# this i m not sure about (yet)
#TTN_LW_CONSOLE_OAUTH_REDIRECT_LOGOUT_URL=https://${Host}

######### http redirect to https, optional #########################
#TTN_LW_HTTP_REDIRECT-TO-TLS
##########################################################

TTN_LW_CONSOLE_UI_CANONICAL_URL=https://${Host}/console
TTN_LW_CONSOLE_UI_AS_BASE_URL=https://${Host}/api/v3
TTN_LW_CONSOLE_UI_GS_BASE_URL=https://${Host}/api/v3
TTN_LW_CONSOLE_UI_IS_BASE_URL=https://${Host}/api/v3
TTN_LW_CONSOLE_UI_JS_BASE_URL=https://${Host}/api/v3
TTN_LW_CONSOLE_UI_NS_BASE_URL=https://${Host}/api/v3
TTN_LW_CONSOLE_UI_EDTC_BASE_URL=https://${Host}/api/v3
TTN_LW_CONSOLE_UI_QRG_BASE_URL=https://${Host}/api/v3

TTN_LW_CONSOLE_OAUTH_CLIENT_ID=console
TTN_LW_CONSOLE_OAUTH_CLIENT_SECRET=${ConsoleClientSecret}

TTN_LW_GS_REQUIRE_REGISTERED_GATEWAYS=true

TTN_LW_GS_MQTT_V2_PUBLIC_ADDRESS=${Host}:1881
TTN_LW_GS_MQTT_V2_PUBLIC_TLS_ADDRESS=${Host}:8881

TTN_LW_GS_MQTT_PUBLIC_ADDRESS=${Host}:1882
TTN_LW_GS_MQTT_PUBLIC_TLS_ADDRESS=${Host}:8882

TTN_LW_GS_BASIC_STATION_USE_TRAFFIC_TLS_ADDRESS=true

TTN_LW_AS_MQTT_PUBLIC_ADDRESS=${Host}:1883
TTN_LW_AS_MQTT_PUBLIC_TLS_ADDRESS=${Host}:8883
TTN_LW_AS_WEBHOOKS_DOWNLINK_PUBLIC_ADDRESS=http://${Host}/api/v3
TTN_LW_AS_WEBHOOKS_DOWNLINK_PUBLIC_TLS_ADDRESS=https://${Host}/api/v3

TTN_LW_GCS_BASIC_STATION_DEFAULT_LNS_URI=wss://${Host}:8887
TTN_LW_GCS_THE_THINGS_GATEWAY_DEFAULT_MQTT_SERVER=mqtts://${Host}:8881
EOF

# Prepare the server:

scp prepare.sh ${SSH}:/tmp/prepare.sh
ssh ${SSH} chmod +x /tmp/prepare.sh
ssh ${SSH} /tmp/prepare.sh

# Prepare the app:

scp docker-compose.yml ${SSH}:/app/the-things-stack/docker-compose.yml
scp .env ${SSH}:/app/the-things-stack/.env

function remote-docker-compose() {
  ssh -t ${SSH} docker-compose -f /app/the-things-stack/docker-compose.yml $@
}

remote-docker-compose pull

remote-docker-compose run --rm stack is-db init

remote-docker-compose run --rm stack is-db create-admin-user \
  --id admin \
  --email ${AdminEmail}

remote-docker-compose run --rm stack is-db create-oauth-client \
  --id cli \
  --name "Command Line Interface" \
  --owner admin \
  --no-secret \
  --redirect-uri "local-callback" \
  --redirect-uri "code"

remote-docker-compose run --rm stack is-db create-oauth-client \
  --id console \
  --name "Console" \
  --owner admin \
  --secret ${ConsoleClientSecret} \
  --redirect-uri "https://${Host}/console/oauth/callback" \
  --redirect-uri "/console/oauth/callback"


remote-docker-compose up -d

cat > config.yml <<EOF
credentials-id: ${Host}
oauth-server-address: https://${Host}/oauth
identity-server-grpc-address: ${Host}:8884
gateway-server-grpc-address: ${Host}:8884
network-server-grpc-address: ${Host}:8884
application-server-grpc-address: ${Host}:8884
join-server-grpc-address: ${Host}:8884
device-claiming-server-grpc-address: ${Host}:8884
device-template-converter-grpc-address: ${Host}:8884
qr-code-generator-grpc-address: ${Host}:8884
EOF

export TTN_LW_CONFIG="${PWD}/config.yml"

echo "Deployment:               https://${Host}"
echo "Documentation:            https://${Host}/assets/doc/"
echo "CLI configuration file:   config.yml"
echo ""
echo "To use the CLI, run:"
echo ""
echo "export TTN_LW_CONFIG=\"${PWD}/config.yml\""
