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
-- (contracts/user.openapi.yaml, GET /users). A extensão precisa existir antes
-- da migração que cria o índice, na Sprint 3.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
