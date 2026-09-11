# Imagem única para todos os serviços — o membro do workspace uv é escolhido por
# build arg. Um Dockerfile por serviço divergiria em silêncio: o quinto serviço
# acabaria com uma versão de Python diferente do primeiro.
#
#   docker build --build-arg SERVICO=auth -t integra-auth services/

ARG PYTHON_VERSION=3.12

FROM python:${PYTHON_VERSION}-slim AS build
ARG SERVICO
COPY --from=ghcr.io/astral-sh/uv:0.11 /uv /usr/local/bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

WORKDIR /build

# Manifestos primeiro, código depois: mexer numa linha de código não invalida a
# camada de dependências, que é a cara de reconstruir.
COPY pyproject.toml uv.lock ./
COPY shared/pyproject.toml shared/
COPY auth/pyproject.toml auth/
COPY user/pyproject.toml user/
RUN uv sync --frozen --no-dev --no-install-workspace --package "integra-${SERVICO}"

COPY shared/ shared/
COPY auth/ auth/
COPY user/ user/
RUN uv sync --frozen --no-dev --package "integra-${SERVICO}"


FROM python:${PYTHON_VERSION}-slim AS runtime
ARG SERVICO
ENV SERVICO=${SERVICO}

# Sem uv e sem toolchain de build na imagem final: menos superfície para quem
# conseguir execução dentro do contêiner.
RUN useradd --create-home --uid 10001 integra
WORKDIR /app
COPY --from=build --chown=integra:integra /build /app

ENV PATH="/app/.venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1

USER integra
EXPOSE 8000

# Forma shell porque ${SERVICO} precisa ser expandido em tempo de execução.
CMD uvicorn ${SERVICO}_service.main:app --host 0.0.0.0 --port 8000
