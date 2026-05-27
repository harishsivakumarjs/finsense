import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Boolean, Text, Enum, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class InsurancePolicy(Base):
    __tablename__ = "insurance_policies"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    policy_type = Column(
        Enum("health", "life", "term", "vehicle", "home", "accident", "travel", "other",
             name="insurance_policy_type"),
        nullable=False,
    )
    policy_name = Column(String, nullable=False)
    insurer_name = Column(String, nullable=True)
    policy_number = Column(String, nullable=True)
    sum_assured = Column(Numeric(12, 2), nullable=True)
    annual_premium = Column(Numeric(12, 2), nullable=False)
    premium_frequency = Column(
        Enum("monthly", "quarterly", "half_yearly", "yearly",
             name="premium_frequency"),
        nullable=False,
        default="yearly",
    )
    next_due_date = Column(Date, nullable=False)
    start_date = Column(Date, nullable=True)
    end_date = Column(Date, nullable=True)
    tax_section = Column(String, nullable=True)
    tax_benefit_amount = Column(Numeric(12, 2), nullable=True)
    is_active = Column(Boolean, default=True, nullable=False)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="insurance_policies")
