from datetime import date
from typing import Dict, List, Any


NEW_REGIME_SLABS = [
    (400000, 0.00),
    (800000, 0.05),
    (1200000, 0.10),
    (1600000, 0.15),
    (2000000, 0.20),
    (2400000, 0.25),
    (float("inf"), 0.30),
]

OLD_REGIME_SLABS = [
    (250000, 0.00),
    (500000, 0.05),
    (1000000, 0.20),
    (float("inf"), 0.30),
]

SURCHARGE_RATES = [
    (5000000, 0.0),
    (10000000, 0.10),
    (20000000, 0.15),
    (50000000, 0.25),
    (float("inf"), 0.37),
]

CESS_RATE = 0.04


def _apply_slabs(taxable_income: float, slabs: list) -> float:
    tax = 0.0
    prev_limit = 0
    for limit, rate in slabs:
        if taxable_income <= prev_limit:
            break
        chunk = min(taxable_income, limit) - prev_limit
        tax += chunk * rate
        prev_limit = limit
    return tax


def _apply_surcharge(tax: float, income: float) -> float:
    surcharge_rate = 0.0
    for threshold, rate in SURCHARGE_RATES:
        if income <= threshold:
            break
        surcharge_rate = rate
    return tax + tax * surcharge_rate


def _apply_cess(tax: float) -> float:
    return tax * (1 + CESS_RATE)


def calculate_salary_tax(salary: float, regime: str = "new", deductions: Dict[str, float] = {}) -> Dict:
    taxable = salary
    if regime == "old":
        standard_deduction = 50000
        taxable -= standard_deduction
        for section, amount in deductions.items():
            limits = get_deduction_limits()
            limit = limits.get(section, 0)
            taxable -= min(amount, limit)
        taxable = max(taxable, 0)
        tax = _apply_slabs(taxable, OLD_REGIME_SLABS)
        # Rebate 87A for old regime
        if taxable <= 500000:
            tax = max(tax - 12500, 0)
    else:
        standard_deduction = 75000
        taxable -= standard_deduction
        taxable = max(taxable, 0)
        tax = _apply_slabs(taxable, NEW_REGIME_SLABS)
        # Rebate 87A for new regime
        if taxable <= 700000:
            tax = 0

    tax = _apply_surcharge(tax, taxable)
    tax = _apply_cess(tax)
    return {"taxable_income": round(taxable, 2), "tax": round(tax, 2), "regime": regime}


def calculate_stcg_tax(amount: float) -> float:
    """STCG taxed at flat 15%"""
    if amount <= 0:
        return 0.0
    tax = amount * 0.15
    tax = _apply_cess(tax)
    return round(tax, 2)


def calculate_ltcg_tax(amount: float) -> float:
    """LTCG taxed at 10% above 1,00,000 exemption"""
    if amount <= 0:
        return 0.0
    exemption = 100000
    taxable = max(amount - exemption, 0)
    tax = taxable * 0.10
    tax = _apply_cess(tax)
    return round(tax, 2)


def calculate_speculative_income_tax(amount: float, total_income: float, regime: str = "new") -> float:
    """Speculative income (intraday) taxed as per slab"""
    if amount <= 0:
        return 0.0
    slabs = NEW_REGIME_SLABS if regime == "new" else OLD_REGIME_SLABS
    tax_before = _apply_slabs(total_income - amount, slabs)
    tax_after = _apply_slabs(total_income, slabs)
    incremental_tax = max(tax_after - tax_before, 0)
    incremental_tax = _apply_cess(incremental_tax)
    return round(incremental_tax, 2)


def calculate_business_income_tax(amount: float, expenses: float, total_income: float, regime: str = "new") -> float:
    """Business/F&O income taxed at slab rate after deducting expenses"""
    net_business = max(amount - expenses, 0)
    if net_business <= 0:
        return 0.0
    slabs = NEW_REGIME_SLABS if regime == "new" else OLD_REGIME_SLABS
    tax_before = _apply_slabs(max(total_income - net_business, 0), slabs)
    tax_after = _apply_slabs(total_income, slabs)
    incremental_tax = max(tax_after - tax_before, 0)
    incremental_tax = _apply_cess(incremental_tax)
    return round(incremental_tax, 2)


def calculate_gold_tax(amount: float, holding_years: float) -> float:
    """Gold: <2 years = slab rate (assume 30%), >= 2 years = 20% with indexation"""
    if amount <= 0:
        return 0.0
    if holding_years < 2:
        tax = amount * 0.30
    else:
        indexation_benefit = amount * 0.15
        taxable = max(amount - indexation_benefit, 0)
        tax = taxable * 0.20
    tax = _apply_cess(tax)
    return round(tax, 2)


def calculate_fd_interest_tax(interest: float, total_income: float, regime: str = "new") -> float:
    """FD interest taxed at slab rate"""
    if interest <= 0:
        return 0.0
    slabs = NEW_REGIME_SLABS if regime == "new" else OLD_REGIME_SLABS
    tax_before = _apply_slabs(max(total_income - interest, 0), slabs)
    tax_after = _apply_slabs(total_income, slabs)
    incremental_tax = max(tax_after - tax_before, 0)
    incremental_tax = _apply_cess(incremental_tax)
    return round(incremental_tax, 2)


def calculate_total_tax_liability(
    income_entries: List[Dict], deductions: Dict[str, float], regime: str = "new"
) -> Dict:
    salary = sum(e.get("amount", 0) for e in income_entries if e.get("tax_category") == "salary")
    business = sum(e.get("amount", 0) for e in income_entries if e.get("tax_category") == "business")
    capital_gains = sum(e.get("amount", 0) for e in income_entries if e.get("tax_category") == "capital_gains")
    exempt = sum(e.get("amount", 0) for e in income_entries if e.get("tax_category") == "exempt")

    total_income = salary + business + capital_gains

    salary_tax_info = calculate_salary_tax(salary, regime, deductions)
    salary_tax = salary_tax_info["tax"]

    stcg_tax = calculate_stcg_tax(capital_gains * 0.5)
    ltcg_tax = calculate_ltcg_tax(capital_gains * 0.5)

    business_tax = calculate_business_income_tax(business, 0, total_income, regime)

    total_tax = salary_tax + stcg_tax + ltcg_tax + business_tax

    return {
        "total_income": round(total_income, 2),
        "salary_income": round(salary, 2),
        "business_income": round(business, 2),
        "capital_gains": round(capital_gains, 2),
        "exempt_income": round(exempt, 2),
        "salary_tax": round(salary_tax, 2),
        "stcg_tax": round(stcg_tax, 2),
        "ltcg_tax": round(ltcg_tax, 2),
        "business_tax": round(business_tax, 2),
        "total_tax": round(total_tax, 2),
        "regime": regime,
        "deductions_used": deductions,
    }


def calculate_advance_tax_installments(total_liability: float) -> List[Dict]:
    """Calculate 4 advance tax installments per Indian tax law"""
    current_year = date.today().year
    fy_start = current_year if date.today().month >= 4 else current_year - 1

    installments = [
        {
            "installment": 1,
            "percentage": 15,
            "due_date": date(fy_start, 6, 15),
            "cumulative_pct": 15,
            "amount_due": round(total_liability * 0.15, 2),
        },
        {
            "installment": 2,
            "percentage": 30,
            "due_date": date(fy_start, 9, 15),
            "cumulative_pct": 45,
            "amount_due": round(total_liability * 0.45, 2),
        },
        {
            "installment": 3,
            "percentage": 30,
            "due_date": date(fy_start, 12, 15),
            "cumulative_pct": 75,
            "amount_due": round(total_liability * 0.75, 2),
        },
        {
            "installment": 4,
            "percentage": 25,
            "due_date": date(fy_start + 1, 3, 15),
            "cumulative_pct": 100,
            "amount_due": round(total_liability, 2),
        },
    ]
    return installments


def get_deduction_limits() -> Dict[str, float]:
    return {
        "80C": 150000,
        "80D": 25000,
        "80CCD": 50000,
        "24B": 200000,
    }


def get_tax_saving_suggestions(remaining_80c: float, remaining_80d: float, total_income: float) -> List[Dict]:
    suggestions = []
    if remaining_80c > 0:
        suggestions.append({
            "section": "80C",
            "message": f"You can invest ₹{remaining_80c:,.0f} more in ELSS/PPF/NSC to maximize 80C deduction",
            "potential_saving": round(remaining_80c * 0.30, 2),
            "priority": "high" if remaining_80c > 50000 else "medium",
        })
    if remaining_80d > 0:
        suggestions.append({
            "section": "80D",
            "message": f"Buy health insurance to claim up to ₹{remaining_80d:,.0f} under 80D",
            "potential_saving": round(remaining_80d * 0.20, 2),
            "priority": "high",
        })
    if total_income > 700000:
        suggestions.append({
            "section": "NPS",
            "message": "Contribute ₹50,000 to NPS to get additional deduction under 80CCD(1B)",
            "potential_saving": round(50000 * 0.20, 2),
            "priority": "medium",
        })
    if total_income > 1000000:
        suggestions.append({
            "section": "HRA",
            "message": "Ensure HRA exemption is claimed if you are paying rent",
            "potential_saving": 0,
            "priority": "medium",
        })
    return suggestions
