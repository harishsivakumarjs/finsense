from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from database import get_db
from models import IncomeEntry, User
from schemas.income import IncomeCreate, IncomeUpdate, IncomeOut
from routers.auth import get_current_user

router = APIRouter(prefix="/api/income", tags=["income"])


@router.get("", response_model=List[IncomeOut])
def list_income(
    year: Optional[int] = None,
    month: Optional[int] = None,
    source_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(IncomeEntry).filter(IncomeEntry.user_id == current_user.id)
    if year:
        query = query.filter(extract("year", IncomeEntry.received_on) == year)
    if month:
        query = query.filter(extract("month", IncomeEntry.received_on) == month)
    if source_type:
        query = query.filter(IncomeEntry.source_type == source_type)
    return query.order_by(IncomeEntry.received_on.desc()).all()


@router.post("", response_model=IncomeOut, status_code=201)
def create_income(
    payload: IncomeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = IncomeEntry(**payload.model_dump(), user_id=current_user.id)
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.put("/{income_id}", response_model=IncomeOut)
def update_income(
    income_id: str,
    payload: IncomeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(IncomeEntry).filter(
        IncomeEntry.id == income_id,
        IncomeEntry.user_id == current_user.id,
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Income entry not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{income_id}", status_code=204)
def delete_income(
    income_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(IncomeEntry).filter(
        IncomeEntry.id == income_id,
        IncomeEntry.user_id == current_user.id,
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Income entry not found")
    db.delete(entry)
    db.commit()


@router.get("/summary")
def income_summary(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year
    query = db.query(
        extract("month", IncomeEntry.received_on).label("month"),
        func.sum(IncomeEntry.amount).label("total"),
    ).filter(
        IncomeEntry.user_id == current_user.id,
        extract("year", IncomeEntry.received_on) == year,
    ).group_by(extract("month", IncomeEntry.received_on)).all()

    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    result = {m: 0.0 for m in months}
    for row in query:
        result[months[int(row.month) - 1]] = float(row.total or 0)
    return result


@router.get("/streams")
def income_streams(
    year: Optional[int] = None,
    month: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(
        IncomeEntry.source_type,
        func.sum(IncomeEntry.amount).label("total"),
    ).filter(IncomeEntry.user_id == current_user.id)
    if year:
        query = query.filter(extract("year", IncomeEntry.received_on) == year)
    if month:
        query = query.filter(extract("month", IncomeEntry.received_on) == month)
    results = query.group_by(IncomeEntry.source_type).all()
    return [{"source_type": r.source_type, "total": float(r.total or 0)} for r in results]
