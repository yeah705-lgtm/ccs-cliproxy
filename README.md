# ccs-cliproxy

Docker Compose project for running a CCS **CLIProxy**-style API proxy (ccproxy-api) locally or on a server.

## What this repo contains
- `docker-compose.yml` – service definition + volumes
- `.env.example` – template for required env vars (no secrets)

## Quick start

```bash
cp .env.example .env
# edit .env and set SECURITY__AUTH_TOKEN

docker compose up -d --build
curl http://localhost:8000/health
```

## Ports
- `8000` – API
- `1455` – OAuth callback port (Codex/Claude)

## OAuth (inside the container)
After the container is up:

```bash
docker exec -it ccproxy-api ccproxy auth login codex
docker exec -it ccproxy-api ccproxy auth login claude-api
```

Credentials are stored in named docker volumes.

## Notes
- Do **not** commit `.env`.
- Generate a fresh `SECURITY__AUTH_TOKEN` per environment.
