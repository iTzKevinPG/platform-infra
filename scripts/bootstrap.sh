export DEBIAN_FRONTEND=noninteractive
export NEEDRESTART_MODE=a
#!/usr/bin/env bash
set -euo pipefail

DEPLOY_USER="${DEPLOY_USER:-deploy}"
APP_ROOT="${APP_ROOT:-/opt/platform}"
COMPOSE_PROJECT="${COMPOSE_PROJECT:-platform_portfolio}"
TRAEFIK_EMAIL="${TRAEFIK_EMAIL:-admin@example.com}"
PORTFOLIO_HOST="${PORTFOLIO_HOST:-itzkevindev.tech}"
PORTFOLIO_IMAGE="${PORTFOLIO_IMAGE:-ghcr.io/itzkevinpg/itzportfolio:latest}"
PORTFOLIO_INTERNAL_PORT="${PORTFOLIO_INTERNAL_PORT:-8080}"
TRAEFIK_NETWORK="${TRAEFIK_NETWORK:-reverse-proxy}"
CF_DNS_API_TOKEN="${CF_DNS_API_TOKEN:-}"

PRIMARY_HOST=${PORTFOLIO_HOST#www.}
WILDCARD_HOST="www.${PRIMARY_HOST}"

log() {
  echo "[bootstrap] $1"
}

log "Actualizando paquetes..."
apt-get update -y && apt-get upgrade -y
apt-get install -y ca-certificates curl gnupg lsb-release ufw

log "Configurando repo Docker..."
install -m 0755 -d /etc/apt/keyrings
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
fi
CODENAME=$( . /etc/os-release ; echo "$VERSION_CODENAME" )
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" > /etc/apt/sources.list.d/docker.list
apt-get update -y
apt-get install -y --allow-downgrades docker-ce=5:24.0.9-1~ubuntu.22.04~jammy docker-ce-cli=5:24.0.9-1~ubuntu.22.04~jammy containerd.io docker-buildx-plugin docker-compose-plugin libltdl7
systemctl enable --now docker

SERVER_API_VERSION=$(docker version --format '{{.Server.APIVersion}}')

if ! id -u "$DEPLOY_USER" >/dev/null 2>&1; then
  log "Creando usuario $DEPLOY_USER"
  useradd -m -s /bin/bash "$DEPLOY_USER"
fi
usermod -aG docker "$DEPLOY_USER"

ufw allow OpenSSH
ufw allow 80
ufw allow 443
ufw --force enable

log "Preparando directorio $APP_ROOT"
mkdir -p "$APP_ROOT/letsencrypt"
chmod 700 "$APP_ROOT/letsencrypt"
touch "$APP_ROOT/letsencrypt/acme.json"
chmod 600 "$APP_ROOT/letsencrypt/acme.json"

cat > "$APP_ROOT/.env.portfolio" <<EOF
PORT=$PORTFOLIO_INTERNAL_PORT
SERVER_NAME=$PORTFOLIO_HOST
EOF

cat > "$APP_ROOT/.env.platform" <<EOF
TRAEFIK_ACME_EMAIL=$TRAEFIK_EMAIL
PORTFOLIO_IMAGE=$PORTFOLIO_IMAGE
PORTFOLIO_HOST=$PORTFOLIO_HOST
PORTFOLIO_INTERNAL_PORT=$PORTFOLIO_INTERNAL_PORT
TRAEFIK_NETWORK=$TRAEFIK_NETWORK
DOCKER_API_VERSION=$SERVER_API_VERSION
CF_DNS_API_TOKEN=$CF_DNS_API_TOKEN
EOF

cat > "$APP_ROOT/docker-compose.yml" <<EOF
services:
  traefik:
    image: traefik:v3.1
    command:
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.email=$TRAEFIK_EMAIL
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
      - --certificatesresolvers.letsencrypt.acme.dnschallenge=true
      - --certificatesresolvers.letsencrypt.acme.dnschallenge.provider=cloudflare
      - --certificatesresolvers.letsencrypt.acme.dnschallenge.delayBeforeCheck=30
      - --api.dashboard=true
    ports:
      - 80:80
      - 443:443
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - $TRAEFIK_NETWORK
    environment:
      - CF_DNS_API_TOKEN=$CF_DNS_API_TOKEN
      - DOCKER_API_VERSION=$SERVER_API_VERSION
    restart: unless-stopped

  portfolio:
    image: $PORTFOLIO_IMAGE
    labels:
      - traefik.enable=true
      - traefik.http.routers.portfolio.rule=Host("$PRIMARY_HOST") || Host("$WILDCARD_HOST")
      - traefik.http.routers.portfolio.entrypoints=websecure
      - traefik.http.routers.portfolio.tls.certresolver=letsencrypt
      - traefik.http.services.portfolio.loadbalancer.server.port=$PORTFOLIO_INTERNAL_PORT
    networks:
      - $TRAEFIK_NETWORK
    restart: unless-stopped

networks:
  $TRAEFIK_NETWORK:
    external: true
EOF

log "Creando red $TRAEFIK_NETWORK si no existe"
docker network inspect "$TRAEFIK_NETWORK" >/dev/null 2>&1 || docker network create "$TRAEFIK_NETWORK"

log "Iniciando stack"
cd "$APP_ROOT"
docker compose --project-name "$COMPOSE_PROJECT" up -d

log "Bootstrap completado"
