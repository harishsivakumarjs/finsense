from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import get_db
from models import FriendLedger, User
from schemas.friend import FriendLedgerCreate, FriendLedgerUpdate, FriendLedgerOut
from routers.auth import get_current_user

router = APIRouter(prefix="/api/friends", tags=["friends"])


@router.get("", response_model=List[FriendLedgerOut])
def list_friends(
    settled: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(FriendLedger).filter(FriendLedger.user_id == current_user.id)
    if settled is not None:
        query = query.filter(FriendLedger.is_settled == settled)
    return query.order_by(FriendLedger.date.desc()).all()


@router.post("", response_model=FriendLedgerOut, status_code=201)
def create_friend_entry(
    payload: FriendLedgerCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = FriendLedger(**payload.model_dump(), user_id=current_user.id)
    db.add(entry)
    db.commit()
    db.refresh(entry)
    return entry


@router.put("/{entry_id}", response_model=FriendLedgerOut)
def update_friend_entry(
    entry_id: str,
    payload: FriendLedgerUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(FriendLedger).filter(
        FriendLedger.id == entry_id, FriendLedger.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(entry, field, value)
    db.commit()
    db.refresh(entry)
    return entry


@router.put("/{entry_id}/settle", response_model=FriendLedgerOut)
def settle_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(FriendLedger).filter(
        FriendLedger.id == entry_id, FriendLedger.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    entry.is_settled = True
    entry.settled_on = date.today()
    db.commit()
    db.refresh(entry)
    return entry


@router.delete("/{entry_id}", status_code=204)
def delete_friend_entry(
    entry_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entry = db.query(FriendLedger).filter(
        FriendLedger.id == entry_id, FriendLedger.user_id == current_user.id
    ).first()
    if not entry:
        raise HTTPException(status_code=404, detail="Entry not found")
    db.delete(entry)
    db.commit()


@router.get("/summary")
def friends_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    entries = db.query(FriendLedger).filter(
        FriendLedger.user_id == current_user.id,
        FriendLedger.is_settled == False,
    ).all()

    receivable = sum(float(e.amount) for e in entries if float(e.amount) > 0)
    payable = abs(sum(float(e.amount) for e in entries if float(e.amount) < 0))
    net = receivable - payable

    receivable_friends = len(set(e.friend_name for e in entries if float(e.amount) > 0))
    payable_friends = len(set(e.friend_name for e in entries if float(e.amount) < 0))

    return {
        "total_receivable": round(receivable, 2),
        "total_payable": round(payable, 2),
        "net": round(net, 2),
        "receivable_friends_count": receivable_friends,
        "payable_friends_count": payable_friends,
    }
