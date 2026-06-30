@echo off
call "C:\practice\cs-daily\scripts\auto-push.cmd"
echo.
echo ===== result (last lines of autopush.log) =====
powershell -NoProfile -Command "Get-Content 'C:\practice\cs-daily\scripts\autopush.log' -Tail 14"
echo ===============================================
echo.
echo OK   : you see "main -> main" or "Everything up-to-date"
echo FAIL : you see 403 / Authentication failed / could not read Username
echo.
pause
