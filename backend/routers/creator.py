from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from database import get_db
from models import CreatorIncome, User
from schemas.creator import CreatorIncomeCreate, CreatorIncomeUpdate, CreatorIncomeOut
from routers.auth import get_current_user

router = APIRouter(prefix="/api/creator", tags=["creator"])


@router.get("", response_model=List[CreatorIncomeOut])
def list_creator_income(
    year: Optional[int] = None,
    month: Optional[int] = None,
    income_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(CreatorIncome).filter(CreatorIncome.user_id == current_user.id)
    if year:
        query = query.filter(extract("year", CreatorIncome.received_on) == year)
    if month:
        query = query.filter(extract("month", CreatorIncome.received_on) == month)
    if income_type:
        query = query.filter(CreatorIncome.income_type == income_type)
    return query.order_by(CreatorIncome.received_on.desc()).all()


@router.post("", response_model=CreatorIncomeOut, status_code=201)
def create_creator_income(
    payload: CreatorIncomeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = CreatorIncome(**payload.model_dump(), user_id=current_user.id)
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.put("/{entry_id}", response_model=CreatorIncomeOut)
def update_creator_income(
    entry_id: str,
    payload: CreatorIncomeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(CreatorIncome).filter(
        CreatorIncome.id == entry_id, CreatorIncome.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Creator income entry not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=204)
def delete_creator_income(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(CreatorIncome).filter(
        CreatorIncome.id == entry_id, CreatorIncome.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Creator income entry not found")
    db.delete(entry)
    db.commit()


@router.get("/summary")
def creator_summary(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year
    results = db.query(
        CreatorIncome.income_type,
        func.sum(CreatorIncome.amount).label("total"),
    ).filter(
        CreatorIncome.user_id == current_user.id,
        extract("year", CreatorIncome.received_on) == year,
    ).group_by(CreatorIncome.income_type).all()

    return [{"income_type": r.income_type, "total": float(r.total or 0)} for r in results]


@router.get("/rpm_trend")
def creator_rpm_trend(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year
    results = db.query(
        extract("month", CreatorIncome.received_on).label("month"),
        func.avg(CreatorIncome.rpm).label("avg_rpm"),
        func.sum(CreatorIncome.amount).label("total"),
    ).filter(
        CreatorIncome.user_id == current_user.id,
        extract("year", CreatorIncome.received_on) == year,
        CreatorIncome.rpm.isnot(None),
    ).group_by(extract("month", CreatorIncome.received_on)).all()

    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    data = {m: {"avg_rpm": 0.0, "total": 0.0} for m in months}
    for row in results:
        data[months[int(row.month) - 1]] = {
            "avg_rpm": round(float(row.avg_rpm or 0), 4),
            "total": round(float(row.total or 0), 2),
        }
    return data
