#!/usr/bin/env bash
set -e

BOLD='\033[1m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}"
echo "  ███████╗██╗███╗   ██╗███████╗███████╗███╗   ██╗███████╗███████╗"
echo "  ██╔════╝██║████╗  ██║██╔════╝██╔════╝████╗  ██║██╔════╝██╔════╝"
echo "  █████╗  ██║██╔██╗ ██║███████╗█████╗  ██╔██╗ ██║███████╗█████╗  "
echo "  ██╔══╝  ██║██║╚██╗██║╚════██║██╔══╝  ██║╚██╗██║╚════██║██╔══╝  "
echo "  ██║     ██║██║ ╚████║███████║███████╗██║ ╚████║███████║███████╗"
echo "  ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝"
echo -e "${NC}"
echo -e "${BOLD}Setup Script — Personal Finance OS${NC}"
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Check dependencies ───────────────────────────────────────────────────────

echo -e "${CYAN}[1/8] Checking dependencies...${NC}"

# Python
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
    echo -e "  ${GREEN}✓${NC} Python $PYTHON_VERSION found"
else
    echo -e "  ${RED}✗ Python 3 not found. Please install Python 3.11+${NC}"
    exit 1
fi

# Node
if command -v node &>/dev/null; then
    NODE_VERSION=$(node --version)
    echo -e "  ${GREEN}✓${NC} Node.js $NODE_VERSION found"
else
    echo -e "  ${RED}✗ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi

# PostgreSQL
if command -v psql &>/dev/null; then
    PG_VERSION=$(psql --version | awk '{print $3}')
    echo -e "  ${GREEN}✓${NC} PostgreSQL $PG_VERSION found"
else
    echo -e "  ${RED}✗ PostgreSQL not found. Please install PostgreSQL 14+${NC}"
    exit 1
fi

# ─── Detect PostgreSQL port ───────────────────────────────────────────────────

PG_PORT=5432
if command -v pg_lsclusters &>/dev/null; then
    DETECTED_PORT=$(pg_lsclusters --no-header 2>/dev/null | awk 'NR==1{print $3}')
    if [ -n "$DETECTED_PORT" ]; then
        PG_PORT=$DETECTED_PORT
    fi
fi
echo -e "  ${GREEN}✓${NC} PostgreSQL port: $PG_PORT"

# ─── Setup PostgreSQL ─────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[2/8] Setting up PostgreSQL database...${NC}"

sudo -u postgres psql -p "$PG_PORT" -c "DROP DATABASE IF EXISTS finsense_db;" 2>/dev/null || true
sudo -u postgres psql -p "$PG_PORT" -c "DROP USER IF EXISTS finsense_user;" 2>/dev/null || true
sudo -u postgres psql -p "$PG_PORT" -c "CREATE USER finsense_user WITH PASSWORD 'finsense_pass';" 2>/dev/null
sudo -u postgres psql -p "$PG_PORT" -c "CREATE DATABASE finsense_db OWNER finsense_user;" 2>/dev/null
sudo -u postgres psql -p "$PG_PORT" -c "GRANT ALL PRIVILEGES ON DATABASE finsense_db TO finsense_user;" 2>/dev/null
sudo -u postgres psql -p "$PG_PORT" -d finsense_db -c "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\";" 2>/dev/null || true

echo -e "  ${GREEN}✓${NC} Database finsense_db created"
echo -e "  ${GREEN}✓${NC} User finsense_user configured"

# ─── Copy .env ────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[3/8] Setting up environment...${NC}"

if [ ! -f "$SCRIPT_DIR/backend/.env" ]; then
    cp "$SCRIPT_DIR/backend/.env.example" "$SCRIPT_DIR/backend/.env"
    echo -e "  ${GREEN}✓${NC} .env created from .env.example"
else
    echo -e "  ${YELLOW}⚠${NC} .env already exists, skipping"
fi

# Patch port in .env if it differs from default 5432
if [ "$PG_PORT" != "5432" ]; then
    sed -i "s|localhost:5432|localhost:$PG_PORT|g" "$SCRIPT_DIR/backend/.env"
    echo -e "  ${GREEN}✓${NC} Updated DATABASE_URL port to $PG_PORT"
fi

# ─── Python virtualenv ────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[4/8] Creating Python virtual environment...${NC}"

cd "$SCRIPT_DIR/backend"

if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "  ${GREEN}✓${NC} Virtual environment created"
else
    echo -e "  ${YELLOW}⚠${NC} Virtual environment already exists"
fi

# ─── Install Python packages ──────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[5/8] Installing Python packages...${NC}"

source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
echo -e "  ${GREEN}✓${NC} Python packages installed"

# ─── Run Alembic migrations ───────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[6/8] Running database migrations...${NC}"

alembic upgrade head
echo -e "  ${GREEN}✓${NC} Database schema created"

deactivate

# ─── Install Node packages ────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[7/8] Installing frontend packages...${NC}"

cd "$SCRIPT_DIR/frontend"
npm install --silent
echo -e "  ${GREEN}✓${NC} Node packages installed"

# ─── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}[8/8] Setup complete!${NC}"
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║    FinSense is ready to launch!      ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════╝${NC}"
echo ""
echo -e "  Next steps:"
echo -e "  ${BOLD}1.${NC} Run the app:    ${CYAN}./run.sh${NC}"
echo -e "  ${BOLD}2.${NC} Open browser:   ${CYAN}http://localhost:5173${NC}"
echo -e "  ${BOLD}3.${NC} API docs:       ${CYAN}http://localhost:8000/docs${NC}"
echo ""
echo -e "  ${YELLOW}Note: Edit backend/.env to change JWT_SECRET for production${NC}"
echo ""
