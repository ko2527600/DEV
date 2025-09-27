-- FarmLink Ghana Database Schema
-- This script creates all necessary tables and sets up Row Level Security (RLS)

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. USERS TABLE (Base user information)
CREATE TABLE IF NOT EXISTS users (ofl
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    user_type TEXT NOT NULL CHECK (user_type IN ('farmer', 'buyer')),
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. FARMERS TABLE (Farmer-specific information)
CREATE TABLE IF NOT EXISTS farmers (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    farm_name TEXT NOT NULL,
    farm_location TEXT,
    farm_size TEXT,
    description TEXT,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. BUYERS TABLE (Buyer-specific information)
CREATE TABLE IF NOT EXISTS buyers (
    id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    company_name TEXT,
    business_type TEXT,
    business_location TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. PRODUCTS TABLE (Product listings)
CREATE TABLE IF NOT EXISTS products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    farmer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    quantity_available INTEGER,
    category TEXT,
    images TEXT[], -- Array of image URLs
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. MESSAGES TABLE (Chat messages)
CREATE TABLE IF NOT EXISTS messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sender_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
CREATE INDEX IF NOT EXISTS idx_users_user_type ON users(user_type);
CREATE INDEX IF NOT EXISTS idx_products_farmer_id ON products(farmer_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON products(category);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON products(created_at);
CREATE INDEX IF NOT EXISTS idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_messages_created_at ON messages(created_at);

-- 7. Enable Row Level Security (RLS)
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE buyers ENABLE ROW LEVEL SECURITY;
ALTER TABLE products ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 8. USERS TABLE POLICIES
-- Users can view their own profile
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own profile
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Users can insert their own profile (during registration)
CREATE POLICY "Users can insert own profile" ON users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Anyone can view basic user info (for product listings)
CREATE POLICY "Anyone can view basic user info" ON users
    FOR SELECT USING (true);

-- 9. FARMERS TABLE POLICIES
-- Farmers can view their own profile
CREATE POLICY "Farmers can view own profile" ON farmers
    FOR SELECT USING (auth.uid() = id);

-- Farmers can update their own profile
CREATE POLICY "Farmers can update own profile" ON farmers
    FOR UPDATE USING (auth.uid() = id);

-- Farmers can insert their own profile
CREATE POLICY "Farmers can insert own profile" ON farmers
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Anyone can view farmer profiles (for product listings)
CREATE POLICY "Anyone can view farmer profiles" ON farmers
    FOR SELECT USING (true);

-- 10. BUYERS TABLE POLICIES
-- Buyers can view their own profile
CREATE POLICY "Buyers can view own profile" ON buyers
    FOR SELECT USING (auth.uid() = id);

-- Buyers can update their own profile
CREATE POLICY "Buyers can update own profile" ON buyers
    FOR UPDATE USING (auth.uid() = id);

-- Buyers can insert their own profile
CREATE POLICY "Buyers can insert own profile" ON buyers
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Anyone can view buyer profiles
CREATE POLICY "Anyone can view buyer profiles" ON buyers
    FOR SELECT USING (true);

-- 11. PRODUCTS TABLE POLICIES
-- Anyone can view products
CREATE POLICY "Anyone can view products" ON products
    FOR SELECT USING (true);

-- Farmers can create products
CREATE POLICY "Farmers can create products" ON products
    FOR INSERT WITH CHECK (auth.uid() = farmer_id);

-- Farmers can update their own products
CREATE POLICY "Farmers can update own products" ON products
    FOR UPDATE USING (auth.uid() = farmer_id);

-- Farmers can delete their own products
CREATE POLICY "Farmers can delete own products" ON products
    FOR DELETE USING (auth.uid() = farmer_id);

-- 12. MESSAGES TABLE POLICIES
-- Users can view messages they sent or received
CREATE POLICY "Users can view own messages" ON messages
    FOR SELECT USING (auth.uid() = sender_id OR auth.uid() = receiver_id);

-- Users can send messages
CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- Users can update their own messages (mark as read)
CREATE POLICY "Users can update own messages" ON messages
    FOR UPDATE USING (auth.uid() = receiver_id);

-- 13. Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_farmers_updated_at BEFORE UPDATE ON farmers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_buyers_updated_at BEFORE UPDATE ON buyers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 14. Insert sample data for testing (optional)
-- Uncomment these lines if you want to add sample data

-- INSERT INTO users (id, email, full_name, phone_number, user_type) VALUES
--     ('11909ce2-756b-4e6f-82d3-aab598a33b89', 'test@example.com', 'Test User', '+233123456789', 'farmer');

-- INSERT INTO farmers (id, farm_name, farm_location, farm_size, description) VALUES
--     ('11909ce2-756b-4e6f-82d3-aab598a33b89', 'Test Farm', 'Accra, Ghana', '5 acres', 'A test farm for development');

-- 15. Verify table creation
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'farmers', 'buyers', 'products', 'messages')
ORDER BY table_name;

-- 16. Show RLS policies
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE schemaname = 'public'
-- FarmLink Ghana Database Schema
-- This script creates the new, clean database structure

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Users Table (extends Supabase auth.users)
CREATE TABLE public.users (
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    phone_number TEXT,
    user_type TEXT NOT NULL CHECK (user_type IN ('farmer', 'buyer')),
    profile_image_url TEXT,
    location TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Farmers Table
CREATE TABLE public.farmers (
    id UUID REFERENCES public.users(id) PRIMARY KEY,
    farm_name TEXT NOT NULL,
    farm_description TEXT,
    farm_size TEXT,
    farm_location TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    business_hours TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Buyers Table
CREATE TABLE public.buyers (
    id UUID REFERENCES public.users(id) PRIMARY KEY,
    company_name TEXT,
    business_type TEXT,
    business_location TEXT,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Products Table
CREATE TABLE public.products (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    farmer_id UUID REFERENCES public.farmers(id) NOT NULL,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) NOT NULL,
    quantity_available DECIMAL(10, 2) NOT NULL,
    unit TEXT NOT NULL, -- kg, pieces, bags, etc.
    category TEXT NOT NULL,
    is_available BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Product Images Table
CREATE TABLE public.product_images (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    image_url TEXT NOT NULL,
    is_primary BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Messages Table
CREATE TABLE public.messages (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    sender_id UUID REFERENCES public.users(id) NOT NULL,
    receiver_id UUID REFERENCES public.users(id) NOT NULL,
    product_id UUID REFERENCES public.products(id),
    content TEXT NOT NULL,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Favorites Table
CREATE TABLE public.favorites (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) NOT NULL,
    product_id UUID REFERENCES public.products(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, product_id)
);

-- Create indexes for better performance
CREATE INDEX idx_users_email ON public.users(email);
CREATE INDEX idx_users_user_type ON public.users(user_type);
CREATE INDEX idx_farmers_location ON public.farmers(farm_location);
CREATE INDEX idx_buyers_location ON public.buyers(business_location);
CREATE INDEX idx_products_farmer_id ON public.products(farmer_id);
CREATE INDEX idx_products_category ON public.products(category);
CREATE INDEX idx_products_is_available ON public.products(is_available);
CREATE INDEX idx_product_images_product_id ON public.product_images(product_id);
CREATE INDEX idx_messages_sender_id ON public.messages(sender_id);
CREATE INDEX idx_messages_receiver_id ON public.messages(receiver_id);
CREATE INDEX idx_messages_product_id ON public.messages(product_id);
CREATE INDEX idx_favorites_user_id ON public.favorites(user_id);
CREATE INDEX idx_favorites_product_id ON public.favorites(product_id);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply updated_at trigger to relevant tables
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON public.users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_farmers_updated_at BEFORE UPDATE ON public.farmers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_buyers_updated_at BEFORE UPDATE ON public.buyers
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_products_updated_at BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buyers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.product_images ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Basic RLS policies (you can customize these later)
-- Allow user registration (unauthenticated insert)
CREATE POLICY "Allow user registration" ON public.users
    FOR INSERT WITH CHECK (true);

-- Users can only see their own data
CREATE POLICY "Users can view own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

-- Farmers can only manage their own farm data
CREATE POLICY "Farmers can manage own farm" ON public.farmers
    FOR ALL USING (auth.uid() = id);

-- Buyers can only manage their own business data
CREATE POLICY "Buyers can manage own business" ON public.buyers
    FOR ALL USING (auth.uid() = id);

-- Products are visible to all authenticated users
CREATE POLICY "Products are visible to all" ON public.products
    FOR SELECT USING (auth.role() = 'authenticated');

-- Farmers can only manage their own products
CREATE POLICY "Farmers can manage own products" ON public.products
    FOR ALL USING (
        auth.uid() IN (
            SELECT farmer_id FROM public.farmers WHERE id = auth.uid()
        )
    );

-- Product images follow product permissions
CREATE POLICY "Product images follow product permissions" ON public.product_images
    FOR ALL USING (
        product_id IN (
            SELECT id FROM public.products WHERE farmer_id = auth.uid()
        )
    );

-- Messages: users can only see messages they sent or received
CREATE POLICY "Users can see their messages" ON public.messages
    FOR ALL USING (auth.uid() IN (sender_id, receiver_id));

-- Favorites: users can only see their own favorites
CREATE POLICY "Users can manage own favorites" ON public.favorites
    FOR ALL USING (auth.uid() = user_id);

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Verify the schema was created correctly
SELECT 
    table_name,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'farmers', 'buyers', 'products', 'product_images', 'messages', 'favorites')
ORDER BY table_name, ordinal_position;
