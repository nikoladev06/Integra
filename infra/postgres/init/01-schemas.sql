-- Um schema por serviço, conforme o escopo: separação lógica agora, com a porta
-- aberta para separar fisicamente depois sem reescrever consulta.
--
-- Roda uma única vez, na criação do volume. Se precisar reaplicar em
-- desenvolvimento: docker compose down -v (apaga os dados).

CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS "user";
CREATE SCHEMA IF NOT EXISTS academic;
CREATE SCHEMA IF NOT EXISTS feed;
CREATE SCHEMA IF NOT EXISTS jobs;

-- Busca de usuários por username e nome usa ILIKE com índice trigram
-- (contracts/user.openapi.yaml, GET /users).
--
-- A migração inicial do user-service também cria a extensão, e é ela que manda:
-- este arquivo só roda na criação do volume do compose, então uma base nova em
-- qualquer outro lugar — o serviço postgres da CI, a VM no primeiro deploy —
-- nunca o vê. A linha fica por conveniência em desenvolvimento; apagá-la não
-- quebra nada, apagar a da migração quebra tudo.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
