import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Text, Enum, ForeignKey, Integer
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class Trade(Base):
    __tablename__ = "trades"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    scrip = Column(String, nullable=False)
    trade_type = Column(
        Enum("intraday", "delivery", "futures", "options", name="trade_type"),
        nullable=False
    )
    buy_price = Column(Numeric(10, 4), nullable=False)
    sell_price = Column(Numeric(10, 4), nullable=True)
    quantity = Column(Integer, nullable=False)
    buy_date = Column(Date, nullable=False, default=date.today)
    sell_date = Column(Date, nullable=True)
    charges = Column(Numeric(10, 2), default=0)
    net_pnl = Column(Numeric(12, 2), nullable=True)
    tax_type = Column(
        Enum("stcg", "ltcg", "speculative", "business", name="trade_tax_type"),
        nullable=True
    )
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="trades")


class TradingLossCarryforward(Base):
    __tablename__ = "trading_loss_carryforward"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    financial_year = Column(String, nullable=False)
    loss_type = Column(
        Enum("speculative", "non_speculative", "stcl", "ltcl", name="loss_type"),
        nullable=False
    )
    original_loss = Column(Numeric(12, 2), nullable=False)
    remaining_loss = Column(Numeric(12, 2), nullable=False)
    expiry_year = Column(String, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="trading_losses")
