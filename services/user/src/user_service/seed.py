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
from hashlib import blake2b
from uuid import UUID, uuid5

from sqlalchemy import select

from integra_shared.cnpj import gerar_valido as gerar_cnpj
from user_service.database import engine, fabrica_de_sessao
from user_service.models import Curso, Universidade

# Namespace fixo do projeto. Trocar este valor muda TODOS os ids: só faça isso
# numa base vazia.
NAMESPACE = UUID("6f1d5b2a-8c34-4f21-9a7e-2b0c5d3e4f60")


def _cnpj_de_exemplo(sigla: str) -> str:
    """Semente estável a partir da sigla, para o CNPJ de exemplo.

    Era `hash(sigla)`, que **não** é determinístico entre execuções: o Python
    randomiza o hash de `str` por processo desde a 3.3, salvo `PYTHONHASHSEED`
    fixo. O comentário logo abaixo prometia determinismo e a base ganhava um CNPJ
    diferente a cada vez que era semeada do zero — o suficiente para uma conta
    institucional reivindicar a universidade na máquina de um dev e não na do
    outro, com os dois olhando o mesmo `seed.py`.

    `blake2b` é estável entre processos, versões e plataformas. Continua sendo um
    valor de exemplo: o que resolve de vez é preencher os CNPJ verdadeiros.
    """
    digest = blake2b(sigla.encode("utf-8"), digest_size=8).digest()
    return gerar_cnpj(int.from_bytes(digest, "big") % 100_000_000)


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
                    # CNPJ determinístico, DERIVADO DA SIGLA e não real.
                    # Os CNPJ verdadeiros das instituições precisam ser
                    # preenchidos antes de qualquer uso sério: uma conta só
                    # reivindica a universidade cujo CNPJ ela informar, então
                    # com estes valores de exemplo a FATEC de verdade não
                    # conseguiria assumir a linha semeada.
                    sessao.add(
                        Universidade(
                            id=uni_id,
                            nome=nome,
                            sigla=sigla,
                            cnpj=_cnpj_de_exemplo(sigla),
                        )
                    )
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
