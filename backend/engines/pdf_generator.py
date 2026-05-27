import io
from datetime import datetime
from typing import Dict, Any
from reportlab.lib.pagesizes import A4
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import cm
from reportlab.platypus import (
    SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, HRFlowable
)
from reportlab.lib.enums import TA_CENTER, TA_RIGHT, TA_LEFT


DARK_BG = colors.HexColor("#0D1117")
CARD_BG = colors.HexColor("#161B22")
TEAL = colors.HexColor("#00C9A7")
RED = colors.HexColor("#FF4757")
AMBER = colors.HexColor("#FFA502")
TEXT_PRIMARY = colors.HexColor("#F0F4F8")
TEXT_SECONDARY = colors.HexColor("#8B949E")
WHITE = colors.white
BLACK = colors.black


def _format_inr(amount: float) -> str:
    """Format amount in Indian number system."""
    if amount is None:
        return "₹0"
    try:
        amount = float(amount)
    except (TypeError, ValueError):
        return "₹0"
    is_negative = amount < 0
    amount = abs(amount)
    s = f"{amount:.2f}"
    integer_part, decimal_part = s.split(".")
    if len(integer_part) <= 3:
        result = integer_part
    else:
        result = integer_part[-3:]
        integer_part = integer_part[:-3]
        while len(integer_part) > 2:
            result = integer_part[-2:] + "," + result
            integer_part = integer_part[:-2]
        if integer_part:
            result = integer_part + "," + result
    formatted = f"₹{result}.{decimal_part}"
    return f"-{formatted}" if is_negative else formatted


def _get_styles():
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle(
        "CustomTitle",
        parent=styles["Title"],
        fontSize=22,
        textColor=WHITE,
        backColor=DARK_BG,
        alignment=TA_CENTER,
        spaceAfter=12,
    )
    heading_style = ParagraphStyle(
        "CustomHeading",
        parent=styles["Heading2"],
        fontSize=14,
        textColor=TEAL,
        spaceAfter=8,
        spaceBefore=16,
    )
    body_style = ParagraphStyle(
        "CustomBody",
        parent=styles["Normal"],
        fontSize=10,
        textColor=BLACK,
        spaceAfter=4,
    )
    return title_style, heading_style, body_style


def generate_monthly_report(data_dict: Dict[str, Any]) -> bytes:
    """Generate monthly financial report as PDF bytes."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    title_style, heading_style, body_style = _get_styles()
    elements = []

    month_label = data_dict.get("month_label", datetime.now().strftime("%B %Y"))
    user_name = data_dict.get("user_name", "User")

    elements.append(Paragraph(f"FinSense Monthly Report", title_style))
    elements.append(Paragraph(f"{month_label} | {user_name}", body_style))
    elements.append(HRFlowable(width="100%", thickness=1, color=TEAL, spaceAfter=12))
    elements.append(Spacer(1, 0.5 * cm))

    # Income Summary
    elements.append(Paragraph("Income Summary", heading_style))
    income_data = [["Source", "Amount"]]
    income_streams = data_dict.get("income_streams", [])
    total_income = 0
    for stream in income_streams:
        amt = float(stream.get("total", 0))
        total_income += amt
        income_data.append([stream.get("source_type", "Other").replace("_", " ").title(), _format_inr(amt)])
    income_data.append(["TOTAL", _format_inr(total_income)])

    income_table = Table(income_data, colWidths=[10 * cm, 6 * cm])
    income_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), TEAL),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("FONTSIZE", (0, 0), (-1, 0), 11),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, colors.HexColor("#F5F5F5")]),
        ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E0E0E0")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ALIGN", (1, 0), (1, -1), "RIGHT"),
        ("PADDING", (0, 0), (-1, -1), 6),
    ]))
    elements.append(income_table)
    elements.append(Spacer(1, 0.5 * cm))

    # Expense Breakdown
    elements.append(Paragraph("Expense Breakdown", heading_style))
    expense_data = [["Category", "Amount", "% of Income"]]
    expense_summary = data_dict.get("expense_summary", [])
    total_expenses = 0
    for cat in expense_summary:
        amt = float(cat.get("total", 0))
        total_expenses += amt
        pct = (amt / total_income * 100) if total_income > 0 else 0
        expense_data.append([
            cat.get("category", "other").replace("_", " ").title(),
            _format_inr(amt),
            f"{pct:.1f}%",
        ])
    expense_data.append(["TOTAL", _format_inr(total_expenses), ""])

    expense_table = Table(expense_data, colWidths=[8 * cm, 5 * cm, 3 * cm])
    expense_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), RED),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, colors.HexColor("#F5F5F5")]),
        ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E0E0E0")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"),
        ("PADDING", (0, 0), (-1, -1), 6),
    ]))
    elements.append(expense_table)
    elements.append(Spacer(1, 0.5 * cm))

    # EMI / Loans
    elements.append(Paragraph("Active EMIs", heading_style))
    emi_data = [["Loan", "Bank", "EMI Amount", "Rate"]]
    loans = data_dict.get("loans", [])
    total_emi = 0
    for loan in loans:
        if loan.get("is_active"):
            emi = float(loan.get("emi_amount", 0))
            total_emi += emi
            emi_data.append([
                loan.get("loan_name", ""),
                loan.get("bank_name", ""),
                _format_inr(emi),
                f"{loan.get('interest_rate', 0)}%",
            ])
    emi_data.append(["TOTAL EMI", "", _format_inr(total_emi), ""])

    emi_table = Table(emi_data, colWidths=[6 * cm, 4 * cm, 4 * cm, 2 * cm])
    emi_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), AMBER),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, colors.HexColor("#F5F5F5")]),
        ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E0E0E0")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ALIGN", (2, 0), (2, -1), "RIGHT"),
        ("PADDING", (0, 0), (-1, -1), 6),
    ]))
    elements.append(emi_table)
    elements.append(Spacer(1, 0.5 * cm))

    # Net Worth & Summary
    elements.append(Paragraph("Financial Summary", heading_style))
    net_worth = float(data_dict.get("net_worth", 0))
    savings = total_income - total_expenses - total_emi
    savings_rate = (savings / total_income * 100) if total_income > 0 else 0

    summary_data = [
        ["Metric", "Value"],
        ["Total Income", _format_inr(total_income)],
        ["Total Expenses", _format_inr(total_expenses)],
        ["Total EMIs", _format_inr(total_emi)],
        ["Net Savings", _format_inr(savings)],
        ["Savings Rate", f"{savings_rate:.1f}%"],
        ["Net Worth", _format_inr(net_worth)],
    ]
    summary_table = Table(summary_data, colWidths=[10 * cm, 6 * cm])
    summary_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#333333")),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F5F5")]),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ALIGN", (1, 0), (1, -1), "RIGHT"),
        ("PADDING", (0, 0), (-1, -1), 6),
    ]))
    elements.append(summary_table)

    elements.append(Spacer(1, 1 * cm))
    elements.append(HRFlowable(width="100%", thickness=1, color=TEXT_SECONDARY))
    elements.append(Paragraph(
        f"Generated by FinSense on {datetime.now().strftime('%d %B %Y at %H:%M')}",
        body_style
    ))

    doc.build(elements)
    buffer.seek(0)
    return buffer.read()


def generate_tax_summary(data_dict: Dict[str, Any]) -> bytes:
    """Generate tax summary report as PDF bytes."""
    buffer = io.BytesIO()
    doc = SimpleDocTemplate(
        buffer,
        pagesize=A4,
        leftMargin=2 * cm,
        rightMargin=2 * cm,
        topMargin=2 * cm,
        bottomMargin=2 * cm,
    )

    title_style, heading_style, body_style = _get_styles()
    elements = []

    fy = data_dict.get("financial_year", "2025-26")
    user_name = data_dict.get("user_name", "User")
    regime = data_dict.get("regime", "new").upper()

    elements.append(Paragraph(f"FinSense Tax Summary", title_style))
    elements.append(Paragraph(f"FY {fy} | {user_name} | {regime} Regime", body_style))
    elements.append(HRFlowable(width="100%", thickness=1, color=TEAL, spaceAfter=12))
    elements.append(Spacer(1, 0.5 * cm))

    # Income by Head
    elements.append(Paragraph("Income by Head", heading_style))
    tax_data = data_dict.get("tax_data", {})
    income_heads = [
        ["Income Head", "Gross Amount", "Tax Rate", "Tax Amount"],
        ["Salary Income", _format_inr(tax_data.get("salary_income", 0)), "Slab Rate", _format_inr(tax_data.get("salary_tax", 0))],
        ["Business Income", _format_inr(tax_data.get("business_income", 0)), "Slab Rate", _format_inr(tax_data.get("business_tax", 0))],
        ["STCG (Equity)", _format_inr(tax_data.get("capital_gains", 0) * 0.5), "15%", _format_inr(tax_data.get("stcg_tax", 0))],
        ["LTCG (Equity)", _format_inr(tax_data.get("capital_gains", 0) * 0.5), "10% above 1L", _format_inr(tax_data.get("ltcg_tax", 0))],
        ["TOTAL TAX", "", "", _format_inr(tax_data.get("total_tax", 0))],
    ]
    income_table = Table(income_heads, colWidths=[5 * cm, 4 * cm, 4 * cm, 3 * cm])
    income_table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), RED),
        ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
        ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
        ("ROWBACKGROUNDS", (0, 1), (-1, -2), [colors.white, colors.HexColor("#F5F5F5")]),
        ("BACKGROUND", (0, -1), (-1, -1), colors.HexColor("#E0E0E0")),
        ("FONTNAME", (0, -1), (-1, -1), "Helvetica-Bold"),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
        ("ALIGN", (1, 0), (-1, -1), "RIGHT"),
        ("PADDING", (0, 0), (-1, -1), 6),
    ]))
    elements.append(income_table)
    elements.append(Spacer(1, 0.5 * cm))

    # Deductions
    elements.append(Paragraph("Deductions Claimed", heading_style))
    deductions = data_dict.get("deductions", [])
    if deductions:
        ded_data = [["Section", "Description", "Amount"]]
        for d in deductions:
            ded_data.append([d.get("section", ""), d.get("description", ""), _format_inr(d.get("amount", 0))])
        ded_table = Table(ded_data, colWidths=[3 * cm, 9 * cm, 4 * cm])
        ded_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), TEAL),
            ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F5F5")]),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
            ("ALIGN", (2, 0), (2, -1), "RIGHT"),
            ("PADDING", (0, 0), (-1, -1), 6),
        ]))
        elements.append(ded_table)
    else:
        elements.append(Paragraph("No deductions recorded.", body_style))
    elements.append(Spacer(1, 0.5 * cm))

    # Advance Tax
    elements.append(Paragraph("Advance Tax Payments", heading_style))
    advance_payments = data_dict.get("advance_payments", [])
    if advance_payments:
        adv_data = [["Installment", "Due Date", "Amount Due", "Amount Paid", "Status"]]
        for p in advance_payments:
            status = "PAID" if p.get("is_paid") else "PENDING"
            adv_data.append([
                f"#{p.get('installment', '')}",
                str(p.get("due_date", "")),
                _format_inr(p.get("amount_due", 0)),
                _format_inr(p.get("amount_paid", 0)),
                status,
            ])
        adv_table = Table(adv_data, colWidths=[3 * cm, 4 * cm, 4 * cm, 4 * cm, 2 * cm])
        adv_table.setStyle(TableStyle([
            ("BACKGROUND", (0, 0), (-1, 0), AMBER),
            ("TEXTCOLOR", (0, 0), (-1, 0), WHITE),
            ("FONTNAME", (0, 0), (-1, 0), "Helvetica-Bold"),
            ("ROWBACKGROUNDS", (0, 1), (-1, -1), [colors.white, colors.HexColor("#F5F5F5")]),
            ("GRID", (0, 0), (-1, -1), 0.5, colors.HexColor("#CCCCCC")),
            ("ALIGN", (2, 0), (-1, -1), "RIGHT"),
            ("PADDING", (0, 0), (-1, -1), 6),
        ]))
        elements.append(adv_table)
    else:
        elements.append(Paragraph("No advance tax payments recorded.", body_style))

    elements.append(Spacer(1, 1 * cm))
    elements.append(HRFlowable(width="100%", thickness=1, color=TEXT_SECONDARY))
    elements.append(Paragraph(
        f"Generated by FinSense on {datetime.now().strftime('%d %B %Y at %H:%M')}",
        body_style
    ))

    doc.build(elements)
    buffer.seek(0)
    return buffer.read()
