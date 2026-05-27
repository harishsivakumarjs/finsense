import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Text, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class Investment(Base):
    __tablename__ = "investments"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    asset_type = Column(
        Enum("mutual_fund", "gold", "silver", "land", "fd", "ppf", "stocks", "insurance", "other",
             name="investment_asset_type"),
        nullable=False
    )
    name = Column(String, nullable=False)
    invested_amount = Column(Numeric(12, 2), nullable=False)
    current_value = Column(Numeric(12, 2), nullable=False)
    purchase_date = Column(Date, nullable=False, default=date.today)
    quantity = Column(Numeric(12, 4), nullable=True)
    unit = Column(String, nullable=True)
    tax_section = Column(String, nullable=True)
    maturity_date = Column(Date, nullable=True)
    notes = Column(Text, nullable=True)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="investments")
