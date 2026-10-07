"""Schemas de entrada e saída do jobs-service.

Espelham `contracts/jobs.openapi.yaml` v1.0.0. camelCase na borda, snake_case dentro.

O que **não** existe como campo de entrada, e a ausência é a garantia:

- **`empresaId`** na publicação — é a conta autenticada. Se fosse campo, uma empresa
  publicaria vaga no nome de outra.
- **`candidatoId`** na candidatura — mesma razão, com o sujeito trocado.
- **`estado`** na candidatura recém-criada — nasce `enviada`, e só a empresa autora
  da vaga a move.
- **`totalDeCandidaturas`** e **`candidaturaEnviada`** — calculados por consulta e
  por leitor.
"""

from datetime import datetime
from typing import Literal
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field

from jobs_service.models import (
    LIMITE_DA_DESCRICAO,
    LIMITE_DO_LOCAL,
    LIMITE_DO_TITULO,
    EstadoDaCandidatura,
    EstadoDaVaga,
    Modalidade,
    TipoDeVaga,
)


def _para_camel(nome: str) -> str:
    primeira, *resto = nome.split("_")
    return primeira + "".join(p.capitalize() for p in resto)


class _Saida(BaseModel):
    model_config = ConfigDict(
        alias_generator=_para_camel,
        populate_by_name=True,
        from_attributes=True,
        serialize_by_alias=True,
    )


class _Entrada(BaseModel):
    model_config = ConfigDict(alias_generator=_para_camel, populate_by_name=True)


# ──────────────────────────────  saída  ──────────────────────────────


class EmpresaDaVagaOut(_Saida):
    """Quem publicou, resolvida na leitura contra o user-service, em lote."""

    id: UUID
    nome: str
    username: str
    foto_url: str | None = None


class CandidatoResumoOut(_Saida):
    """O que a empresa vê de quem se candidatou: **o mesmo resumo de qualquer card**.

    Nem CPF, nem telefone, nem e-mail — e a garantia é o tipo não ter os campos, e
    não uma remoção que cada rota nova precise lembrar de fazer. A candidatura não
    pode virar um canal para o que o perfil público esconde; para o resto, a empresa
    abre o perfil dele no app, onde o currículo já é público.
    """

    id: UUID
    nome_completo: str
    username: str
    foto_url: str | None = None


class VagaOut(_Saida):
    id: UUID
    empresa: EmpresaDaVagaOut
    titulo: str
    descricao: str
    tipo: TipoDeVaga
    modalidade: Modalidade

    # Nulo exatamente em `modalidade == remoto`.
    local: str | None = None

    estado: EstadoDaVaga

    # Visível para todos. Ao contrário do "N alunos com vínculo" que saiu do perfil da
    # instituição, quantos concorrem a uma vaga é informação de quem vai se
    # candidatar — e a empresa publicou a vaga justamente para ser concorrida.
    total_de_candidaturas: int = 0

    # Estado por leitor. **Nulo para quem não é `aluno`**: uma empresa não tem o que
    # responder aqui, e `false` a faria parecer elegível.
    candidatura_enviada: bool | None = None

    # Se o leitor é a empresa autora. A tela lê isto em vez de comparar ids por conta
    # própria — e concluir diferente do servidor num caso de borda.
    pode_editar: bool = False

    criado_em: datetime
    editado_em: datetime | None = None


class CandidaturaOut(_Saida):
    id: UUID

    # A vaga inteira, e não só o id: a lista do aluno é de "onde me candidatei", e um
    # item sem título de vaga não é uma linha legível.
    vaga: VagaOut

    candidato: CandidatoResumoOut
    estado: EstadoDaCandidatura
    criado_em: datetime
    visualizada_em: datetime | None = None


class PaginaDeVagas(_Saida):
    itens: list[VagaOut]
    proximo_cursor: str | None = None


class PaginaDeCandidaturas(_Saida):
    itens: list[CandidaturaOut]
    proximo_cursor: str | None = None


# ──────────────────────────────  entrada  ──────────────────────────────


class PublicarVagaIn(_Entrada):
    """`POST /jobs/vagas`.

    A coerência entre `modalidade` e `local` **não** é validada aqui, e a razão é a
    mesma que `academic_service.schemas` registra: um `ValueError` de
    `model_validator` chega ao cliente com `loc = ("body",)`, que o tradutor de erros
    transforma em `fields: {"_": [...]}` — e o formulário não tem onde pintar a
    mensagem. A regra mora em `services.vagas` e nomeia a coluna.
    """

    titulo: str = Field(min_length=1, max_length=LIMITE_DO_TITULO)
    descricao: str = Field(min_length=1, max_length=LIMITE_DA_DESCRICAO)
    tipo: TipoDeVaga
    modalidade: Modalidade
    local: str | None = Field(default=None, max_length=LIMITE_DO_LOCAL)

    @property
    def local_limpo(self) -> str | None:
        return self.local.strip() if self.local and self.local.strip() else None


class EditarVagaIn(_Entrada):
    """`PATCH /jobs/vagas/{id}`. Campos omitidos ficam inalterados.

    A coerência de `local` não pode ser validada aqui pelo mesmo motivo do
    `EditarPostIn` do acadêmico: o valor que falta pode estar na vaga gravada —
    sair de `remoto` sem informar `local` é válido se a vaga já tinha um.
    """

    titulo: str | None = Field(default=None, min_length=1, max_length=LIMITE_DO_TITULO)
    descricao: str | None = Field(default=None, min_length=1, max_length=LIMITE_DA_DESCRICAO)
    tipo: TipoDeVaga | None = None
    modalidade: Modalidade | None = None
    local: str | None = Field(default=None, max_length=LIMITE_DO_LOCAL)
    estado: EstadoDaVaga | None = None

    @property
    def vazio(self) -> bool:
        return not any(
            (self.titulo, self.descricao, self.tipo, self.modalidade, self.local, self.estado)
        )

    @property
    def local_limpo(self) -> str | None:
        return self.local.strip() if self.local and self.local.strip() else None


class EditarCandidaturaIn(_Entrada):
    """`PATCH /jobs/candidaturas/{id}`. Só `visualizada` é aceito.

    `Literal["visualizada"]`, e não `EstadoDaCandidatura`: o estado não volta atrás, e
    um tipo que aceita `enviada` obrigaria o serviço a recusá-la depois — com uma
    checagem que a próxima rota pode esquecer. Assim a recusa é do Pydantic, sai com
    o campo nomeado (`enum` → "Valor fora das opções permitidas" em
    `integra_shared.errors`) e o formulário tem onde pintá-la.
    """

    estado: Literal["visualizada"]
