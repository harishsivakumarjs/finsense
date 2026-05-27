from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import get_db
from models import Investment, User
from schemas.investment import InvestmentCreate, InvestmentUpdate, InvestmentOut
from routers.auth import get_current_user
from engines.forecast import calculate_xirr

router = APIRouter(prefix="/api/investments", tags=["investments"])


@router.get("", response_model=List[InvestmentOut])
def list_investments(
    asset_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Investment).filter(Investment.user_id == current_user.id)
    if asset_type:
        query = query.filter(Investment.asset_type == asset_type)
    return query.order_by(Investment.created_at.desc()).all()


@router.post("", response_model=InvestmentOut, status_code=201)
def create_investment(
    payload: InvestmentCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    inv = Investment(**payload.model_dump(), user_id=current_user.id)
    db.add(inv)
    db.commit()
    db.refresh(inv)
    return inv


@router.put("/{inv_id}", response_model=InvestmentOut)
def update_investment(
    inv_id: str,
    payload: InvestmentUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    inv = db.query(Investment).filter(Investment.id == inv_id, Investment.user_id == current_user.id).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Investment not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(inv, field, value)
    db.commit()
    db.refresh(inv)
    return inv


@router.put("/{inv_id}/value")
def update_investment_value(
    inv_id: str,
    payload: dict,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    inv = db.query(Investment).filter(Investment.id == inv_id, Investment.user_id == current_user.id).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Investment not found")
    inv.current_value = payload.get("current_value", inv.current_value)
    db.commit()
    db.refresh(inv)
    return InvestmentOut.model_validate(inv)


@router.delete("/{inv_id}", status_code=204)
def delete_investment(
    inv_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    inv = db.query(Investment).filter(Investment.id == inv_id, Investment.user_id == current_user.id).first()
    if not inv:
        raise HTTPException(status_code=404, detail="Investment not found")
    db.delete(inv)
    db.commit()


@router.get("/allocation")
def investment_allocation(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    results = db.query(
        Investment.asset_type,
        func.sum(Investment.current_value).label("total_value"),
    ).filter(Investment.user_id == current_user.id).group_by(Investment.asset_type).all()

    total = sum(float(r.total_value or 0) for r in results)
    if total == 0:
        return []

    return [
        {
            "asset_type": r.asset_type,
            "total_value": float(r.total_value or 0),
            "percentage": round(float(r.total_value or 0) / total * 100, 2),
        }
        for r in results
    ]


@router.get("/xirr")
def investment_xirr(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    investments = db.query(Investment).filter(Investment.user_id == current_user.id).all()
    if not investments:
        return {"xirr": None, "message": "No investments found"}

    dates = []
    cashflows = []
    for inv in investments:
        dates.append(inv.purchase_date)
        cashflows.append(-float(inv.invested_amount))

    today = date.today()
    dates.append(today)
    cashflows.append(sum(float(inv.current_value) for inv in investments))

    xirr_value = calculate_xirr(dates, cashflows)
    return {"xirr": xirr_value, "unit": "%"}
