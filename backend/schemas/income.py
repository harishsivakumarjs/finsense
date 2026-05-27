from pydantic import BaseModel, condecimal
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class IncomeCreate(BaseModel):
    source_type: str
    amount: Decimal
    description: Optional[str] = None
    received_on: date
    tax_category: str = "salary"

    model_config = {"from_attributes": True}


class IncomeUpdate(BaseModel):
    source_type: Optional[str] = None
    amount: Optional[Decimal] = None
    description: Optional[str] = None
    received_on: Optional[date] = None
    tax_category: Optional[str] = None


class IncomeOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    source_type: str
    amount: Decimal
    description: Optional[str]
    received_on: date
    tax_category: str
    created_at: datetime

    model_config = {"from_attributes": True}
