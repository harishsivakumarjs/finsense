from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class NetWorthSnapshotOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    snapshot_date: date
    total_assets: Decimal
    total_liabilities: Decimal
    net_worth: Decimal
    debt_score: Optional[int]
    created_at: datetime

    model_config = {"from_attributes": True}


class GoalCreate(BaseModel):
    goal_name: str
    target_amount: Decimal
    current_amount: Decimal = Decimal("0")
    target_date: Optional[date] = None


class GoalOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    goal_name: str
    target_amount: Decimal
    current_amount: Decimal
    target_date: Optional[date]
    is_achieved: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class TaxDeductionCreate(BaseModel):
    financial_year: str
    section: str
    description: Optional[str] = None
    amount: Decimal


class TaxDeductionOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    financial_year: str
    section: str
    description: Optional[str]
    amount: Decimal
    created_at: datetime

    model_config = {"from_attributes": True}


class AdvanceTaxOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    financial_year: str
    installment: int
    due_date: date
    amount_due: Decimal
    amount_paid: Decimal
    paid_on: Optional[date]
    is_paid: bool

    model_config = {"from_attributes": True}
