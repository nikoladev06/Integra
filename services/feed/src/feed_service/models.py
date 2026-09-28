"""Tabelas do feed-service, no schema `feed`.

## Três tabelas, e as mesmas três do acadêmico

    Post        um post profissional, de aluno ou de empresa
    Curtida     (post, usuário) — chave primária composta, não coluna contadora
    Comentario  texto de qualquer conta autenticada

O formato repete o academic-service de propósito: é o que a Sprint 4 resolveu, e
o rascunho do contrato já dizia que este serviço herda o formato de comentário.
O que **não** repete é a tabela de alcance — aqui não há `visibilidade` nem
`curso_id`, porque não há conteúdo restrito neste pilar.

## O que este post guarda do autor, e por quê

Três colunas opacas, e cada uma existe por um motivo diferente:

- **`autor_id`** — quem publicou. Guardado para "só o autor edita e apaga" ser
  comparação de id, e não reconsulta ao user-service.
- **`autor_tipo`** — `aluno` ou `empresa`. É o que o `escopo` da tela filtra, e
  precisa ser coluna porque o filtro entra na consulta paginada: resolver o tipo
  depois, em Python, faria uma página de 20 vir com 3 itens e o cursor mentir
  sobre onde parou.
- **`autor_universidade_id`** — o vínculo do autor **no momento da publicação**,
  nulo para empresa e para aluno sem vínculo. É o que decide `recomendado`.

A terceira é a única denormalização deste serviço, e a escolha tem uma
consequência escrita no contrato: quem troca de faculdade deixa os posts antigos
na comunidade anterior. A alternativa era perguntar ao user-service "quais
usuários têm vínculo nestas universidades?" a cada página — uma lista sem teto,
que entraria num `IN` e cresceria com a base.

O que se copia é um **id**, não um nome. Foi o nome que envelheceu no protótipo:
`nomeCompleto` gravado dentro do post continuava exibindo o nome antigo depois de
a pessoa trocar. Id não tem essa propriedade — ele nunca é exibido.

## Por que não há chave estrangeira para `usuarios`

Ela vive no schema `user`, de outro serviço. Mesma decisão do academic-service, e
pelo mesmo motivo: a FK funcionaria no Postgres de hoje, e é por isso que é a
armadilha — amarraria os dois num ponto que nenhuma consulta declara, e o filtro
`include_name` das migrações proporia apagar a tabela do outro lado. O preço é um
post poder citar uma conta apagada; nesse caso o card não resolve e o post fica
**fora** da resposta, em vez de derrubá-la.
"""

from datetime import datetime
from enum import StrEnum
from uuid import UUID, uuid4

from sqlalchemy import DateTime, Enum, ForeignKey, Index, String, func
from sqlalchemy.dialects.postgresql import UUID as PgUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from integra_shared.db import criar_base

Base = criar_base("feed")

LIMITE_DO_POST = 2000
LIMITE_DO_COMENTARIO = 1000
LIMITE_DA_URL = 500


class TipoDeAutor(StrEnum):
    """O tipo da conta que publicou, e o que o `escopo` da tela filtra.

    `faculdade` não está aqui, e a ausência é a regra: comunicado de instituição é
    o pilar acadêmico. Uma faculdade publicando no feed profissional seria a mesma
    coisa escrita duas vezes em dois lugares, e o aluno leria o comunicado dela
    duas vezes por motivos diferentes.
    """

    ALUNO = "aluno"
    EMPRESA = "empresa"


class Post(Base):
    """Um post profissional. Sem alcance: legível por qualquer conta autenticada."""

    __tablename__ = "posts"
    __table_args__ = (
        # O índice do perfil ("publicações de uma pessoa") e da metade `seguindo`
        # do feed. A ordem das colunas é a da consulta: filtra por autor (um `IN`)
        # e ordena por data decrescente.
        Index("ix_posts_autor_criado_em", "autor_id", "criado_em"),
        # O índice da metade `recomendado`: filtra pelas universidades do leitor.
        # Separado do de cima porque as duas metades são `OR` — o Postgres usa um
        # índice para cada ramo e junta por bitmap, o que um índice composto das
        # duas colunas não permitiria.
        Index("ix_posts_universidade_criado_em", "autor_universidade_id", "criado_em"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)

    # Sem `index=True`: `ix_posts_autor_criado_em` já tem esta coluna à esquerda, e
    # o Postgres o usa para filtrar só por ela. Um índice simples ao lado seria uma
    # segunda estrutura para manter a cada escrita, sem consulta que a preferisse.
    autor_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True))

    autor_tipo: Mapped[TipoDeAutor] = mapped_column(
        Enum(
            TipoDeAutor,
            name="tipo_de_autor",
            schema="feed",
            values_callable=lambda e: [i.value for i in e],
        )
    )

    # O vínculo do autor ao publicar. Nulo em post de empresa e de aluno sem
    # vínculo — e o nulo é o que os mantém fora de `recomendado`: `IN` nunca casa
    # com NULL, então eles alcançam apenas quem segue o autor. É o comportamento
    # que o contrato promete, e não um efeito colateral a corrigir depois.
    autor_universidade_id: Mapped[UUID | None] = mapped_column(PgUUID(as_uuid=True))

    conteudo: Mapped[str] = mapped_column(String(LIMITE_DO_POST))

    # A URL no storage, enviada pelo cliente depois do `PUT` na URL pré-assinada.
    # O serviço não confere que o arquivo chegou: um `HEAD` no storage a cada post
    # pagaria uma ida de rede para salvar o cliente de um erro que ele causou.
    imagem_url: Mapped[str | None] = mapped_column(String(LIMITE_DA_URL))

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    editado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    curtidas: Mapped[list["Curtida"]] = relationship(
        back_populates="post", cascade="all, delete-orphan"
    )
    comentarios: Mapped[list["Comentario"]] = relationship(
        back_populates="post", cascade="all, delete-orphan"
    )


class Curtida(Base):
    """Uma curtida. Chave primária composta, e não um contador na tabela de posts.

    A unicidade é estrutural: curtir duas vezes não tem como criar duas linhas,
    nem por condição de corrida. O `PUT` idempotente do contrato é consequência
    disso, e não uma checagem em código.

    O protótipo tinha `isLiked` dentro do post, e o resultado era a curtida de uma
    pessoa aparecendo para todas.
    """

    __tablename__ = "curtidas"

    post_id: Mapped[UUID] = mapped_column(
        ForeignKey("posts.id", ondelete="CASCADE"), primary_key=True
    )
    usuario_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True)
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    post: Mapped[Post] = relationship(back_populates="curtidas")


class Comentario(Base):
    """Um comentário sob o post. Mesmo formato do academic-service."""

    __tablename__ = "comentarios"
    __table_args__ = (
        # Comentários se leem em ordem cronológica crescente — conversa se lê na
        # ordem em que aconteceu.
        Index("ix_comentarios_post_criado_em", "post_id", "criado_em"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    post_id: Mapped[UUID] = mapped_column(ForeignKey("posts.id", ondelete="CASCADE"))
    autor_id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), index=True)

    conteudo: Mapped[str] = mapped_column(String(LIMITE_DO_COMENTARIO))
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    post: Mapped[Post] = relationship(back_populates="comentarios")
