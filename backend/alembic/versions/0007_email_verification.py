"""Add email verification fields to users

Revision ID: 0007
Revises: 0006
Create Date: 2026-05-31 00:00:00.000000

Uses raw SQL with IF NOT EXISTS so the migration is safe to run in ANY
database state:
  - columns never existed  → they are created
  - columns already exist  → no-op, no error
  - alembic_version shows 0006 → upgrade runs this script
  - alembic_version shows 0007 but columns were dropped → run 0008 safety net
"""
from typing import Sequence, Union
from alembic import op


revision: str = '0007'
down_revision: Union[str, None] = '0006'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # ADD COLUMN IF NOT EXISTS is idempotent — safe whether or not the
    # columns were previously created manually and then removed.
    op.execute("""
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT false
    """)
    op.execute("""
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS verification_token VARCHAR(64)
    """)
    op.execute("""
        ALTER TABLE users
        ADD COLUMN IF NOT EXISTS verification_token_expires_at TIMESTAMP
    """)

    # Mark every existing row as verified so no one is locked out.
    # New registrations start with email_verified = false (set in application code).
    op.execute("UPDATE users SET email_verified = true WHERE email_verified = false")


def downgrade() -> None:
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS verification_token_expires_at")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS verification_token")
    op.execute("ALTER TABLE users DROP COLUMN IF EXISTS email_verified")
