# syntax=docker/dockerfile:1
# Image de l'API : dépendances installées dans une couche dédiée (cache), code
# du projet ensuite, image finale sans uv ni outils de build, utilisateur non root.
FROM ghcr.io/astral-sh/uv:0.13.7 AS uv

FROM python:__PYTHON_VERSION__-slim AS builder
COPY --from=uv /uv /bin/uv
ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0
WORKDIR /app

# Couche dépendances : invalidée seulement si pyproject.toml / uv.lock changent.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --locked --no-dev --no-install-project

COPY pyproject.toml uv.lock README.md ./
COPY src ./src
# Pas de .git dans le contexte : version fournie par la release (tag vX.Y.Z).
ARG VERSION=0.0.0
RUN --mount=type=cache,target=/root/.cache/uv \
    SETUPTOOLS_SCM_PRETEND_VERSION="${VERSION#v}" uv sync --locked --no-dev --no-editable

FROM python:__PYTHON_VERSION__-slim
# Correctifs de sécurité Debian publiés après l'image de base (sinon le scan Trivy
# de la release bloque sur des CVE déjà corrigées en amont).
RUN apt-get update \
    && apt-get upgrade -y --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 10001 app
COPY --from=builder --chown=app:app /app/.venv /app/.venv
ENV PATH="/app/.venv/bin:$PATH" \
    PYTHONUNBUFFERED=1
USER app
WORKDIR /app
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=3)"]
CMD ["uvicorn", "__PACKAGE__.api.app:app", "--host", "0.0.0.0", "--port", "8000"]
