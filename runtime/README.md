# docker-compose.yml (2025-11) - servicios Traefik + portfolio

## Variables
- TRAEFIK_ACME_EMAIL: correo para Let's Encrypt.
- TRAEFIK_NETWORK: red externa Docker (default 
everse-proxy).
- PORTFOLIO_IMAGE: imagen GHCR a desplegar (ej. ghcr.io/itzkevinpg/itzportfolio:latest).
- PORTFOLIO_HOST: host que Traefik usara para enrutar (ej. itzkevindev.tech).
- PORTFOLIO_INTERNAL_PORT: puerto interno expuesto por la app (default 8080).

## Servicios
- **traefik**: expone 80/443, usa docker provider, resuelve certificados ACME http-01 y habilita dashboard.
- **portfolio**: contenedor de la app Angular (o futuros servicios). No publica puertos; Traefik enruta via labels 	raefik.http.routers.portfolio.*.

## Como añadir otro servicio
1. Copia el bloque portfolio, cambia el nombre (ej. landing).
2. Ajusta image, env_file o variables necesarias.
3. Define labels Traefik con el nuevo host, por ejemplo Host(landing.tu-dominio.com).
4. Añade las variables al .env.platform o crea un .env.<servicio>.
5. Ejecuta docker compose up -d landing y actualiza DNS.
