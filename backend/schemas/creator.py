from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class CreatorIncomeCreate(BaseModel):
    income_type: str
    amount: Decimal
    brand_name: Optional[str] = None
    video_title: Optional[str] = None
    received_on: date
    rpm: Optional[Decimal] = None
    notes: Optional[str] = None


class CreatorIncomeUpdate(BaseModel):
    income_type: Optional[str] = None
    amount: Optional[Decimal] = None
    brand_name: Optional[str] = None
    video_title: Optional[str] = None
    received_on: Optional[date] = None
    rpm: Optional[Decimal] = None
    notes: Optional[str] = None


class CreatorIncomeOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    income_type: str
    amount: Decimal
    brand_name: Optional[str]
    video_title: Optional[str]
    received_on: date
    rpm: Optional[Decimal]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
