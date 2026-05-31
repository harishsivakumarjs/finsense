"""Add email verification fields to users

Revision ID: 0007
Revises: 0006
Create Date: 2026-05-31 00:00:00.000000

"""
from typing import Sequence, Union
from alembic import op
import sqlalchemy as sa

revision: str = '0007'
down_revision: Union[str, None] = '0006'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column('users', sa.Column(
        'email_verified',
        sa.Boolean(),
        nullable=False,
        server_default='false',
    ))
    op.add_column('users', sa.Column('verification_token', sa.String(64), nullable=True))
    op.add_column('users', sa.Column('verification_token_expires_at', sa.DateTime(), nullable=True))

    # Mark ALL existing users as verified so they are not locked out.
    # New registrations will start with email_verified = false.
    op.execute("UPDATE users SET email_verified = true")


def downgrade() -> None:
    op.drop_column('users', 'verification_token_expires_at')
    op.drop_column('users', 'verification_token')
    op.drop_column('users', 'email_verified')
