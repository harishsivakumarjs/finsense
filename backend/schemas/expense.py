from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class ExpenseCreate(BaseModel):
    amount: Decimal
    category: str
    description: Optional[str] = None
    spent_on: date
    is_recurring: bool = False
    is_creator_expense: bool = False


class ExpenseUpdate(BaseModel):
    amount: Optional[Decimal] = None
    category: Optional[str] = None
    description: Optional[str] = None
    spent_on: Optional[date] = None
    is_recurring: Optional[bool] = None
    is_creator_expense: Optional[bool] = None


class ExpenseOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    amount: Decimal
    category: str
    description: Optional[str]
    spent_on: date
    is_recurring: bool
    is_creator_expense: bool
    created_at: datetime

    model_config = {"from_attributes": True}


class BudgetCreate(BaseModel):
    category: str
    monthly_limit: Decimal
    month: int
    year: int


class BudgetOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    category: str
    monthly_limit: Decimal
    month: int
    year: int

    model_config = {"from_attributes": True}
