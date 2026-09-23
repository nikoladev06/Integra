"""Carga inicial de universidades e cursos.

Sem isto o cadastro não fecha: a tela pede universidade e curso, e a validação do
par exige que existam. É a dependência mais fácil de descobrir tarde — o serviço
sobe, o `/health` responde 200, e só o primeiro cadastro revela que falta.

Rodar:
    uv run --project .. python -m user_service.seed

Idempotente: pode rodar quantas vezes quiser, em qualquer ambiente.

Os identificadores são **determinísticos** (UUIDv5 sobre o nome), então a FATEC
tem o mesmo id na máquina de cada dev, na CI e na VM. Isso permite conferir um
bug citando o id sem perguntar "qual é o seu?", e deixa as fixtures do Flutter
casarem com o banco real.
"""

import asyncio
from uuid import UUID, uuid5

from sqlalchemy import select

from user_service.database import engine, fabrica_de_sessao
from user_service.models import Curso, Universidade

# Namespace fixo do projeto. Trocar este valor muda TODOS os ids: só faça isso
# numa base vazia.
NAMESPACE = UUID("6f1d5b2a-8c34-4f21-9a7e-2b0c5d3e4f60")


def _id_de(*partes: str) -> UUID:
    return uuid5(NAMESPACE, "|".join(partes))


# Instituições da região onde o projeto nasce. Acrescentar aqui é seguro: o seed
# insere o que falta e não toca no que existe.
CATALOGO: dict[tuple[str, str], list[str]] = {
    (
        "Faculdade de Tecnologia de Ribeirão Preto",
        "FATEC RP",
    ): [
        "Análise e Desenvolvimento de Sistemas",
        "Gestão Empresarial",
        "Gestão da Produção Industrial",
    ],
    (
        "Universidade de São Paulo",
        "USP",
    ): [
        "Ciência da Computação",
        "Sistemas de Informação",
        "Engenharia de Computação",
    ],
    (
        "Universidade Estadual Paulista",
        "UNESP",
    ): [
        "Ciência da Computação",
        "Engenharia de Produção",
    ],
    (
        "Instituto Federal de São Paulo",
        "IFSP",
    ): [
        "Análise e Desenvolvimento de Sistemas",
        "Engenharia Elétrica",
    ],
}


async def semear() -> tuple[int, int]:
    """Insere o que falta. Devolve (universidades novas, cursos novos)."""
    universidades_novas = 0
    cursos_novos = 0

    async with fabrica_de_sessao() as sessao:
        for (nome, sigla), cursos in CATALOGO.items():
            uni_id = _id_de("universidade", sigla)

            existente = await sessao.get(Universidade, uni_id)
            if existente is None:
                # Checa por nome também: uma base semeada antes dos ids
                # determinísticos teria a mesma universidade com outro id, e
                # inserir de novo violaria a unicidade do nome.
                por_nome = await sessao.execute(
                    select(Universidade).where(Universidade.nome == nome)
                )
                if por_nome.scalar_one_or_none() is None:
                    sessao.add(Universidade(id=uni_id, nome=nome, sigla=sigla))
                    universidades_novas += 1
                    await sessao.flush()

            for nome_do_curso in cursos:
                curso_id = _id_de("curso", sigla, nome_do_curso)
                if await sessao.get(Curso, curso_id) is None:
                    sessao.add(Curso(id=curso_id, universidade_id=uni_id, nome=nome_do_curso))
                    cursos_novos += 1

        await sessao.commit()

    return universidades_novas, cursos_novos


async def _principal() -> None:
    universidades, cursos = await semear()
    print(f"seed: {universidades} universidade(s) e {cursos} curso(s) inseridos")
    await engine.dispose()


if __name__ == "__main__":
    asyncio.run(_principal())
