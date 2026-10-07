"""Quais posts entram no feed de um leitor — e por que isto NÃO é autorização.

## A diferença em relação a `academic_service.visibilidade`

Lá a cláusula decide **o que alguém pode ver**: um post restrito a um curso não
alcança quem não tem vínculo naquele curso, e a regra existe em duas formas
(Python e SQL) com um teste comparando as duas, porque errá-la vaza comunicado
interno.

Aqui não há nada a vazar. **Todo post profissional é legível por qualquer conta
autenticada** — `GET /feed/posts/{id}` nunca responde 404 por permissão. O que
este módulo monta é a consulta do **feed**, que é curadoria: o que aparece por
padrão numa lista que ninguém pediu item por item.

A consequência é que existe uma forma só da regra, e não duas. Não há `pode_ver`
para comparar, porque não há pergunta "este leitor alcança este post?" — a
resposta é sempre sim. Escrever a segunda forma só para ter simetria com o
acadêmico criaria a duplicação que lá é um custo aceito e aqui não compra nada.

## O conjunto

O feed de um leitor é a união de dois ramos, e nada além deles:

    autor_id IN (seguidos + o próprio leitor)     origem: seguindo
    autor_universidade_id IN (universidades)      origem: recomendado

`universidades` é vínculo + seguidas, e vem da **mesma** rota interna do
user-service que alimenta o escopo `geral` do feed acadêmico. Uma segunda
definição de "as universidades do usuário" divergiria da primeira, e o sintoma
seria um feed recomendando por um critério enquanto o outro lista por outro.

O próprio leitor entra no primeiro ramo porque ninguém precisa de explicação para
se ver no próprio feed — e um rótulo "recomendado" no que ele mesmo escreveu seria
absurdo na tela.

## Empresa nunca é recomendada, e o nulo é o que garante isso

Conta `empresa` não tem vínculo, então `autor_universidade_id` é nulo nos posts
dela — e `NULL IN (...)` nunca é verdadeiro. Ela alcança apenas quem a segue.
Não é efeito colateral: é o que o contrato promete, e vem de graça em vez de
precisar de uma cláusula própria.

## O escopo da tela estreita, nunca amplia

`geral | empresas | pessoas` entra com `AND` sobre a união acima, filtrando por
`autor_tipo`. Pedir `escopo=empresas` não traz empresa nenhuma que o leitor não
siga: o `AND` não tem como acrescentar ao conjunto, só remover dele. É a mesma
disciplina do parâmetro `visibilidade` do acadêmico — um `OR` ali transformaria
filtro em concessão.
"""

from typing import Literal
from uuid import UUID

from sqlalchemy import ColumnElement, or_

from feed_service.models import Post, TipoDeAutor

Escopo = Literal["geral", "empresas", "pessoas"]

# O `escopo` da tela mapeado no tipo de conta que ele deixa passar. `geral` não
# está aqui: ele é a ausência de filtro, e um valor `None` no dicionário faria
# cada chamador conferir se a chave existe E se o valor é nulo.
_TIPO_POR_ESCOPO: dict[str, TipoDeAutor] = {
    "empresas": TipoDeAutor.EMPRESA,
    "pessoas": TipoDeAutor.ALUNO,
}


def clausula_do_feed(
    leitor_id: UUID,
    seguidos: list[UUID],
    universidades: list[UUID],
) -> ColumnElement[bool]:
    """A união dos dois ramos: quem o leitor segue, e quem lhe é recomendado.

    Montada condicionalmente em vez de emitir `IN ()` vazio. Um `IN` de lista
    vazia é aceito pelo Postgres e nunca casa — funcionaria por acidente —, mas a
    próxima pessoa a mexer numa negação ou num `NOT IN` herdaria uma expressão
    cujo valor lógico depende de a lista estar vazia.

    O próprio leitor entra sempre, mesmo sem seguir ninguém: quem publicou se vê
    no próprio feed.
    """
    ramos: list[ColumnElement[bool]] = [Post.autor_id.in_([leitor_id, *seguidos])]

    if universidades:
        ramos.append(Post.autor_universidade_id.in_(universidades))

    return or_(*ramos)


def clausula_de_tipo(escopo: Escopo) -> ColumnElement[bool] | None:
    """O filtro do seletor da tela, ou `None` em `geral`.

    Devolve `None` em vez de uma cláusula sempre-verdadeira porque quem chama
    precisa saber se há filtro: acrescentar um `WHERE true` funciona e some no
    plano de execução, mas torna impossível ler na consulta se o escopo foi
    aplicado.
    """
    tipo = _TIPO_POR_ESCOPO.get(escopo)
    return None if tipo is None else Post.autor_tipo == tipo


def origem(autor_id: UUID, leitor_id: UUID, seguidos: set[UUID]) -> str:
    """Por que este post está no feed — `seguindo` ou `recomendado`.

    Calculado em Python, e não na consulta: é uma pergunta sobre pertencer a um
    conjunto que quem chama já tem em memória, e resolvê-la no banco custaria uma
    coluna computada por linha para reproduzir um `in` de set.

    O próprio autor conta como `seguindo` — ver a nota no módulo.
    """
    return "seguindo" if autor_id == leitor_id or autor_id in seguidos else "recomendado"


# Não existe atalho de "feed vazio sem consultar o banco", como no academic-service.
# Lá a lista de universidades pode ser vazia e a consulta inteira fica sem `WHERE`
# possível; aqui o primeiro ramo sempre tem ao menos o id do leitor, então a
# consulta tem sempre o que comparar — e um retorno antecipado esconderia os
# próprios posts de quem acabou de publicar e ainda não segue ninguém, que é o caso
# exato de uma conta nova testando o app.
