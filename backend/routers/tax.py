from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import extract, func

from database import get_db
from models import IncomeEntry, User, TaxDeduction, AdvanceTaxPayment, TradingLossCarryforward
from schemas.networth import TaxDeductionCreate, TaxDeductionOut, AdvanceTaxOut
from routers.auth import get_current_user
from engines.tax_engine import (
    calculate_total_tax_liability,
    calculate_advance_tax_installments,
    get_deduction_limits,
    get_tax_saving_suggestions,
)

router = APIRouter(prefix="/api/tax", tags=["tax"])


def _get_financial_year(year: Optional[int] = None) -> str:
    if year:
        return f"{year}-{str(year + 1)[-2:]}"
    today = date.today()
    fy_start = today.year if today.month >= 4 else today.year - 1
    return f"{fy_start}-{str(fy_start + 1)[-2:]}"


@router.get("/summary")
def tax_summary(
    year: Optional[int] = None,
    regime: str = "new",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    fy = _get_financial_year(year)
    fy_year = int(fy.split("-")[0])

    incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) >= fy_year,
        extract("year", IncomeEntry.received_on) <= fy_year + 1,
    ).all()

    deductions_db = db.query(TaxDeduction).filter(
        TaxDeduction.user_id == current_user.id,
        TaxDeduction.financial_year == fy,
    ).all()

    deductions_dict = {}
    for d in deductions_db:
        deductions_dict[d.section] = deductions_dict.get(d.section, 0) + float(d.amount)

    income_entries = [
        {"amount": float(i.amount), "tax_category": i.tax_category}
        for i in incomes
    ]

    result = calculate_total_tax_liability(income_entries, deductions_dict, regime)
    result["financial_year"] = fy
    return result


@router.get("/deductions", response_model=List[TaxDeductionOut])
def list_deductions(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    fy = _get_financial_year(year)
    return db.query(TaxDeduction).filter(
        TaxDeduction.user_id == current_user.id,
        TaxDeduction.financial_year == fy,
    ).all()


@router.post("/deductions", response_model=TaxDeductionOut, status_code=201)
def create_deduction(
    payload: TaxDeductionCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ded = TaxDeduction(**payload.model_dump(), user_id=current_user.id)
    db.add(ded)
    db.commit()
    db.refresh(ded)
    return ded


@router.delete("/deductions/{ded_id}", status_code=204)
def delete_deduction(
    ded_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    ded = db.query(TaxDeduction).filter(
        TaxDeduction.id == ded_id, TaxDeduction.user_id == current_user.id
    ).first()
    if not ded:
        raise HTTPException(status_code=404, detail="Deduction not found")
    db.delete(ded)
    db.commit()


@router.get("/advance")
def get_advance_tax(
    year: Optional[int] = None,
    regime: str = "new",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    fy = _get_financial_year(year)
    fy_year = int(fy.split("-")[0])

    incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) >= fy_year,
        extract("year", IncomeEntry.received_on) <= fy_year + 1,
    ).all()

    income_entries = [{"amount": float(i.amount), "tax_category": i.tax_category} for i in incomes]
    tax_info = calculate_total_tax_liability(income_entries, {}, regime)
    total_liability = tax_info["total_tax"]

    existing = db.query(AdvanceTaxPayment).filter(
        AdvanceTaxPayment.user_id == current_user.id,
        AdvanceTaxPayment.financial_year == fy,
    ).all()

    if existing:
        return [AdvanceTaxOut.model_validate(p) for p in existing]

    installments = calculate_advance_tax_installments(total_liability)
    result = []
    for inst in installments:
        payment = AdvanceTaxPayment(
            user_id=current_user.id,
            financial_year=fy,
            installment=inst["installment"],
            due_date=inst["due_date"],
            amount_due=inst["amount_due"],
            amount_paid=0,
            is_paid=False,
        )
        db.add(payment)
        result.append(payment)
    db.commit()
    for p in result:
        db.refresh(p)
    return [AdvanceTaxOut.model_validate(p) for p in result]


@router.put("/advance/{payment_id}/pay")
def mark_advance_tax_paid(
    payment_id: str,
    payload: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    payment = db.query(AdvanceTaxPayment).filter(
        AdvanceTaxPayment.id == payment_id,
        AdvanceTaxPayment.user_id == current_user.id,
    ).first()
    if not payment:
        raise HTTPException(status_code=404, detail="Payment not found")
    payment.amount_paid = payload.get("amount_paid", payment.amount_due)
    payment.paid_on = date.today()
    payment.is_paid = True
    db.commit()
    db.refresh(payment)
    return AdvanceTaxOut.model_validate(payment)


@router.get("/carryforward")
def get_carryforward(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    losses = db.query(TradingLossCarryforward).filter(
        TradingLossCarryforward.user_id == current_user.id,
    ).order_by(TradingLossCarryforward.financial_year.desc()).all()
    return [
        {
            "id": str(l.id),
            "financial_year": l.financial_year,
            "loss_type": l.loss_type,
            "original_loss": float(l.original_loss),
            "remaining_loss": float(l.remaining_loss),
            "expiry_year": l.expiry_year,
        }
        for l in losses
    ]


@router.get("/suggestions")
def get_tax_suggestions(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    fy = _get_financial_year(year)
    fy_year = int(fy.split("-")[0])

    incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) >= fy_year,
    ).all()
    total_income = sum(float(i.amount) for i in incomes)

    deductions_db = db.query(TaxDeduction).filter(
        TaxDeduction.user_id == current_user.id,
        TaxDeduction.financial_year == fy,
    ).all()

    used_80c = sum(float(d.amount) for d in deductions_db if d.section == "80C")
    used_80d = sum(float(d.amount) for d in deductions_db if d.section == "80D")

    limits = get_deduction_limits()
    remaining_80c = max(limits["80C"] - used_80c, 0)
    remaining_80d = max(limits["80D"] - used_80d, 0)

    return get_tax_saving_suggestions(remaining_80c, remaining_80d, total_income)
