"""O que o feed-service pergunta ao user-service, e o que ele não pergunta.

## O que NÃO passa por aqui

**Autorização de leitura.** Não existe. Todo post profissional é legível por
qualquer conta autenticada, então nenhuma consulta deste serviço precisa saber
nada sobre o leitor além do id dele — que vem do token.

**CPF, CNPJ, e-mail e telefone.** Nem para conferir ativação: a rota
`/users/interno/{id}/ativacao` devolve dois campos e nada mais, justamente para
este serviço não ter acesso ao que um serviço de posts não tem o que fazer com.

## O que passa: três coisas

1. **O escopo do feed** — `seguidos` + `universidades`, numa chamada. Uma por
   página de feed. É curadoria, não permissão: se a lista vier errada, o feed
   mostra gente a mais ou a menos, e não há conteúdo restrito para escapar.
2. **A ativação da conta que publica.** Uma por publicação, e só na escrita.
   Vem do banco, não de um claim — no JWT, uma conta desativada seguiria
   publicando por até 15 minutos.
3. **Nome, arroba e foto** dos autores, em lote, para montar os cards.

O item 3 é uma chamada por página. A alternativa era copiar `nomeCompleto` para
dentro de cada post na publicação — o erro do protótipo, que via o nome envelhecer
ali: trocar de nome não alcançava o que já estava publicado.

## Falha

Nenhuma resposta parcial silenciosa. Sem o user-service, o feed responde 503 com
"tente novamente" em vez de uma lista que parece completa e não está.

A exceção deliberada é a **leitura de um post por id**: ela não chama o escopo, só
os resumos, e por isso continua respondendo enquanto o user-service estiver de pé
para o lote de perfis. Não há um equivalente ao `escopo=minha` do acadêmico, que é
atendido inteiramente pelo token — aqui todo card precisa do nome de alguém, e
nome é do user-service.
"""

from uuid import UUID

from pydantic import BaseModel, Field

from feed_service.settings import settings
from integra_shared import interno
from integra_shared.interno import ResumoDePerfil as ResumoDeAutor


class EscopoDoFeed(BaseModel):
    """As duas listas que decidem o que entra no feed, e por qual ramo.

    Vazias é estado normal: é o de quem acabou de entrar e ainda não seguiu ninguém
    nem informou CPF em nenhuma instituição. A tela mostra o convite, não um erro —
    e os próprios posts do leitor continuam aparecendo, porque o id dele entra no
    primeiro ramo sem passar por esta lista.
    """

    universidades: list[UUID] = Field(default_factory=list)
    seguidos: list[UUID] = Field(default_factory=list)

    model_config = {"populate_by_name": True}


class Ativacao(BaseModel):
    """Se a conta pode publicar, e o tipo dela.

    O `tipo` vem daqui, e não do token, por um motivo estreito: ele é gravado no
    post (`autor_tipo`) e decide o escopo em que o post aparece para sempre. Um
    claim de token é o que o auth-service escreveu no login; este é o que está no
    banco agora. Para um campo que não se edita mais, a diferença é pequena — mas a
    chamada já está sendo feita para conferir a ativação, então usar o valor
    autoritativo não custa nada.
    """

    ativa: bool
    tipo: str


async def _pedir(caminho: str, params: dict | None = None) -> object:
    """Uma chamada interna ao user-service, com as credenciais deste serviço."""
    return await interno.pedir(settings.user_service_url, settings.servico_token, caminho, params)


async def escopo_do_feed(usuario_id: UUID) -> EscopoDoFeed:
    """Quem o leitor segue, e as universidades que o tornam alvo de recomendação."""
    return EscopoDoFeed.model_validate(await _pedir(f"/users/interno/{usuario_id}/escopo-do-feed"))


async def ativacao(usuario_id: UUID) -> Ativacao:
    """Se esta conta pode publicar. Consultado no banco, a cada publicação."""
    return Ativacao.model_validate(await _pedir(f"/users/interno/{usuario_id}/ativacao"))


async def resumos_de_autores(ids: set[UUID]) -> dict[UUID, ResumoDeAutor]:
    """Cabeçalhos de card, em lote, indexados por id."""
    return await interno.resumos_de_perfis(settings.user_service_url, settings.servico_token, ids)
