-- ========================================
-- SmartStudy Database Setup (FIXED)
-- Complete SQL with proper table creation order
-- ========================================

-- 1. USERS TABLE (Must be created first)
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('student', 'teacher', 'admin')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  avatar_url TEXT,
  bio TEXT,
  preferences JSONB DEFAULT '{}'::jsonb,
  phone TEXT,
  date_of_birth DATE,
  education_level TEXT,
  interests TEXT[]
);

-- Enable Row Level Security for users
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create basic policies for users (without circular references)
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);

-- 2. COURSES TABLE
CREATE TABLE courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES users(id),
  category TEXT NOT NULL,
  subcategory TEXT,
  level TEXT NOT NULL CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  duration_minutes INTEGER DEFAULT 0,
  price DECIMAL(10,2) DEFAULT 0.00,
  is_published BOOLEAN DEFAULT false,
  is_featured BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  thumbnail_url TEXT,
  tags TEXT[],
  requirements TEXT[],
  learning_outcomes TEXT[],
  max_students INTEGER,
  current_students INTEGER DEFAULT 0,
  rating DECIMAL(3,2) DEFAULT 0.00,
  total_ratings INTEGER DEFAULT 0
);

-- Enable RLS for courses
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Policies for courses
CREATE POLICY "Anyone can view published courses" ON courses
  FOR SELECT USING (is_published = true);

CREATE POLICY "Instructors can manage their courses" ON courses
  FOR ALL USING (auth.uid() = instructor_id);

CREATE POLICY "Admins can manage all courses" ON courses
  FOR ALL USING (
    auth.uid() IN (
      SELECT id FROM users WHERE user_type = 'admin'
    )
  );

-- 3. ENROLLMENTS TABLE
CREATE TABLE enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  course_id UUID REFERENCES courses(id),
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress_percentage DECIMAL(5,2) DEFAULT 0.00,
  completed_at TIMESTAMP WITH TIME ZONE,
  last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  certificate_issued BOOLEAN DEFAULT false,
  certificate_url TEXT,
  notes TEXT,
  UNIQUE(user_id, course_id)
);

-- Enable RLS for enrollments
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Policies for enrollments
CREATE POLICY "Users can view their enrollments" ON enrollments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can enroll in courses" ON enrollments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their progress" ON enrollments
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Instructors can view their course enrollments" ON enrollments
  FOR SELECT USING (
    auth.uid() IN (
      SELECT instructor_id FROM courses WHERE id = course_id
    )
  );

-- 4. LESSONS TABLE
CREATE TABLE lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id),
  title TEXT NOT NULL,
  description TEXT,
  content TEXT,
  video_url TEXT,
  audio_url TEXT,
  duration_minutes INTEGER DEFAULT 0,
  order_index INTEGER NOT NULL,
  is_published BOOLEAN DEFAULT false,
  is_free BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  resources JSONB DEFAULT '[]'::jsonb,
  quiz_id UUID,
  UNIQUE(course_id, order_index)
);

-- Enable RLS for lessons
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Policies for lessons
CREATE POLICY "Anyone can view published lessons" ON lessons
  FOR SELECT USING (is_published = true);

CREATE POLICY "Instructors can manage their lessons" ON lessons
  FOR ALL USING (
    auth.uid() IN (
      SELECT instructor_id FROM courses WHERE id = course_id
    )
  );

-- 5. STUDY GROUPS TABLE
CREATE TABLE study_groups (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  creator_id UUID REFERENCES users(id),
  course_id UUID REFERENCES courses(id),
  max_members INTEGER DEFAULT 10,
  current_members INTEGER DEFAULT 1,
  is_public BOOLEAN DEFAULT true,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  meeting_schedule JSONB,
  rules TEXT[]
);

-- Enable RLS for study_groups
ALTER TABLE study_groups ENABLE ROW LEVEL SECURITY;

-- Policies for study_groups
CREATE POLICY "Anyone can view public study groups" ON study_groups
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can create study groups" ON study_groups
  FOR INSERT WITH CHECK (auth.uid() = creator_id);

CREATE POLICY "Group creators can manage their groups" ON study_groups
  FOR UPDATE USING (auth.uid() = creator_id);

-- 6. STUDY GROUP MEMBERS TABLE
CREATE TABLE study_group_members (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  group_id UUID REFERENCES study_groups(id),
  user_id UUID REFERENCES users(id),
  role TEXT NOT NULL CHECK (role IN ('member', 'moderator', 'admin')),
  joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  UNIQUE(group_id, user_id)
);

-- Enable RLS for study_group_members
ALTER TABLE study_group_members ENABLE ROW LEVEL SECURITY;

-- Policies for study_group_members
CREATE POLICY "Users can join public groups" ON study_group_members
  FOR INSERT WITH CHECK (
    auth.uid() = user_id AND
    group_id IN (
      SELECT id FROM study_groups WHERE is_public = true
    )
  );

CREATE POLICY "Group members can view membership" ON study_group_members
  FOR SELECT USING (
    group_id IN (
      SELECT id FROM study_groups WHERE creator_id = auth.uid()
      UNION
      SELECT group_id FROM study_group_members WHERE user_id = auth.uid()
    )
  );

-- 7. PROGRESS TRACKING TABLE
CREATE TABLE progress_tracking (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  lesson_id UUID REFERENCES lessons(id),
  course_id UUID REFERENCES courses(id),
  completion_status TEXT NOT NULL CHECK (completion_status IN ('not_started', 'in_progress', 'completed')),
  time_spent_minutes INTEGER DEFAULT 0,
  last_accessed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  quiz_score DECIMAL(5,2),
  notes TEXT,
  UNIQUE(user_id, lesson_id)
);

-- Enable RLS for progress_tracking
ALTER TABLE progress_tracking ENABLE ROW LEVEL SECURITY;

-- Policies for progress_tracking
CREATE POLICY "Users can view their own progress" ON progress_tracking
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" ON progress_tracking
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own progress" ON progress_tracking
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Instructors can view student progress" ON progress_tracking
  FOR SELECT USING (
    auth.uid() IN (
      SELECT instructor_id FROM courses WHERE id = course_id
    )
  );

-- 8. NOTIFICATIONS TABLE
CREATE TABLE notifications (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  type TEXT NOT NULL CHECK (type IN ('course_update', 'enrollment', 'achievement', 'reminder', 'system')),
  is_read BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  action_url TEXT,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- Enable RLS for notifications
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Policies for notifications
CREATE POLICY "Users can view their own notifications" ON notifications
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can update their own notifications" ON notifications
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "System can create notifications" ON notifications
  FOR INSERT WITH CHECK (true);

-- 9. ACHIEVEMENTS TABLE
CREATE TABLE achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  name TEXT NOT NULL,
  description TEXT,
  icon_url TEXT,
  points INTEGER DEFAULT 0,
  criteria JSONB NOT NULL,
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create user achievements table
CREATE TABLE user_achievements (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  achievement_id UUID REFERENCES achievements(id),
  earned_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, achievement_id)
);

-- Enable RLS for achievements
ALTER TABLE achievements ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_achievements ENABLE ROW LEVEL SECURITY;

-- Policies for achievements
CREATE POLICY "Anyone can view achievements" ON achievements
  FOR SELECT USING (is_active = true);

-- Policies for user_achievements
CREATE POLICY "Users can view their own achievements" ON user_achievements
  FOR SELECT USING (auth.uid() = user_id);

-- 10. RESOURCES TABLE
CREATE TABLE resources (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  type TEXT NOT NULL CHECK (type IN ('pdf', 'video', 'audio', 'link', 'document')),
  url TEXT,
  file_size INTEGER,
  duration_minutes INTEGER,
  category TEXT,
  tags TEXT[],
  is_public BOOLEAN DEFAULT false,
  uploaded_by UUID REFERENCES users(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  download_count INTEGER DEFAULT 0
);

-- Enable RLS for resources
ALTER TABLE resources ENABLE ROW LEVEL SECURITY;

-- Policies for resources
CREATE POLICY "Anyone can view public resources" ON resources
  FOR SELECT USING (is_public = true);

CREATE POLICY "Users can upload resources" ON resources
  FOR INSERT WITH CHECK (auth.uid() = uploaded_by);

CREATE POLICY "Users can manage their own resources" ON resources
  FOR UPDATE USING (auth.uid() = uploaded_by);

-- ========================================
-- CREATE INDEXES FOR PERFORMANCE
-- ========================================

CREATE INDEX idx_courses_instructor ON courses(instructor_id);
CREATE INDEX idx_courses_category ON courses(category);
CREATE INDEX idx_courses_published ON courses(is_published);
CREATE INDEX idx_enrollments_user ON enrollments(user_id);
CREATE INDEX idx_enrollments_course ON enrollments(course_id);
CREATE INDEX idx_lessons_course ON lessons(course_id);
CREATE INDEX idx_lessons_order ON lessons(course_id, order_index);
CREATE INDEX idx_progress_user ON progress_tracking(user_id);
CREATE INDEX idx_progress_lesson ON progress_tracking(lesson_id);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(user_id, is_read);
CREATE INDEX idx_study_groups_course ON study_groups(course_id);
CREATE INDEX idx_study_group_members_group ON study_group_members(group_id);
CREATE INDEX idx_study_group_members_user ON study_group_members(user_id);

-- ========================================
-- CREATE FUNCTIONS FOR AUTOMATION
-- ========================================

-- Function to update course student count
CREATE OR REPLACE FUNCTION update_course_student_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE courses 
    SET current_students = current_students + 1 
    WHERE id = NEW.course_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE courses 
    SET current_students = current_students - 1 
    WHERE id = OLD.course_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for enrollment changes
CREATE TRIGGER update_course_student_count_trigger
  AFTER INSERT OR DELETE ON enrollments
  FOR EACH ROW
  EXECUTE FUNCTION update_course_student_count();

-- Function to update study group member count
CREATE OR REPLACE FUNCTION update_study_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE study_groups 
    SET current_members = current_members + 1 
    WHERE id = NEW.group_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE study_groups 
    SET current_members = current_members - 1 
    WHERE id = OLD.group_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger for study group member changes
CREATE TRIGGER update_study_group_member_count_trigger
  AFTER INSERT OR DELETE ON study_group_members
  FOR EACH ROW
  EXECUTE FUNCTION update_study_group_member_count();

-- ========================================
-- INSERT SAMPLE DATA (OPTIONAL)
-- ========================================

-- Insert sample achievements
INSERT INTO achievements (name, description, points, criteria) VALUES
('First Course', 'Complete your first course', 10, '{"type": "course_completion", "count": 1}'),
('Study Group Leader', 'Create a study group', 20, '{"type": "study_group_creation", "count": 1}'),
('Perfect Score', 'Get 100% on a quiz', 15, '{"type": "quiz_perfect_score", "count": 1}'),
('Consistent Learner', 'Study for 7 consecutive days', 25, '{"type": "consecutive_days", "count": 7}'),
('Course Creator', 'Create your first course', 50, '{"type": "course_creation", "count": 1}');

-- ========================================
-- ADD ADDITIONAL POLICIES AFTER ALL TABLES EXIST
-- ========================================

-- Add teacher policy for viewing student profiles (now that all tables exist)
CREATE POLICY "Teachers can view student profiles" ON users
  FOR SELECT USING (
    auth.uid() IN (
      SELECT instructor_id FROM courses WHERE id IN (
        SELECT course_id FROM enrollments WHERE user_id = users.id
      )
    )
  );

-- Add group member policy for viewing groups (now that all tables exist)
CREATE POLICY "Group members can view their groups" ON study_groups
  FOR SELECT USING (
    id IN (
      SELECT group_id FROM study_group_members WHERE user_id = auth.uid()
    )
  );

-- ========================================
-- DATABASE SETUP COMPLETE
-- ========================================

-- Verify tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_type = 'BASE TABLE'
ORDER BY table_name; 