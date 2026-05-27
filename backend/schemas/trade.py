from pydantic import BaseModel
from typing import Optional
from datetime import date, datetime
import uuid
from decimal import Decimal


class TradeCreate(BaseModel):
    scrip: str
    trade_type: str
    buy_price: Decimal
    sell_price: Optional[Decimal] = None
    quantity: int
    buy_date: date
    sell_date: Optional[date] = None
    charges: Decimal = Decimal("0")
    net_pnl: Optional[Decimal] = None
    tax_type: Optional[str] = None
    notes: Optional[str] = None


class TradeUpdate(BaseModel):
    scrip: Optional[str] = None
    trade_type: Optional[str] = None
    buy_price: Optional[Decimal] = None
    sell_price: Optional[Decimal] = None
    quantity: Optional[int] = None
    buy_date: Optional[date] = None
    sell_date: Optional[date] = None
    charges: Optional[Decimal] = None
    net_pnl: Optional[Decimal] = None
    tax_type: Optional[str] = None
    notes: Optional[str] = None


class TradeOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    scrip: str
    trade_type: str
    buy_price: Decimal
    sell_price: Optional[Decimal]
    quantity: int
    buy_date: date
    sell_date: Optional[date]
    charges: Decimal
    net_pnl: Optional[Decimal]
    tax_type: Optional[str]
    notes: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}


class TradingLossCreate(BaseModel):
    financial_year: str
    loss_type: str
    original_loss: Decimal
    remaining_loss: Decimal
    expiry_year: Optional[str] = None


class TradingLossOut(BaseModel):
    id: uuid.UUID
    user_id: uuid.UUID
    financial_year: str
    loss_type: str
    original_loss: Decimal
    remaining_loss: Decimal
    expiry_year: Optional[str]
    created_at: datetime

    model_config = {"from_attributes": True}
