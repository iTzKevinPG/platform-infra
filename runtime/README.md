# 🐳 Runtime: Traefik + Portfolio

`docker-compose.yml` mantiene Traefik y el contenedor del portfolio en el droplet (noviembre 2025).

## 🔧 Variables
- `TRAEFIK_ACME_EMAIL`: correo de Let’s Encrypt.
- `TRAEFIK_NETWORK`: red externa Docker (por defecto `reverse-proxy`).
- `PORTFOLIO_IMAGE`: imagen GHCR a desplegar (ej. `ghcr.io/itzkevinpg/itzportfolio:latest`).
- `PORTFOLIO_HOST`: host que Traefik usará para enrutar (`itzkevindev.tech`).
- `PORTFOLIO_INTERNAL_PORT`: puerto expuesto por la app (default `8080`).

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
