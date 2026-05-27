from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from database import get_db
from models import Expense, User
from schemas.expense import ExpenseCreate, ExpenseUpdate, ExpenseOut
from routers.auth import get_current_user

router = APIRouter(prefix="/api/expenses", tags=["expenses"])


@router.get("", response_model=List[ExpenseOut])
def list_expenses(
    month: Optional[int] = None,
    year: Optional[int] = None,
    category: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Expense).filter(Expense.user_id == current_user.id)
    if month:
        query = query.filter(extract("month", Expense.spent_on) == month)
    if year:
        query = query.filter(extract("year", Expense.spent_on) == year)
    if category:
        query = query.filter(Expense.category == category)
    return query.order_by(Expense.spent_on.desc()).all()


@router.post("", response_model=ExpenseOut, status_code=201)
def create_expense(
    payload: ExpenseCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    expense = Expense(**payload.model_dump(), user_id=current_user.id)
    db.add(expense)
    db.commit()
    db.refresh(expense)
    return expense


@router.put("/{expense_id}", response_model=ExpenseOut)
def update_expense(
    expense_id: str,
    payload: ExpenseUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id,
    ).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(expense, field, value)
    db.commit()
    db.refresh(expense)
    return expense


@router.delete("/{expense_id}", status_code=204)
def delete_expense(
    expense_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    expense = db.query(Expense).filter(
        Expense.id == expense_id,
        Expense.user_id == current_user.id,
    ).first()
    if not expense:
        raise HTTPException(status_code=404, detail="Expense not found")
    db.delete(expense)
    db.commit()


@router.get("/summary")
def expense_summary(
    month: Optional[int] = None,
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year
    if month is None:
        month = date.today().month
    results = db.query(
        Expense.category,
        func.sum(Expense.amount).label("total"),
    ).filter(
        Expense.user_id == current_user.id,
        extract("month", Expense.spent_on) == month,
        extract("year", Expense.spent_on) == year,
    ).group_by(Expense.category).all()
    return [{"category": r.category, "total": float(r.total or 0)} for r in results]


@router.get("/heatmap")
def expense_heatmap(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year
    results = db.query(
        Expense.spent_on,
        func.sum(Expense.amount).label("total"),
    ).filter(
        Expense.user_id == current_user.id,
        extract("year", Expense.spent_on) == year,
    ).group_by(Expense.spent_on).all()
    return [{"date": str(r.spent_on), "total": float(r.total or 0)} for r in results]


@router.get("/subscriptions", response_model=List[ExpenseOut])
def list_subscriptions(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return db.query(Expense).filter(
        Expense.user_id == current_user.id,
        Expense.is_recurring == True,
    ).order_by(Expense.created_at.desc()).all()
