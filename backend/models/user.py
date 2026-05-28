import uuid
from datetime import datetime
from sqlalchemy import Column, String, Text, DateTime, Enum
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class User(Base):
    __tablename__ = "users"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    name = Column(String, nullable=False)
    mobile = Column(String, nullable=True)
    photo = Column(Text, nullable=True)
    mode = Column(Enum("student", "earner", name="user_mode"), default="student", nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    income_entries = relationship("IncomeEntry", back_populates="user", cascade="all, delete-orphan")
    expenses = relationship("Expense", back_populates="user", cascade="all, delete-orphan")
    budgets = relationship("Budget", back_populates="user", cascade="all, delete-orphan")
    loans = relationship("Loan", back_populates="user", cascade="all, delete-orphan")
    credit_cards = relationship("CreditCard", back_populates="user", cascade="all, delete-orphan")
    trades = relationship("Trade", back_populates="user", cascade="all, delete-orphan")
    trading_losses = relationship("TradingLossCarryforward", back_populates="user", cascade="all, delete-orphan")
    investments = relationship("Investment", back_populates="user", cascade="all, delete-orphan")
    creator_incomes = relationship("CreatorIncome", back_populates="user", cascade="all, delete-orphan")
    friend_ledger = relationship("FriendLedger", back_populates="user", cascade="all, delete-orphan")
    net_worth_snapshots = relationship("NetWorthSnapshot", back_populates="user", cascade="all, delete-orphan")
    goals = relationship("Goal", back_populates="user", cascade="all, delete-orphan")
    tax_deductions = relationship("TaxDeduction", back_populates="user", cascade="all, delete-orphan")
    advance_tax_payments = relationship("AdvanceTaxPayment", back_populates="user", cascade="all, delete-orphan")
    insurance_policies = relationship("InsurancePolicy", back_populates="user", cascade="all, delete-orphan")
    debt_payments = relationship("DebtPayment", back_populates="user", cascade="all, delete-orphan")
