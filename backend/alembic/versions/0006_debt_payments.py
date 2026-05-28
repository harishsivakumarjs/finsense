"""Add debt payments tracking

Revision ID: 0006
Revises: 0005
Create Date: 2026-05-28 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0006'
down_revision: Union[str, None] = '0005'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # Add columns to loans
    op.add_column('loans', sa.Column('remaining_balance', sa.Numeric(12, 2), nullable=True))
    op.add_column('loans', sa.Column('last_paid_date', sa.Date(), nullable=True))

    # Add column to credit_cards
    op.add_column('credit_cards', sa.Column('last_paid_date', sa.Date(), nullable=True))

    # Add 'emi' to loan_type enum (PostgreSQL specific)
    op.execute("ALTER TYPE loan_type ADD VALUE IF NOT EXISTS 'emi'")

    # Create debt_payments table
    op.create_table(
        'debt_payments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, nullable=False),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('loan_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('loans.id', ondelete='CASCADE'), nullable=True),
        sa.Column('card_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('credit_cards.id', ondelete='CASCADE'), nullable=True),
        sa.Column('amount_paid', sa.Numeric(12, 2), nullable=False),
        sa.Column('remaining_balance', sa.Numeric(12, 2), nullable=False),
        sa.Column('paid_on', sa.Date(), nullable=False),
        sa.Column('notes', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()'), nullable=False),
    )


def downgrade() -> None:
    op.drop_table('debt_payments')
    op.drop_column('credit_cards', 'last_paid_date')
    op.drop_column('loans', 'last_paid_date')
    op.drop_column('loans', 'remaining_balance')
