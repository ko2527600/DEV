-- =====================================================
-- COMMUNITY LIBRARY MOBILE APP - DATABASE SETUP
-- =====================================================
-- Run this in your Supabase SQL Editor
-- This will create all necessary tables, policies, and initial data

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- 1. CREATE TABLES
-- =====================================================

-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT NOT NULL,
    student_id TEXT UNIQUE,
    phone TEXT,
    avatar_url TEXT,
    department TEXT,
    year_level INTEGER CHECK (year_level >= 1 AND year_level <= 6),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Subjects table
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    code TEXT UNIQUE,
    description TEXT,
    department TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Books table (updated for smart cover system)
CREATE TABLE IF NOT EXISTS public.books (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    author TEXT NOT NULL,
    isbn TEXT UNIQUE,
    subject_id UUID REFERENCES public.subjects(id),
    publication_year INTEGER,
    publisher TEXT,
    description TEXT,
    file_url TEXT NOT NULL, -- PDF file URL (required)
    cover_url TEXT, -- Auto-generated from PDF first page
    total_copies INTEGER DEFAULT 1,
    available_copies INTEGER DEFAULT 1,
    location TEXT,
    call_number TEXT,
    is_available BOOLEAN DEFAULT true,
    file_size_mb DECIMAL(5,2), -- File size in MB
    pages_count INTEGER, -- Number of pages in PDF
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Loans table
CREATE TABLE IF NOT EXISTS public.loans (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES public.books(id) ON DELETE CASCADE,
    loan_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE NOT NULL,
    return_date TIMESTAMP WITH TIME ZONE,
    is_returned BOOLEAN DEFAULT false,
    is_overdue BOOLEAN DEFAULT false,
    fine_amount DECIMAL(10,2) DEFAULT 0.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Reservations table
CREATE TABLE IF NOT EXISTS public.reservations (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    book_id UUID REFERENCES public.books(id) ON DELETE CASCADE,
    reservation_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expiry_date TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Academic guides table
CREATE TABLE IF NOT EXISTS public.academic_guides (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    category TEXT NOT NULL,
    content TEXT NOT NULL,
    author TEXT,
    is_published BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications table
CREATE TABLE IF NOT EXISTS public.notifications (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    type TEXT DEFAULT 'info',
    is_read BOOLEAN DEFAULT false,
    user_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- =====================================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- =====================================================

-- Books indexes
CREATE INDEX IF NOT EXISTS idx_books_title ON public.books(title);
CREATE INDEX IF NOT EXISTS idx_books_author ON public.books(author);
CREATE INDEX IF NOT EXISTS idx_books_subject ON public.books(subject_id);
CREATE INDEX IF NOT EXISTS idx_books_isbn ON public.books(isbn);
CREATE INDEX IF NOT EXISTS idx_books_available ON public.books(is_available);
CREATE INDEX IF NOT EXISTS idx_books_file_url ON public.books(file_url);

-- Loans indexes
CREATE INDEX IF NOT EXISTS idx_loans_user ON public.loans(user_id);
CREATE INDEX IF NOT EXISTS idx_loans_book ON public.loans(book_id);
CREATE INDEX IF NOT EXISTS idx_loans_due_date ON public.loans(due_date);
CREATE INDEX IF NOT EXISTS idx_loans_overdue ON public.loans(is_overdue);

-- Users indexes
CREATE INDEX IF NOT EXISTS idx_users_email ON public.users(email);
CREATE INDEX IF NOT EXISTS idx_users_student_id ON public.users(student_id);

-- =====================================================
-- 3. CREATE ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS on all tables
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.books ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.loans ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.academic_guides ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Users policies
CREATE POLICY "Users can view their own profile" ON public.users
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.users
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.users
    FOR INSERT WITH CHECK (auth.uid() = id);

-- Books policies (public read, authenticated borrow, service role insert/update)
CREATE POLICY "Anyone can view books" ON public.books
    FOR SELECT USING (true);

CREATE POLICY "Authenticated users can borrow books" ON public.books
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Service role can insert books" ON public.books
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can update books" ON public.books
    FOR UPDATE USING (auth.role() = 'service_role');

-- Loans policies
CREATE POLICY "Users can view their own loans" ON public.loans
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create loans" ON public.loans
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own loans" ON public.loans
    FOR UPDATE USING (auth.uid() = user_id);

-- Reservations policies
CREATE POLICY "Users can view their own reservations" ON public.reservations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create reservations" ON public.reservations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own reservations" ON public.reservations
    FOR UPDATE USING (auth.uid() = user_id);

-- Subjects policies (public read, service role insert/update)
CREATE POLICY "Anyone can view subjects" ON public.subjects
    FOR SELECT USING (true);

CREATE POLICY "Service role can insert subjects" ON public.subjects
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can update subjects" ON public.subjects
    FOR UPDATE USING (auth.role() = 'service_role');

-- Academic guides policies (public read, service role insert/update)
CREATE POLICY "Anyone can view published academic guides" ON public.academic_guides
    FOR SELECT USING (is_published = true);

CREATE POLICY "Service role can insert academic guides" ON public.academic_guides
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

CREATE POLICY "Service role can update academic guides" ON public.academic_guides
    FOR UPDATE USING (auth.role() = 'service_role');

-- Notifications policies
CREATE POLICY "Users can view their own notifications" ON public.notifications
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON public.notifications
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can insert notifications" ON public.notifications
    FOR INSERT WITH CHECK (auth.role() = 'service_role');

-- =====================================================
-- 4. INSERT INITIAL DATA
-- =====================================================

-- Insert sample subjects
INSERT INTO public.subjects (name, code, description, department) VALUES
('Computer Science', 'CS101', 'Introduction to Computer Science', 'Engineering'),
('Mathematics', 'MATH101', 'Basic Mathematics', 'Science'),
('English Literature', 'ENG101', 'Introduction to English Literature', 'Arts'),
('Physics', 'PHY101', 'Fundamental Physics', 'Science'),
('Business Management', 'BUS101', 'Principles of Business Management', 'Business'),
('History', 'HIST101', 'World History', 'Arts'),
('Chemistry', 'CHEM101', 'General Chemistry', 'Science'),
('Economics', 'ECO101', 'Microeconomics', 'Business')
ON CONFLICT (code) DO NOTHING;

-- Insert sample academic guides
INSERT INTO public.academic_guides (title, category, content, author) VALUES
('Student Code of Conduct', 'Conduct', 'Students must maintain high standards of academic integrity. Plagiarism, cheating, and other forms of academic dishonesty are strictly prohibited. Respect for teachers, staff, and fellow students is mandatory.', 'Academic Affairs'),
('Building Relationships with Teachers', 'Relationships', 'Develop professional relationships with your teachers and lecturers. Attend office hours, ask questions, and show genuine interest in your studies. Communication is key to academic success.', 'Student Services'),
('Effective Study Strategies', 'Study Skills', 'Use active learning techniques: summarize in your own words, teach others, practice with past exams, and create mind maps. Study in focused 25-minute sessions with 5-minute breaks.', 'Learning Center'),
('Time Management for Students', 'Study Skills', 'Create a weekly schedule, prioritize tasks using the Eisenhower Matrix, eliminate time-wasters, and use productivity tools. Balance academics with personal well-being.', 'Student Success'),
('Academic Writing Guidelines', 'Writing', 'Follow proper citation formats, write clear thesis statements, use evidence to support arguments, and proofread thoroughly. Academic writing requires precision and clarity.', 'Writing Center'),
('Research Methods', 'Research', 'Start with a clear research question, use credible sources, take detailed notes, and organize your findings systematically. Good research is the foundation of academic excellence.', 'Research Office')
ON CONFLICT DO NOTHING;

-- =====================================================
-- 5. CREATE FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update book availability when loaned
CREATE OR REPLACE FUNCTION update_book_availability()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Decrease available copies when book is loaned
        UPDATE public.books 
        SET available_copies = available_copies - 1,
            is_available = CASE WHEN available_copies - 1 > 0 THEN true ELSE false END
        WHERE id = NEW.book_id;
        
        -- Set due date to 14 days from loan date
        NEW.due_date = NOW() + INTERVAL '14 days';
        
    ELSIF TG_OP = 'UPDATE' AND NEW.is_returned = true AND OLD.is_returned = false THEN
        -- Increase available copies when book is returned
        UPDATE public.books 
        SET available_copies = available_copies + 1,
            is_available = CASE WHEN available_copies + 1 > 0 THEN true ELSE false END
        WHERE id = NEW.book_id;
        
        -- Set return date
        NEW.return_date = NOW();
        
        -- Check if overdue and calculate fine
        IF NEW.due_date < NOW() THEN
            NEW.is_overdue = true;
            -- Calculate fine: $1 per day overdue
            NEW.fine_amount = EXTRACT(EPOCH FROM (NOW() - NEW.due_date)) / 86400 * 1.00;
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Function to generate cover URL from PDF file URL
CREATE OR REPLACE FUNCTION generate_cover_url(pdf_file_url TEXT)
RETURNS TEXT AS $$
BEGIN
    -- This function will be called by your Flutter app
    -- to generate cover URLs from PDF file URLs
    -- The actual PDF processing will happen in your app
    -- This is just a placeholder for the database structure
    
    -- Example: convert PDF URL to cover URL
    -- From: https://.../storage/v1/object/public/book-files/book.pdf
    -- To: https://.../storage/v1/object/public/book-files/book_cover.jpg
    
    RETURN REPLACE(pdf_file_url, '.pdf', '_cover.jpg');
END;
$$ LANGUAGE plpgsql;

-- Trigger for loans table
CREATE TRIGGER trigger_update_book_availability
    AFTER INSERT OR UPDATE ON public.loans
    FOR EACH ROW
    EXECUTE FUNCTION update_book_availability();

-- Function to update timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at columns
CREATE TRIGGER trigger_update_users_updated_at
    BEFORE UPDATE ON public.users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_books_updated_at
    BEFORE UPDATE ON public.books
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER trigger_update_academic_guides_updated_at
    BEFORE UPDATE ON public.academic_guides
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- 6. CREATE STORAGE BUCKETS
-- =====================================================

-- Note: Storage buckets cannot be created via SQL in this Supabase version
-- You need to create them manually in the Supabase dashboard

-- Required buckets to create manually:
-- 1. book-files (Private - for PDF books)
-- 2. user-avatars (Public - for user profile pictures)  
-- 3. academic-images (Public - for academic guide images)

-- Steps to create buckets:
-- 1. Go to Storage in your Supabase dashboard
-- 2. Click "Create bucket" for each bucket
-- 3. Set appropriate public/private permissions
-- 4. Set file size limits as needed

-- The database setup below will work regardless of bucket creation method

-- =====================================================
-- 7. SETUP COMPLETE MESSAGE
-- =====================================================

SELECT 'Database setup completed successfully!' as status;
SELECT 'Next steps:' as next_steps;
SELECT '1. Create storage buckets manually in Supabase dashboard' as step1;
SELECT '2. Test your Flutter app' as step2;
SELECT '3. Add books when ready - just upload PDFs!' as step3;
SELECT '4. Covers will be auto-generated from PDF first pages' as step4;
