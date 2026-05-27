from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class InsurancePolicyCreate(BaseModel):
    policy_type: str
    policy_name: str
    insurer_name: Optional[str] = None
    policy_number: Optional[str] = None
    sum_assured: Optional[Decimal] = None
    annual_premium: Decimal
    premium_frequency: str = "yearly"
    next_due_date: date
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    tax_section: Optional[str] = None
    tax_benefit_amount: Optional[Decimal] = None
    is_active: bool = True
    notes: Optional[str] = None


class InsurancePolicyUpdate(BaseModel):
    policy_type: Optional[str] = None
    policy_name: Optional[str] = None
    insurer_name: Optional[str] = None
    policy_number: Optional[str] = None
    sum_assured: Optional[Decimal] = None
    annual_premium: Optional[Decimal] = None
    premium_frequency: Optional[str] = None
    next_due_date: Optional[date] = None
    start_date: Optional[date] = None
    end_date: Optional[date] = None
    tax_section: Optional[str] = None
    tax_benefit_amount: Optional[Decimal] = None
    is_active: Optional[bool] = None
    notes: Optional[str] = None


class InsurancePolicyOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    policy_type: str
    policy_name: str
    insurer_name: Optional[str]
    policy_number: Optional[str]
    sum_assured: Optional[Decimal]
    annual_premium: Decimal
    premium_frequency: str
    next_due_date: date
    start_date: Optional[date]
    end_date: Optional[date]
    tax_section: Optional[str]
    tax_benefit_amount: Optional[Decimal]
    is_active: bool
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
