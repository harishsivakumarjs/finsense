"""Add insurance_policies table

Revision ID: 0002
Revises: 0001
Create Date: 2026-05-24 12:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0002'
down_revision: Union[str, None] = '0001'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

insurance_policy_type = postgresql.ENUM(
    'health', 'life', 'term', 'vehicle', 'home', 'accident', 'travel', 'other',
    name='insurance_policy_type', create_type=False)

premium_frequency = postgresql.ENUM(
    'monthly', 'quarterly', 'half_yearly', 'yearly',
    name='premium_frequency', create_type=False)


def upgrade() -> None:
    op.execute("CREATE TYPE insurance_policy_type AS ENUM ('health', 'life', 'term', 'vehicle', 'home', 'accident', 'travel', 'other')")
    op.execute("CREATE TYPE premium_frequency AS ENUM ('monthly', 'quarterly', 'half_yearly', 'yearly')")

    op.create_table(
        'insurance_policies',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('policy_type', insurance_policy_type, nullable=False),
        sa.Column('policy_name', sa.String(), nullable=False),
        sa.Column('insurer_name', sa.String(), nullable=True),
        sa.Column('policy_number', sa.String(), nullable=True),
        sa.Column('sum_assured', sa.Numeric(12, 2), nullable=True),
        sa.Column('annual_premium', sa.Numeric(12, 2), nullable=False),
        sa.Column('premium_frequency', premium_frequency, nullable=False, server_default='yearly'),
        sa.Column('next_due_date', sa.Date(), nullable=False),
        sa.Column('start_date', sa.Date(), nullable=True),
        sa.Column('end_date', sa.Date(), nullable=True),
        sa.Column('tax_section', sa.String(), nullable=True),
        sa.Column('tax_benefit_amount', sa.Numeric(12, 2), nullable=True),
        sa.Column('is_active', sa.Boolean(), nullable=False, server_default='true'),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), nullable=True),
    )
    op.create_index('ix_insurance_policies_user_id', 'insurance_policies', ['user_id'])
    op.create_index('ix_insurance_policies_next_due_date', 'insurance_policies', ['next_due_date'])


def downgrade() -> None:
    op.drop_table('insurance_policies')
    op.execute("DROP TYPE IF EXISTS insurance_policy_type")
    op.execute("DROP TYPE IF EXISTS premium_frequency")
