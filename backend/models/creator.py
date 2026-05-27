import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Text, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class CreatorIncome(Base):
    __tablename__ = "creator_income"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    income_type = Column(
        Enum("adsense", "sponsorship", "membership", "merch", "course", "other",
             name="creator_income_type"),
        nullable=False
    )
    amount = Column(Numeric(12, 2), nullable=False)
    brand_name = Column(String, nullable=True)
    video_title = Column(String, nullable=True)
    received_on = Column(Date, nullable=False, default=date.today)
    rpm = Column(Numeric(8, 4), nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="creator_incomes")
