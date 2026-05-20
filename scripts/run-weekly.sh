#!/bin/bash
# 주말(토·일) 실행
set -e

cd "$(dirname "$0")/.."
mkdir -p logs

if [ -f .env ]; then
  set -a
  source <(grep -Ev '^\s*(#|$)' .env)
  set +a
fi

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/weekly_${TIMESTAMP}.log"

echo "[$(date)] CS Weekly 요약 시작" | tee -a "$LOG_FILE"

cat prompts/weekly.md | claude -p \
  --mcp-config .mcp.json \
  --allowed-tools "mcp__notion__*,Read,Write,Edit" \
  --permission-mode acceptEdits \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

E