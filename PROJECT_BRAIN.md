# FinSense — Project Brain

> Paste this file at the start of any future Claude session to restore full context.
> Last updated: 2026-05-24 (Session 2)

---

## What This Is

FinSense is a solo personal finance operating system built for an Indian professional who trades stocks, invests in mutual funds/gold/silver/land, plans a YouTube channel, and needs complete tax visibility. Full-stack web app: FastAPI backend, PostgreSQL database, React 18 frontend. Not a prototype — every module has real CRUD, real calculations, and a working UI.

---

## How to Run

```bash
# Backend (MUST use port 8001 — NOT 8000, which is a different system process)
cd backend
source venv/bin/activate
uvicorn main:app --reload --port 8001

# Frontend
cd frontend
npm run dev
```

| Service     | URL                           |
|-------------|-------------------------------|
| Frontend    | http://localhost:5173         |
| Backend API | http://localhost:8001         |
| Swagger UI  | http://localhost:8001/docs    |

**Critical port note:** On this machine, a system-level uvicorn runs `app.main:app` from `/app/` on port 8000. That is a completely different application. FinSense must run on port 8001. The Vite proxy in `frontend/vite.config.js` points `/api` → `http://localhost:8001`.

**PostgreSQL port:** On this machine PostgreSQL 16 runs on port **5433** (not the standard 5432). `backend/.env` uses `localhost:5433`.

**Demo user:** `demo@finsense.app` — password is in `.env` or was set during setup.

---

## Repository Layout

```
finsense/
├── backend/
│   ├── main.py                          # FastAPI app + CORS + APScheduler snapshot job
│   ├── database.py                      # SQLAlchemy engine (port 5433), get_db()
│   ├── models/
│   │   ├── __init__.py                  # Exports all 16 model classes
│   │   ├── user.py                      # User (has insurance_policies relationship)
│   │   ├── income.py                    # IncomeEntry
│   │   ├── expense.py                   # Expense, Budget
│   │   ├── loan.py                      # Loan, CreditCard
│   │   ├── trade.py                     # Trade, TradingLossCarryforward
│   │   ├── investment.py                # Investment
│   │   ├── creator.py                   # CreatorIncome
│   │   ├── friend_ledger.py             # FriendLedger
│   │   ├── net_worth.py                 # NetWorthSnapshot, Goal, TaxDeduction, AdvanceTaxPayment
│   │   └── insurance.py                 # InsurancePolicy  ← NEW (Session 2)
│   ├── routers/
│   │   ├── auth.py                      # register, login, logout, me, PUT /mode
│   │   ├── dashboard.py
│   │   ├── income.py
│   │   ├── expenses.py
│   │   ├── loans.py
│   │   ├── trades.py
│   │   ├── investments.py
│   │   ├── creator.py
│   │   ├── tax.py
│   │   ├── networth.py
│   │   ├── friends.py
│   │   ├── simulator.py
│   │   ├── reports.py
│   │   └── insurance.py                 # ← NEW (Session 2)
│   ├── schemas/
│   │   └── insurance.py                 # ← NEW (Session 2)
│   ├── engines/
│   │   ├── debt_score.py
│   │   ├── tax_engine.py
│   │   ├── forecast.py
│   │   ├── pdf_generator.py
│   │   └── __init__.py
│   ├── alembic/
│   │   └── versions/
│   │       ├── 0001_initial_migration.py  # All original 15 tables + enums
│   │       └── 0002_add_insurance.py      # ← NEW (Session 2): insurance_policies table
│   ├── alembic.ini
│   ├── requirements.txt
│   └── .env
├── frontend/
│   ├── index.html                       # Google Fonts: Plus Jakarta Sans + Outfit + JetBrains Mono
│   ├── vite.config.js                   # Proxy /api → localhost:8001
│   ├── tailwind.config.js               # Color tokens → CSS vars; font-mono = JetBrains Mono
│   └── src/
│       ├── App.jsx                      # Routes + PrivateRoute + /insurance route
│       ├── main.jsx
│       ├── index.css                    # CSS variable design system (full redesign Session 2)
│       ├── api/axios.js                 # JWT Bearer interceptor → port 8001
│       ├── store/useStore.js            # Zustand: auth + data fetchers + setUser()
│       ├── utils/format.js              # formatINR, formatDate (DD Mon YYYY), etc.
│       ├── components/
│       │   ├── Sidebar.jsx              # Nav + profile dropdown (fixed-position) + SettingsModal
│       │   ├── TopBar.jsx               # Search (280px, grouped results) + Bell + Theme toggle
│       │   ├── Modal.jsx                # border-radius 20px, Outfit title font
│       │   ├── MetricCard.jsx           # Colored top border per card, JetBrains Mono values
│       │   ├── AlertCard.jsx            # Softer palette
│       │   ├── DatePickerInput.jsx      # ← NEW (Session 2): Calendar popup, YYYY-MM-DD internal
│       │   └── charts/
│       │       ├── BarChart.jsx         # colorFn prop for threshold coloring
│       │       ├── AreaChart.jsx
│       │       ├── DonutChart.jsx
│       │       └── LineChart.jsx
│       └── pages/
│           ├── Login.jsx
│           ├── Register.jsx
│           ├── Dashboard.jsx            # Redesigned: Outfit greeting, DTI colors, icon activity
│           ├── Income.jsx               # Full edit + DatePickerInput + row-click detail
│           ├── Expenses.jsx             # Full edit + DatePickerInput + row-click detail
│           ├── Debt.jsx                 # Full edit + DatePickerInput + loan/card detail views
│           ├── Trading.jsx              # Full edit + DatePickerInput + P&L detail view
│           ├── Investments.jsx          # Full edit + DatePickerInput + tax/LTCG detail view
│           ├── Creator.jsx              # Full edit + DatePickerInput + tax treatment detail
│           ├── Friends.jsx              # Full edit + DatePickerInput + person history detail
│           ├── Tax.jsx
│           ├── NetWorth.jsx
│           ├── Simulator.jsx
│           └── Insurance.jsx            # ← NEW (Session 2): full insurance module
├── PROJECT_BRAIN.md                     # This file
├── setup.sh
├── run.sh
└── README.md
```

---

## Tech Stack

### Backend
| Concern | Library |
|---|---|
| Framework | FastAPI 0.111.0 |
| ORM | SQLAlchemy 2.0.30 |
| Migrations | Alembic 1.13.1 |
| Database | PostgreSQL 16 on port 5433 |
| Auth | python-jose[cryptography] 3.3.0 (JWT) |
| Passwords | passlib[bcrypt] 1.7.4 |
| Validation | Pydantic v2 2.7.1 |
| Scheduling | APScheduler 3.10.4 |
| PDFs | ReportLab 4.2.0 |
| Math | numpy 1.26.4, scipy 1.13.0 |
| ASGI | uvicorn[standard] 0.29.0 |

### Frontend
| Concern | Library |
|---|---|
| UI framework | React 18.3.1 + Vite 5.4.x |
| Styling | Tailwind CSS 3.4.x |
| State | Zustand 4.5.2 |
| Routing | React Router v6.23.1 |
| Charts | Recharts 2.12.7 |
| HTTP | Axios 1.7.2 |
| Notifications | React Hot Toast 2.4.1 |
| Icons | Lucide React 0.378.0 |

---

## Database — 16 Tables

Original 15 tables from `0001_initial_migration.py` plus `insurance_policies` from `0002_add_insurance.py`.

### Alembic ENUM pattern (critical)
All PostgreSQL ENUMs must be declared with `create_type=False` at module level and created explicitly via `op.execute("CREATE TYPE ...")`. Never use `sa.Enum(...)` inside `op.create_table()` — it tries to create the type a second time and raises `DuplicateObject`.

```python
# Correct pattern:
my_enum = postgresql.ENUM('a', 'b', name='my_enum', create_type=False)

def upgrade():
    op.execute("CREATE TYPE my_enum AS ENUM ('a', 'b')")
    op.create_table('my_table',
        sa.Column('col', my_enum, nullable=False),
        ...
    )
def downgrade():
    op.drop_table('my_table')
    op.execute("DROP TYPE IF EXISTS my_enum")
```

### All enum types
```
user_mode: student | earner
income_source_type: salary | pocket_money | freelance | youtube | trading | investment | other
income_tax_category: salary | business | capital_gains | exempt
expense_category: food | transport | bills | health | entertainment | shopping | subscriptions | education | other
loan_type: home | personal | car | education | bnpl | cc_emi | other
trade_type: intraday | delivery | futures | options
trade_tax_type: stcg | ltcg | speculative | business
investment_asset_type: mutual_fund | gold | silver | land | fd | ppf | stocks | insurance | other
creator_income_type: adsense | sponsorship | membership | merch | course | other
loss_type: speculative | non_speculative | stcl | ltcl
insurance_policy_type: health | life | term | vehicle | home | accident | travel | other   ← NEW
premium_frequency: monthly | quarterly | half_yearly | yearly                              ← NEW
```

### Table summary
| Table | Key columns |
|---|---|
| `users` | id(UUID), email(unique), password_hash, name, mode(student/earner), created_at |
| `income_entries` | user_id, source_type, amount(12,2), received_on, tax_category, description |
| `expenses` | user_id, amount, category, spent_on, is_recurring, is_creator_expense |
| `loans` | user_id, loan_type, loan_name, bank_name, principal, emi_amount, interest_rate, start_date, months_total, is_active |
| `credit_cards` | user_id, card_name, bank_name, credit_limit, outstanding, minimum_due, due_date(day), statement_date(day) |
| `trades` | user_id, scrip, trade_type, buy_price(10,4), sell_price(10,4), quantity, buy_date, sell_date, charges, net_pnl, tax_type, notes |
| `investments` | user_id, asset_type, name, invested_amount, current_value, purchase_date, quantity(12,4), unit, tax_section, maturity_date |
| `creator_income` | user_id, income_type, amount, brand_name, video_title, received_on, rpm(8,4) |
| `friend_ledger` | user_id, friend_name, amount(positive=owed to you, negative=you owe), reason, date, is_settled |
| `net_worth_snapshots` | user_id, snapshot_date, total_assets, total_liabilities, net_worth, debt_score |
| `budgets` | user_id, category, monthly_limit, month, year |
| `goals` | user_id, goal_name, target_amount, current_amount, target_date, is_achieved |
| `tax_deductions` | user_id, financial_year, section(80C/80D/80CCD/24B), description, amount |
| `advance_tax_payments` | user_id, financial_year, installment(1-4), due_date, amount_due, amount_paid, is_paid |
| `trading_loss_carryforward` | user_id, financial_year, loss_type, original_loss, remaining_loss, expiry_year |
| `insurance_policies` | user_id, policy_type, policy_name, insurer_name, policy_number, sum_assured, annual_premium, premium_frequency, next_due_date, start_date, end_date, tax_section(80C/80D), tax_benefit_amount, is_active, notes, created_at |

---

## API Endpoints (all prefixed `/api`)

```
AUTH
  POST /auth/register          POST /auth/login
  POST /auth/logout            GET  /auth/me
  PUT  /auth/mode              ← toggles student ↔ earner

DASHBOARD
  GET  /dashboard              ← single endpoint, returns everything

INCOME
  GET/POST /income             PUT/DELETE /income/:id
  GET /income/summary?year=    GET /income/streams

EXPENSES
  GET/POST /expenses           PUT/DELETE /expenses/:id
  GET /expenses/summary        GET /expenses/heatmap?year=
  GET /expenses/subscriptions

LOANS & CREDIT CARDS
  GET/POST /loans              PUT/DELETE /loans/:id
  GET /loans/score             GET /loans/forecast
  GET /loans/debtfree          POST /loans/simulate
  GET/POST /loans/cards        PUT/DELETE /loans/cards/:id

TRADES
  GET/POST /trades             PUT/DELETE /trades/:id
  GET /trades/pnl              GET /trades/analytics
  GET /trades/taxsummary

INVESTMENTS
  GET/POST /investments        PUT/DELETE /investments/:id
  PUT /investments/:id/value   GET /investments/allocation
  GET /investments/xirr

CREATOR INCOME
  GET/POST /creator            PUT/DELETE /creator/:id
  GET /creator/summary         GET /creator/rpm_trend

TAX
  GET /tax/summary?year=       GET/POST /tax/deductions
  GET /tax/advance             PUT /tax/advance/:id/pay
  GET /tax/carryforward        GET /tax/suggestions

NET WORTH
  GET /networth                GET /networth/history
  POST /networth/snapshot      GET /networth/forecast

FRIENDS
  GET/POST /friends            PUT/DELETE /friends/:id
  PUT /friends/:id/settle      GET /friends/summary

SIMULATOR
  POST /simulator/scenario     POST /simulator/skipemi

REPORTS
  GET /reports/monthly         GET /reports/monthly/pdf
  GET /reports/tax             GET /reports/tax/pdf
  GET /reports/networth

INSURANCE  ← NEW (Session 2)
  GET  /insurance              ← list all, ordered by next_due_date asc
  POST /insurance              ← create (201)
  PUT  /insurance/:id          ← update
  DELETE /insurance/:id        ← delete (204)
  GET  /insurance/summary      ← aggregates: coverage, premium, tax benefits, upcoming renewals
```

### Insurance summary response shape
```json
{
  "total_coverage": 5900000,
  "total_annual_premium": 26700,
  "total_tax_benefit": 20500,
  "active_count": 3,
  "coverage_by_type": { "health": {"sum_assured": 500000, "annual_premium": 12000, "count": 1}, ... },
  "section_80c": 8500,
  "section_80d": 12000,
  "upcoming_renewals": [{"id": "...", "policy_name": "...", "days_until": 17, ...}]
}
```

---

## Frontend Architecture

### Auth Flow
- JWT stored in `localStorage` as `finsense_token`
- User object in `localStorage` as `finsense_user` (JSON)
- Axios interceptor adds `Authorization: Bearer <token>` to every request
- On 401: clears localStorage → `window.location.href = '/login'`

### Routing (`App.jsx`)
`PrivateRoute` checks `token` from Zustand. Authenticated layout: fixed Sidebar (220px or 64px collapsed) + TopBar + scrollable main. All unknown routes → `/dashboard`.

Routes: `/login`, `/register`, `/dashboard`, `/income`, `/expenses`, `/debt`, `/trading`, `/investments`, `/insurance` ← NEW, `/creator`, `/tax`, `/networth`, `/friends`, `/simulator`

### Sidebar Navigation Order
Home → Income → Expenses → Debt → Trading → Investments → **Insurance** → Creator → Tax → Net Worth → Friends → Simulator

### State Management (`useStore.js`)
Zustand. Key actions: `setUser(user)` (updates user + localStorage), `setToken`, `logout`, `fetchDashboard`, `fetchExpenses`, `fetchLoans`, `fetchTrades`, `fetchInvestments`, `fetchFriends`, `fetchIncome`.

---

## Design System (Session 2 Redesign)

### Color Palette (CSS Variables)

Dark mode (`:root`):
```css
--color-dark: #0F1117          /* page background — warm dark */
--color-card: #171B26          /* cards, sidebar — warm dark navy */
--color-tertiary: #1E2333      /* inputs, hover states */
--color-text-primary: #E8EDF5  /* warm white */
--color-text-secondary: #8892A4
--color-text-tertiary: #535D6E /* labels, muted */
--color-border: rgba(255,255,255,0.06)
--color-border-accent: rgba(99,179,237,0.2)
--color-teal: #3ECFB2          /* primary accent (softer than old #00C9A7) */
--color-accent: #3ECFB2
--color-accent-dim: rgba(62,207,178,0.12)
--color-accent-glow: rgba(62,207,178,0.08)
--color-positive: #2DD4A7      /* gains, income */
--color-negative: #F16B6B      /* losses, expenses (warmer than old #FF4757) */
--color-warning: #F5A623       /* amber */
--color-info: #5B9CF6          /* soft blue */
--color-purple: #9B8FE8        /* softer purple */
--color-danger: #F16B6B        /* alias for negative */
--color-input-bg: #1E2333      /* all inputs use tertiary bg via !important */
```

Light mode (`html.light`): `#F4F6FB` bg, `#FFFFFF` cards, `#1A2236` text.

### Typography
```css
--font-body: 'Plus Jakarta Sans', sans-serif   /* all UI text, labels, nav */
--font-heading: 'Outfit', sans-serif           /* h1/h2/h3, page titles, greeting */
--font-mono: 'JetBrains Mono', monospace       /* financial amounts only */
```
- `body { font-family: var(--font-body) }`
- `h1, h2, h3 { font-family: var(--font-heading) }`
- `font-mono` Tailwind class → JetBrains Mono (was DM Mono)
- Google Fonts imported in `index.html`

### Tailwind Color Tokens
```js
teal     → var(--color-teal)      // #3ECFB2
accent   → var(--color-accent)
danger   → var(--color-negative)  // #F16B6B
negative → var(--color-negative)
positive → var(--color-positive)  // #2DD4A7
amber    → var(--color-warning)   // #F5A623
warning  → var(--color-warning)
info     → var(--color-info)      // #5B9CF6
purple   → var(--color-purple)    // #9B8FE8
tertiary → var(--color-tertiary)
```

### Card Pattern
```
bg-card border border-white/8 rounded-2xl
box-shadow: 0 1px 3px rgba(0,0,0,0.14), 0 4px 16px rgba(0,0,0,0.07)  (auto via .bg-card CSS rule)
```
MetricCards: `border-top: 2px solid <accent-color>` (teal/blue/amber/red per card type).

### MetricCard Top Border Colors
- Net Worth: teal `#3ECFB2`
- Free Cash: info blue `#5B9CF6`
- Debt Score: amber/teal/red based on score
- Tax Due: negative red `#F16B6B`

### Button Styles
- Primary: `background: var(--color-accent)`, `color: #0F1117`, `border-radius: 10px`
- Ghost: transparent, `border: 1px solid var(--border-primary)`, hover → teal border + accent-dim bg
- Danger: `background: rgba(241,107,107,0.12)`, border `rgba(241,107,107,0.3)`

### Input Style
All inputs use `background: var(--color-input-bg)` (`#1E2333`) globally via CSS `!important`. Focus: `border-color: var(--color-accent)`, `box-shadow: 0 0 0 3px var(--color-accent-glow)`.

---

## Component Architecture

### `DatePickerInput` (`components/DatePickerInput.jsx`)
Reusable calendar popup component used across ALL date fields in the app.
- **Props:** `value` (YYYY-MM-DD string or ''), `onChange((str) => void)`, `placeholder`, `disabled`
- **Internal:** displays as DD/MM/YYYY. Calendar popup with month navigation (ChevronLeft/Right). Today button.
- **Click-outside:** `document.addEventListener('mousedown', handle)` with containerRef. `onMouseDown={e => e.stopPropagation()}` on popup prevents immediate close.
- **Used in:** Income, Expenses, Debt (loans), Trading (buy/sell dates), Investments, Creator, Friends, Insurance (all date fields)

### `Sidebar` (`components/Sidebar.jsx`)
- Fixed left, 220px expanded / 64px collapsed. `overflow-hidden` stays on root.
- Logo: Outfit bold 18px, `F` icon in `--color-accent-dim` background.
- Nav items: 13.5px Plus Jakarta Sans, `stroke-width: 1.8` on icons (via class `sidebar-nav-icon`), `rounded-xl`, 3px left accent bar when active.
- **User section at bottom:** Clickable button (not static display). Clicking opens profile dropdown.
- **Profile dropdown:** Uses `position: fixed` so it escapes the sidebar's `overflow: hidden`. Computed via `getBoundingClientRect()` on click. When collapsed → appears to the right; when expanded → appears above.
- **Profile dropdown contents:** User info (gradient avatar, name, email, mode badge) → Settings → Theme toggle → Switch mode → Logout.
- **Avatar:** `linear-gradient(135deg, #3ECFB2, #5B9CF6)`, Outfit font, dark text.
- **Switch mode:** Calls `PUT /api/auth/mode`, updates Zustand via `setUser(res.data)`.
- **SettingsModal:** Lives inside Sidebar.jsx (moved from TopBar). Contains: profile (read-only name/email), theme toggle, monthly budget setting (localStorage).

### `TopBar` (`components/TopBar.jsx`)
Header: page title (left) | Search + Bell + Theme toggle (right). **No avatar** — profile lives in Sidebar only.
- **Search bar:** 240px → expands to 300px on focus. Teal border glow on focus (`border-color: rgba(62,207,178,0.45)`, `box-shadow: 0 0 0 3px rgba(62,207,178,0.08)`).
- **Search results:** Grouped by type (Expenses, Trades, Investments, Income, Friends) with color-coded section headers and color dots per row.
- **Notifications:** Fetches loans, credit cards, insurance on bell open. Shows EMI alerts (≤7d amber), CC due alerts (≤7d red), insurance renewal alerts (≤30d amber, ≤7d red), budget exceeded/80% alerts.

### `BarChart` (`components/charts/BarChart.jsx`)
Added `colorFn` prop: `bars={[{ key: 'dti', colorFn: (v) => v < 20 ? '#2DD4A7' : v < 40 ? '#5B9CF6' : v < 70 ? '#F5A623' : '#F16B6B' }]}`. Used by DTI chart in Dashboard to color bars by threshold. Existing `colorByValue` still works. Tooltip uses `--color-tertiary` background with `--color-border-accent` border.

### `Modal` (`components/Modal.jsx`)
`border-radius: 20px`, `box-shadow: 0 20px 60px rgba(0,0,0,0.4), 0 4px 16px rgba(0,0,0,0.2)`, Outfit title font 18px.

---

## Session 2 Features Built

### Feature 1: Full Edit Functionality Across All Modules

Every row in every module has an edit button (pencil icon) that opens a pre-filled modal. Pattern consistent across all pages:

**State pattern:**
```js
const [editItem, setEditItem] = useState(null)  // null = add mode, object = edit mode
const openEdit = (item) => { setEditItem(item); setShowModal(true) }
const openAdd = () => { setEditItem(null); setShowModal(true) }
```

**Modal behavior:**
- Opens pre-filled when editing
- "Save Changes" teal button / "Add X" teal button based on mode
- Ghost "Cancel" button
- Red "Delete" button (only in edit mode) with two-click confirmation (`confirmDelete` state)
- Delete calls `setShowModal(false)` before `load()` to close modal after delete
- All save/delete operations show toast success/error

**Modules updated:** Investments, Debt (Loans + Credit Cards separate modals), Trading, Creator, Friends, Expenses, Income.

### Feature 2: DatePickerInput Everywhere

Created `frontend/src/components/DatePickerInput.jsx`. Replaced all HTML `<input type="date">` across the entire app. `formatDate()` in `utils/format.js` changed to return `"24 May 2026"` format (DD Mon YYYY, locale-independent).

### Feature 3: Row-Click Detail Views

Every table row is clickable (not just the action buttons). Clicking opens a detail modal for that entry. Action buttons use `e.stopPropagation()` / `onClick={ev => ev.stopPropagation()}` on the actions cell to prevent row-click from firing when editing.

**Detail views per module:**
- **Investments:** 3-card grid (invested/current/gain%), purchase date, tax classification (LTCG/STCG), days to LTCG threshold. LTCG thresholds: stocks/mutual_fund = 365d, gold/silver/land = 730d, fd/ppf/insurance = slab rate.
- **Debt — Loans:** Repayment progress bar, months elapsed/remaining, interest analysis (total interest, interest paid to date, principal paid).
- **Debt — Credit Cards:** Utilization gauge, available credit, minimum due.
- **Trading:** P&L breakdown (gross PnL, charges, net PnL), annualized return (`((sell/buy)^(365/days) - 1) * 100`), tax classification with explanation.
- **Friends:** All transactions with that person, net position, settle-up button.
- **Creator:** Tax treatment note by income type, estimated views from RPM.
- **Expenses:** Category badge, amount, description, date, recurring/creator-expense flags.
- **Income:** Source type badge, amount, date, tax category, taxable status.

### Feature 4: Insurance Module (Full Stack)

**Backend files created:**
- `backend/models/insurance.py` — `InsurancePolicy` model with all fields
- `backend/schemas/insurance.py` — `InsurancePolicyCreate`, `InsurancePolicyUpdate`, `InsurancePolicyOut`
- `backend/routers/insurance.py` — 5 endpoints (list, create, update, delete, summary)
- `backend/alembic/versions/0002_add_insurance.py` — migration (ran successfully)

**Model fields:** id(UUID), user_id, policy_type(ENUM), policy_name, insurer_name, policy_number, sum_assured, annual_premium, premium_frequency(ENUM), next_due_date, start_date, end_date, tax_section, tax_benefit_amount, is_active, notes, created_at.

**Frontend: `frontend/src/pages/Insurance.jsx`**
- 4 metric cards: Total Coverage, Annual Premium, Tax Benefit, Active Policies
- Policies table (2/3 width): type icon, name, insurer, coverage, premium+frequency, due date with color-coded badge (red ≤7d, amber ≤30d, green >30d), tax section
- Upcoming Renewals panel (right column): cards for policies due ≤60 days
- Tax Benefits panel: 80C progress bar (limit ₹1.5L), 80D progress bar (limit ₹25K)
- Coverage Overview: horizontal progress bars per policy type

**Add/Edit modal:**
- 8 policy type selector cards with icons (Heart=health, Shield=life/term, Car=vehicle, Home=home, AlertCircle=accident, Plane=travel, Package=other)
- Auto-fills `tax_section` (80D for health, 80C for life/term) and `tax_benefit_amount` = annual_premium when type is selected
- `is_active` toggle, DatePickerInput for all 3 dates, two-click delete confirmation

**Detail modal:** large sum-assured display, premium+frequency, renewal countdown with urgency color, tax benefit badge, notes, Edit button.

**Sidebar:** Shield icon between Investments and Creator.

**TopBar notifications:** insurance policies with `next_due_date` ≤30 days trigger bell notifications (amber ≤30d, red ≤7d).

**Test data (demo user):**
1. Star Health Comprehensive: health, ₹5L covered, ₹12,000/yr, 80D, due 2026-08-01
2. LIC Term Plan: term, ₹50L covered, ₹8,500/yr, 80C, due 2026-09-15
3. HDFC Ergo Car Insurance: vehicle, ₹8L covered, ₹6,200/yr, no tax section, due 2026-06-10

### Feature 5: Sidebar Profile Dropdown

Replaced the static user section at the bottom of the Sidebar with a clickable button that opens a fixed-position dropdown. The dropdown escapes `overflow: hidden` because it uses `position: fixed` — computed from `getBoundingClientRect()`.

Dropdown: user info (gradient avatar + name + email + mode badge) → Settings → Theme toggle → Switch mode (calls `PUT /auth/mode`) → Logout (red).

SettingsModal moved from TopBar into Sidebar.jsx. TopBar no longer has any profile/avatar functionality.

### Feature 6: TopBar Cleanup

Removed avatar and all profile state from TopBar. Header is now: **title | search | bell | theme**.

Search bar: 240px default, expands to 300px on focus with teal glow. Results grouped by type with color-coded headers. Added `searchFocused` state to track expansion.

### Feature 7: Full UI Redesign

Replaced the harsh fintech-aesthetic with a warm, trustworthy design:

- **Fonts:** Inter+DM Mono → Plus Jakarta Sans (body) + Outfit (headings) + JetBrains Mono (amounts only)
- **Colors:** Harsh `#00C9A7` → softer `#3ECFB2`, harsh `#FF4757` → warmer `#F16B6B`, `#0D1117` → `#0F1117` (warmer), cards `#161B22` → `#171B26`
- **Card shadows:** `box-shadow: 0 1px 3px rgba(0,0,0,0.14), 0 4px 16px rgba(0,0,0,0.07)` auto-applied via `.bg-card` CSS rule
- **MetricCard:** 2px colored top border per card, JetBrains Mono for values (not colored), `text-tertiary` labels with uppercase tracking
- **Input background:** `#1E2333` (tertiary) instead of page background — inputs feel clearly distinct from page
- **Dashboard greeting:** Outfit 24px, weights 600
- **DTI chart:** Now colors bars by value (`<20%` teal, `<40%` blue, `<40-70%` amber, `>70%` red) via new `colorFn` prop on BarChart
- **Activity icons:** Proper icon circles per category (Utensils=food, Car=transport, Heart=health, etc.) with 14% opacity colored backgrounds
- **Amount display:** Removed `+/-` prefix — color communicates direction
- **Quick Add toggle:** Pill container in tertiary bg, selected state uses accent background

---

## Business Logic Decisions

**Financial Year:** April–March. FY 2025-26 = Apr 1 2025 – Mar 31 2026. Month ≥ 4 → current year is fyStart.

**Indian Number System:** `formatINR` — last 3 digits grouped, then groups of 2. `₹4,28,40,250.00`. Implemented from scratch, not Intl API.

**Debt Score:** 0-100 (higher = more dangerous). <40 = safe (teal), 40-69 = caution (amber), ≥70 = danger (red). Components: DTI (max 60pts), savings rate (max 15pts), emergency fund (max 10pts), credit card utilization (max 15pts).

**Loan Outstanding:** Real-time via reducing balance formula: `EMI × (1 - (1+r)^(-n)) / r` where r = monthly rate, n = remaining months.

**Capital Gains LTCG thresholds:**
- Stocks, mutual_fund: 365 days
- Gold, silver, land: 730 days (2 years)
- FD, PPF, insurance: always slab rate (no LTCG benefit)

**Annualized return formula:** `((sell_price / buy_price) ^ (365 / days_held) - 1) * 100`

**Friend Ledger sign convention:** `amount > 0` = friend owes you (receivable, teal). `amount < 0` = you owe friend (payable, red). `openEdit()` converts to direction toggle; `handleSave()` converts back.

**Tax Regime Default:** New regime (FY 2025-26). New regime slabs: 0-4L:0%, 4-8L:5%, 8-12L:10%, 12-16L:15%, 16-20L:20%, 20-24L:25%, >24L:30%. Standard deduction ₹75K. 87A rebate if taxable ≤ 7L → tax = 0.

**Insurance auto-fill tax:** When policy type = health → `tax_section = "80D"`. life/term → `tax_section = "80C"`. `tax_benefit_amount` auto-set to `annual_premium` when type selected.

**Monthly Snapshot (APScheduler):** Fires at 02:00 on the 1st of each month. Computes net worth for every user and inserts `net_worth_snapshots` row.

---

## Known Architecture Patterns

### Row click + button click conflict
Table rows have `onClick` for detail view. Action cells (pencil/trash) need:
```jsx
// In <td> wrapping action buttons:
onClick={e => e.stopPropagation()}
// In clickable card containers:
onClick={ev => ev.stopPropagation()}
```

### Fixed-position dropdown from fixed parent
When a fixed sidebar has `overflow: hidden`, child dropdowns can still render outside bounds by using `position: fixed`. Compute position with:
```js
const rect = ref.current.getBoundingClientRect()
// collapsed: { top: rect.top, left: rect.right + 8 }
// expanded: { bottom: window.innerHeight - rect.top + 8, left: rect.left }
```

### Edit/delete in same modal
`editItem` state = null (add mode) or object (edit mode). Delete button only renders when `editItem` is set. Two-click confirmation via `confirmDelete` boolean state. Always call `setShowModal(false)` before `load()` in delete handler.

### Alembic ENUM pattern
See Database section above. Always `create_type=False` + explicit `op.execute("CREATE TYPE ...")`.

---

## Environment Variables

File: `backend/.env`
```env
DATABASE_URL=postgresql://finsense_user:finsense_pass@localhost:5433/finsense_db
JWT_SECRET=<32+ char random string>
JWT_ALGORITHM=HS256
JWT_EXPIRE_HOURS=24
ENVIRONMENT=development
CORS_ORIGINS=http://localhost:5173
```

---

## Known Gaps / Not Yet Built

1. **Budget CRUD endpoints** — `budgets` table exists but no `/api/budgets` router. TopBar uses localStorage for budget limit.
2. **Goals endpoints** — `goals` table exists but no `/api/goals` router.
3. **Student mode UI branching** — `mode` field stored and toggleable via sidebar dropdown, but frontend pages don't fully branch (e.g., "Pocket Money" label not applied conditionally everywhere).
4. **No email verification / password reset** — auth is minimal.
5. **PDF styling** — ReportLab output is functional but not matched to the new design.
6. **No frontend tests** — no Vitest or Playwright.
7. **Reports page** — exists in routing but uses GET endpoints that return JSON summaries, not always shown in a dedicated Reports UI.

---

## Useful Commands

```bash
# Backend
cd backend && source venv/bin/activate
uvicorn main:app --reload --port 8001

# Frontend
cd frontend && npm run dev

# Database
psql -U finsense_user -h localhost -p 5433 -d finsense_db

# New Alembic migration
cd backend && source venv/bin/activate
alembic revision --autogenerate -m "description"
alembic upgrade head

# Roll back
alembic downgrade -1

# Build check (should say "✓ 2392 modules transformed, 0 errors")
cd frontend && npx vite build --mode development

# Kill FinSense backend if port 8001 is in use
lsof -ti:8001 | xargs kill -9
# DO NOT kill port 8000 — that's the system process
```

---

## Files Modified in Session 2 (Comprehensive List)

**New backend files:**
- `backend/models/insurance.py`
- `backend/schemas/insurance.py`
- `backend/routers/insurance.py`
- `backend/alembic/versions/0002_add_insurance.py`

**Modified backend files:**
- `backend/models/__init__.py` — added InsurancePolicy
- `backend/models/user.py` — added insurance_policies relationship
- `backend/main.py` — added insurance router

**New frontend files:**
- `frontend/src/components/DatePickerInput.jsx`
- `frontend/src/pages/Insurance.jsx`

**Modified frontend files:**
- `frontend/index.html` — new Google Fonts
- `frontend/tailwind.config.js` — new color tokens + fonts
- `frontend/src/index.css` — full design system rewrite
- `frontend/src/App.jsx` — added /insurance route
- `frontend/src/utils/format.js` — formatDate → DD Mon YYYY
- `frontend/src/store/useStore.js` — (setUser existed, no change needed)
- `frontend/src/components/Sidebar.jsx` — full rewrite (profile dropdown, settings modal, new design)
- `frontend/src/components/TopBar.jsx` — full rewrite (no avatar, grouped search, new design)
- `frontend/src/components/Modal.jsx` — rounded-2xl → 20px radius, Outfit title
- `frontend/src/components/MetricCard.jsx` — full rewrite (top border, JetBrains Mono, new palette)
- `frontend/src/components/AlertCard.jsx` — new palette
- `frontend/src/components/charts/BarChart.jsx` — colorFn prop, new tooltip, new axis styles
- `frontend/src/pages/Dashboard.jsx` — greeting font, DTI colors, activity icons, Quick Add toggle
- `frontend/src/pages/Income.jsx` — DatePickerInput, edit modal, detail modal, delete fix
- `frontend/src/pages/Expenses.jsx` — DatePickerInput, edit modal, detail modal, delete fix
- `frontend/src/pages/Debt.jsx` — full rewrite (loan + card edit + detail views, DatePickerInput)
- `frontend/src/pages/Trading.jsx` — full rewrite (edit + detail + annualized return)
- `frontend/src/pages/Investments.jsx` — full rewrite (edit + LTCG detail + tax classification)
- `frontend/src/pages/Creator.jsx` — full rewrite (edit + detail + tax treatment)
- `frontend/src/pages/Friends.jsx` — full rewrite (edit with direction toggle + person history detail)
