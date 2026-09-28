"""Tabelas do academic-service, no schema `academic`.

## Três tabelas, e o que cada uma sabe

    Post        um comunicado da faculdade, com um nível de alcance
    Curtida     (post, usuário) — chave primária composta, não coluna contadora
    Comentario  texto de quem pode ver o post

## Por que não há chave estrangeira para `usuarios` nem para `universidades`

Elas vivem no schema `user`, de outro serviço. Uma FK entre schemas funcionaria
no Postgres de hoje — é a mesma instância — e é exatamente por isso que ela é a
armadilha: amarraria os dois serviços num ponto que nenhuma consulta declara, e
a separação física que o plano deixa em aberto passaria a exigir reescrever
schema em vez de mudar DSN. O filtro `include_name` das migrações também não veria
a tabela do outro lado, então o Alembic proporia apagá-la.

O que fica no lugar: `universidade_id`, `autor_id` e `curso_id` são identificadores
**opacos**. A integridade deles é do serviço dono, e a consequência aceita é que
um post pode citar uma universidade que o user-service apagou. Nesse caso o
cabeçalho do card não resolve e o post não entra na resposta — em vez de um 500
por linha órfã.

## Onde a regra de visibilidade NÃO está

Não está aqui. Um post não guarda quem pode vê-lo: guarda o **alcance**
(`visibilidade` + `curso_id`), e quem pode é decidido na consulta, cruzando isso
com o vínculo do leitor. Materializar a lista de destinatários na publicação
significaria que criar um vínculo novo não daria acesso ao que já foi publicado —
e que remover um vínculo não tiraria.
"""

from datetime import datetime
from enum import StrEnum
from uuid import UUID, uuid4

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    func,
)
from sqlalchemy.dialects.postgresql import UUID as PgUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from integra_shared.db import criar_base

Base = criar_base("academic")

LIMITE_DO_POST = 2000
LIMITE_DO_COMENTARIO = 1000


class Visibilidade(StrEnum):
    """O alcance de um post. Três níveis, e só o primeiro dispensa vínculo.

        publico        qualquer conta autenticada
        institucional  vínculo ativo com esta universidade
        curso          vínculo ativo NESTE curso dela

    Não existe um quarto nível "rascunho": algo que a faculdade guarda para si
    tem outro ciclo de vida e seria outra entidade, não um post de alcance zero.
    """

    PUBLICO = "publico"
    INSTITUCIONAL = "institucional"
    CURSO = "curso"


class Post(Base):
    """Um comunicado publicado por uma conta `faculdade`."""

    __tablename__ = "posts"
    __table_args__ = (
        # A invariante central do registro, no banco e não só no schema Pydantic:
        # `curso_id` existe exatamente quando o alcance é `curso`.
        #
        # Nos dois sentidos, de propósito. Um `curso_id` sobrando num post
        # `institucional` pareceria uma restrição que não existe — e um post
        # `curso` sem `curso_id` seria restrito a ninguém, que é pior: ao montar
        # a consulta, `curso_id = NULL` nunca casa, e o comunicado ficaria
        # invisível para a instituição inteira sem erro nenhum aparecer.
        CheckConstraint(
            "(visibilidade = 'curso') = (curso_id IS NOT NULL)",
            name="curso_id_exatamente_quando_restrito_a_curso",
        ),
        # O índice do feed. A ordem das colunas é a da consulta: filtra por
        # universidade (um `IN` do escopo) e ordena por data decrescente. Sem o
        # `criado_em` aqui, o Postgres ordenaria em memória a cada página.
        Index("ix_posts_universidade_criado_em", "universidade_id", "criado_em"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)

    # A universidade dona do comunicado. **Não vem do corpo da requisição**: é a
    # que a conta autora administra, lida do user-service na publicação. Aceitá-la
    # do cliente deixaria uma faculdade publicar no nome de outra.
    # Sem `index=True`: o índice composto `ix_posts_universidade_criado_em` já tem
    # esta coluna à esquerda, e o Postgres o usa para filtrar só por ela. Um índice
    # simples ao lado seria uma segunda estrutura para manter a cada escrita, sem
    # nenhuma consulta que a preferisse.
    universidade_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True))

    # A conta `faculdade` que publicou. Guardado para "só a autora edita e
    # apaga" ser uma comparação de id, e não uma reconsulta ao user-service.
    autor_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), index=True)

    visibilidade: Mapped[Visibilidade] = mapped_column(
        Enum(
            Visibilidade,
            name="visibilidade",
            schema="academic",
            values_callable=lambda e: [i.value for i in e],
        )
    )

    # Nulo, exceto em `visibilidade == curso` — ver o CheckConstraint acima.
    curso_id: Mapped[UUID | None] = mapped_column(PgUUID(as_uuid=True), index=True)

    conteudo: Mapped[str] = mapped_column(String(LIMITE_DO_POST))

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    # Não nulo depois de um `PATCH`, e a tela mostra "editado" ao lado da data.
    #
    # A edição aceita mudar o alcance, e o custo disso está registrado no
    # contrato: quem já leu não é avisado, e um post restrito a um curso pode
    # passar a público depois de lido. Foi decisão de produto na Sprint 4; este
    # campo é o que mantém a mudança visível em vez de silenciosa.
    editado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    curtidas: Mapped[list["Curtida"]] = relationship(
        back_populates="post", cascade="all, delete-orphan"
    )
    comentarios: Mapped[list["Comentario"]] = relationship(
        back_populates="post", cascade="all, delete-orphan"
    )

    @property
    def restrito_a_curso(self) -> bool:
        return self.visibilidade == Visibilidade.CURSO


class Curtida(Base):
    """Uma curtida. Chave primária composta, e não um contador na tabela de posts.

    A diferença aparece no campo `curtidoPorMim` do contrato: com um contador,
    saber se **este** leitor já curtiu exigiria guardar a lista em outro lugar de
    qualquer forma. O protótipo tinha `isLiked` dentro do post, e o resultado era
    a curtida de uma pessoa aparecendo para todas.

    A unicidade é estrutural: curtir duas vezes não tem como criar duas linhas,
    nem por condição de corrida. O `PUT` idempotente do contrato é consequência
    disso, não uma checagem em código.
    """

    __tablename__ = "curtidas"

    post_id: Mapped[UUID] = mapped_column(
        ForeignKey("posts.id", ondelete="CASCADE"), primary_key=True
    )
    usuario_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True)
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    post: Mapped[Post] = relationship(back_populates="curtidas")


class Comentario(Base):
    """Um comentário sob o post. Mesmo formato que o `feed-service` reusa na Sprint 5."""

    __tablename__ = "comentarios"
    __table_args__ = (
        # Comentários se leem em ordem cronológica, do mais antigo para o mais
        # novo — conversa se lê na ordem em que aconteceu.
        Index("ix_comentarios_post_criado_em", "post_id", "criado_em"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    # Também sem índice simples: `ix_comentarios_post_criado_em` cobre.
    post_id: Mapped[UUID] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"))

    # Qualquer conta que possa VER o post. Opaco, como os outros ids de fora.
    autor_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), index=True)

    conteudo: Mapped[str] = mapped_column(String(LIMITE_DO_COMENTARIO))
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    post: Mapped[Post] = relationship(back_populates="comentarios")
