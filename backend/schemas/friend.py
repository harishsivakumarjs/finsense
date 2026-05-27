from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class FriendLedgerCreate(BaseModel):
    friend_name: str
    amount: Decimal
    reason: Optional[str] = None
    date: date
    is_settled: bool = False


class FriendLedgerUpdate(BaseModel):
    friend_name: Optional[str] = None
    amount: Optional[Decimal] = None
    reason: Optional[str] = None
    date: Optional[date] = None
    is_settled: Optional[bool] = None
    settled_on: Optional[date] = None


class FriendLedgerOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    friend_name: str
    amount: Decimal
    reason: Optional[str]
    date: date
    is_settled: bool
    settled_on: Optional[date]
    created_at: datetime

    model_config = {"from_attributes": True}
