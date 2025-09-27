@echo off
echo ========================================
echo    Creating .env file for SmartStudy
echo ========================================
echo.
echo Creating .env file with your Supabase credentials...
echo.

echo SUPABASE_URL=https://xxkkdnkkyswjrypvhiln.supabase.co > .env
echo SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4a2tkbmtreXN3anJ5cHZoaWxuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTQ0NDE0NDYsImV4cCI6MjA3MDAxNzQ0Nn0.48iKOjU9YajI_N5CjW9hqSdVn06djm3d-0woLjtRCWk >> .env

echo .env file created successfully!
echo.
echo Your Supabase credentials are now configured.
echo.
echo Next steps:
echo 1. Run the SQL commands from SUPABASE_SETUP.md in your Supabase dashboard
echo 2. Test the app with: flutter run -d chrome
echo.
pause 