@echo off
schtasks /Create /TN "CS-Daily Auto Push" /TR "cmd /c \"C:\practice\cs-daily\scripts\auto-push.cmd\"" /SC DAILY /ST 08:45 /F
echo.
echo Registered: "CS-Daily Auto Push" runs every day at 08:45.
echo Run now to test : schtasks /Run /TN "CS-Daily Auto Push"
echo Remove          : schtasks /Delete /TN "CS-Daily Auto Push" /F
echo Log file        : C:\practice\cs-daily\scripts\autopush.log
echo.
pause
