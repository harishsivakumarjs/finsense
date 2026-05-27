import os
from datetime import datetime
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from apscheduler.schedulers.background import BackgroundScheduler

load_dotenv()

from database import SessionLocal
from routers import auth, dashboard, income, expenses, loans, trades, investments, creator, tax, networth, friends, simulator, reports
from routers import insurance

app = FastAPI(
    title="FinSense API",
    description="Personal Finance Management API",
    version="1.0.0",
)

CORS_ORIGINS = os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include all routers
app.include_router(auth.router)
app.include_router(dashboard.router)
app.include_router(income.router)
app.include_router(expenses.router)
app.include_router(loans.router)
app.include_router(trades.router)
app.include_router(investments.router)
app.include_router(creator.router)
app.include_router(tax.router)
app.include_router(networth.router)
app.include_router(friends.router)
app.include_router(simulator.router)
app.include_router(reports.router)
app.include_router(insurance.router)


def take_monthly_snapshot():
    """APScheduler job: take net worth snapshot on the 1st of each month."""
    from models import User, Loan, CreditCard, Investment, NetWorthSnapshot, IncomeEntry, Expense
    from sqlalchemy import func, extract
    from engines.debt_score import calculate_debt_score
    from datetime import date

    db = SessionLocal()
    try:
        today = date.today()
        users = db.query(User).all()
        for user in users:
            total_investments = db.query(func.sum(Investment.current_value)).filter(
                Investment.user_id == user.id
            ).scalar() or 0

            loans = db.query(Loan).filter(Loan.user_id == user.id, Loan.is_active == True).all()
            loan_outstanding = 0
            for loan in loans:
                months_elapsed = (today.year - loan.start_date.year) * 12 + (today.month - loan.start_date.month)
                remaining_months = max(loan.months_total - months_elapsed, 0)
                r = float(loan.interest_rate) / 100 / 12
                emi = float(loan.emi_amount)
                if r > 0 and remaining_months > 0:
                    outstanding = emi * (1 - (1 + r) ** (-remaining_months)) / r
                else:
                    outstanding = emi * remaining_months
                loan_outstanding += outstanding

            cc_outstanding = db.query(func.sum(CreditCard.outstanding)).filter(
                CreditCard.user_id == user.id
            ).scalar() or 0

            total_assets = float(total_investments)
            total_liabilities = loan_outstanding + float(cc_outstanding)
            net_worth = total_assets - total_liabilities

            monthly_income = db.query(func.sum(IncomeEntry.amount)).filter(
                IncomeEntry.user_id == user.id,
                extract("month", IncomeEntry.received_on) == today.month,
                extract("year", IncomeEntry.received_on) == today.year,
            ).scalar() or 1

            total_emi = sum(float(l.emi_amount) for l in loans)
            cards = db.query(CreditCard).filter(CreditCard.user_id == user.id).all()
            cc_min = sum(float(c.minimum_due) for c in cards)
            savings = max(float(monthly_income) - total_emi - cc_min, 0)
            score = calculate_debt_score(float(monthly_income), total_emi, cc_min, savings, float(monthly_income) * 3)

            snapshot = NetWorthSnapshot(
                user_id=user.id,
                snapshot_date=today,
                total_assets=total_assets,
                total_liabilities=total_liabilities,
                net_worth=net_worth,
                debt_score=score,
            )
            db.add(snapshot)
        db.commit()
    except Exception as e:
        print(f"Snapshot error: {e}")
        db.rollback()
    finally:
        db.close()


scheduler = BackgroundScheduler()
scheduler.add_job(
    take_monthly_snapshot,
    trigger="cron",
    day=1,
    hour=2,
    minute=0,
    id="monthly_snapshot",
)


@app.on_event("startup")
def startup_event():
    scheduler.start()
    print("FinSense API started. Scheduler running.")


@app.on_event("shutdown")
def shutdown_event():
    scheduler.shutdown()


@app.get("/")
def root():
    return {"message": "FinSense API v1.0", "status": "running", "docs": "/docs"}


@app.get("/health")
def health():
    return {"status": "healthy", "timestamp": datetime.utcnow().isoformat()}
