#!/bin/bash
# ==============================================================
# CS Daily - Notion DB 스키마 검증 (bash 버전)
#   - requires: jq, curl
#   - macOS: brew install jq
# ==============================================================
set -e

cd "$(dirname "$0")/.."

if [ ! -f .env ]; then
  echo ".env 가 없습니다." >&2
  exit 1
fi

set -a
source <(grep -Ev '^[[:space:]]*(#|$)' .env)
set +a

if [ -z "$NOTION_TOKEN" ] || [ -z "$NOTION_DB_ID" ]; then
  echo "NOTION_TOKEN 또는 NOTION_DB_ID 가 비어있습니다." >&2
  exit 1
fi

echo "Notion DB 조회 중... ($NOTION_DB_ID)"
RESP=$(curl -sS -w "\n%{http_code}" \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  "https://api.notion.com/v1/databases/$NOTION_DB_ID")

HTTP_CODE=$(echo "$RESP" | tail -n1)
BODY=$(echo "$RESP" | sed '$d')

if [ "$HTTP_CODE" != "200" ]; then
  echo "DB 조회 실패: HTTP $HTTP_CODE" >&2
  echo "$BODY" >&2
  echo "원인 후보: 토큰 오류 / DB 에 Integration Connect 안 됨 / DB ID 오타" >&2
  exit 1
fi

TITLE=$(echo "$BODY" | jq -r '.title[0].plain_text // "(no title)"')
echo "DB Title: $TITLE"
echo ""

declare -A EXPECTED=(
  [Title]=title
  [Category]=select
  [Level]=select
  [Date]=date
  [Day]=select
  [Status]=select
  [Tags]=multi_select
  [실무연결도]=select
)

PROBLEMS=0
for name in "${!EXPECTED[@]}"; do
  want="${EXPECTED[$name]}"
  actual=$(echo "$BODY" | jq -r --arg n "$name" '.properties[$n].type // "MISSING"')
  if [ "$actual" = "MISSING" ]; then
    echo "❌ property 누락: '$name'"
    PROBLEMS=$((PROBLEMS+1))
  elif [ "$actual" != "$want" ]; then
    echo "❌ '$name' 타입 불일치: expected=$want actual=$actual"
    PROBLEMS=$((PROBLEMS+1))
  else
    echo "✅ $name ($actual)"
  fi
done

echo ""
echo "Select 옵션 점검 (없는 것은 페이지 생성 시 자동 추가됨):"

check_select() {
  local name="$1"; shift
  local want_opts=("$@")
  local actual_opts
  actual_opts=$(echo "$BODY" | jq -r --arg n "$name" '
    (.properties[$n].select.options // .properties[$n].multi_select.options // [])
    | map(.name) | .[]
  ')
  for w in "${want_opts[@]}"; do
    if ! echo "$actual_opts" | grep -Fxq "$w"; then
      echo "  ⚠️  '$name' 옵션 미등록: '$w'"
    fi
  done
}

check_select "Level" "기초" "응용" "주간요약"
check_select "Day" "월" "화" "수" "목" "금" "토" "일"
check_select "Status" "신규" "읽음" "복습필요" "완료"
check_select "실무연결도" "⭐" "⭐⭐" "⭐⭐⭐"

echo ""
if [ $PROBLEMS -eq 0 ]; then
  echo "===== 스키마 점검 통과 ====="
  exit 0
else
  echo "===== 스키마 문제 $PROBLEMS 건 ====="
  exit 1
fi
