# 🐳 Runtime: Traefik + Portfolio

`docker-compose.yml` mantiene Traefik y el contenedor del portfolio en el droplet (noviembre 2025).

## 🔧 Variables
- `TRAEFIK_ACME_EMAIL`: correo de Let’s Encrypt (inyectado desde el secret `TRAEFIK_EMAIL`).
- `TRAEFIK_NETWORK`: red externa Docker (por defecto `reverse-proxy`).
- `PORTFOLIO_IMAGE`: imagen GHCR a desplegar (`ghcr.io/itzkevinpg/itzportfolio:latest` vía variable de Actions).
- `PORTFOLIO_HOST`: host que Traefik usará para enrutar (`itzkevindev.tech`).
- `PORTFOLIO_INTERNAL_PORT`: puerto expuesto por la app (default `8080`).
- `CF_DNS_API_TOKEN` y `DOCKER_API_VERSION`: requeridos para Traefik DNS challenge / compatibilidad Docker.

> El workflow `deploy-compose.yml` recrea `/opt/platform/.env.platform` con estas variables usando los Secrets/Variables de GitHub Actions para que Traefik quede listo sin pasos manuales.

## 🚢 Servicios
- **traefik**: expone 80/443, usa el provider Docker, resuelve certificados ACME (DNS challenge) y habilita dashboard.
- **portfolio**: contenedor Angular. No publica puertos; Traefik enruta usando las labels `traefik.http.routers.portfolio.*`.

## ➕ Añadir otro servicio
1. Duplica el bloque `portfolio` y renómbralo (ej. `landing`).
2. Ajusta `image`, `env_file` o variables necesarias.
3. Define labels Traefik con el nuevo host, p. ej. `Host("landing.tu-dominio.com")`.
4. Declara las variables en `.env.platform` o crea un `.env.<servicio>`.
5. Ejecuta `docker compose up -d <servicio>` y actualiza DNS/Cloudflare.

---

<p align="center">
  <img src="../IconoITzKEvin.png" alt="iTzKevin logo" width="120">
</p>
