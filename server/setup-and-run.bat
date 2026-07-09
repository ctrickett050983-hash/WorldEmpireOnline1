@echo off
setlocal

echo ==========================================
echo World Empire Game Server - Windows Setup
echo ==========================================

where node >nul 2>nul
if %errorlevel% neq 0 (
  echo Node.js is not installed. Install Node.js LTS from https://nodejs.org then run this again.
  pause
  exit /b 1
)

if not exist .env (
  copy .env.example .env >nul
  echo Created .env from .env.example
  echo Edit .env if your PostgreSQL username/password/database are different.
)

echo Installing dependencies...
call npm install
if %errorlevel% neq 0 goto fail

echo Applying database schema...
call npm run migrate
if %errorlevel% neq 0 goto fail

echo Adding starter cities/properties/dev account...
call npm run seed
if %errorlevel% neq 0 goto fail

echo Starting server...
call npm start
exit /b 0

:fail
echo Setup failed. Check PostgreSQL is running and DATABASE_URL in .env is correct.
pause
exit /b 1
