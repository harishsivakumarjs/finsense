from .debt_score import calculate_debt_score, get_score_verdict
from .tax_engine import (
    calculate_salary_tax,
    calculate_stcg_tax,
    calculate_ltcg_tax,
    calculate_speculative_income_tax,
    calculate_business_income_tax,
    calculate_gold_tax,
    calculate_fd_interest_tax,
    calculate_total_tax_liability,
    calculate_advance_tax_installments,
    get_deduction_limits,
    get_tax_saving_suggestions,
)
from .forecast import (
    forecast_debt_ratio,
    forecast_net_worth,
    forecast_creator_income,
    calculate_xirr,
    calculate_fi_ratio,
    calculate_debt_free_date,
)
