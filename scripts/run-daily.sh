#!/bin/bash
# 평일(월~금) 매일 실행. 토·일이면 weekly 로 위임.
set -e

cd "$(dirname "$0")/.."
mkdir -p logs

# .env 로드 (빈 줄/# 주석 제외)
if [ -f .env ]; then
  set -a
  source <(grep -Ev '^[[:space:]]*(#|$)' .env)
  set +a
fi

DAY=$(date +%u)  # 1=월 ... 7=일
TODAY=$(date +%Y%m%d)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_FILE="logs/daily_${TIMESTAMP}.log"
LOCK_FILE="logs/.lastrun_${TODAY}.lock"

if [ -f "$LOCK_FILE" ]; then
  echo "[$(date)] 오늘 이미 실행됨. 종료." | tee -a "$LOG_FILE"
  exit 0
fi

# 주말이면 weekly 로 위임
if [ "$DAY" -ge 6 ]; then
  echo "[$(date)] 주말이라 weekly 로 위임" | tee -a "$LOG_FILE"
  bash "$(dirname "$0")/run-weekly.sh"
  RC=$?
  [ $RC -eq 0 ] && echo "done" > "$LOCK_FILE"
  exit $RC
fi

echo "[$(date)] CS Daily 시작 (DOW=$DAY)" | tee -a "$LOG_FILE"

cat prompts/daily.md | claude -p \
  --mcp-config .mcp.json \
  --allowed-tools "mcp__notion__*,Read,Write,Edit" \
  --permission-mode acceptEdits \
  --output-format text \
  2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}
echo "[$(date)] 종료 (exit=$EXIT_CODE)" | tee -a "$LOG_FILE"

if [ $EXIT_CODE -eq 0 ]; then
  echo "done" > "$LOCK_FILE"
fi
exit $EXIT_CODE
