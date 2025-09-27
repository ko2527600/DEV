-- FarmLink Ghana Database Cleanup Script
-- This script will remove existing tables and prepare for new schema
-- WARNING: This will delete all existing data!

-- Drop existing tables in reverse dependency order
-- (Drop child tables before parent tables)

-- 1. Drop tables that reference other tables first
DROP TABLE IF EXISTS public.favorites CASCADE;
DROP TABLE IF EXISTS public.product_images CASCADE;
DROP TABLE IF EXISTS public.messages CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;

-- 2. Drop user profile tables
DROP TABLE IF EXISTS public.buyers CASCADE;
DROP TABLE IF EXISTS public.farmers CASCADE;

-- 3. Drop main users table (this extends Supabase auth.users)
DROP TABLE IF EXISTS public.users CASCADE;

-- 4. Drop any other custom tables that might exist
-- (Add any other table names you find in your database)
-- DROP TABLE IF EXISTS public.your_old_table_name CASCADE;

-- 5. Clean up any custom functions or triggers
-- DROP FUNCTION IF EXISTS your_function_name CASCADE;

-- 6. Clean up any custom types
-- DROP TYPE IF EXISTS your_custom_type CASCADE;

-- 7. Reset sequences if they exist
-- ALTER SEQUENCE IF EXISTS your_sequence_name RESTART WITH 1;

-- 8. Clean up any RLS (Row Level Security) policies
-- DROP POLICY IF EXISTS your_policy_name ON your_table_name;

-- 9. Clean up any custom schemas (be careful with this)
-- DROP SCHEMA IF EXISTS your_custom_schema CASCADE;

-- 10. Verify cleanup
-- This will show remaining tables in the public schema
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE';

-- Note: Supabase auth.users table will remain (this is managed by Supabase)
-- We only need to clean up our custom tables in the public schema
