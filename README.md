# Platform Infra

Infraestructura como código para desplegar Traefik + apps estáticas en un droplet de DigitalOcean utilizando Terraform, GitHub Actions y GHCR.

## Estructura

```
platform-infra/
+-- README.md
+-- .gitignore
+-- terraform/
     +-- main.tf
     +-- variables.tf
     +-- droplet.tf
     +-- firewall.tf
     +-- ssh_key.tf
     +-- outputs.tf
     +-- bootstrap/
+-- terraform.tfvars.example
+-- .github/workflows/
    +-- infra.yml           # plan/apply de Terraform
    +-- deploy-compose.yml  # actualiza el docker-compose en el droplet
```

## Prerrequisitos
- Terraform = 1.5
- Cuenta de DigitalOcean con token API (`do_token` / `DO_TOKEN`).
- Terraform Cloud (o backend remoto) configurado en `terraform/main.tf`.
- Clave SSH registrada en DigitalOcean (`ssh_key_name`).
- Token API de Cloudflare con permisos `Zone:DNS:Edit` (`CF_DNS_API_TOKEN`).
- Secrets en GitHub (para los workflows): `DO_TOKEN`, `DO_SSH_USER`, `DO_SSH_KEY`, `DO_HOST`, `TF_API_TOKEN`, `REGISTRY_USERNAME`, `REGISTRY_TOKEN`.

## Uso local
1. Copia `terraform.tfvars.example` a `terraform.tfvars` y rellena las variables.
2. Desde `terraform/` ejecuta:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```
3. Toma nota del `droplet_ip` mostrado en los outputs.

## GitHub Actions (infra.yml)
- `plan`: se ejecuta en cada PR (fmt + init + validate + plan).
- `apply`: al hacer push a `main` repite fmt/init/validate/plan y aplica con `terraform apply -auto-approve`.

## Bootstrap
Tras `terraform apply` copia el script al droplet y ejecútalo pasando el token de Cloudflare para el challenge DNS:
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
El script instala Docker 24.0.9, genera `/opt/platform/.env.*`, levanta Traefik + portfolio (con DNS challenge) y deja todo listo para `docker compose --project-name platform_portfolio up -d`.

## Flujo completo tras un `terraform destroy`
1. **Recrear la infra** (`terraform apply`).
2. **Ejecutar el bootstrap** como se describe arriba.
3. **(Opcional) Validar**:
   ```bash
   cd /opt/platform
   docker compose --project-name platform_portfolio up -d
   docker compose --project-name platform_portfolio ps
   docker logs platform_portfolio-traefik-1 --tail 50
   ```
   También puedes verificar el origen con `curl -k -H "Host: itzkevindev.tech" https://<droplet_ip>`.
4. **DNS/Cloudflare**: deja los registros A/CNAME en proxy naranja y el modo SSL en **Full**. El challenge DNS se encarga del certificado.
5. **Pipelines automáticos**:
   - `iTzPortfolio/.github/workflows/node.js.yml`: construye/pushea la imagen en GHCR y ejecuta `docker compose pull/up portfolio`.
   - `platform-infra/.github/workflows/deploy-compose.yml`: copia `runtime/docker-compose.yml` al droplet y ejecuta `docker compose pull/up` cuando cambias el stack.

Con esto todo el flujo (Terraform ? bootstrap ? Traefik + apps ? actualizaciones del compose) queda automatizado. Solo necesitas repetir los pasos anteriores si destruyes el droplet o cambias de dominio.
