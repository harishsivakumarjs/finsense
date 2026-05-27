import uuid
from datetime import datetime, date
from sqlalchemy import Column, String, DateTime, Date, Numeric, Text, Boolean, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import relationship
from database import Base


class FriendLedger(Base):
    __tablename__ = "friend_ledger"

    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    friend_name = Column(String, nullable=False)
    amount = Column(Numeric(12, 2), nullable=False)  # positive = they owe you, negative = you owe them
    reason = Column(Text, nullable=True)
    date = Column(Date, nullable=False, default=date.today)
    is_settled = Column(Boolean, default=False)
    settled_on = Column(Date, nullable=True)
    created_at = Column(DateTime, default=datetime.utcnow)

    user = relationship("User", back_populates="friend_ledger")
