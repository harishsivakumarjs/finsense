from datetime import date, timedelta
from typing import List, Dict, Optional, Tuple
import numpy as np


def forecast_debt_ratio(loans: List[Dict], income: float, months: int = 6) -> List[Dict]:
    """Forecast DTI ratio over N months as loans are paid down."""
    result = []
    today = date.today()

    for m in range(months):
        forecast_date = date(today.year + (today.month + m - 1) // 12,
                             (today.month + m - 1) % 12 + 1, 1)
        total_emi = 0.0
        for loan in loans:
            if not loan.get("is_active", True):
                continue
            start = loan.get("start_date")
            months_total = loan.get("months_total", 0)
            if isinstance(start, str):
                start = date.fromisoformat(start)
            if start is None:
                continue
            months_elapsed = (today.year - start.year) * 12 + (today.month - start.month) + m
            if months_elapsed < months_total:
                total_emi += float(loan.get("emi_amount", 0))

        dti = (total_emi / income * 100) if income > 0 else 0
        result.append({
            "month": forecast_date.strftime("%b %Y"),
            "dti": round(dti, 2),
            "total_emi": round(total_emi, 2),
        })
    return result


def forecast_net_worth(snapshots: List[Dict], monthly_savings: float, months: int = 12) -> List[Dict]:
    """Forecast net worth using linear trend from historical snapshots."""
    result = []
    today = date.today()

    if len(snapshots) >= 2:
        values = [float(s.get("net_worth", 0)) for s in snapshots[-6:]]
        n = len(values)
        x = np.arange(n)
        slope = np.polyfit(x, values, 1)[0]
        base_nw = values[-1]
    elif len(snapshots) == 1:
        base_nw = float(snapshots[0].get("net_worth", 0))
        slope = monthly_savings
    else:
        base_nw = 0
        slope = monthly_savings

    for m in range(1, months + 1):
        forecast_date = date(today.year + (today.month + m - 1) // 12,
                             (today.month + m - 1) % 12 + 1, 1)
        projected_nw = base_nw + slope * m
        result.append({
            "month": forecast_date.strftime("%b %Y"),
            "net_worth": round(projected_nw, 2),
            "market_avg": round(projected_nw * 1.08 / 12 + projected_nw, 2),
        })
    return result


def forecast_creator_income(monthly_totals: List[float], months: int = 6) -> List[Dict]:
    """Forecast creator income using linear regression."""
    result = []
    today = date.today()

    if len(monthly_totals) < 2:
        base = monthly_totals[-1] if monthly_totals else 0
        for m in range(1, months + 1):
            forecast_date = date(today.year + (today.month + m - 1) // 12,
                                 (today.month + m - 1) % 12 + 1, 1)
            result.append({
                "month": forecast_date.strftime("%b %Y"),
                "projected_income": round(base, 2),
            })
        return result

    x = np.arange(len(monthly_totals))
    y = np.array(monthly_totals, dtype=float)
    coeffs = np.polyfit(x, y, 1)
    slope, intercept = coeffs

    for m in range(1, months + 1):
        forecast_date = date(today.year + (today.month + m - 1) // 12,
                             (today.month + m - 1) % 12 + 1, 1)
        x_next = len(monthly_totals) + m - 1
        projected = slope * x_next + intercept
        result.append({
            "month": forecast_date.strftime("%b %Y"),
            "projected_income": round(max(projected, 0), 2),
        })
    return result


def calculate_xirr(dates: List[date], cashflows: List[float], max_iterations: int = 100) -> Optional[float]:
    """Calculate XIRR using Newton-Raphson method."""
    if len(dates) != len(cashflows):
        return None
    if not any(cf < 0 for cf in cashflows):
        return None

    base_date = dates[0]
    years = [(d - base_date).days / 365.0 for d in dates]

    def npv(rate):
        return sum(cf / ((1 + rate) ** t) for cf, t in zip(cashflows, years))

    def npv_deriv(rate):
        return sum(-t * cf / ((1 + rate) ** (t + 1)) for cf, t in zip(cashflows, years))

    rate = 0.1
    for _ in range(max_iterations):
        f = npv(rate)
        f_prime = npv_deriv(rate)
        if abs(f_prime) < 1e-10:
            break
        new_rate = rate - f / f_prime
        if abs(new_rate - rate) < 1e-6:
            return round(new_rate * 100, 2)
        rate = new_rate

    return round(rate * 100, 2)


def calculate_fi_ratio(passive_income: float, monthly_expenses: float) -> Dict:
    """Calculate Financial Independence ratio."""
    if monthly_expenses == 0:
        ratio = 100.0 if passive_income > 0 else 0.0
    else:
        ratio = (passive_income / monthly_expenses) * 100

    return {
        "fi_ratio": round(min(ratio, 100), 2),
        "is_fi": ratio >= 100,
        "monthly_expenses": round(monthly_expenses, 2),
        "passive_income": round(passive_income, 2),
        "gap": round(max(monthly_expenses - passive_income, 0), 2),
    }


def calculate_debt_free_date(loans: List[Dict]) -> Optional[str]:
    """Calculate when all active loans will be paid off."""
    latest_end = None

    for loan in loans:
        if not loan.get("is_active", True):
            continue
        start = loan.get("start_date")
        months_total = loan.get("months_total", 0)

        if isinstance(start, str):
            start = date.fromisoformat(start)
        if start is None:
            continue

        end_month = start.month + months_total - 1
        end_year = start.year + end_month // 12
        end_month = end_month % 12 + 1
        end_date = date(end_year, end_month, 1)

        if latest_end is None or end_date > latest_end:
            latest_end = end_date

    if latest_end is None:
        return None

    today = date.today()
    if latest_end <= today:
        return "Already debt free!"

    months_remaining = (latest_end.year - today.year) * 12 + (latest_end.month - today.month)
    return {
        "date": latest_end.isoformat(),
        "months_remaining": months_remaining,
        "formatted": latest_end.strftime("%B %Y"),
    }
