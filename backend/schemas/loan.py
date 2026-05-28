from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class LoanCreate(BaseModel):
    loan_type: str
    loan_name: str
    bank_name: Optional[str] = None
    principal: Decimal
    emi_amount: Decimal
    interest_rate: Decimal
    start_date: date
    months_total: int
    is_active: bool = True
    remaining_balance: Optional[Decimal] = None


class LoanUpdate(BaseModel):
    loan_type: Optional[str] = None
    loan_name: Optional[str] = None
    bank_name: Optional[str] = None
    principal: Optional[Decimal] = None
    emi_amount: Optional[Decimal] = None
    interest_rate: Optional[Decimal] = None
    start_date: Optional[date] = None
    months_total: Optional[int] = None
    paid_months: Optional[int] = None
    is_active: Optional[bool] = None


class LoanOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    loan_type: str
    loan_name: str
    bank_name: Optional[str]
    principal: Decimal
    emi_amount: Decimal
    interest_rate: Decimal
    start_date: date
    months_total: int
    paid_months: int = 0
    is_active: bool
    created_at: datetime
    remaining_balance: Optional[Decimal] = None
    last_paid_date: Optional[date] = None

    model_config = {"from_attributes": True}


class CreditCardCreate(BaseModel):
    card_name: str
    bank_name: Optional[str] = None
    credit_limit: Decimal
    outstanding: Decimal = Decimal("0")
    minimum_due: Decimal = Decimal("0")
    due_date: Optional[int] = None
    statement_date: Optional[int] = None


class CreditCardUpdate(BaseModel):
    card_name: Optional[str] = None
    bank_name: Optional[str] = None
    credit_limit: Optional[Decimal] = None
    outstanding: Optional[Decimal] = None
    minimum_due: Optional[Decimal] = None
    due_date: Optional[int] = None
    statement_date: Optional[int] = None


class CreditCardOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    card_name: str
    bank_name: Optional[str]
    credit_limit: Decimal
    outstanding: Decimal
    minimum_due: Decimal
    due_date: Optional[int]
    statement_date: Optional[int]
    updated_at: datetime
    last_paid_date: Optional[date] = None

    model_config = {"from_attributes": True}


class LoanPayPayload(BaseModel):
    amount: Decimal
    paid_on: Optional[date] = None
    notes: Optional[str] = None


class CardPayPayload(BaseModel):
    amount: Decimal
    paid_on: Optional[date] = None
    notes: Optional[str] = None


class DebtPaymentOut(BaseModel):
    id: uuid.UUID
    loan_id: Optional[uuid.UUID]
    card_id: Optional[uuid.UUID]
    amount_paid: Decimal
    remaining_balance: Decimal
    paid_on: date
    notes: Optional[str]
    created_at: datetime
    model_config = {"from_attributes": True}
