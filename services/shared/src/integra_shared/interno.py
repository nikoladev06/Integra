"""Chamadas de serviço para serviço, e o resumo de perfil que todas elas buscam.

Nasceu duplicado: o `academic-service` escreveu este cliente na Sprint 4, e na
Sprint 5 o `feed` e o `jobs` precisariam do mesmo — três cópias de um cliente
HTTP, três traduções do mesmo 503, três formas de ler `fotoUrl`. Subiu para cá
antes da segunda cópia existir.

## O que fica aqui e o que fica em cada serviço

Aqui: **como** se chama (o cabeçalho de serviço, o tempo limite, a tradução do
erro) e o **resumo de perfil**, que os três serviços pedem igual para montar
cards de autor.

Em cada serviço: **o que** se chama. O academic pede universidades e cursos; o
feed pede quem o leitor segue; o jobs pede o resumo da empresa. Trazer os
caminhos para cá faria este módulo saber das regras de todos os pilares.

## Por que um cliente por chamada

Cada chamada abre e fecha o próprio `AsyncClient`. Um cliente global economizaria
o handshake, mas guardaria um pool preso ao event loop em que nasceu — a mesma
classe de problema que fez o conftest criar um engine por teste.
"""

from uuid import UUID

import httpx
from pydantic import BaseModel, Field

from integra_shared.errors import AppError

_TEMPO_LIMITE = httpx.Timeout(10.0)


class ResumoDePerfil(BaseModel):
    """Nome, arroba e foto. O cabeçalho de qualquer card de autor.

    É o resumo que `GET /users/interno/resumos` devolve, e deliberadamente **não**
    é o perfil completo: arrastar formações, vínculo, CPF e telefone para cá faria
    um serviço de posts depender do formato de perfil inteiro — e um dia entregaria
    CPF num card de comentário porque o tipo de saída tinha o campo.
    """

    id: UUID
    nome_completo: str = Field(alias="nomeCompleto")
    username: str
    foto_url: str | None = Field(default=None, alias="fotoUrl")

    model_config = {"populate_by_name": True}


def indisponivel() -> AppError:
    """503 com mensagem única para timeout, conexão recusada e 5xx do outro serviço.

    Para quem está na tela a ação é a mesma — tentar de novo —, e distinguir os
    casos só serviria a quem estivesse mapeando a topologia interna.

    Nunca uma resposta parcial silenciosa: um feed que esconde metade das
    instituições sem dizer nada é pior que um erro, porque o usuário conclui que
    não há nada publicado.
    """
    return AppError(
        code="dependencia_indisponivel",
        message="Não foi possível carregar os dados agora. Tente novamente em instantes.",
        status_code=503,
    )


async def pedir(
    base_url: str,
    token: str,
    caminho: str,
    params: dict | None = None,
) -> object:
    """Um `GET` interno, com o segredo de serviço no cabeçalho.

    `token` é o `INTEGRA_SERVICO_TOKEN`, distinto do JWT: quem chama é um serviço,
    não um usuário. As rotas `/…/interno/…` do user-service ficam fora do OpenAPI
    público e exigem esse cabeçalho.
    """
    try:
        async with httpx.AsyncClient(base_url=base_url, timeout=_TEMPO_LIMITE) as cliente:
            resposta = await cliente.get(
                caminho,
                params=params,
                headers={"X-Servico-Token": token},
            )
    except httpx.HTTPError as erro:
        raise indisponivel() from erro

    if resposta.status_code == 200:
        return resposta.json()

    # 403 e 404 são casos de negócio, não de infraestrutura — a conta `faculdade`
    # que não administra universidade nenhuma, por exemplo. Repassar o código do
    # outro serviço mantém a mensagem exata, em vez de traduzi-la para um 503 que
    # mandaria o usuário "tentar de novo" num erro que não passa com o tempo.
    try:
        corpo = resposta.json()
    except ValueError:
        corpo = {}

    if resposta.status_code in (403, 404):
        raise AppError(
            code=corpo.get("code", "permissao_negada"),
            message=corpo.get("message", "Sua conta não tem permissão para esta ação"),
            status_code=resposta.status_code,
        )

    raise indisponivel()


async def resumos_de_perfis(
    base_url: str,
    token: str,
    ids: set[UUID],
) -> dict[UUID, ResumoDePerfil]:
    """Cabeçalhos de card, em lote, indexados por id.

    Devolve dicionário porque quem chama precisa casar cada linha com o seu autor,
    e um `for` aninhado sobre lista faria isso em O(n²) por página.

    Uma chamada por página, e não uma por item: uma página de 20 comentários de 5
    pessoas custa uma consulta. A alternativa era copiar nome e arroba para dentro
    de cada registro na escrita — o erro do protótipo, que via o nome envelhecer
    ali.
    """
    if not ids:
        return {}
    dados = await pedir(base_url, token, "/users/interno/resumos", {"ids": [str(i) for i in ids]})
    resumos = [ResumoDePerfil.model_validate(d) for d in dados]  # type: ignore[union-attr]
    return {r.id: r for r in resumos}
