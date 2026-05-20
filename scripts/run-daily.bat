@echo off
REM ============================================================
REM CS Daily - 평일 실행 (월~금), 주말이면 weekly로 위임
REM 같은 날 중복 실행 방지 (lock 파일)
REM ============================================================
setlocal enabledelayedexpansion

REM 프로젝트 루트로 이동
cd /d "%~dp0\.."

REM logs 디렉토리 보장
if not exist "logs" mkdir "logs"

REM .env 로드 (빈 줄, # 주석 라인 스킵)
if exist ".env" (
  for /f "usebackq tokens=1,* delims==" %%a in (".env") do (
    set "KEY=%%a"
    if defined KEY (
      set "FIRST=!KEY:~0,1!"
      if not "!FIRST!"=="#" set "!KEY!=%%b"
    )
  )
)

REM 오늘 날짜 (YYYYMMDD) - locale-safe
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('yyyyMMdd')"') do set TODAY=%%i

REM 오늘 이미 실행됐는지 체크
set LOCK_FILE=logs\.lastrun_%TODAY%.lock
if exist "%LOCK_FILE%" (
  echo [%date% %time%] 오늘 이미 실행됨. 종료.
  exit /b 0
)

REM 요일 (월=1, 화=2, ..., 토=6, 일=0)
for /f %%i in ('powershell -NoProfile -Command "[int](Get-Date).DayOfWeek"') do set DOW=%%i

REM 타임스탬프 (HHMM 공백을 0으로)
for /f %%i in ('powershell -NoProfile -Command "(Get-Date).ToString('HHmmss')"') do set HHMMSS=%%i
set LOG_FILE=logs\daily_%TODAY%_%HHMMSS%.log

REM 토(6), 일(0)이면 weekly로 분기
if "%DOW%"=="6" goto weekly
if "%DOW%"=="0" goto weekly

echo [%date% %time%] CS Daily 시작 (DOW=%DOW%) >> "%LOG_FILE%"

REM prompts/daily.md 의 내용을 stdin 으로 claude 에 전달
type "prompts\daily.md" | claude -p ^
  --mcp-config .mcp.json ^
  --allowed-tools "mcp__notion__*,Read,Write,Edit" ^
  --permission-mode acceptEdits ^
  --output-format text >> "%LOG_FILE%" 2>&1

if errorlevel 1 (
  echo [%date% %time%] 실패 - lock 미생성, 다음 시도 가능 >> "%LOG_FILE%"
  exit /b 1
)

echo done > "%LOCK_FILE%"
echo [%date% %time%] 완료 >> "%LOG_FILE%"
goto end

:weekly
echo [%date% %time%] 주말 - run-weekly.bat 위임 >> "%LOG_FILE%"
call "%~dp0run-weekly.bat"
if not errorlevel 1 echo done > "%LOCK_FILE%"

:end
endlocal
