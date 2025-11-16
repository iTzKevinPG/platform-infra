# ⚙️ Platform Infra

Infraestructura como código para desplegar Traefik + apps estáticas en un droplet de DigitalOcean usando Terraform, GitHub Actions y GHCR.

## 🗂️ Estructura
```
platform-infra/
├── README.md
├── .gitignore
├── terraform/
│   ├── main.tf / variables.tf / outputs.tf
│   ├── droplet.tf / firewall.tf / ssh_key.tf
│   └── bootstrap/
├── terraform.tfvars.example
└── .github/workflows/
    ├── infra.yml            # plan/apply de Terraform
    └── deploy-compose.yml   # sincroniza el docker-compose en el droplet
```

## ✅ Prerrequisitos
- Terraform >= 1.5 y backend remoto configurado en `terraform/main.tf` (Terraform Cloud).
- Cuenta de DigitalOcean con token API (`do_token` / secret `DO_TOKEN`) y clave SSH registrada (`ssh_key_name`).
- Token API de Cloudflare con permisos `Zone:DNS:Edit` (`CF_DNS_API_TOKEN`).
- Secrets/variables en GitHub Actions:
  - **Secrets**: `DO_TOKEN`, `DO_HOST`, `DO_SSH_USER`, `DO_SSH_KEY`, `TF_API_TOKEN`, `REGISTRY_USERNAME`, `REGISTRY_TOKEN`, `CF_DNS_API_TOKEN`, `TRAEFIK_EMAIL`.
  - **Variables**: `PORTFOLIO_HOST`, `PORTFOLIO_IMAGE`, `PORTFOLIO_INTERNAL_PORT`, `DOCKER_API_VERSION`.

## 🛠️ Uso local
1. Copia `terraform.tfvars.example` a `terraform.tfvars` y rellena valores.
2. Dentro de `terraform/` ejecuta:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
3. Guarda el `droplet_ip` que muestran los outputs.

## 🤖 GitHub Actions (infra.yml)
- **plan**: en cada PR corre `fmt`, `init`, `validate` y `plan`.
- **apply**: en `main` repite los pasos anteriores y ejecuta `terraform apply -auto-approve`.

## 🚀 Bootstrap del droplet
Después de `terraform apply`, sube y ejecuta el script pasando el token de Cloudflare (challenge DNS):
```bash
scp -i <ruta/id_digitalocean> scripts/bootstrap.sh root@<droplet_ip>:/tmp/
ssh -i <ruta/id_digitalocean> root@<droplet_ip>
chmod +x /tmp/bootstrap.sh
CF_DNS_API_TOKEN=<token_cf> \
DEPLOY_USER=deploy \
TRAEFIK_EMAIL=tu-correo \
PORTFOLIO_HOST=itzkevindev.tech \
/tmp/bootstrap.sh
```
El script instala Docker 24.0.9, prepara `/opt/platform`, crea `.env.platform`, levanta Traefik + portfolio (DNS challenge) y deja listo `docker compose --project-name platform_portfolio up -d`.

## 🔁 Flujo tras un `terraform destroy`
1. **Recrear la infraestructura**: `terraform apply`.
2. **Ejecutar el bootstrap** usando el comando anterior.
3. **Verificar servicios**:
   ```bash
   cd /opt/platform
   docker compose --project-name platform_portfolio up -d
   docker compose --project-name platform_portfolio ps
   docker logs platform_portfolio-traefik-1 --tail 50
   curl -k -H "Host: itzkevindev.tech" https://<droplet_ip>
   ```
4. **DNS / Cloudflare**: registros A y CNAME en proxy naranja, modo SSL = **Full** (Traefik renueva certificados vía DNS challenge).
5. **Pipelines automáticos**:
   - `iTzPortfolio/.github/workflows/node.js.yml`: build de Angular, push a GHCR y `docker compose pull/up portfolio` vía SSH.
   - `platform-infra/.github/workflows/deploy-compose.yml`: despliega cambios del `runtime/docker-compose.yml`, recrea automáticamente `/opt/platform/.env.platform` usando los secrets/variables anteriores y ejecuta `docker compose --env-file .env.platform pull/up`.

Con esto el ciclo queda automatizado: Terraform crea infra, el bootstrap deja el entorno listo y las pipelines mantienen Traefik + apps actualizadas. Solo repite el flujo después de destruir el droplet o al cambiar de dominio.

---

<p align="center">
  <img src="IconoITzKEvin.png" alt="iTzKevin logo" width="120">
</p>
