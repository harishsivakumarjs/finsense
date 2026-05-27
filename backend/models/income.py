import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Text, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class IncomeEntry(Base):
    __tablename__ = "income_entries"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    source_type = Column(
        Enum("salary", "pocket_money", "freelance", "youtube", "trading", "investment", "other",
             name="income_source_type"),
        nullable=False
    )
    amount = Column(Numeric(12, 2), nullable=False)
    description = Column(Text, nullable=True)
    received_on = Column(Date, nullable=False, default=date.today)
    tax_category = Column(
        Enum("salary", "business", "capital_gains", "exempt", name="income_tax_category"),
        nullable=False,
        default="salary"
    )
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="income_entries")
