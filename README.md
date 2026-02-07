# ccs-cliproxy

Docker Compose project for running a CCS **CLIProxy**-style API proxy (**ccproxy-api**) locally or on a server.

## Where the code comes from
This repo is the *wrapper* (compose + env + docs). The actual proxy implementation lives in **ccproxy-api**.

You need to place the source at:

```
./ccproxy-api/
```

Recommended upstream (the one I used earlier):
- https://github.com/CaddyGlow/ccproxy-api

Fetch it like this:

```bash
git clone https://github.com/CaddyGlow/ccproxy-api ./ccproxy-api
```

(If you already have it elsewhere, you can also use a git submodule or symlink; the compose build context expects `./ccproxy-api`.)

## What this repo contains
- `docker-compose.yml` – service definition + named volumes
- `.env.example` – template for required env vars (no secrets)

## Build & run

```bash
# 1) get proxy code
if [ ! -d ccproxy-api ]; then git clone https://github.com/CaddyGlow/ccproxy-api ./ccproxy-api; fi

# 2) configure env
cp .env.example .env
# edit .env and set SECURITY__AUTH_TOKEN

# 3) build image and start container
docker compose up -d --build

# 4) verify
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
