# FinSense — Personal Finance OS

> Built for Indians. Track income, manage debt, plan taxes, and grow wealth — all in one place.

## Quick Start

```bash
# 1. Setup (first time only)
chmod +x setup.sh run.sh
./setup.sh

# 2. Run
./run.sh
```

- Frontend: http://localhost:5173
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | React 18 + Vite, Tailwind CSS, Zustand, Recharts |
| Backend | FastAPI (Python), SQLAlchemy, Alembic |
| Database | PostgreSQL |
| Auth | JWT (HS256) |

## Features

### Dashboard
- Net Worth, Free Cash, Debt Score, Tax Due overview
- Income vs Expense 6-month chart
- Debt ratio forecast
- Quick add expense/income
- Recent activity feed

### Expenses
- Month navigator
- Category breakdown charts
- Subscription tracker
- Budget tracking

### Debt Manager
- Debt Danger Score (0-100)
- EMI tracking with progress bars
- Credit card utilization
- 6-month DTI forecast
- Skip EMI cost calculator

### Trading
- Trade log (Intraday, Delivery, F&O)
- P&L analytics + win rate
- Monthly P&L chart
- Tax summary (STCG/LTCG/Speculative/Business)

### Investments
- Portfolio tracking across 9 asset types
- Asset allocation donut chart
- XIRR calculation
- Gain/loss per holding

### Creator Hub
- AdSense, sponsorship, membership income tracking
- RPM trend chart
- Income growth chart
- Brand deal management

### Tax Planner
- New + Old regime comparison
- FY 2025-26 slab rates
- Deductions tracker (80C/80D/80CCD/24B)
- Advance tax calendar
- Tax saving suggestions
- PDF export

### Net Worth
- Real-time net worth calculation
- Monthly snapshot history
- 12-month forecast
- Asset & liability breakdown
- Milestone progress

### Friends Ledger
- Track who owes you and who you owe
- Settlement tracking
- Net position summary
- CSV export

### Simulator
- Live debt scenario modeler (income/EMI sliders)
- Debt danger score preview
- Skip EMI cost calculator
- 6-month debt ratio projection

## Project Structure

```
finsense/
├── backend/
│   ├── main.py              # FastAPI app
│   ├── database.py          # SQLAlchemy setup
│   ├── models/              # 15 database models
│   ├── routers/             # 13 API routers
│   ├── engines/             # Debt score, tax, forecast, PDF
│   ├── schemas/             # Pydantic v2 schemas
│   └── alembic/             # Migrations
└── frontend/
    └── src/
        ├── pages/           # 12 full pages
        ├── components/      # Sidebar, charts, modals
        ├── store/           # Zustand state
        └── api/             # Axios instance
```

## Environment Variables

Edit `backend/.env`:

```env
DATABASE_URL=postgresql://finsense_user:finsense_pass@localhost:5432/finsense_db
JWT_SECRET=your-very-long-secret-key-here
JWT_ALGORITHM=HS256
JWT_EXPIRE_HOURS=24
CORS_ORIGINS=http://localhost:5173
```

## Indian Tax Engine (FY 2025-26)

### New Regime Slabs
| Income | Rate |
|--------|------|
| 0 – 4L | 0% |
| 4 – 8L | 5% |
| 8 – 12L | 10% |
| 12 – 16L | 15% |
| 16 – 20L | 20% |
| 20 – 24L | 25% |
| > 24L | 30% |

### Old Regime Slabs
| Income | Rate |
|--------|------|
| 0 – 2.5L | 0% |
| 2.5 – 5L | 5% |
| 5 – 10L | 20% |
| > 10L | 30% |

## Debt Danger Score

Scoring formula (0-100, lower is safer):
- **DTI component** (max 60 pts): Debt-to-Income ratio
- **Savings rate** (max 15 pts): Saving < 5% of income
- **Emergency fund** (max 10 pts): < 3 months coverage
- **Credit card** (max 15 pts): Minimum due / income ratio

Verdict:
- **0-39**: Safe (teal)
- **40-69**: Caution (amber)
- **70-100**: Danger (red)
