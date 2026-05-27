from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class InvestmentCreate(BaseModel):
    asset_type: str
    name: str
    invested_amount: Decimal
    current_value: Decimal
    purchase_date: date
    quantity: Optional[Decimal] = None
    unit: Optional[str] = None
    tax_section: Optional[str] = None
    maturity_date: Optional[date] = None
    notes: Optional[str] = None


class InvestmentUpdate(BaseModel):
    asset_type: Optional[str] = None
    name: Optional[str] = None
    invested_amount: Optional[Decimal] = None
    current_value: Optional[Decimal] = None
    purchase_date: Optional[date] = None
    quantity: Optional[Decimal] = None
    unit: Optional[str] = None
    tax_section: Optional[str] = None
    maturity_date: Optional[date] = None
    notes: Optional[str] = None


class InvestmentOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    asset_type: str
    name: str
    invested_amount: Decimal
    current_value: Decimal
    purchase_date: date
    quantity: Optional[Decimal]
    unit: Optional[str]
    tax_section: Optional[str]
    maturity_date: Optional[date]
    notes: Optional[str]
    updated_at: datetime
    created_at: datetime

    model_config = {"from_attributes": True}
