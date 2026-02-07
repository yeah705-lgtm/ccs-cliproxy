# ccs-cliproxy wrapper image
#
# Builds ccproxy-api from source in ./ccproxy-api and adds a lightweight entrypoint
# that maps a single bind-mounted host directory (/inject_dir) to the expected
# persistence locations (/root/.ccproxy, /root/.claude, /root/.opencode, /tmp/ccproxy).

# Stage 1: install bun + claude-code
FROM oven/bun:1-slim AS bun-deps
RUN bun install -g @anthropic-ai/claude-code

# Stage 2: Python builder (uv)
FROM ghcr.io/astral-sh/uv:python3.11-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 UV_LINK_MODE=copy
ENV UV_PYTHON_DOWNLOADS=0

WORKDIR /app

# Install git
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Install Python deps
RUN --mount=type=cache,target=/root/.cache/uv \
  --mount=type=bind,source=ccproxy-api/uv.lock,target=uv.lock \
  --mount=type=bind,source=ccproxy-api/pyproject.toml,target=pyproject.toml \
  uv sync --locked --no-install-project --no-dev

# Copy ccproxy-api source
COPY ccproxy-api/ /app/

# Install project
RUN --mount=type=cache,target=/root/.cache/uv \
  uv sync --locked --no-dev

# Stage 3: runtime
FROM python:3.11-slim-bookworm

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
  --mount=type=cache,target=/var/lib/apt,sharing=locked \
  apt-get update && apt-get install -y \
    curl wget ripgrep fd-find exa sed mawk procps \
    build-essential \
    git \
  && rm -rf /var/lib/apt/lists/*

# bun -> node/npx compatibility
COPY --from=bun-deps /usr/local/bin/bun /usr/local/bin/
COPY --from=bun-deps /usr/local/bin/bunx /usr/local/bin/
RUN ln -s /usr/local/bin/bun /usr/local/bin/node && ln -s /usr/local/bin/bunx /usr/local/bin/npx

# install claude-code CLI
COPY --from=bun-deps /root/.bun/install/global /app/bun_global
RUN ln -s /app/bun_global/node_modules/\@anthropic-ai/claude-code/cli.js /usr/local/bin/claude

# app runtime
COPY --from=builder /app /app
WORKDIR /app

ENV PATH="/app/.venv/bin:/app/bun_global/bin:$PATH"
ENV PYTHONPATH=/app
ENV SERVER__HOST=0.0.0.0
ENV SERVER__PORT=8000
ENV LOGGING__LEVEL=INFO
ENV LOGGING__FORMAT=json

# inject-dir mapping entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]

EXPOSE ${SERVER__PORT:-8000}

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${SERVER__PORT:-8000}/health || exit 1

CMD ["ccproxy"]
