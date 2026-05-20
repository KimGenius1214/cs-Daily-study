@echo off
REM ============================================================
REM CS Weekly - 주말 요약 페이지 생성 (토·일)
REM run-daily.bat 에서 위임되어 호출됨
REM ============================================================
setlocal enabledelayedexpansion

cd /d "%~dp0\.."

REM logs 디렉토리 보장
if not exist "logs" mkdir "logs"

REM .env 로드
if exist ".env" (
  for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    set "KEY=%%a"
    if defined KEY (
      set "FIRST=!KEY:~0,1!"
      if not "!FIRST!"=="#" set "!KEY!=%%b"
    )
  )
)

for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd')"') do set TODAY=%%i
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('HHmmss')"') do set HHMMSS=%%i
set LOG_FILE=logs\weekly_%TODAY%_%HHMMSS%.log

echo [%date% %time%] CS Weekly 시작 >> "%LOG_FILE%"

type "prompts\weekly.md" | claude -p ^
  --mcp-config .mcp.json ^
  --allowed-tools "mcp__notion__*,Read,Write,Edit" ^
  --permission-mode acceptEdits ^
  --output-format text >> "%LOG_FILE%" 2>&1

set EXITCODE=%errorlevel%
echo [%date% %time%] 종료 (exit=%EXITCODE%) >> "%LOG_FILE%"
endlocal & exit /b %EXITCODE%
