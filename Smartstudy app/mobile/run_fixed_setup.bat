@echo off
echo ========================================
echo    SmartStudy Database Setup (FIXED)
echo ========================================
echo.
echo This fixes the "relation 'courses' does not exist" error!
echo.
echo Follow these steps:
echo.
echo 1. Go to your Supabase dashboard:
echo    https://supabase.com/dashboard/project/xxkkdnkkyswjrypvhiln
echo.
echo 2. Navigate to SQL Editor (left sidebar)
echo.
echo 3. Copy the contents of database_fixed.sql
echo.
echo 4. Paste and run the SQL commands
echo.
echo 5. Verify tables were created successfully
echo.
echo The fixed SQL contains:
echo - Proper table creation order (users first, then courses)
echo - No circular references in RLS policies
echo - 6 core tables for basic functionality
echo - Performance indexes
echo.
echo Press any key to open the fixed SQL file...
pause

notepad database_fixed.sql

echo.
echo After running the SQL commands, test your app:
echo flutter run -d chrome
echo.
pause 