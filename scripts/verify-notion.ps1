# ==============================================================
# CS Daily - Notion DB 스키마 검증
# ==============================================================
# 사용법:
#   cd C:\path\to\cs-daily
#   .\scripts\verify-notion.ps1
#
# .env 의 NOTION_TOKEN, NOTION_DB_ID 를 읽어 Notion API 로
# DB property 8 개와 핵심 select 옵션이 다 있는지 확인한다.
# ==============================================================

$ErrorActionPreference = "Stop"

$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$EnvFile    = Join-Path $ProjectDir ".env"

if (-not (Test-Path $EnvFile)) {
  Write-Error ".env 가 없습니다: $EnvFile"
  exit 1
}

# .env 파싱
$envVars = @{}
Get-Content $EnvFile | ForEach-Object {
  if ($_ -match '^\s*#') { return }
  if ($_ -match '^\s*$') { return }
  $kv = $_ -split '=', 2
  if ($kv.Count -eq 2) {
    $envVars[$kv[0].Trim()] = $kv[1].Trim()
  }
}

$Token = $envVars["NOTION_TOKEN"]
$DbId  = $envVars["NOTION_DB_ID"]

if (-not $Token -or -not $DbId) {
  Write-Error "NOTION_TOKEN 또는 NOTION_DB_ID 가 비어있습니다."
  exit 1
}

Write-Host "Notion DB 조회 중... ($DbId)" -ForegroundColor Cyan

$headers = @{
  "Authorization"  = "Bearer $Token"
  "Notion-Version" = "2022-06-28"
}

try {
  $db = Invoke-RestMethod -Uri "https://api.notion.com/v1/databases/$DbId" -Headers $headers
} catch {
  Write-Error "DB 조회 실패: $($_.Exception.Message)"
  Write-Host "원인 후보: 토큰 오류 / DB 에 Integration Connect 안 됨 / DB ID 오타" -ForegroundColor Yellow
  exit 1
}

Write-Host "DB Title: $($db.title[0].plain_text)" -ForegroundColor Green
Write-Host ""

# 기대 schema
$expected = @{
  "Title"     = "title"
  "Category"  = "select"
  "Level"     = "select"
  "Date"      = "date"
  "Day"       = "select"
  "Status"    = "select"
  "Tags"      = "multi_select"
  "실무연결도" = "select"
}

$expectedSelectOptions = @{
  "Category" = @(
    "🧮 자료구조/알고리즘", "🌐 네트워크/브라우저", "⚙️ 운영체제/시스템",
    "💾 데이터베이스", "🔐 보안/인증", "🤖 AI/ML/LLM",
    "🏛️ 시스템 설계/아키텍처", "⚛️ 프론트엔드 심화"
  )
  "Level"  = @("기초", "응용", "주간요약")
  "Day"    = @("월", "화", "수", "목", "금", "토", "일")
  "Status" = @("신규", "읽음", "복습필요", "완료")
  "실무연결도" = @("⭐", "⭐⭐", "⭐⭐⭐")
}

$problems = @()
$props = $db.properties

# 1) Property 존재/타입 체크
foreach ($name in $expected.Keys) {
  if (-not $props.PSObject.Properties.Name.Contains($name)) {
    $problems += "❌ property 누락: '$name'"
    continue
  }
  $actualType = $props.$name.type
  if ($actualType -ne $expected[$name]) {
    $problems += "❌ property '$name' 타입 불일치: expected=$($expected[$name]), actual=$actualType"
  } else {
    Write-Host "✅ $name ($actualType)" -ForegroundColor Green
  }
}

# 2) Select 옵션 체크 (있으면 좋음, 없어도 자동 생성되긴 함)
Write-Host ""
Write-Host "Select 옵션 점검 (없는 것은 페이지 생성 시 자동 추가됨):" -ForegroundColor Cyan
foreach ($name in $expectedSelectOptions.Keys) {
  if (-not $props.PSObject.Properties.Name.Contains($name)) { continue }
  $actual = @()
  if ($props.$name.type -eq "select") {
    $actual = $props.$name.select.options | ForEach-Object { $_.name }
  } elseif ($props.$name.type -eq "multi_select") {
    $actual = $props.$name.multi_select.options | ForEach-Object { $_.name }
  }
  foreach ($want in $expectedSelectOptions[$name]) {
    if ($actual -notcontains $want) {
      Write-Host "  ⚠️  '$name' 옵션 미등록: '$want'" -ForegroundColor Yellow
    }
  }
}

Write-Host ""
if ($problems.Count -eq 0) {
  Write-Host "===== 스키마 점검 통과 =====" -ForegroundColor Green
  exit 0
} else {
  Write-Host "===== 스키마 문제 $($problems.Count) 건 =====" -ForegroundColor Red
  $problems | ForEach-Object { Write-Host $_ -ForegroundColor Red }
  exit 1
}
