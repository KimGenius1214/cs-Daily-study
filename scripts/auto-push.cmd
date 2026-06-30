@echo off
setlocal
cd /d C:\practice\cs-daily
set LOG=C:\practice\cs-daily\scripts\autopush.log

REM --- author/committer = KimGenius1214 so contributions land on that account ---
set GIT_AUTHOR_NAME=KimGenius1214
set GIT_AUTHOR_EMAIL=97489808+KimGenius1214@users.noreply.github.com
set GIT_COMMITTER_NAME=KimGenius1214
set GIT_COMMITTER_EMAIL=97489808+KimGenius1214@users.noreply.github.com

echo.>>"%LOG%"
echo [%date% %time%] auto-push start>>"%LOG%"
git add components >>"%LOG%" 2>&1
git diff --cached --quiet
if errorlevel 1 (
  git commit -m "auto: design daily components update" >>"%LOG%" 2>&1
  echo [%date% %time%] committed as KimGenius1214>>"%LOG%"
) else (
  echo [%date% %time%] no new components changes>>"%LOG%"
)
git push origin main >>"%LOG%" 2>&1
set RC=%errorlevel%
echo [%date% %time%] auto-push done push_exit=%RC%>>"%LOG%"
endlocal
exit /b %RC%
