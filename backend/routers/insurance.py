from datetime import date
from typing import List
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session

from database import get_db
from models import User
from models.insurance import InsurancePolicy
from schemas.insurance import InsurancePolicyCreate, InsurancePolicyUpdate, InsurancePolicyOut
from routers.auth import get_current_user

router = APIRouter(prefix="/api/insurance", tags=["insurance"])


@router.get("", response_model=List[InsurancePolicyOut])
def list_policies(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    return (
        db.query(InsurancePolicy)
        .filter(InsurancePolicy.user_id == current_user.id)
        .order_by(InsurancePolicy.next_due_date.asc())
        .all()
    )


@router.post("", response_model=InsurancePolicyOut, status_code=201)
def create_policy(
    payload: InsurancePolicyCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    policy = InsurancePolicy(**payload.model_dump(), user_id=current_user.id)
    db.add(policy)
    db.commit()
    db.refresh(policy)
    return policy


@router.put("/{policy_id}", response_model=InsurancePolicyOut)
def update_policy(
    policy_id: str,
    payload: InsurancePolicyUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    policy = db.query(InsurancePolicy).filter(
        InsurancePolicy.id == policy_id,
        InsurancePolicy.user_id == current_user.id,
    ).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(policy, field, value)
    db.commit()
    db.refresh(policy)
    return policy


@router.delete("/{policy_id}", status_code=204)
def delete_policy(
    policy_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    policy = db.query(InsurancePolicy).filter(
        InsurancePolicy.id == policy_id,
        InsurancePolicy.user_id == current_user.id,
    ).first()
    if not policy:
        raise HTTPException(status_code=404, detail="Policy not found")
    db.delete(policy)
    db.commit()


@router.get("/summary")
def insurance_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    policies = (
        db.query(InsurancePolicy)
        .filter(InsurancePolicy.user_id == current_user.id, InsurancePolicy.is_active == True)
        .all()
    )

    today = date.today()

    total_coverage = sum(float(p.sum_assured or 0) for p in policies)
    total_annual_premium = sum(float(p.annual_premium or 0) for p in policies)
    total_tax_benefit = sum(float(p.tax_benefit_amount or 0) for p in policies)
    active_count = len(policies)

    # Coverage by type
    coverage_by_type = {}
    for p in policies:
        ptype = p.policy_type
        if ptype not in coverage_by_type:
            coverage_by_type[ptype] = {"sum_assured": 0.0, "annual_premium": 0.0, "count": 0}
        coverage_by_type[ptype]["sum_assured"] += float(p.sum_assured or 0)
        coverage_by_type[ptype]["annual_premium"] += float(p.annual_premium or 0)
        coverage_by_type[ptype]["count"] += 1

    # Tax breakdown
    section_80c = sum(float(p.tax_benefit_amount or 0) for p in policies if p.tax_section == "80C")
    section_80d = sum(float(p.tax_benefit_amount or 0) for p in policies if p.tax_section == "80D")

    # Upcoming renewals (next 60 days)
    upcoming = []
    for p in policies:
        days_until = (p.next_due_date - today).days
        if 0 <= days_until <= 60:
            upcoming.append({
                "id": str(p.id),
                "policy_name": p.policy_name,
                "insurer_name": p.insurer_name,
                "policy_type": p.policy_type,
                "annual_premium": float(p.annual_premium),
                "next_due_date": p.next_due_date.isoformat(),
                "days_until": days_until,
            })

    return {
        "total_coverage": total_coverage,
        "total_annual_premium": total_annual_premium,
        "total_tax_benefit": total_tax_benefit,
        "active_count": active_count,
        "coverage_by_type": coverage_by_type,
        "section_80c": section_80c,
        "section_80d": section_80d,
        "upcoming_renewals": sorted(upcoming, key=lambda x: x["days_until"]),
    }
