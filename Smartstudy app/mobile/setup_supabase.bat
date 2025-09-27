@echo off
echo ========================================
echo    SmartStudy Supabase Setup
echo ========================================
echo.
echo This script will help you set up Supabase
echo.
echo Step 1: Create a Supabase project
echo - Go to https://supabase.com
echo - Sign up/Login with GitHub
echo - Create a new project
echo.
echo Step 2: Get your credentials
echo - Go to Settings > API
echo - Copy your Project URL and Anon Key
echo.
echo Step 3: Create .env file
echo - Copy .env.example to .env
echo - Update with your credentials
echo.
echo Step 4: Create database tables
echo - Run SQL from SUPABASE_SETUP.md
echo.
echo Step 5: Test the app
echo - Run: flutter run -d chrome
echo.
echo Press any key to continue...
pause

echo.
echo Creating .env file template...
if not exist .env (
  echo SUPABASE_URL=https://your-project-id.supabase.co > .env
  echo SUPABASE_ANON_KEY=your-anon-key-here >> .env
  echo .env file created! Update it with your credentials.
) else (
  echo .env file already exists.
)

echo.
echo Setup complete! Follow the steps above to configure Supabase.
echo.
pause 