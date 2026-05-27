from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from database import get_db
from models import User
from routers.auth import get_current_user
from engines.debt_score import calculate_debt_score, get_score_verdict
from engines.forecast import forecast_debt_ratio

router = APIRouter(prefix="/api/simulator", tags=["simulator"])


@router.post("/scenario")
def run_scenario(
    payload: dict,
    current_user: User = Depends(get_current_user),
):
    income = float(payload.get("income", 0))
    emi = float(payload.get("emi", 0))
    expenses = float(payload.get("expenses", 0))
    savings = float(payload.get("savings", 0))
    emergency_fund = float(payload.get("emergency_fund", 0))

    if income == 0:
        return {
            "dti": 0, "free_cash": 0, "debt_score": 0,
            "verdict": {"level": "safe", "color": "teal", "message": "Enter income to see results."},
            "months_to_debtfree": None,
            "savings_rate": 0,
        }

    dti = ((emi) / income * 100) if income > 0 else 0
    free_cash = income - emi - expenses
    savings_rate = (savings / income * 100) if income > 0 else 0

    debt_score = calculate_debt_score(income, emi, 0, savings, emergency_fund)
    verdict = get_score_verdict(debt_score)

    # Simple months to debt free based on current scenario
    if emi > 0:
        months_to_debtfree = int(emergency_fund / emi) if emi > 0 else None
    else:
        months_to_debtfree = 0

    # Generate mock forecast for the scenario
    mock_loans = [{"is_active": True, "start_date": None, "months_total": 60, "emi_amount": emi}]
    if emi > 0:
        from datetime import date
        mock_loans[0]["start_date"] = date.today()

    return {
        "dti": round(dti, 2),
        "free_cash": round(free_cash, 2),
        "debt_score": debt_score,
        "verdict": verdict,
        "months_to_debtfree": months_to_debtfree,
        "savings_rate": round(savings_rate, 2),
        "forecast": [
            {"month": f"M+{i+1}", "dti": round(max(dti - (dti / 60) * i, 0), 2)}
            for i in range(6)
        ],
    }


@router.post("/skipemi")
def calculate_skip_emi(
    payload: dict,
    current_user: User = Depends(get_current_user),
):
    emi_amount = float(payload.get("emi_amount", 0))
    interest_rate = float(payload.get("interest_rate", 10))

    monthly_rate = interest_rate / 100 / 12

    # Standard penalty for skipping EMI
    penalty = emi_amount * 0.02
    extra_interest = emi_amount * monthly_rate
    compounding_cost = emi_amount * monthly_rate * 1.5
    total_cost = penalty + extra_interest + compounding_cost

    cibil_impact = -50 if emi_amount > 0 else 0
    cibil_message = "Skipping even 1 EMI can drop your CIBIL score by 50-100 points"

    return {
        "penalty": round(penalty, 2),
        "extra_interest": round(extra_interest, 2),
        "compounding_cost": round(compounding_cost, 2),
        "cibil_impact": cibil_impact,
        "cibil_message": cibil_message,
        "total_cost": round(total_cost, 2),
        "recommendation": "Contact your bank for moratorium or restructuring options instead of skipping.",
        "alternatives": [
            "Request EMI holiday from bank (3-6 months usually available)",
            "Part-prepayment to reduce EMI burden",
            "Debt consolidation at lower interest rate",
        ],
    }
