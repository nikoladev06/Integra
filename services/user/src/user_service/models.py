"""Tabelas do user-service, no schema `user`.

## O modelo de vínculo (v2)

Até a v1 havia uma noção só de afiliação, obrigatória no cadastro, que ao mesmo
tempo aparecia no perfil e concedia acesso aos posts internos da instituição.
Isso misturava duas coisas de naturezas diferentes, e o resultado era que bastava
**declarar** uma faculdade para ler os comunicados internos dela.

A v2 separa em duas entidades com cardinalidades diferentes:

    Formacao   0..N, acumula   cosmético; o selo de verificada é permanente
    Vinculo    0..1, se move   concede visibilidade; um por vez

E uma terceira, do lado da instituição:

    Matricula  a lista de CPF que a faculdade cadastra, antes de a conta existir,
               e que **vence** nos semestres que o curso declara

A consequência que não se pode esquecer em nenhuma consulta: **formação
verificada sem vínculo ativo não concede nada.** Quem se formou, ou foi removido
pela instituição, mantém o selo e volta a ver apenas os posts públicos.
"""

from calendar import monthrange
from datetime import UTC, datetime
from enum import StrEnum
from uuid import UUID, uuid4

from sqlalchemy import (
    CheckConstraint,
    DateTime,
    Enum,
    ForeignKey,
    Index,
    String,
    UniqueConstraint,
    func,
)
from sqlalchemy.dialects.postgresql import UUID as PgUUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from integra_shared.db import criar_base

Base = criar_base("user")

_CPF_SOMENTE_DIGITOS = "cpf ~ '^[0-9]{11}$'"


class TipoConta(StrEnum):
    ALUNO = "aluno"
    FACULDADE = "faculdade"
    EMPRESA = "empresa"


def _agora() -> datetime:
    return datetime.now(UTC)


# Um semestre é meio ano de calendário. Não é aproximação: é a unidade em que a
# instituição declara a duração do curso, e em que o prazo da matrícula conta.
MESES_POR_SEMESTRE = 6


def somar_semestres(inicio: datetime, semestres: int) -> datetime:
    """`inicio` mais `semestres` semestres, em meses de calendário.

    Somar dias seria mais curto e estaria errado: 182 dias por semestre adianta o
    fim de um curso de 10 semestres em quase uma semana, e o aluno perde o acesso
    antes da hora por causa de anos bissextos.

    O `min` no dia é para 31/08 + 1 semestre dar 28/02, e não estourar: fevereiro
    não tem dia 31.
    """
    meses = inicio.month - 1 + semestres * MESES_POR_SEMESTRE
    ano, mes = inicio.year + meses // 12, meses % 12 + 1
    return inicio.replace(year=ano, month=mes, day=min(inicio.day, monthrange(ano, mes)[1]))


class Universidade(Base):
    __tablename__ = "universidades"

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    nome: Mapped[str] = mapped_column(String(200), unique=True)
    sigla: Mapped[str] = mapped_column(String(20), index=True)

    # A identidade institucional. Único: é o que faz a conta que se cadastra
    # REIVINDICAR esta linha em vez de criar uma segunda FATEC.
    #
    # Nulo nas universidades semeadas antes de termos o CNPJ real de cada uma —
    # essas não podem ser reivindicadas até alguém preencher, e é melhor assim
    # que deixar a primeira conta a chegar assumir uma linha sem identidade.
    cnpj: Mapped[str | None] = mapped_column(String(14), unique=True, index=True)

    bio: Mapped[str | None] = mapped_column(String(280))
    foto_url: Mapped[str | None] = mapped_column(String(500))

    # A conta `faculdade` que administra esta instituição: cadastra cursos,
    # matrícula alunos e publica no pilar Acadêmico. Nula enquanto a instituição
    # existe apenas no catálogo, sem ninguém a operando — o estado de toda
    # universidade vinda do seed.
    conta_id: Mapped[UUID | None] = mapped_column(
        ForeignKey("usuarios.id", ondelete="SET NULL"), unique=True
    )

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    cursos: Mapped[list["Curso"]] = relationship(back_populates="universidade")

    @property
    def tem_conta(self) -> bool:
        """Se alguma conta institucional administra esta universidade.

        Uma sem conta existe no catálogo e pode ser seguida e declarada, mas não
        publica nada — a tela do perfil diz isso, em vez de mostrar feed vazio
        sem explicação.
        """
        return self.conta_id is not None


class Curso(Base):
    """Curso cadastrado pela própria instituição, nas configurações dela."""

    __tablename__ = "cursos"
    __table_args__ = (
        # O mesmo nome de curso existe em várias universidades; a unicidade é do par.
        UniqueConstraint("universidade_id", "nome"),
        # 20 semestres são dez anos: não existe graduação mais longa, e um dígito
        # digitado errado na tela da secretaria para aqui em vez de virar uma
        # matrícula que vence no próximo século.
        CheckConstraint(
            "duracao_semestres IS NULL OR duracao_semestres BETWEEN 1 AND 20",
            name="duracao_em_semestres_plausivel",
        ),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="CASCADE"), index=True
    )
    nome: Mapped[str] = mapped_column(String(200))

    # Quantos semestres o curso dura, e por consequência quanto tempo vale uma
    # matrícula nele — a contagem corre de `Matricula.criado_em`. Ver
    # [Matricula.expira_em], que é onde a conta acontece.
    #
    # **Nulo nos cursos que existiam antes desta regra**, inclusive os do seed.
    # Sem duração declarada a matrícula não vence: é mais honesto que arbitrar um
    # prazo para o curso de alguém. Todo curso novo é obrigado a declarar — a
    # exigência mora em `CriarCursoIn`, não aqui, porque o nulo tem que continuar
    # representável para as linhas antigas.
    duracao_semestres: Mapped[int | None] = mapped_column()
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    universidade: Mapped[Universidade] = relationship(back_populates="cursos")


class Usuario(Base):
    __tablename__ = "usuarios"
    __table_args__ = (
        # Pessoa tem CPF, organização tem CNPJ. Nunca os dois: uma conta com os
        # dois seria elegível a vínculo de aluno E a publicar como instituição.
        CheckConstraint(
            "NOT (cpf IS NOT NULL AND cnpj IS NOT NULL)",
            name="cpf_ou_cnpj_nunca_os_dois",
        ),
        Index(
            "ix_usuarios_trgm_username",
            "username",
            postgresql_using="gin",
            postgresql_ops={"username": "gin_trgm_ops"},
        ),
        Index(
            "ix_usuarios_trgm_nome",
            "nome_completo",
            postgresql_using="gin",
            postgresql_ops={"nome_completo": "gin_trgm_ops"},
        ),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True)

    nome_completo: Mapped[str] = mapped_column(String(200))
    username: Mapped[str] = mapped_column(String(50), unique=True, index=True)

    # Cópia do e-mail que o auth-service guarda como credencial. Denormalizar
    # entre serviços normalmente envelhece — foi o erro do protótipo ao copiar
    # nomes dentro de cada post. Aqui é seguro por um motivo específico: **o
    # contrato não permite trocar de e-mail**. Se isso mudar, os dois lados
    # passam a ter que atualizar juntos, e esta linha vira o ponto de falha.
    email: Mapped[str] = mapped_column(String(320), unique=True)

    # Apenas dígitos, único, obrigatório para contas `aluno` e nulo para
    # `faculdade` e `empresa` — instituição não tem CPF.
    #
    # É a chave que liga a conta às matrículas. NÃO é editável: trocar o próprio
    # CPF pelo de outra pessoa permitiria assumir a matrícula dela. E nunca sai
    # em resposta pública, nem mascarado.
    cpf: Mapped[str | None] = mapped_column(String(11), unique=True, index=True)

    # CNPJ das contas `faculdade` e `empresa`. Nulo em `aluno` — e o inverso do
    # CPF, que é nulo nas institucionais. Um `CheckConstraint` garante que uma
    # conta não tenha os dois.
    cnpj: Mapped[str | None] = mapped_column(String(14), unique=True, index=True)

    # Quando a conta passou a poder agir. **Nulo = pendente.**
    #
    # Contas `aluno` nascem com a data preenchida: autocadastro de pessoa não
    # precisa de aprovação. Contas institucionais nascem NULAS e não publicam nem
    # matriculam até serem ativadas.
    #
    # O motivo é o selo de verificado: CNPJ é dado público, então qualquer um
    # consulta o de uma faculdade e se cadastra como ela. Sem este estado,
    # bastaria isso para distribuir formações "verificadas" no nome dela — e o
    # selo, que é a peça central do modelo, deixaria de significar algo.
    #
    # É data em vez de booleano para o registro de QUANDO vir de graça.
    ativada_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    telefone: Mapped[str | None] = mapped_column(String(20))

    tipo: Mapped[TipoConta] = mapped_column(
        Enum(
            TipoConta,
            name="tipo_conta",
            schema="user",
            values_callable=lambda e: [i.value for i in e],
        ),
        default=TipoConta.ALUNO,
    )

    foto_url: Mapped[str | None] = mapped_column(String(500))
    bio: Mapped[str | None] = mapped_column(String(280))

    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    alterado_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))

    formacoes: Mapped[list["Formacao"]] = relationship(
        back_populates="usuario",
        lazy="selectin",
        order_by="Formacao.criado_em.desc()",
        cascade="all, delete-orphan",
    )
    vinculo: Mapped["Vinculo | None"] = relationship(
        back_populates="usuario",
        lazy="joined",
        cascade="all, delete-orphan",
        uselist=False,
    )

    @property
    def ativa(self) -> bool:
        """Se a conta pode agir. Existe para nenhuma checagem comparar com None."""
        return self.ativada_em is not None


class Formacao(Base):
    """Uma linha do currículo: universidade + curso, verificada ou não.

    **Acumula.** Trocar de faculdade não apaga a anterior, e o selo de verificada
    é permanente — quem se formou realmente estudou lá, e apagar reescreveria o
    passado.

    `verificada_em` não nulo é o selo. O cliente mostra apenas o selo: a ausência
    já comunica que aquilo foi só declarado, sem precisar de rótulo dizendo isso.
    """

    __tablename__ = "formacoes"
    # A mesma formação não entra duas vezes no currículo.
    __table_args__ = (UniqueConstraint("usuario_id", "universidade_id", "curso_id"),)

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    usuario_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), index=True
    )
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="RESTRICT")
    )
    curso_id: Mapped[UUID] = mapped_column(ForeignKey("cursos.id", ondelete="RESTRICT"))

    verificada_em: Mapped[datetime | None] = mapped_column(DateTime(timezone=True))
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    usuario: Mapped[Usuario] = relationship(back_populates="formacoes")
    universidade: Mapped[Universidade] = relationship(lazy="joined")
    curso: Mapped[Curso] = relationship(lazy="joined")

    @property
    def verificada(self) -> bool:
        return self.verificada_em is not None


class Vinculo(Base):
    """O laço ativo com uma instituição. **Um por usuário, no máximo.**

    A unicidade é estrutural, não checada em código: `usuario_id` é a chave
    primária. Não existe estado em que alguém tenha dois vínculos, nem por
    condição de corrida.

    É o **único** mecanismo que concede visibilidade de posts `institucional` e
    `curso`. Nem formação declarada, nem formação verificada antiga, nem seguir a
    instituição concedem qualquer coisa.
    """

    __tablename__ = "vinculos"

    usuario_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True
    )
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="CASCADE"), index=True
    )
    curso_id: Mapped[UUID] = mapped_column(ForeignKey("cursos.id", ondelete="RESTRICT"))

    criado_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_agora, server_default=func.now()
    )

    usuario: Mapped[Usuario] = relationship(back_populates="vinculo")
    universidade: Mapped[Universidade] = relationship(lazy="joined")
    curso: Mapped[Curso] = relationship(lazy="joined")


class Matricula(Base):
    """Um CPF que a instituição cadastrou, com o curso.

    **Pode existir antes da conta do aluno.** É uma lista de espera: o vínculo
    nasce quando alguém com aquele CPF reivindicar. Sem isso, a secretaria só
    poderia cadastrar quem já tivesse baixado o app.

    Por isso não há chave estrangeira para `usuarios`: o CPF é o único elo, e ele
    pode não corresponder a conta nenhuma ainda.

    **Tem prazo.** A matrícula vale os semestres que o curso declara, contados de
    `criado_em`. Passado o prazo ela é apagada, e o vínculo que ela sustenta vai
    com ela — ver `services.instituicoes.expirar_matriculas_vencidas`. O que
    **não** vai é a formação verificada: ela cursou o que cursou, e no currículo
    fica o selo ao lado do nome da instituição.
    """

    __tablename__ = "matriculas"
    __table_args__ = (
        # Um CPF uma vez por instituição. Nada impede o mesmo CPF constar em
        # várias faculdades — o aluno é que só pode ter vínculo com uma por vez.
        UniqueConstraint("universidade_id", "cpf"),
        CheckConstraint(_CPF_SOMENTE_DIGITOS, name="cpf_somente_digitos"),
    )

    id: Mapped[UUID] = mapped_column(PgUUID(as_uuid=True), primary_key=True, default=uuid4)
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="CASCADE"), index=True
    )
    cpf: Mapped[str] = mapped_column(String(11), index=True)
    curso_id: Mapped[UUID] = mapped_column(ForeignKey("cursos.id", ondelete="RESTRICT"))

    # **O início da contagem.** É a data em que a instituição cadastrou o CPF, e
    # não a do vínculo: o prazo é do curso, e não do dia em que o aluno resolveu
    # informar o CPF no app. Quem demora um ano para informar chega com um ano a
    # menos — que é o que acontece na faculdade de verdade.
    criado_em: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())

    universidade: Mapped[Universidade] = relationship(lazy="joined")
    curso: Mapped[Curso] = relationship(lazy="joined")

    @property
    def expira_em(self) -> datetime | None:
        """Quando esta matrícula deixa de valer. **Nulo = não vence.**

        Nulo quando o curso não declara duração, o caso das linhas que existiam
        antes desta regra. Nenhum outro caso: curso com duração sempre tem prazo.

        Derivado, e não uma coluna: uma data gravada na criação envelheceria em
        silêncio no dia em que a instituição corrigisse a duração do curso.
        """
        if self.curso.duracao_semestres is None:
            return None
        return somar_semestres(self.criado_em, self.curso.duracao_semestres)

    @property
    def vencida(self) -> bool:
        """Se o prazo já passou. **A única definição de "passou".**

        Lida pelos dois lados da regra: por quem apaga as vencidas e por quem
        recusa criar vínculo a partir de uma. Duas comparações escritas à mão
        divergiriam na borda — e a borda aqui é o dia em que o aluno perde acesso.
        """
        fim = self.expira_em
        return fim is not None and fim <= datetime.now(UTC)


class SeguindoUniversidade(Base):
    """Universidades que o usuário acompanha no feed.

    **Seguir não concede acesso a conteúdo restrito** — só o vínculo faz isso.
    Quem segue sem vínculo vê exclusivamente posts `publico`. Esta tabela
    registra interesse, nada mais.
    """

    __tablename__ = "seguindo_universidades"

    usuario_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True
    )
    universidade_id: Mapped[UUID] = mapped_column(
        ForeignKey("universidades.id", ondelete="CASCADE"), primary_key=True
    )
    seguida_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_agora, server_default=func.now()
    )


class SeguindoUsuario(Base):
    """Pessoas e empresas que o usuário segue, para o feed profissional."""

    __tablename__ = "seguindo_usuarios"
    __table_args__ = (CheckConstraint("seguidor_id <> seguido_id", name="nao_seguir_a_si_mesmo"),)

    seguidor_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True
    )
    seguido_id: Mapped[UUID] = mapped_column(
        ForeignKey("usuarios.id", ondelete="CASCADE"), primary_key=True, index=True
    )
    seguido_em: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=_agora, server_default=func.now()
    )
