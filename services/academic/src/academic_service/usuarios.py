"""O que o academic-service pergunta ao user-service, e o que ele não pergunta.

## O que NÃO passa por aqui: o vínculo

O vínculo ativo viaja no **token**, nos claims `vinculoUniversidadeId` e
`vinculoCursoId`. É o desenho descrito em `integra_shared.security`: o preço é que
entrar ou sair de um vínculo só vale no token seguinte — no máximo 15 minutos — e
o ganho é que resolver visibilidade não custa uma ida ao user-service por
requisição.

A consequência boa aparece na falha: `escopo=minha` é atendido **inteiramente a
partir do token**. Com o user-service fora do ar, o feed da própria instituição
continua respondendo.

## O que passa: três coisas que o user-service é dono

1. **A lista de universidades do escopo `geral`** — vínculo + seguidas. Decide
   QUAIS instituições entram no feed, nunca O QUE se vê dentro delas. Se esta
   lista viesse errada, o feed mostraria instituições a mais ou a menos; nenhum
   post restrito escaparia por ela, porque o alcance é decidido pela cláusula de
   visibilidade, com o vínculo do token.
2. **A universidade da conta que publica**, com os cursos e o estado de ativação.
3. **Nome, sigla e foto** de universidades e autores, para montar os cards.

O item 3 é uma chamada por página de feed, em lote. A alternativa era copiar nome
e sigla para dentro de cada post na publicação — e era o erro do protótipo, que
gravava `nomeCompleto` dentro do post e via o nome envelhecer ali: trocar o nome
não alcançava o que já estava publicado.

## Falha

Nenhuma resposta parcial silenciosa. Sem o user-service, `geral` responde 503 com
mensagem de "tente novamente" em vez de um feed que parece completo e não está —
um feed que esconde metade das instituições sem dizer nada é pior que um erro,
porque o usuário conclui que não há nada publicado.
"""

from uuid import UUID

from pydantic import BaseModel, Field

from academic_service.settings import settings
from integra_shared import interno
from integra_shared.interno import ResumoDePerfil as ResumoDeAutor


class Curso(BaseModel):
    id: UUID
    nome: str


class ResumoDeUniversidade(BaseModel):
    """O cabeçalho do card: quem publicou, com os cursos dela.

    Os cursos vêm aqui porque a etiqueta de um post restrito precisa do **nome** do
    curso, e não só do id. Não é desperdício tão grande quanto parece: um post
    restrito a curso só é visível a quem tem vínculo naquele curso, então o nome a
    exibir é sempre de um curso desta mesma universidade.
    """

    id: UUID
    nome: str
    sigla: str
    foto_url: str | None = Field(default=None, alias="fotoUrl")
    cursos: list[Curso] = Field(default_factory=list)

    model_config = {"populate_by_name": True}

    def curso(self, curso_id: UUID | None) -> Curso | None:
        if curso_id is None:
            return None
        return next((c for c in self.cursos if c.id == curso_id), None)

    def tem_curso(self, curso_id: UUID) -> bool:
        """Se o curso é desta instituição.

        Existe como método para a rota não comparar listas à mão — e para o nome
        dizer o que a checagem significa: um post restrito a curso de outra
        faculdade não é "não encontrado", é campo errado.
        """
        return any(c.id == curso_id for c in self.cursos)


class UniversidadeDaConta(ResumoDeUniversidade):
    """O resumo mais a única coisa que só a publicação precisa: se a conta age.

    `conta_ativa` vem do banco do user-service, não de um claim: uma conta
    desativada com token válido seguiria publicando por até 15 minutos.
    """

    conta_ativa: bool = Field(alias="contaAtiva")


async def _pedir(caminho: str, params: dict | None = None) -> object:
    """Uma chamada interna ao user-service, com as credenciais deste serviço.

    O como (cabeçalho de serviço, tempo limite, tradução do erro) vive em
    `integra_shared.interno`; o que se pede é o que este módulo decide.
    """
    return await interno.pedir(settings.user_service_url, settings.servico_token, caminho, params)


async def universidade_da_conta(conta_id: UUID) -> UniversidadeDaConta:
    """A instituição que esta conta `faculdade` administra, com cursos e ativação."""
    dados = await _pedir(f"/universidades/interno/de-conta/{conta_id}")
    return UniversidadeDaConta.model_validate(dados)


async def universidades_do_escopo(usuario_id: UUID) -> list[UUID]:
    """Vínculo + seguidas. O conjunto de instituições do escopo `geral`.

    Vazio é estado normal: é o de quem acabou de entrar e ainda não seguiu nem
    informou CPF em nenhuma instituição. A tela mostra o convite, não um erro.
    """
    dados = await _pedir(f"/users/interno/{usuario_id}/seguindo/universidades")
    return [UUID(str(i)) for i in dados]  # type: ignore[union-attr]


async def resumos_de_universidades(ids: set[UUID]) -> dict[UUID, ResumoDeUniversidade]:
    """Cabeçalhos de card, em lote, indexados por id.

    Devolve dicionário porque quem chama precisa casar cada post com a sua
    instituição, e um `for` aninhado sobre lista faria isso em O(n²) por página.
    """
    if not ids:
        return {}
    dados = await _pedir("/universidades/interno/resumos", {"ids": [str(i) for i in ids]})
    resumos = [ResumoDeUniversidade.model_validate(d) for d in dados]  # type: ignore[union-attr]
    return {r.id: r for r in resumos}


async def resumos_de_autores(ids: set[UUID]) -> dict[UUID, ResumoDeAutor]:
    """Autores de comentário, em lote, indexados por id.

    Mesmo lote que o feed-service usa para os autores de post: a rota e o formato
    são do user-service, então a chamada mora em `integra_shared.interno`.
    """
    return await interno.resumos_de_perfis(
        settings.user_service_url, settings.servico_token, ids
    )
