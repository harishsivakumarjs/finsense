"""Initial migration - create all tables

Revision ID: 0001
Revises:
Create Date: 2026-05-24 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

revision: str = '0001'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None

# Pre-declare enum types with create_type=False so SQLAlchemy doesn't auto-create
# them during create_table — we create them explicitly via op.execute() below.
user_mode = postgresql.ENUM('student', 'earner', name='user_mode', create_type=False)
income_source_type = postgresql.ENUM(
    'salary', 'pocket_money', 'freelance', 'youtube', 'trading', 'investment', 'other',
    name='income_source_type', create_type=False)
income_tax_category = postgresql.ENUM(
    'salary', 'business', 'capital_gains', 'exempt',
    name='income_tax_category', create_type=False)
expense_category = postgresql.ENUM(
    'food', 'transport', 'bills', 'health', 'entertainment',
    'shopping', 'subscriptions', 'education', 'other',
    name='expense_category', create_type=False)
loan_type = postgresql.ENUM(
    'home', 'personal', 'car', 'education', 'bnpl', 'cc_emi', 'other',
    name='loan_type', create_type=False)
trade_type = postgresql.ENUM(
    'intraday', 'delivery', 'futures', 'options',
    name='trade_type', create_type=False)
trade_tax_type = postgresql.ENUM(
    'stcg', 'ltcg', 'speculative', 'business',
    name='trade_tax_type', create_type=False)
investment_asset_type = postgresql.ENUM(
    'mutual_fund', 'gold', 'silver', 'land', 'fd', 'ppf', 'stocks', 'insurance', 'other',
    name='investment_asset_type', create_type=False)
creator_income_type = postgresql.ENUM(
    'adsense', 'sponsorship', 'membership', 'merch', 'course', 'other',
    name='creator_income_type', create_type=False)
loss_type = postgresql.ENUM(
    'speculative', 'non_speculative', 'stcl', 'ltcl',
    name='loss_type', create_type=False)


def upgrade() -> None:
    # Create all ENUM types first (once, explicitly)
    op.execute("CREATE TYPE user_mode AS ENUM ('student', 'earner')")
    op.execute("CREATE TYPE income_source_type AS ENUM ('salary', 'pocket_money', 'freelance', 'youtube', 'trading', 'investment', 'other')")
    op.execute("CREATE TYPE income_tax_category AS ENUM ('salary', 'business', 'capital_gains', 'exempt')")
    op.execute("CREATE TYPE expense_category AS ENUM ('food', 'transport', 'bills', 'health', 'entertainment', 'shopping', 'subscriptions', 'education', 'other')")
    op.execute("CREATE TYPE loan_type AS ENUM ('home', 'personal', 'car', 'education', 'bnpl', 'cc_emi', 'other')")
    op.execute("CREATE TYPE trade_type AS ENUM ('intraday', 'delivery', 'futures', 'options')")
    op.execute("CREATE TYPE trade_tax_type AS ENUM ('stcg', 'ltcg', 'speculative', 'business')")
    op.execute("CREATE TYPE investment_asset_type AS ENUM ('mutual_fund', 'gold', 'silver', 'land', 'fd', 'ppf', 'stocks', 'insurance', 'other')")
    op.execute("CREATE TYPE creator_income_type AS ENUM ('adsense', 'sponsorship', 'membership', 'merch', 'course', 'other')")
    op.execute("CREATE TYPE loss_type AS ENUM ('speculative', 'non_speculative', 'stcl', 'ltcl')")

    # users
    op.create_table(
        'users',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('email', sa.String(), nullable=False, unique=True),
        sa.Column('password_hash', sa.String(), nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('mode', user_mode, nullable=False, server_default='student'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )
    op.create_index('ix_users_email', 'users', ['email'], unique=True)

    # income_entries
    op.create_table(
        'income_entries',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('source_type', income_source_type, nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('received_on', sa.Date(), nullable=False),
        sa.Column('tax_category', income_tax_category, nullable=False, server_default='salary'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # expenses
    op.create_table(
        'expenses',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('category', expense_category, nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('spent_on', sa.Date(), nullable=False),
        sa.Column('is_recurring', sa.Boolean(), server_default='false'),
        sa.Column('is_creator_expense', sa.Boolean(), server_default='false'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # budgets
    op.create_table(
        'budgets',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('category', sa.String(), nullable=False),
        sa.Column('monthly_limit', sa.Numeric(12, 2), nullable=False),
        sa.Column('month', sa.Integer(), nullable=False),
        sa.Column('year', sa.Integer(), nullable=False),
    )

    # loans
    op.create_table(
        'loans',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('loan_type', loan_type, nullable=False),
        sa.Column('loan_name', sa.String(), nullable=False),
        sa.Column('bank_name', sa.String(), nullable=True),
        sa.Column('principal', sa.Numeric(12, 2), nullable=False),
        sa.Column('emi_amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('interest_rate', sa.Numeric(5, 2), nullable=False),
        sa.Column('start_date', sa.Date(), nullable=False),
        sa.Column('months_total', sa.Integer(), nullable=False),
        sa.Column('is_active', sa.Boolean(), server_default='true'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # credit_cards
    op.create_table(
        'credit_cards',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('card_name', sa.String(), nullable=False),
        sa.Column('bank_name', sa.String(), nullable=True),
        sa.Column('credit_limit', sa.Numeric(12, 2), nullable=False),
        sa.Column('outstanding', sa.Numeric(12, 2), server_default='0'),
        sa.Column('minimum_due', sa.Numeric(12, 2), server_default='0'),
        sa.Column('due_date', sa.Integer(), nullable=True),
        sa.Column('statement_date', sa.Integer(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # trades
    op.create_table(
        'trades',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('scrip', sa.String(), nullable=False),
        sa.Column('trade_type', trade_type, nullable=False),
        sa.Column('buy_price', sa.Numeric(10, 4), nullable=False),
        sa.Column('sell_price', sa.Numeric(10, 4), nullable=True),
        sa.Column('quantity', sa.Integer(), nullable=False),
        sa.Column('buy_date', sa.Date(), nullable=False),
        sa.Column('sell_date', sa.Date(), nullable=True),
        sa.Column('charges', sa.Numeric(10, 2), server_default='0'),
        sa.Column('net_pnl', sa.Numeric(12, 2), nullable=True),
        sa.Column('tax_type', trade_tax_type, nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # investments
    op.create_table(
        'investments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('asset_type', investment_asset_type, nullable=False),
        sa.Column('name', sa.String(), nullable=False),
        sa.Column('invested_amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('current_value', sa.Numeric(12, 2), nullable=False),
        sa.Column('purchase_date', sa.Date(), nullable=False),
        sa.Column('quantity', sa.Numeric(12, 4), nullable=True),
        sa.Column('unit', sa.String(), nullable=True),
        sa.Column('tax_section', sa.String(), nullable=True),
        sa.Column('maturity_date', sa.Date(), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('updated_at', sa.DateTime(), server_default=sa.text('now()')),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # creator_income
    op.create_table(
        'creator_income',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('income_type', creator_income_type, nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('brand_name', sa.String(), nullable=True),
        sa.Column('video_title', sa.String(), nullable=True),
        sa.Column('received_on', sa.Date(), nullable=False),
        sa.Column('rpm', sa.Numeric(8, 4), nullable=True),
        sa.Column('notes', sa.Text(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # friend_ledger
    op.create_table(
        'friend_ledger',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('friend_name', sa.String(), nullable=False),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('reason', sa.Text(), nullable=True),
        sa.Column('date', sa.Date(), nullable=False),
        sa.Column('is_settled', sa.Boolean(), server_default='false'),
        sa.Column('settled_on', sa.Date(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # net_worth_snapshots
    op.create_table(
        'net_worth_snapshots',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('snapshot_date', sa.Date(), nullable=False),
        sa.Column('total_assets', sa.Numeric(12, 2), nullable=False),
        sa.Column('total_liabilities', sa.Numeric(12, 2), nullable=False),
        sa.Column('net_worth', sa.Numeric(12, 2), nullable=False),
        sa.Column('debt_score', sa.Integer(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # goals
    op.create_table(
        'goals',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('goal_name', sa.String(), nullable=False),
        sa.Column('target_amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('current_amount', sa.Numeric(12, 2), server_default='0'),
        sa.Column('target_date', sa.Date(), nullable=True),
        sa.Column('is_achieved', sa.Boolean(), server_default='false'),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # tax_deductions
    op.create_table(
        'tax_deductions',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('financial_year', sa.String(), nullable=False),
        sa.Column('section', sa.String(), nullable=False),
        sa.Column('description', sa.Text(), nullable=True),
        sa.Column('amount', sa.Numeric(12, 2), nullable=False),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )

    # advance_tax_payments
    op.create_table(
        'advance_tax_payments',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('financial_year', sa.String(), nullable=False),
        sa.Column('installment', sa.Integer(), nullable=False),
        sa.Column('due_date', sa.Date(), nullable=False),
        sa.Column('amount_due', sa.Numeric(12, 2), nullable=False),
        sa.Column('amount_paid', sa.Numeric(12, 2), server_default='0'),
        sa.Column('paid_on', sa.Date(), nullable=True),
        sa.Column('is_paid', sa.Boolean(), server_default='false'),
    )

    # trading_loss_carryforward
    op.create_table(
        'trading_loss_carryforward',
        sa.Column('id', postgresql.UUID(as_uuid=True), primary_key=True, server_default=sa.text('gen_random_uuid()')),
        sa.Column('user_id', postgresql.UUID(as_uuid=True), sa.ForeignKey('users.id', ondelete='CASCADE'), nullable=False),
        sa.Column('financial_year', sa.String(), nullable=False),
        sa.Column('loss_type', loss_type, nullable=False),
        sa.Column('original_loss', sa.Numeric(12, 2), nullable=False),
        sa.Column('remaining_loss', sa.Numeric(12, 2), nullable=False),
        sa.Column('expiry_year', sa.String(), nullable=True),
        sa.Column('created_at', sa.DateTime(), server_default=sa.text('now()')),
    )


def downgrade() -> None:
    op.drop_table('trading_loss_carryforward')
    op.drop_table('advance_tax_payments')
    op.drop_table('tax_deductions')
    op.drop_table('goals')
    op.drop_table('net_worth_snapshots')
    op.drop_table('friend_ledger')
    op.drop_table('creator_income')
    op.drop_table('investments')
    op.drop_table('trades')
    op.drop_table('credit_cards')
    op.drop_table('loans')
    op.drop_table('budgets')
    op.drop_table('expenses')
    op.drop_table('income_entries')
    op.drop_index('ix_users_email', table_name='users')
    op.drop_table('users')

    op.execute("DROP TYPE IF EXISTS loss_type")
    op.execute("DROP TYPE IF EXISTS creator_income_type")
    op.execute("DROP TYPE IF EXISTS investment_asset_type")
    op.execute("DROP TYPE IF EXISTS trade_tax_type")
    op.execute("DROP TYPE IF EXISTS trade_type")
    op.execute("DROP TYPE IF EXISTS loan_type")
    op.execute("DROP TYPE IF EXISTS expense_category")
    op.execute("DROP TYPE IF EXISTS income_tax_category")
    op.execute("DROP TYPE IF EXISTS income_source_type")
    op.execute("DROP TYPE IF EXISTS user_mode")
