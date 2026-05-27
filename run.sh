#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CYAN='\033[0;36m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${CYAN}${BOLD}Starting FinSense...${NC}"
echo ""

# Kill existing processes on these ports
echo -e "  Stopping any existing processes..."
lsof -ti:8001 | xargs kill -9 2>/dev/null || true
lsof -ti:5173 | xargs kill -9 2>/dev/null || true
sleep 1

# Start backend using full venv path (avoids 'source venv/bin/activate' in subshell)
echo -e "  ${GREEN}→${NC} Starting FastAPI backend on port 8001..."
cd "$SCRIPT_DIR/backend"
"$SCRIPT_DIR/backend/venv/bin/uvicorn" main:app --reload --port 8001 --host 0.0.0.0 &
BACKEND_PID=$!
echo -e "    Backend PID: $BACKEND_PID"

# Start frontend
echo -e "  ${GREEN}→${NC} Starting Vite frontend on port 5173..."
cd "$SCRIPT_DIR/frontend"
npm run dev &
FRONTEND_PID=$!
echo -e "    Frontend PID: $FRONTEND_PID"

echo ""
echo -e "${GREEN}${BOLD}FinSense is running!${NC}"
echo ""
echo -e "  ${CYAN}Frontend:${NC}  http://localhost:5173"
echo -e "  ${CYAN}Backend:${NC}   http://localhost:8001"
echo -e "  ${CYAN}API Docs:${NC}  http://localhost:8001/docs"
echo ""
echo -e "  Press Ctrl+C to stop all services"
echo ""

# Wait and handle Ctrl+C
cleanup() {
    echo ""
    echo -e "  Stopping services..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    echo -e "  ${GREEN}All services stopped.${NC}"
    exit 0
}

trap cleanup SIGINT SIGTERM
wait
