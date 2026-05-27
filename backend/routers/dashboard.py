from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from database import get_db
from models import User, IncomeEntry, Expense, Loan, CreditCard, Investment, Trade, FriendLedger, CreatorIncome
from routers.auth import get_current_user
from engines.debt_score import calculate_debt_score, get_score_verdict
from engines.tax_engine import calculate_total_tax_liability
from engines.forecast import forecast_debt_ratio

router = APIRouter(prefix="/api/dashboard", tags=["dashboard"])


@router.get("")
def get_dashboard(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    current_month = today.month
    current_year = today.year

    # Monthly income
    monthly_income = db.query(func.sum(IncomeEntry.amount)).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == current_month,
        extract("year", IncomeEntry.received_on) == current_year,
    ).scalar() or 0

    # Monthly expenses
    monthly_expenses = db.query(func.sum(Expense.amount)).filter(
        Expense.user_id == current_user.id,
        extract("month", Expense.spent_on) == current_month,
        extract("year", Expense.spent_on) == current_year,
    ).scalar() or 0

    # Active loans
    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()
    total_emi = sum(float(l.emi_amount) for l in loans)

    # Credit cards
    cards = db.query(CreditCard).filter(CreditCard.user_id == current_user.id).all()
    cc_min = sum(float(c.minimum_due) for c in cards)
    cc_outstanding = sum(float(c.outstanding) for c in cards)

    income_f = float(monthly_income)
    expenses_f = float(monthly_expenses)
    free_cash = income_f - expenses_f - total_emi
    savings = max(free_cash, 0)
    savings_rate = (savings / income_f * 100) if income_f > 0 else 0

    # Debt score
    emergency_fund = income_f * 3
    debt_score = calculate_debt_score(income_f, total_emi, cc_min, savings, emergency_fund)
    debt_verdict = get_score_verdict(debt_score)

    # Net worth
    total_investments = db.query(func.sum(Investment.current_value)).filter(
        Investment.user_id == current_user.id
    ).scalar() or 0

    loan_outstanding = 0
    for loan in loans:
        months_elapsed = (today.year - loan.start_date.year) * 12 + (today.month - loan.start_date.month)
        remaining_months = max(loan.months_total - months_elapsed, 0)
        r = float(loan.interest_rate) / 100 / 12
        emi = float(loan.emi_amount)
        if r > 0 and remaining_months > 0:
            outstanding = emi * (1 - (1 + r) ** (-remaining_months)) / r
        else:
            outstanding = emi * remaining_months
        loan_outstanding += outstanding

    total_assets = float(total_investments)
    total_liabilities = loan_outstanding + cc_outstanding
    net_worth = total_assets - total_liabilities

    # Tax estimate
    all_incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) >= (current_year if current_month >= 4 else current_year - 1),
    ).all()
    income_entries = [{"amount": float(i.amount), "tax_category": i.tax_category} for i in all_incomes]
    tax_info = calculate_total_tax_liability(income_entries, {}, "new")
    tax_due = tax_info["total_tax"]

    # Income vs Expense chart (last 6 months)
    months_data = []
    month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    for i in range(5, -1, -1):
        m = ((current_month - 1 - i) % 12) + 1
        y = current_year if current_month - i > 0 else current_year - 1

        inc = db.query(func.sum(IncomeEntry.amount)).filter(
            IncomeEntry.user_id == current_user.id,
            extract("month", IncomeEntry.received_on) == m,
            extract("year", IncomeEntry.received_on) == y,
        ).scalar() or 0

        exp = db.query(func.sum(Expense.amount)).filter(
            Expense.user_id == current_user.id,
            extract("month", Expense.spent_on) == m,
            extract("year", Expense.spent_on) == y,
        ).scalar() or 0

        months_data.append({
            "month": month_names[m - 1],
            "income": float(inc),
            "expense": float(exp),
        })

    # Debt ratio forecast
    loan_dicts = [
        {
            "is_active": l.is_active,
            "start_date": l.start_date,
            "months_total": l.months_total,
            "emi_amount": float(l.emi_amount),
        }
        for l in loans
    ]
    debt_forecast = forecast_debt_ratio(loan_dicts, income_f if income_f > 0 else 1, months=6)

    # Recent activity (last 10 across all modules)
    recent_activity = []

    recent_incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id
    ).order_by(IncomeEntry.created_at.desc()).limit(3).all()
    for i in recent_incomes:
        recent_activity.append({
            "type": "income",
            "description": i.description or f"{i.source_type} income",
            "amount": float(i.amount),
            "date": str(i.received_on),
            "positive": True,
        })

    recent_expenses = db.query(Expense).filter(
        Expense.user_id == current_user.id
    ).order_by(Expense.created_at.desc()).limit(4).all()
    for e in recent_expenses:
        recent_activity.append({
            "type": "expense",
            "description": e.description or e.category,
            "amount": float(e.amount),
            "date": str(e.spent_on),
            "positive": False,
        })

    recent_trades = db.query(Trade).filter(
        Trade.user_id == current_user.id, Trade.net_pnl.isnot(None)
    ).order_by(Trade.created_at.desc()).limit(3).all()
    for t in recent_trades:
        recent_activity.append({
            "type": "trade",
            "description": f"{t.scrip} ({t.trade_type})",
            "amount": float(t.net_pnl),
            "date": str(t.sell_date or t.buy_date),
            "positive": float(t.net_pnl) > 0,
        })

    recent_activity.sort(key=lambda x: x["date"], reverse=True)
    recent_activity = recent_activity[:10]

    # Top alert
    top_alert = None
    if debt_score >= 70:
        top_alert = {
            "level": "danger",
            "message": f"Debt Danger Score is {debt_score}/100 — EMIs consuming too much income. Consider refinancing or prepayment.",
        }
    elif savings_rate < 10 and income_f > 0:
        top_alert = {
            "level": "caution",
            "message": f"Savings rate is only {savings_rate:.1f}%. Try to save at least 20% of income.",
        }
    elif tax_due > 50000:
        top_alert = {
            "level": "info",
            "message": f"Estimated tax liability is ₹{tax_due:,.0f}. Consider tax-saving investments before March 31.",
        }

    return {
        "net_worth": round(net_worth, 2),
        "free_cash": round(free_cash, 2),
        "debt_score": debt_score,
        "debt_verdict": debt_verdict,
        "tax_due": round(tax_due, 2),
        "monthly_income": round(income_f, 2),
        "monthly_expenses": round(expenses_f, 2),
        "savings_rate": round(savings_rate, 2),
        "total_emi": round(total_emi, 2),
        "income_vs_expense_data": months_data,
        "debt_ratio_forecast": debt_forecast,
        "recent_activity": recent_activity,
        "top_alert": top_alert,
        "total_assets": round(total_assets, 2),
        "total_liabilities": round(total_liabilities, 2),
    }
