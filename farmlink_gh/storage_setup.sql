-- FarmLink Ghana Storage Bucket Setup
-- This script creates storage buckets and sets up access policies

-- 1. Create Storage Buckets
-- Note: Bucket names must be lowercase and contain only letters, numbers, and hyphens

-- Product Images Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'product-images',
    'product-images',
    true, -- Public bucket (anyone can view images)
    5242880, -- 5MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/heic']
) ON CONFLICT (id) DO NOTHING;

-- Profile Images Bucket
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'profile-images',
    'profile-images',
    true, -- Public bucket (anyone can view profile images)
    2097152, -- 2MB file size limit
    ARRAY['image/jpeg', 'image/png', 'image/webp']
) ON CONFLICT (id) DO NOTHING;

-- 2. Set up Storage Policies for Product Images Bucket

-- Allow authenticated users to upload product images
CREATE POLICY "Users can upload product images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow users to view all product images (public access)
CREATE POLICY "Anyone can view product images" ON storage.objects
    FOR SELECT USING (bucket_id = 'product-images');

-- Allow users to update their own product images
CREATE POLICY "Users can update own product images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow users to delete their own product images
CREATE POLICY "Users can delete own product images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'product-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- 3. Set up Storage Policies for Profile Images Bucket

-- Allow authenticated users to upload profile images
CREATE POLICY "Users can upload profile images" ON storage.objects
    FOR INSERT WITH CHECK (
        bucket_id = 'profile-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow users to view all profile images (public access)
CREATE POLICY "Anyone can view profile images" ON storage.objects
    FOR SELECT USING (bucket_id = 'profile-images');

-- Allow users to update their own profile images
CREATE POLICY "Users can update own profile images" ON storage.objects
    FOR UPDATE USING (
        bucket_id = 'profile-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- Allow users to delete their own profile images
CREATE POLICY "Users can delete own profile images" ON storage.objects
    FOR DELETE USING (
        bucket_id = 'profile-images' 
        AND auth.role() = 'authenticated'
        AND (storage.foldername(name))[1] = auth.uid()::text
    );

-- 4. Create helper functions for file management

-- Function to get user's storage folder path
CREATE OR REPLACE FUNCTION get_user_storage_path(user_id UUID)
RETURNS TEXT AS $$
BEGIN
    RETURN user_id::text || '/';
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user owns a file
CREATE OR REPLACE FUNCTION user_owns_file(file_path TEXT, user_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN (storage.foldername(file_path))[1] = user_id::text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 5. Verify storage setup
SELECT 
    id as bucket_id,
    name as bucket_name,
    public,
    file_size_limit,
    allowed_mime_types
FROM storage.buckets 
WHERE id IN ('product-images', 'profile-images');

-- 6. Show storage policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'objects' 
AND schemaname = 'storage';
