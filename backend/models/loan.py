import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Boolean, Enum, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class Loan(Base):
    __tablename__ = "loans"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    loan_type = Column(
        Enum("home", "personal", "car", "education", "bnpl", "cc_emi", "other", name="loan_type"),
        nullable=False
    )
    loan_name = Column(String, nullable=False)
    bank_name = Column(String, nullable=True)
    principal = Column(Numeric(12, 2), nullable=False)
    emi_amount = Column(Numeric(12, 2), nullable=False)
    interest_rate = Column(Numeric(5, 2), nullable=False)
    start_date = Column(Date, nullable=False, default=date.today)
    months_total = Column(Integer, nullable=False)
    paid_months = Column(Integer, default=0)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    remaining_balance = Column(Numeric(12, 2), nullable=True)
    last_paid_date = Column(Date, nullable=True)

    user = relationship("User", back_populates="loans")
    payments = relationship("DebtPayment", back_populates="loan", cascade="all, delete-orphan")


class CreditCard(Base):
    __tablename__ = "credit_cards"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    card_name = Column(String, nullable=False)
    bank_name = Column(String, nullable=True)
    credit_limit = Column(Numeric(12, 2), nullable=False)
    outstanding = Column(Numeric(12, 2), default=0)
    minimum_due = Column(Numeric(12, 2), default=0)
    due_date = Column(Integer, nullable=True)
    statement_date = Column(Integer, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    last_paid_date = Column(Date, nullable=True)

    user = relationship("User", back_populates="credit_cards")
    payments = relationship("DebtPayment", back_populates="card", cascade="all, delete-orphan")


class DebtPayment(Base):
    __tablename__ = "debt_payments"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    loan_id = Column(UUID(as_uuid=True), ForeignKey("loans.id", ondelete="CASCADE"), nullable=True)
    card_id = Column(UUID(as_uuid=True), ForeignKey("credit_cards.id", ondelete="CASCADE"), nullable=True)
    amount_paid = Column(Numeric(12, 2), nullable=False)
    remaining_balance = Column(Numeric(12, 2), nullable=False)
    paid_on = Column(Date, nullable=False)
    notes = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)
    user = relationship("User", back_populates="debt_payments")
    loan = relationship("Loan", back_populates="payments", foreign_keys=[loan_id])
    card = relationship("CreditCard", back_populates="payments", foreign_keys=[card_id])
