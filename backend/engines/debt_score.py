def calculate_debt_score(income, total_emi, cc_min, savings, emergency_fund):
    if income == 0:
        return 0
    total_debt_payment = total_emi + cc_min
    dti = total_debt_payment / income
    score = 0
    # DTI component (max 60 points)
    if dti >= 0.7:
        score += 60
    elif dti >= 0.5:
        score += 45
    elif dti >= 0.4:
        score += 30
    elif dti >= 0.3:
        score += 15
    else:
        score += dti * 50
    # Savings rate (max 15 points)
    savings_rate = savings / income
    if savings_rate < 0.05:
        score += 15
    elif savings_rate < 0.1:
        score += 10
    elif savings_rate < 0.2:
        score += 5
    # Emergency fund (max 10 points)
    months_covered = emergency_fund / income if income > 0 else 0
    if months_covered < 1:
        score += 10
    elif months_covered < 3:
        score += 5
    # Credit card (max 15 points)
    if cc_min > 0:
        cc_ratio = cc_min / income
        score += min(cc_ratio * 30, 15)
    return min(round(score), 100)


def get_score_verdict(score):
    if score < 40:
        return {"level": "safe", "color": "teal", "message": "Safe zone — your debt is well managed."}
    elif score < 70:
        return {"level": "caution", "color": "amber", "message": "Caution — one income dip could create pressure."}
    else:
        return {"level": "danger", "color": "red", "message": "Danger — EMIs are consuming too much income."}
