# EC2 Backend Deployment Guide (Lengkap)

Panduan deploy backend NestJS, Next.js, dan Express ke Amazon EC2 memakai Docker, GitHub Actions, dan akses aman via Tailscale. Disusun dari referensi `shipshitdev/skills/ec2-backend-deployer` dan disesuaikan dengan lab `aws-ec2-web-hosting-part-1`.

## Daftar isi

1. [Project context discovery](#1-project-context-discovery)
2. [Docker setup](#2-docker-setup)
3. [Container registry](#3-container-registry)
4. [CI/CD pipeline](#4-cicd-pipeline)
5. [EC2 deployment process](#5-ec2-deployment-process)
6. [Multi-service deployment](#6-multi-service-deployment)
7. [Security best practices](#7-security-best-practices)
8. [Monitoring & health checks](#8-monitoring--health-checks)
9. [Rollback procedures](#9-rollback-procedures)
10. [Docker cleanup](#10-docker-cleanup)
11. [Troubleshooting](#11-troubleshooting)
12. [Checklist](#12-checklist)

---

## 1. Project context discovery

Sebelum deployment, jawab pertanyaan ini:

| Pertanyaan | Contoh |
| --- | --- |
| Framework | NestJS, Next.js, atau Express |
| Package manager | npm, yarn, pnpm, bun |
| Node version | 20 / 22 (lihat `.nvmrc`) |
| Build output | `dist/`, `.next/`, `build/` |
| Port | 3000 / 3001 |
| Environment variables | DATABASE_URL, REDIS_URL, JWT_SECRET |
| Health endpoint | `/health`, `/api/health`, `/health/live` |
| Database | PostgreSQL (Prisma), Redis |

```bash
cat package.json | jq '.dependencies, .scripts'
ls -la Dockerfile* docker-compose*
cat .nvmrc 2>/dev/null || cat package.json | jq '.engines.node'
ls -la .github/workflows/
```

## 2. Docker setup

### Dockerfile multi-stage — Next.js standalone

```dockerfile
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache libc6-compat

FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci

FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

FROM base AS runner
ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
ENV PORT=3000
ENV HOSTNAME="0.0.0.0"
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/api/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"
CMD ["node", "server.js"]
```

`next.config.js`:

```js
const nextConfig = { output: 'standalone' };
module.exports = nextConfig;
```

### Dockerfile multi-stage — NestJS

```dockerfile
FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache libc6-compat
FROM base AS deps
COPY package.json package-lock.json* ./
RUN npm ci
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
FROM base AS runner
ENV NODE_ENV=production
RUN addgroup --system --gid 1001 nodejs && \
    adduser --system --uid 1001 nestjs
COPY --from=builder --chown=nestjs:nodejs /app/dist ./dist
COPY --from=builder --chown=nestjs:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=nestjs:nodejs /app/package.json ./package.json
USER nestjs
EXPOSE 3001
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3001/health', (r) => process.exit(r.statusCode === 200 ? 0 : 1))"
CMD ["node", "dist/main.js"]
```

### Dockerfile Bun

```dockerfile
FROM oven/bun:1 AS base
WORKDIR /app
FROM base AS deps
COPY package.json bun.lock ./
RUN bun install --frozen-lockfile
FROM base AS builder
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN bun run build
FROM base AS runner
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
EXPOSE 3001
CMD ["bun", "run", "start:prod"]
```

### .dockerignore

```gitignore
node_modules
npm-debug.log*
yarn-debug.log*
dist
.next
build
.git
.gitignore
*.md
.env*
.env.local
.idea
.vscode
coverage
.nyc_output
*.test.ts
*.spec.ts
__tests__
Dockerfile*
docker-compose*
.github
.gitlab-ci.yml
.DS_Store
```

## 3. Container registry

### GHCR (direkomendasikan)

```yaml
permissions:
  contents: read
  packages: write
```

Nama image: `ghcr.io/<owner>/<repo>:<tag>`.

### Amazon ECR

```bash
aws ecr create-repository \
  --repository-name my-api \
  --image-scanning-configuration scanOnPush=true \
  --region us-east-1

aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-east-1.amazonaws.com
```

### Docker Hub

```yaml
- uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```

## 4. CI/CD pipeline

```yaml
# .github/workflows/deploy.yml
name: Build and Deploy to EC2

on:
  push:
    branches: [main]
  workflow_dispatch:

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
      packages: write
    steps:
      - uses: actions/checkout@v4
      - uses: docker/setup-buildx-action@v3
      - uses: docker/login-action@v3
        with:
          registry: ${{ env.REGISTRY }}
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      - id: meta
        uses: docker/metadata-action@v5
        with:
          images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
          tags: |
            type=ref,event=branch
            type=sha,prefix=sha-
            type=raw,value=latest,enable={{is_default_branch}}
      - uses: docker/build-push-action@v5
        with:
          context: .
          push: true
          tags: ${{ steps.meta.outputs.tags }}
          cache-from: type=gha
          cache-to: type=gha,mode=max
          platforms: linux/amd64

  deploy:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Setup Tailscale
        uses: tailscale/github-action@v2
        with:
          oauth-client-id: ${{ secrets.TS_OAUTH_CLIENT_ID }}
          oauth-secret: ${{ secrets.TS_OAUTH_SECRET }}
          tags: tag:ci
      - uses: appleboy/ssh-action@v1.0.3
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          host: ${{ secrets.EC2_HOST }}
          username: ${{ secrets.EC2_USER }}
          key: ${{ secrets.EC2_SSH_KEY }}
          envs: GITHUB_TOKEN
          script: |
            set -e
            echo "$GITHUB_TOKEN" | docker login ghcr.io -u ${{ github.actor }} --password-stdin
            cd /home/${{ secrets.EC2_USER }}/app
            docker compose pull
            docker compose up -d --remove-orphans
            sleep 10
            curl -fsS http://localhost:3001/health || exit 1
            docker image prune -af --filter "until=24h"
```

## 5. EC2 deployment process

### Setup awal EC2

```bash
#!/bin/bash
set -e
sudo apt-get update && sudo apt-get upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
sudo apt-get install docker-compose-plugin -y
docker --version && docker compose version
mkdir -p ~/app && cd ~/app
cat > .env <<'EOF'
NODE_ENV=production
PORT=3001
EOF
chmod 600 .env
```

### Tailscale

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --ssh
tailscale status
tailscale ip -4
```

## 6. Multi-service deployment

```yaml
services:
  api:
    image: ghcr.io/myorg/api:${API_VERSION:-latest}
    restart: unless-stopped
    env_file: .env
    depends_on:
      redis:
        condition: service_healthy
    networks: [frontend, backend]
  redis:
    image: redis:7-alpine
    volumes: [redis_data:/data]
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
    networks: [backend]
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes: [./nginx.conf:/etc/nginx/nginx.conf:ro]
    depends_on: [api]
    networks: [frontend]

networks:
  frontend:
  backend:
    internal: true
volumes:
  redis_data:
```

## 7. Security best practices

- Container berjalan sebagai **non-root** (`USER nodejs`).
- Rahasia via Docker secrets / SSM Parameter Store / Secrets Manager, **never** di-commit.
- BuildKit secrets: `RUN --mount=type=secret,id=npm_token ...`.
- `chmod 600 .env`, jangan pernah log nilai secret.
- Least-privilege IAM, network internal untuk database.
- SSH deploy key khusus, bukan key pribadi utama.
- Tailscale ACL: `tag:ci` → `tag:server:22`.

## 8. Monitoring & health checks

Tiga pilar observability: **logs**, **metrics**, **traces**.

- Grafana menjawab *"THAT the system is broken"* (metrics/infra).
- Sentry menjawab *"WHY the system is broken"* (exception di kode).
- Endpoint `/health`, `/health/live`, `/health/ready` mengembalikan 200 bila sehat.

## 9. Rollback procedures

```bash
CURRENT_DIGEST=$(docker inspect --format='{{index .RepoDigests 0}}' api 2>/dev/null || echo "")
echo "$CURRENT_DIGEST" > .rollback_image
docker compose pull && docker compose up -d
for i in {1..30}; do
  curl -sf http://localhost:3001/health && break
  sleep 2
done
# bila gagal: docker compose down; sed -i tag lama; docker compose up -d
```

Blue-green: jalankan `api-green` di port 3002, uji, lalu alihkan Nginx ke green.

## 10. Docker cleanup

```bash
docker container prune -f
docker image prune -af --filter "until=24h"
docker volume prune -f
docker network prune -f
docker builder prune -af --filter "until=24h"
docker system df
```

Cron harian: `0 3 * * * /home/ubuntu/scripts/docker-cleanup.sh >> /var/log/docker-cleanup.log 2>&1`

## 11. Troubleshooting

| Masalah | Perintah |
| --- | --- |
| Container tidak start | `docker compose logs api --tail=100` |
| Health check gagal | `curl -v http://localhost:3001/health` |
| Image pull gagal | `docker manifest inspect ghcr.io/...` |
| SSH gagal | `ssh -i deploy_key -v user@host` |
| OOM | `free -h`, `docker stats --no-stream` |
| Port dipakai | `sudo lsof -i :3001` |

## 12. Checklist

**Pre-deployment:** Dockerfile multi-stage ✓, non-root ✓, health endpoint ✓, `.dockerignore` ✓, secrets terdokumentasi ✓, registry login ✓, EC2 Docker + Compose ✓, Tailscale ✓, SSH key ✓.

**Secrets GitHub:** `EC2_HOST`, `EC2_USER`, `EC2_SSH_KEY`, `TS_OAUTH_CLIENT_ID`, `TS_OAUTH_SECRET`, `GITHUB_TOKEN`.

**Post-deployment:** `docker ps`, `curl /health`, `docker compose logs --tail=50`, `docker stats`, rollback terdokumentasi.

## Referensi

- https://github.com/shipshitdev/skills/blob/main/skills/ec2-backend-deployer/references/full-guide.md
- https://docs.github.com/en/actions
- https://docs.docker.com/
- https://tailscale.com/kb/
