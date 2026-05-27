from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import Investment, Loan, CreditCard, NetWorthSnapshot, User, IncomeEntry, Expense
from schemas.networth import NetWorthSnapshotOut
from routers.auth import get_current_user
from engines.debt_score import calculate_debt_score
from engines.forecast import forecast_net_worth

router = APIRouter(prefix="/api/networth", tags=["networth"])


def _compute_current_networth(db: Session, user_id):
    total_investments = db.query(__import__("sqlalchemy").func.sum(Investment.current_value)).filter(
        Investment.user_id == user_id
    ).scalar() or 0

    loan_outstanding = 0
    loans = db.query(Loan).filter(Loan.user_id == user_id, Loan.is_active == True).all()
    for loan in loans:
        from datetime import date as _date
        months_elapsed = (_date.today().year - loan.start_date.year) * 12 + (_date.today().month - loan.start_date.month)
        remaining_months = max(loan.months_total - months_elapsed, 0)
        r = float(loan.interest_rate) / 100 / 12
        emi = float(loan.emi_amount)
        if r > 0 and remaining_months > 0:
            outstanding = emi * (1 - (1 + r) ** (-remaining_months)) / r
        else:
            outstanding = emi * remaining_months
        loan_outstanding += outstanding

    cc_outstanding = db.query(__import__("sqlalchemy").func.sum(CreditCard.outstanding)).filter(
        CreditCard.user_id == user_id
    ).scalar() or 0

    total_assets = float(total_investments)
    total_liabilities = loan_outstanding + float(cc_outstanding)
    net_worth = total_assets - total_liabilities
    return total_assets, total_liabilities, net_worth


@router.get("")
def get_current_networth(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    total_assets, total_liabilities, net_worth = _compute_current_networth(db, current_user.id)
    return {
        "net_worth": round(net_worth, 2),
        "total_assets": round(total_assets, 2),
        "total_liabilities": round(total_liabilities, 2),
        "as_of": date.today().isoformat(),
    }


@router.get("/history")
def networth_history(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    snapshots = db.query(NetWorthSnapshot).filter(
        NetWorthSnapshot.user_id == current_user.id
    ).order_by(NetWorthSnapshot.snapshot_date.asc()).all()
    return [NetWorthSnapshotOut.model_validate(s) for s in snapshots]


@router.post("/snapshot", response_model=NetWorthSnapshotOut, status_code=201)
def take_snapshot(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import extract, func as sqlfunc
    today = date.today()
    total_assets, total_liabilities, net_worth = _compute_current_networth(db, current_user.id)

    monthly_income = db.query(sqlfunc.sum(IncomeEntry.amount)).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == today.month,
        extract("year", IncomeEntry.received_on) == today.year,
    ).scalar() or 1

    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()
    cards = db.query(CreditCard).filter(CreditCard.user_id == current_user.id).all()
    total_emi = sum(float(l.emi_amount) for l in loans)
    cc_min = sum(float(c.minimum_due) for c in cards)
    savings = max(float(monthly_income) - total_emi - cc_min, 0)
    score = calculate_debt_score(float(monthly_income), total_emi, cc_min, savings, float(monthly_income) * 3)

    snapshot = NetWorthSnapshot(
        user_id=current_user.id,
        snapshot_date=today,
        total_assets=total_assets,
        total_liabilities=total_liabilities,
        net_worth=net_worth,
        debt_score=score,
    )
    db.add(snapshot)
    db.commit()
    db.refresh(snapshot)
    return NetWorthSnapshotOut.model_validate(snapshot)


@router.get("/forecast")
def networth_forecast(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    from sqlalchemy import extract, func as sqlfunc
    today = date.today()
    snapshots = db.query(NetWorthSnapshot).filter(
        NetWorthSnapshot.user_id == current_user.id
    ).order_by(NetWorthSnapshot.snapshot_date.asc()).all()

    monthly_income = db.query(sqlfunc.sum(IncomeEntry.amount)).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == today.month,
        extract("year", IncomeEntry.received_on) == today.year,
    ).scalar() or 0

    monthly_expenses = db.query(sqlfunc.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        extract("month", Expense.spent_on) == today.month,
        extract("year", Expense.spent_on) == today.year,
    ).scalar() or 0

    monthly_savings = max(float(monthly_income) - float(monthly_expenses), 0)
    snapshot_dicts = [{"net_worth": float(s.net_worth)} for s in snapshots]

    return forecast_net_worth(snapshot_dicts, monthly_savings, months=12)
