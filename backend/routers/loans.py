from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Loan, CreditCard, IncomeEntry, User
from schemas.loan import (
    LoanCreate, LoanUpdate, LoanOut,
    CreditCardCreate, CreditCardUpdate, CreditCardOut,
)
from routers.auth import get_current_user
from engines.debt_score import calculate_debt_score, get_score_verdict
from engines.forecast import forecast_debt_ratio, calculate_debt_free_date

router = APIRouter(prefix="/api/loans", tags=["loans"])


@router.get("", response_model=List[LoanOut])
def list_loans(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(Loan).filter(Loan.user_id == current_user.id).order_by(Loan.created_at.desc()).all()


@router.post("", response_model=LoanOut, status_code=201)
def create_loan(
    payload: LoanCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    loan = Loan(**payload.model_dump(), user_id=current_user.id)
    db.add(loan)
    db.commit()
    db.refresh(loan)
    return loan


@router.put("/{loan_id}", response_model=LoanOut)
def update_loan(
    loan_id: str,
    payload: LoanUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    loan = db.query(Loan).filter(Loan.id == loan_id, Loan.user_id == current_user.id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(loan, field, value)
    db.commit()
    db.refresh(loan)
    return loan


@router.delete("/{loan_id}", status_code=204)
def delete_loan(
    loan_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    loan = db.query(Loan).filter(Loan.id == loan_id, Loan.user_id == current_user.id).first()
    if not loan:
        raise HTTPException(status_code=404, detail="Loan not found")
    db.delete(loan)
    db.commit()


# Credit Cards
@router.get("/cards", response_model=List[CreditCardOut])
def list_cards(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(CreditCard).filter(CreditCard.user_id == current_user.id).all()


@router.post("/cards", response_model=CreditCardOut, status_code=201)
def create_card(
    payload: CreditCardCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    card = CreditCard(**payload.model_dump(), user_id=current_user.id)
    db.add(card)
    db.commit()
    db.refresh(card)
    return card


@router.put("/cards/{card_id}", response_model=CreditCardOut)
def update_card(
    card_id: str,
    payload: CreditCardUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    card = db.query(CreditCard).filter(CreditCard.id == card_id, CreditCard.user_id == current_user.id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Credit card not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(card, field, value)
    db.commit()
    db.refresh(card)
    return card


@router.delete("/cards/{card_id}", status_code=204)
def delete_card(
    card_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    card = db.query(CreditCard).filter(CreditCard.id == card_id, CreditCard.user_id == current_user.id).first()
    if not card:
        raise HTTPException(status_code=404, detail="Credit card not found")
    db.delete(card)
    db.commit()


@router.get("/score")
def get_debt_score(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    from sqlalchemy import extract, func
    monthly_income = db.query(func.sum(IncomeEntry.amount)).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == today.month,
        extract("year", IncomeEntry.received_on) == today.year,
    ).scalar() or 0

    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()
    cards = db.query(CreditCard).filter(CreditCard.user_id == current_user.id).all()

    total_emi = sum(float(l.emi_amount) for l in loans)
    cc_min = sum(float(c.minimum_due) for c in cards)
    income = float(monthly_income)
    savings = max(income - total_emi - cc_min, 0)
    emergency_fund = income * 3

    score = calculate_debt_score(income, total_emi, cc_min, savings, emergency_fund)
    verdict = get_score_verdict(score)

    return {
        "score": score,
        "verdict": verdict,
        "monthly_income": income,
        "total_emi": total_emi,
        "cc_minimum": cc_min,
        "dti": round((total_emi + cc_min) / income * 100, 2) if income > 0 else 0,
    }


@router.get("/forecast")
def get_debt_forecast(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import extract, func
    today = date.today()
    monthly_income = db.query(func.sum(IncomeEntry.amount)).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == today.month,
        extract("year", IncomeEntry.received_on) == today.year,
    ).scalar() or 1

    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()
    loan_dicts = [
        {
            "is_active": l.is_active,
            "start_date": l.start_date,
            "months_total": l.months_total,
            "emi_amount": float(l.emi_amount),
        }
        for l in loans
    ]
    return forecast_debt_ratio(loan_dicts, float(monthly_income), months=6)


@router.get("/debtfree")
def get_debt_free_date(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()
    loan_dicts = [
        {"is_active": l.is_active, "start_date": l.start_date, "months_total": l.months_total}
        for l in loans
    ]
    result = calculate_debt_free_date(loan_dicts)
    return {"debt_free": result}


@router.post("/simulate")
def simulate_skip_emi(payload: dict, current_user: User = Depends(get_current_user)):
    emi_amount = float(payload.get("emi_amount", 0))
    interest_rate = float(payload.get("interest_rate", 10))

    monthly_rate = interest_rate / 100 / 12
    penalty = emi_amount * 0.02
    extra_interest = emi_amount * monthly_rate
    cibil_impact = -50 if emi_amount > 0 else 0
    total_cost = penalty + extra_interest

    return {
        "penalty": round(penalty, 2),
        "extra_interest": round(extra_interest, 2),
        "cibil_impact": cibil_impact,
        "total_cost": round(total_cost, 2),
        "recommendation": "Avoid skipping EMIs — contact your bank for moratorium options instead.",
    }
