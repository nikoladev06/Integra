import os

os.environ.setdefault("INTEGRA_JWT_SECRET", "segredo-de-teste-com-32-caracteres-ok")
os.environ.setdefault("INTEGRA_AMBIENTE", "local")
os.environ.setdefault("INTEGRA_SERVICO_TOKEN", "token-de-servico-com-32-caracteres-ok")
os.environ.setdefault("INTEGRA_DATABASE_URL", "postgresql+asyncpg://u:p@localhost/integra")
