from datetime import date
from typing import Optional
from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.orm import Session
from sqlalchemy import func, extract
import io

from database import get_db
from models import User, IncomeEntry, Expense, Loan, Investment, NetWorthSnapshot, TaxDeduction, AdvanceTaxPayment
from routers.auth import get_current_user
from engines.pdf_generator import generate_monthly_report, generate_tax_summary
from engines.tax_engine import calculate_total_tax_liability

router = APIRouter(prefix="/api/reports", tags=["reports"])


@router.get("/monthly")
def monthly_report_json(
    month: Optional[int] = None,
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    m = month or today.month
    y = year or today.year

    income_streams = db.query(
        IncomeEntry.source_type,
        func.sum(IncomeEntry.amount).label("total"),
    ).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == m,
        extract("year", IncomeEntry.received_on) == y,
    ).group_by(IncomeEntry.source_type).all()

    expense_summary = db.query(
        Expense.category,
        func.sum(Expense.amount).label("total"),
    ).filter(
        Expense.user_id == current_user.id,
        extract("month", Expense.spent_on) == m,
        extract("year", Expense.spent_on) == y,
    ).group_by(Expense.category).all()

    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()

    total_investments = db.query(func.sum(Investment.current_value)).filter(
        Investment.user_id == current_user.id
    ).scalar() or 0

    return {
        "month": m,
        "year": y,
        "income_streams": [{"source_type": r.source_type, "total": float(r.total)} for r in income_streams],
        "expense_summary": [{"category": r.category, "total": float(r.total)} for r in expense_summary],
        "loans": [
            {"loan_name": l.loan_name, "bank_name": l.bank_name, "emi_amount": float(l.emi_amount),
             "interest_rate": float(l.interest_rate), "is_active": l.is_active}
            for l in loans
        ],
        "net_worth": float(total_investments),
    }


@router.get("/monthly/pdf")
def monthly_report_pdf(
    month: Optional[int] = None,
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    m = month or today.month
    y = year or today.year

    month_names = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    income_streams = db.query(
        IncomeEntry.source_type,
        func.sum(IncomeEntry.amount).label("total"),
    ).filter(
        IncomeEntry.user_id == current_user.id,
        extract("month", IncomeEntry.received_on) == m,
        extract("year", IncomeEntry.received_on) == y,
    ).group_by(IncomeEntry.source_type).all()

    expense_summary = db.query(
        Expense.category,
        func.sum(Expense.amount).label("total"),
    ).filter(
        Expense.user_id == current_user.id,
        extract("month", Expense.spent_on) == m,
        extract("year", Expense.spent_on) == y,
    ).group_by(Expense.category).all()

    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()
    total_investments = float(db.query(func.sum(Investment.current_value)).filter(
        Investment.user_id == current_user.id
    ).scalar() or 0)

    data_dict = {
        "month_label": f"{month_names[m-1]} {y}",
        "user_name": current_user.name,
        "income_streams": [{"source_type": r.source_type, "total": float(r.total)} for r in income_streams],
        "expense_summary": [{"category": r.category, "total": float(r.total)} for r in expense_summary],
        "loans": [
            {"loan_name": l.loan_name, "bank_name": l.bank_name, "emi_amount": float(l.emi_amount),
             "interest_rate": float(l.interest_rate), "is_active": l.is_active}
            for l in loans
        ],
        "net_worth": total_investments,
    }

    pdf_bytes = generate_monthly_report(data_dict)
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=finsense_report_{y}_{m:02d}.pdf"},
    )


@router.get("/tax")
def tax_report_json(
    year: Optional[int] = None,
    regime: str = "new",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    fy_start = year or (today.year if today.month >= 4 else today.year - 1)
    fy = f"{fy_start}-{str(fy_start + 1)[-2:]}"

    incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) >= fy_start,
    ).all()

    deductions = db.query(TaxDeduction).filter(
        TaxDeduction.user_id == current_user.id,
        TaxDeduction.financial_year == fy,
    ).all()

    advance_payments = db.query(AdvanceTaxPayment).filter(
        AdvanceTaxPayment.user_id == current_user.id,
        AdvanceTaxPayment.financial_year == fy,
    ).all()

    income_entries = [{"amount": float(i.amount), "tax_category": i.tax_category} for i in incomes]
    ded_dict = {}
    for d in deductions:
        ded_dict[d.section] = ded_dict.get(d.section, 0) + float(d.amount)

    tax_data = calculate_total_tax_liability(income_entries, ded_dict, regime)

    return {
        "financial_year": fy,
        "regime": regime,
        "tax_data": tax_data,
        "deductions": [{"section": d.section, "description": d.description, "amount": float(d.amount)} for d in deductions],
        "advance_payments": [
            {
                "installment": p.installment,
                "due_date": str(p.due_date),
                "amount_due": float(p.amount_due),
                "amount_paid": float(p.amount_paid),
                "is_paid": p.is_paid,
            }
            for p in advance_payments
        ],
    }


@router.get("/tax/pdf")
def tax_report_pdf(
    year: Optional[int] = None,
    regime: str = "new",
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    today = date.today()
    fy_start = year or (today.year if today.month >= 4 else today.year - 1)
    fy = f"{fy_start}-{str(fy_start + 1)[-2:]}"

    incomes = db.query(IncomeEntry).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) >= fy_start,
    ).all()
    deductions = db.query(TaxDeduction).filter(
        TaxDeduction.user_id == current_user.id,
        TaxDeduction.financial_year == fy,
    ).all()
    advance_payments = db.query(AdvanceTaxPayment).filter(
        AdvanceTaxPayment.user_id == current_user.id,
        AdvanceTaxPayment.financial_year == fy,
    ).all()

    income_entries = [{"amount": float(i.amount), "tax_category": i.tax_category} for i in incomes]
    ded_dict = {}
    for d in deductions:
        ded_dict[d.section] = ded_dict.get(d.section, 0) + float(d.amount)
    tax_data = calculate_total_tax_liability(income_entries, ded_dict, regime)

    data_dict = {
        "financial_year": fy,
        "user_name": current_user.name,
        "regime": regime,
        "tax_data": tax_data,
        "deductions": [{"section": d.section, "description": d.description, "amount": float(d.amount)} for d in deductions],
        "advance_payments": [
            {
                "installment": p.installment,
                "due_date": str(p.due_date),
                "amount_due": float(p.amount_due),
                "amount_paid": float(p.amount_paid),
                "is_paid": p.is_paid,
            }
            for p in advance_payments
        ],
    }

    pdf_bytes = generate_tax_summary(data_dict)
    return StreamingResponse(
        io.BytesIO(pdf_bytes),
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename=finsense_tax_{fy}.pdf"},
    )


@router.get("/networth")
def networth_report_json(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year

    snapshots = db.query(NetWorthSnapshot).filter(
        NetWorthSnapshot.user_id == current_user.id,
        extract("year", NetWorthSnapshot.snapshot_date) == year,
    ).order_by(NetWorthSnapshot.snapshot_date.asc()).all()

    investments = db.query(Investment).filter(Investment.user_id == current_user.id).all()
    loans = db.query(Loan).filter(Loan.user_id == current_user.id, Loan.is_active == True).all()

    return {
        "year": year,
        "snapshots": [
            {
                "date": str(s.snapshot_date),
                "net_worth": float(s.net_worth),
                "total_assets": float(s.total_assets),
                "total_liabilities": float(s.total_liabilities),
                "debt_score": s.debt_score,
            }
            for s in snapshots
        ],
        "investments": [
            {"name": i.name, "asset_type": i.asset_type, "current_value": float(i.current_value)}
            for i in investments
        ],
        "loans": [
            {"loan_name": l.loan_name, "emi_amount": float(l.emi_amount)}
            for l in loans
        ],
    }
