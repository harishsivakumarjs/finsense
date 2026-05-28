from datetime import date
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func, extract

from database import get_db
from models import Trade, User
from schemas.trade import TradeCreate, TradeUpdate, TradeOut
from routers.auth import get_current_user

router = APIRouter(prefix="/api/trades", tags=["trades"])


@router.get("", response_model=List[TradeOut])
def list_trades(
    month: Optional[int] = None,
    year: Optional[int] = None,
    trade_type: Optional[str] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    query = db.query(Trade).filter(Trade.user_id == current_user.id)
    if month:
        query = query.filter(extract("month", Trade.buy_date) == month)
    if year:
        query = query.filter(extract("year", Trade.buy_date) == year)
    if trade_type:
        query = query.filter(Trade.trade_type == trade_type)
    return query.order_by(Trade.buy_date.desc()).all()


@router.post("", response_model=TradeOut, status_code=201)
def create_trade(
    payload: TradeCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    data = payload.model_dump()
    if data.get("sell_price") and data.get("buy_price"):
        gross_pnl = (float(data["sell_price"]) - float(data["buy_price"])) * data["quantity"]
        data["net_pnl"] = gross_pnl - float(data.get("charges", 0))

        buy_dt = data.get("buy_date")
        sell_dt = data.get("sell_date")
        if buy_dt and sell_dt:
            holding_days = (sell_dt - buy_dt).days
            if data.get("trade_type") == "intraday":
                data["tax_type"] = "speculative"
            elif data.get("trade_type") == "delivery":
                data["tax_type"] = "ltcg" if holding_days > 365 else "stcg"
            elif data.get("trade_type") in ("futures", "options"):
                data["tax_type"] = "business"

    trade = Trade(**data, user_id=current_user.id)
    db.add(trade)
    db.commit()
    db.refresh(trade)
    return trade


@router.put("/{trade_id}", response_model=TradeOut)
def update_trade(
    trade_id: str,
    payload: TradeUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    trade = db.query(Trade).filter(Trade.id == trade_id, Trade.user_id == current_user.id).first()
    if not trade:
        raise HTTPException(status_code=404, detail="Trade not found")
    for field, value in payload.model_dump(exclude_unset=True).items():
        setattr(trade, field, value)
    db.commit()
    db.refresh(trade)
    return trade


@router.delete("/{trade_id}", status_code=204)
def delete_trade(
    trade_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    trade = db.query(Trade).filter(Trade.id == trade_id, Trade.user_id == current_user.id).first()
    if not trade:
        raise HTTPException(status_code=404, detail="Trade not found")
    db.delete(trade)
    db.commit()


@router.get("/pnl")
def trade_pnl(
    month: Optional[int] = None,
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year

    query = db.query(
        extract("month", Trade.sell_date).label("month"),
        func.sum(Trade.net_pnl).label("total_pnl"),
        func.count(Trade.id).label("trade_count"),
    ).filter(
        Trade.user_id == current_user.id,
        Trade.sell_date.isnot(None),
        Trade.net_pnl.isnot(None),
        extract("year", Trade.sell_date) == year,
    )
    if month:
        query = query.filter(extract("month", Trade.sell_date) == month)

    results = query.group_by(extract("month", Trade.sell_date)).all()
    months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    data = {m: {"pnl": 0.0, "count": 0} for m in months}
    for row in results:
        data[months[int(row.month) - 1]] = {"pnl": float(row.total_pnl or 0), "count": int(row.trade_count or 0)}
    return data


@router.get("/analytics")
def trade_analytics(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    trades = db.query(Trade).filter(
        Trade.user_id == current_user.id,
        Trade.net_pnl.isnot(None),
    ).all()

    if not trades:
        return {
            "total_trades": 0, "winning_trades": 0, "losing_trades": 0,
            "win_rate": 0, "total_pnl": 0,
            "avg_win": 0, "avg_loss": 0, "best_trade": 0, "worst_trade": 0,
            "profit_factor": 0,
            "by_type": {},
        }

    pnls = [float(t.net_pnl) for t in trades]
    wins = [p for p in pnls if p > 0]
    losses = [p for p in pnls if p < 0]

    by_type: dict = {}
    for t in trades:
        tt = t.trade_type or "other"
        if tt not in by_type:
            by_type[tt] = {"pnl": 0.0, "count": 0}
        by_type[tt]["pnl"] += float(t.net_pnl)
        by_type[tt]["count"] += 1

    gross_wins = sum(wins)
    gross_losses = abs(sum(losses))
    profit_factor = round(gross_wins / gross_losses, 2) if gross_losses > 0 else (999.0 if gross_wins > 0 else 0.0)

    return {
        "total_trades": len(trades),
        "winning_trades": len(wins),
        "losing_trades": len(losses),
        "win_rate": round(len(wins) / len(trades) * 100, 2) if trades else 0,
        "total_pnl": round(sum(pnls), 2),
        "avg_win": round(sum(wins) / len(wins), 2) if wins else 0,
        "avg_loss": round(sum(losses) / len(losses), 2) if losses else 0,
        "best_trade": round(max(pnls), 2) if pnls else 0,
        "worst_trade": round(min(pnls), 2) if pnls else 0,
        "profit_factor": profit_factor,
        "by_type": by_type,
    }


@router.get("/taxsummary")
def trade_tax_summary(
    year: Optional[int] = None,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if year is None:
        year = date.today().year

    trades = db.query(Trade).filter(
        Trade.user_id == current_user.id,
        Trade.net_pnl.isnot(None),
        Trade.sell_date.isnot(None),
        extract("year", Trade.sell_date) == year,
    ).all()

    summary = {"stcg": 0.0, "ltcg": 0.0, "speculative": 0.0, "business": 0.0}
    for t in trades:
        tax_type = t.tax_type or "stcg"
        if tax_type in summary:
            summary[tax_type] += float(t.net_pnl)

    from engines.tax_engine import calculate_stcg_tax, calculate_ltcg_tax
    return {
        "stcg_income": round(summary["stcg"], 2),
        "stcg_tax": calculate_stcg_tax(max(summary["stcg"], 0)),
        "ltcg_income": round(summary["ltcg"], 2),
        "ltcg_tax": calculate_ltcg_tax(max(summary["ltcg"], 0)),
        "speculative_income": round(summary["speculative"], 2),
        "business_income": round(summary["business"], 2),
        "net_pnl": round(sum(summary.values()), 2),
    }
