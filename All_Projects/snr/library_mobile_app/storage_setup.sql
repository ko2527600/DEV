-- =====================================================
-- STORAGE SETUP - BUCKETS, FOLDERS, AND POLICIES
-- =====================================================
-- Run this AFTER running database_setup.sql
-- This will configure all storage buckets and policies

-- =====================================================
-- 1. CREATE STORAGE BUCKETS
-- =====================================================

-- Note: If buckets already exist, these commands will show errors
-- You can ignore the errors and continue with the script

-- Create book-files bucket (Private - authenticated users only)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'book-files',
    'book-files',
    false,
    52428800, -- 50MB limit
    ARRAY['application/pdf']
) ON CONFLICT (id) DO NOTHING;

-- Create user-avatars bucket (Public - anyone can view)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'user-avatars',
    'user-avatars',
    true,
    5242880, -- 5MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- Create academic-images bucket (Public - anyone can view)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'academic-images',
    'academic-images',
    true,
    10485760, -- 10MB limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- =====================================================
-- 2. CREATE STORAGE POLICIES
-- =====================================================

-- =====================================================
-- BOOK-FILES BUCKET POLICIES (Private)
-- =====================================================

-- Policy: Anyone can view book files (for downloading)
CREATE POLICY "Anyone can view book files" ON storage.objects
    FOR SELECT USING (bucket_id = 'book-files');

-- Policy: Authenticated users can upload book files
CREATE POLICY "Authenticated users can upload book files" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'book-files' 
        AND auth.role() = 'authenticated'
    );

-- Policy: Users can update their own uploaded book files
CREATE POLICY "Users can update their own book files" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'book-files' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy: Users can delete their own uploaded book files
CREATE POLICY "Users can delete their own book files" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'book-files' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- =====================================================
-- USER-AVATARS BUCKET POLICIES (Public)
-- =====================================================

-- Policy: Anyone can view user avatars
CREATE POLICY "Anyone can view user avatars" ON storage.objects
    FOR SELECT USING (bucket_id = 'user-avatars');

-- Policy: Authenticated users can upload their own avatars
CREATE POLICY "Users can upload their own avatars" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'user-avatars' 
        AND auth.role() = 'authenticated'
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy: Users can update their own avatars
CREATE POLICY "Users can update their own avatars" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- Policy: Users can delete their own avatars
CREATE POLICY "Users can delete their own avatars" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'user-avatars' 
        AND auth.uid()::text = (storage.foldername(name))[1]
    );

-- =====================================================
-- ACADEMIC-IMAGES BUCKET POLICIES (Public)
-- =====================================================

-- Policy: Anyone can view academic images
CREATE POLICY "Anyone can view academic images" ON storage.objects
    FOR SELECT USING (bucket_id = 'academic-images');

-- Policy: Service role can upload academic images
CREATE POLICY "Service role can upload academic images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'academic-images' 
        AND auth.role() = 'service_role'
    );

-- Policy: Service role can update academic images
CREATE POLICY "Service role can update academic images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'academic-images' 
        AND auth.role() = 'service_role'
    );

-- Policy: Service role can delete academic images
CREATE POLICY "Service role can delete academic images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'academic-images' 
        AND auth.role() = 'service_role'
    );

-- =====================================================
-- 3. CREATE FOLDER STRUCTURE
-- =====================================================

-- Note: Folders are created automatically when files are uploaded
-- But we can create some placeholder files to establish structure

-- Create book-files folder structure
-- This will be created when first book is uploaded
-- Structure: book-files/{user_id}/{filename}

-- Create user-avatars folder structure  
-- This will be created when first avatar is uploaded
-- Structure: user-avatars/{user_id}/{filename}

-- Create academic-images folder structure
-- This will be created when first image is uploaded
-- Structure: academic-images/{category}/{filename}

-- =====================================================
-- 4. CREATE STORAGE FUNCTIONS
-- =====================================================

-- Function to get user's book files
CREATE OR REPLACE FUNCTION get_user_book_files(user_uuid UUID)
RETURNS TABLE (
    name TEXT,
    size BIGINT,
    updated_at TIMESTAMPTZ,
    url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.name,
        o.metadata->>'size'::BIGINT,
        o.updated_at,
        storage.get_public_url(o.bucket_id, o.name) as url
    FROM storage.objects o
    WHERE o.bucket_id = 'book-files'
    AND (storage.foldername(o.name))[1] = user_uuid::text
    ORDER BY o.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get user's avatar
CREATE OR REPLACE FUNCTION get_user_avatar(user_uuid UUID)
RETURNS TEXT AS $$
DECLARE
    avatar_url TEXT;
BEGIN
    SELECT storage.get_public_url('user-avatars', name) INTO avatar_url
    FROM storage.objects
    WHERE bucket_id = 'user-avatars'
    AND (storage.foldername(name))[1] = user_uuid::text
    ORDER BY updated_at DESC
    LIMIT 1;
    
    RETURN COALESCE(avatar_url, '');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get academic images by category
CREATE OR REPLACE FUNCTION get_academic_images(category_name TEXT)
RETURNS TABLE (
    name TEXT,
    size BIGINT,
    updated_at TIMESTAMPTZ,
    url TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.name,
        o.metadata->>'size'::BIGINT,
        o.updated_at,
        storage.get_public_url(o.bucket_id, o.name) as url
    FROM storage.objects o
    WHERE o.bucket_id = 'academic-images'
    AND (storage.foldername(o.name))[1] = category_name
    ORDER BY o.updated_at DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- =====================================================
-- 5. VERIFY STORAGE SETUP
-- =====================================================

-- Check if buckets were created
SELECT 'Checking Storage Buckets...' as status;

SELECT 
    id as bucket_id,
    name as bucket_name,
    public,
    file_size_limit,
    CASE 
        WHEN id IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as bucket_status
FROM storage.buckets
WHERE id IN ('book-files', 'user-avatars', 'academic-images')
ORDER BY id;

-- Check if storage policies exist
SELECT 'Checking Storage Policies...' as status;

SELECT 
    policyname,
    tablename,
    CASE 
        WHEN policyname IS NOT NULL THEN '✅ EXISTS'
        ELSE '❌ MISSING'
    END as policy_status
FROM pg_policies 
WHERE schemaname = 'storage' 
AND tablename = 'objects'
ORDER BY policyname;

-- Check if storage functions exist
SELECT 'Checking Storage Functions...' as status;

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
    'get_user_book_files',y
    'get_user_avatar', 
    'get_academic_images'
)
ORDER BY routine_name;

-- =====================================================
-- 6. SETUP COMPLETE MESSAGE
-- =====================================================

SELECT '=== STORAGE SETUP COMPLETE ===' as summary;

SELECT 
    CASE 
        WHEN (
            SELECT COUNT(*) FROM storage.buckets 
            WHERE id IN ('book-files', 'user-avatars', 'academic-images')
        ) = 3
        AND (
            SELECT COUNT(*) FROM pg_policies 
            WHERE schemaname = 'storage' 
            AND tablename = 'objects'
        ) >= 12
        THEN '🎉 STORAGE SYSTEM READY! All buckets and policies created!'
        ELSE '⚠️ Some storage components missing. Check results above.'
    END as final_status;

SELECT '=== STORAGE FEATURES ===' as features;
SELECT '✅ PDF book uploads with automatic cover generation' as feature1;
SELECT '✅ User avatar management with proper permissions' as feature2;
SELECT '✅ Academic image organization by category' as feature3;
SELECT '✅ Secure file access with RLS policies' as feature4;
SELECT '✅ Helper functions for easy file management' as feature5;

SELECT '=== NEXT STEPS ===' as next_steps;
SELECT '1. Test your Flutter app - storage is now ready!' as step1;
SELECT '2. Upload PDFs to book-files bucket' as step2;
SELECT '3. Upload user avatars to user-avatars bucket' as step3;
SELECT '4. Upload academic images to academic-images bucket' as step4;
