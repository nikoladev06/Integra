"""duracao do curso, que e o prazo da matricula

Revision ID: b4f1c90ad257
Revises: 3510bd333ffc
Create Date: 2026-11-13 00:00:00.000000

A coluna nasce NULA e assim fica nos cursos que já existem, inclusive os do seed.
Sem duração declarada a matrícula não vence — preencher com um palpite daria a
alunos reais um prazo que a instituição nunca escolheu. O seed completa os cursos
que ele mesmo criou; os demais ficam para a instituição declarar.
"""

from collections.abc import Sequence

import sqlalchemy as sa
from alembic import op

revision: str = 'b4f1c90ad257'
down_revision: str | None = '3510bd333ffc'
branch_labels: str | Sequence[str] | None = None
depends_on: str | Sequence[str] | None = None


def upgrade() -> None:
    op.add_column(
        'cursos',
        sa.Column('duracao_semestres', sa.Integer(), nullable=True),
        schema='user',
    )
    op.create_check_constraint(
        'duracao_em_semestres_plausivel',
        'cursos',
        'duracao_semestres IS NULL OR duracao_semestres BETWEEN 1 AND 20',
        schema='user',
    )


def downgrade() -> None:
    op.drop_constraint(
        'ck_cursos_duracao_em_semestres_plausivel',
        'cursos',
        type_='check',
        schema='user',
    )
    op.drop_column('cursos', 'duracao_semestres', schema='user')
