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

# O MESMO caminho das duas etapas, de propósito. O uv grava o interpretador em
# caminho absoluto no shebang de cada script do venv (`#!/app/.venv/bin/python`),
# então um venv construído em /build e copiado para /app fica com todos os
# scripts apontando para um caminho que não existe mais. O sintoma é enganoso:
# o shell responde "uvicorn: not found" mesmo com o arquivo presente e executável.
WORKDIR /app

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
COPY --from=build --chown=integra:integra /app /app

ENV PATH="/app/.venv/bin:${PATH}" \
    PYTHONUNBUFFERED=1

USER integra
EXPOSE 8000

# Forma JSON com `exec`, e as duas metades importam.
#
# A forma shell (`CMD uvicorn ...`) faz o /bin/sh ser o PID 1, e o sh NÃO
# repassa SIGTERM ao filho. Resultado: `docker compose restart` ou um deploy
# novo não avisam o uvicorn, que é morto por SIGKILL 10 s depois — derrubando
# as requisições em voo a cada atualização. O `exec` troca o shell pelo uvicorn,
# que então recebe o sinal e desliga com calma.
#
# O `sh -c` continua necessário porque ${SERVICO} é expandido em tempo de execução.
CMD ["sh", "-c", "exec uvicorn ${SERVICO}_service.main:app --host 0.0.0.0 --port 8000"]
