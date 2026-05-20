# ==============================================================
# CS Daily - Windows 작업 스케줄러 등록 스크립트
# ==============================================================
# 사용법 (관리자 PowerShell):
#   cd C:\path\to\cs-daily
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\scripts\register-task.ps1
#
# 트리거 두 개:
#   1) 매일 오전 7:00
#   2) 시스템 시작 후 5분 지연 (PC 꺼져있던 날의 보충용)
# ==============================================================

param(
  [string]$TaskName = "CS Daily",
  [string]$AtTime   = "07:00",
  [switch]$Unregister
)

$ErrorActionPreference = "Stop"

# 스크립트 자기 위치 -> cs-daily 프로젝트 루트 계산
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path
$BatPath    = Join-Path $ProjectDir "scripts\run-daily.bat"

Write-Host ""
Write-Host "==================================================="
Write-Host " CS Daily Task Scheduler 등록"
Write-Host "==================================================="
Write-Host " ProjectDir : $ProjectDir"
Write-Host " BatPath    : $BatPath"
Write-Host " TaskName   : $TaskName"
Write-Host " AtTime     : $AtTime"
Write-Host ""

if (-not (Test-Path $BatPath)) {
  Write-Error "run-daily.bat 을 찾을 수 없습니다: $BatPath"
  exit 1
}

# Unregister 모드면 기존 작업 삭제만 하고 종료
if ($Unregister) {
  if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    Write-Host "기존 작업 '$TaskName' 삭제됨." -ForegroundColor Yellow
  } else {
    Write-Host "삭제할 작업이 없음."
  }
  exit 0
}

# 기존 동명 작업이 있으면 덮어쓰기
if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
  Write-Host "이미 '$TaskName' 작업이 있음. 갱신합니다." -ForegroundColor Yellow
  Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# 동작: run-daily.bat 을 프로젝트 루트에서 실행
$Action = New-ScheduledTaskAction `
  -Execute $BatPath `
  -WorkingDirectory $ProjectDir

# 트리거 1: 매일 지정 시각
$Trigger1 = New-ScheduledTaskTrigger -Daily -At $AtTime

# 트리거 2: 시스템 시작 후 5분 지연 (놓친 날의 보충 실행)
$Trigger2 = New-ScheduledTaskTrigger -AtStartup
$Trigger2.Delay = "PT5M"

# 설정: 배터리/예약 시간 놓쳐도 가능하면 실행
$Settings = New-ScheduledTaskSettingsSet `
  -StartWhenAvailable `
  -AllowStartIfOnBatteries `
  -DontStopIfGoingOnBatteries `
  -ExecutionTimeLimit (New-TimeSpan -Minutes 30) `
  -MultipleInstances IgnoreNew

# 현재 사용자로 등록 (대화 세션 필요 없음, 백그라운드 실행)
$Principal = New-ScheduledTaskPrincipal `
  -UserId $env:USERNAME `
  -LogonType S4U `
  -RunLevel Limited

Register-ScheduledTask `
  -TaskName $TaskName `
  -Action $Action `
  -Trigger @($Trigger1, $Trigger2) `
  -Settings $Settings `
  -Principal $Principal `
  -Description "Auto-generates CS study pages in Notion daily via Claude Code" | Out-Null

Write-Host ""
Write-Host "등록 완료." -ForegroundColor Green
Write-Host "다음 실행 시간:"
$task = Get-ScheduledTask -TaskName $TaskName
$task | Get-ScheduledTaskInfo | Format-List TaskName, NextRunTime, LastRunTime, LastTaskResult

Write-Host ""
Write-Host "팁:"
Write-Host "  · 즉시 한 번 테스트:    Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "  · 상태 확인:           Get-ScheduledTaskInfo -TaskName '$TaskName'"
Write-Host "  · 삭제:                .\scripts\register-task.ps1 -Unregister"
Write-Host "  · 시간 변경:           .\scripts\register-task.ps1 -AtTime 08:30"
