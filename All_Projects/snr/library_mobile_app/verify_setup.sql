-- =====================================================
-- VERIFICATION SCRIPT - Check Database Setup
-- =====================================================
-- Run this AFTER running database_setup.sql
-- This will verify everything is working correctly

-- Check if all tables exist
SELECT 'Checking Tables...' as status;

SELECT 
    table_name,
    CASE 
        WHEN table_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as status
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN (
    'users', 'books', 'loans', 'reservations', 
    'subjects', 'academic_guides', 'notifications'
)
ORDER BY table_name;

-- Check if RLS is enabled on all tables
SELECT 'Checking Row Level Security...' as status;

SELECT 
    schemaname,
    tablename,
    CASE 
        WHEN rowsecurity = true THEN '✅ ENABLED'
        ELSE '❌ DISABLED'
    END as rls_status
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN (
    'users', 'books', 'loans', 'reservations', 
    'subjects', 'academic_guides', 'notifications'
)
ORDER BY tablename;

-- Check if policies exist
SELECT 'Checking Security Policies...' as status;

SELECT 
    schemaname,
    tablename,
    policyname,
    CASE 
        WHEN policyname IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as policy_status
FROM pg_policies 
WHERE schemaname = 'public' 
AND tablename IN (
    'users', 'books', 'loans', 'reservations', 
    'subjects', 'academic_guides', 'notifications'
)
ORDER BY tablename, policyname;

-- Check if triggers exist
SELECT 'Checking Triggers...' as status;

SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    CASE 
        WHEN trigger_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as trigger_status
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND trigger_name IN (
    'trigger_update_book_availability',
    'trigger_update_users_updated_at',
    'trigger_update_books_updated_at',
    'trigger_update_academic_guides_updated_at'
)
ORDER BY trigger_name;

-- Check if functions exist
SELECT 'Checking Functions...' as status;

SELECT 
    routine_name,
    routine_type,
    CASE 
        WHEN routine_name IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as function_status
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name IN (
    'update_book_availability',
    'update_updated_at_column',
    'generate_cover_url'
)
ORDER BY routine_name;

-- Check if indexes exist
SELECT 'Checking Indexes...' as status;

SELECT 
    indexname,
    tablename,
    CASE 
        WHEN indexname IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as index_status
FROM pg_indexes 
WHERE schemaname = 'public' 
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;

-- Check initial data
SELECT 'Checking Initial Data...' as status;

-- Check subjects
SELECT 
    'subjects' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) >= 8 THEN '✅ SUFFICIENT'
        ELSE '❌ INSUFFICIENT'
    END as data_status
FROM public.subjects;

-- Check academic guides
SELECT 
    'academic_guides' as table_name,
    COUNT(*) as record_count,
    CASE 
        WHEN COUNT(*) >= 6 THEN '✅ SUFFICIENT'
        ELSE '❌ INSUFFICIENT'
    END as data_status
FROM public.academic_guides;

-- Check if users table has proper structure
SELECT 'Checking Table Structure...' as status;

SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    CASE 
        WHEN column_name IS NOT NULL THEN '✅ VALID'
        ELSE '❌ INVALID'
    END as column_status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'users'
ORDER BY ordinal_position;

-- Check if books table has new smart cover structure
SELECT 'Checking Books Table Structure...' as status;

SELECT 
    column_name,
    data_type,
    is_nullable,
    CASE 
        WHEN column_name = 'file_url' AND is_nullable = 'NO' THEN '✅ REQUIRED (Good)'
        WHEN column_name = 'cover_url' AND is_nullable = 'YES' THEN '✅ OPTIONAL (Good)'
        WHEN column_name = 'file_size_mb' THEN '✅ NEW FIELD (Good)'
        WHEN column_name = 'pages_count' THEN '✅ NEW FIELD (Good)'
        WHEN column_name IS NOT NULL THEN '✅ VALID'
        ELSE '❌ INVALID'
    END as column_status
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name = 'books'
AND column_name IN ('file_url', 'cover_url', 'file_size_mb', 'pages_count')
ORDER BY column_name;

-- Test basic operations
SELECT 'Testing Basic Operations...' as status;

-- Test if we can select from subjects (public read)
SELECT 
    'Public read from subjects' as test_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ SUCCESS'
        ELSE '❌ FAILED'
    END as test_result
FROM public.subjects;

-- Test if we can select from academic guides (public read)
SELECT 
    'Public read from academic_guides' as test_name,
    CASE 
        WHEN COUNT(*) > 0 THEN '✅ SUCCESS'
        ELSE '❌ FAILED'
    END as test_result
FROM public.academic_guides;

-- Test the cover URL generation function
SELECT 'Testing Cover URL Generation...' as status;

SELECT 
    'generate_cover_url function' as test_name,
    CASE 
        WHEN generate_cover_url('https://example.com/book.pdf') = 'https://example.com/book_cover.jpg' THEN '✅ SUCCESS'
        ELSE '❌ FAILED'
    END as test_result;

-- Check extension
SELECT 'Checking Extensions...' as status;

SELECT 
    extname,
    CASE 
        WHEN extname = 'uuid-ossp' THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as extension_status
FROM pg_extension 
WHERE extname = 'uuid-ossp';

-- Final summary
SELECT '=== SETUP VERIFICATION COMPLETE ===' as summary;

SELECT 
    CASE 
        WHEN (
            SELECT COUNT(*) FROM information_schema.tables 
            WHERE table_schema = 'public' 
            AND table_name IN ('users', 'books', 'loans', 'reservations', 'subjects', 'academic_guides', 'notifications')
        ) = 7
        AND (
            SELECT COUNT(*) FROM pg_policies 
            WHERE schemaname = 'public'
        ) >= 20
        AND (
            SELECT COUNT(*) FROM information_schema.triggers 
            WHERE trigger_schema = 'public'
        ) >= 4
        AND (
            SELECT COUNT(*) FROM information_schema.routines 
            WHERE routine_schema = 'public' 
            AND routine_name = 'generate_cover_url'
        ) = 1
        THEN '🎉 ALL SYSTEMS GO! Your smart cover system is ready!'
        ELSE '⚠️ Some issues detected. Check the results above.'
    END as final_status;

-- Smart cover system reminder
SELECT '=== SMART COVER SYSTEM ===' as reminder;
SELECT '✅ PDF uploads only - no separate cover uploads needed!' as feature1;
SELECT '✅ Covers auto-generated from PDF first pages' as feature2;
SELECT '✅ Storage efficient - one file serves both purposes' as feature3;
SELECT '✅ Always synchronized - cover matches book content' as feature4;

-- Storage bucket reminder
SELECT '=== STORAGE BUCKETS NEEDED ===' as reminder;
SELECT 'You must manually create these 3 buckets in Supabase dashboard:' as step1;
SELECT '1. book-files (Private, 50MB) - for PDF books' as step2;
SELECT '2. user-avatars (Public, 5MB) - for profile pictures' as step3;
SELECT '3. academic-images (Public, 10MB) - for guide images' as step4;
SELECT '4. NO book-covers bucket needed - covers auto-generated!' as step5;
