"""A regra de visibilidade, e o único lugar onde ela existe.

Esta é a peça que a Sprint 4 põe à prova: é a primeira vez que a regra do vínculo
sai do `user-service` e passa a decidir o que alguém lê.

## A regra

    a conta AUTORA do post             qualquer       vê
                                         alcance

    vínculo ATIVO com a universidade   publico        vê
                                       institucional  vê
                                       curso == o do  vê
                                         vínculo
                                       outro curso    NÃO vê

    segue, sem vínculo                 publico        vê
                                       institucional  NÃO vê
                                       curso          NÃO vê

    nem segue nem tem vínculo          publico        vê
                                       o resto        NÃO vê

A primeira linha não estava no rascunho, e a falta dela era um furo: **a conta
`faculdade` não tem vínculo** — vínculo é de aluno. Sem essa cláusula, a
instituição publicava um comunicado restrito a um curso e em seguida não conseguia
abrir o que acabara de publicar; `GET` respondia 404 no próprio post. Não é
exceção à regra, é a regra dita inteira: o autor alcança o que escreveu.

## Três coisas que não concedem nada

1. **Formação declarada** — o usuário digita o que quiser, sem verificação.
2. **Formação verificada sem vínculo ativo** — quem se formou mantém o selo e
   volta a ver apenas os públicos. O selo é currículo, não credencial.
3. **Seguir** — coloca a instituição no feed; não abre o conteúdo interno.

Nenhuma das três chega aqui, e isso é estrutural em vez de disciplinado:
[UsuarioAutenticado] não tem campo de formação, e a lista de seguidas entra na
consulta como **conjunto de universidades do escopo**, num parâmetro separado do
que esta cláusula decide. Não há como confundi-los porque não são o mesmo
argumento.

## Duas formas da mesma regra, e por que as duas existem

[pode_ver] é a versão em Python, para uma linha já carregada — o `GET` de um post
por id, e a checagem antes de curtir ou comentar. [clausula_de_visibilidade] é a
versão em SQL, para o feed não trazer do banco o que vai descartar.

Duas escritas da mesma regra divergem calado, e é o risco conhecido desta
duplicação. O que fecha isso é `test_as_duas_formas_da_regra_concordam`: ele
monta todas as combinações de post e leitor, roda a consulta e compara com a
função, e falha se uma disser algo que a outra não diz.

Filtrar no cliente nunca foi opção. Uma tela que recebe o post e esconde tem o
post na resposta da API, e a regra passa a ser decoração — contornável por quem
ler o JSON em vez de olhar a tela.
"""

from uuid import UUID

from sqlalchemy import ColumnElement, and_, or_

from academic_service.models import Post, Visibilidade
from integra_shared.security import UsuarioAutenticado


def pode_ver(post: Post, usuario: UsuarioAutenticado) -> bool:
    """Se este leitor alcança este post. A regra em Python.

    Note o que **não** é consultado: nem formação, nem lista de seguidas. Seguir
    decide se a universidade entra no feed; não decide o que o leitor vê dentro
    dela.
    """
    # O autor alcança o que escreveu, em qualquer alcance. Vem primeiro porque é
    # o único caso que não olha vínculo nenhum.
    if post.autor_id == usuario.id:
        return True

    if post.visibilidade == Visibilidade.PUBLICO:
        return True

    # Daqui para baixo, tudo exige vínculo ativo com ESTA universidade. Vínculo
    # com outra não vale, e `tem_vinculo_com` já devolve False sem vínculo algum.
    if not usuario.tem_vinculo_com(post.universidade_id):
        return False

    if post.visibilidade == Visibilidade.INSTITUCIONAL:
        return True

    # `curso`: o vínculo tem que ser no curso do post. A comparação com None do
    # lado esquerdo é impossível aqui — quem tem vínculo tem curso —, mas o
    # `is not None` fica explícito para a leitura não depender disso.
    return post.curso_id is not None and usuario.vinculo_curso_id == post.curso_id


def clausula_de_visibilidade(usuario: UsuarioAutenticado) -> ColumnElement[bool]:
    """A mesma regra como filtro SQL, para o feed.

    Montada condicionalmente em vez de deixar o `NULL` do Postgres resolver. Um
    `Post.universidade_id == None` renderia `= NULL`, que não é verdadeiro nem
    falso: funcionaria por acidente aqui, e a próxima pessoa a mexer numa negação
    ou num `NOT IN` herdaria uma expressão que não tem valor lógico. Sem vínculo,
    o resultado é `visibilidade = 'publico'` e nada mais.
    """
    proprio = Post.autor_id == usuario.id
    publico = Post.visibilidade == Visibilidade.PUBLICO

    if not usuario.tem_vinculo:
        # O caso de toda conta `faculdade` e `empresa`, e de todo aluno recém
        # cadastrado: os públicos, mais o que a própria conta publicou.
        return or_(proprio, publico)

    universidade: UUID = usuario.vinculo_universidade_id  # type: ignore[assignment]
    da_minha_instituicao = Post.universidade_id == universidade

    return or_(
        proprio,
        publico,
        and_(Post.visibilidade == Visibilidade.INSTITUCIONAL, da_minha_instituicao),
        and_(
            Post.visibilidade == Visibilidade.CURSO,
            da_minha_instituicao,
            Post.curso_id == usuario.vinculo_curso_id,
        ),
    )
