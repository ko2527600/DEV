# Supabase Setup Guide for SmartStudy

## 🚀 Getting Started with Supabase

### 1. Create Supabase Project

1. Go to [supabase.com](https://supabase.com)
2. Sign up/Login with your GitHub account
3. Click "New Project"
4. Choose your organization
5. Enter project details:
   - **Name**: `smartstudy-app`
   - **Database Password**: Create a strong password
   - **Region**: Choose closest to your users
6. Click "Create new project"

### 2. Get Your Project Credentials

1. Go to **Settings** → **API**
2. Copy your credentials:
   - **Project URL**: `https://your-project-id.supabase.co`
   - **Anon Key**: `your-anon-key`

### 3. Update Environment Variables

Create a `.env` file in the `mobile` directory:

```env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

### 4. Create Database Tables

Run these SQL commands in your Supabase SQL Editor:

#### Users Table
```sql
-- Create users table
CREATE TABLE users (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  user_type TEXT NOT NULL CHECK (user_type IN ('student', 'teacher')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_login TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT true,
  avatar_url TEXT,
  bio TEXT,
  preferences JSONB DEFAULT '{}'::jsonb
);

-- Enable Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile" ON users
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON users
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);
```

#### Courses Table
```sql
-- Create courses table
CREATE TABLE courses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  instructor_id UUID REFERENCES users(id),
  category TEXT NOT NULL,
  level TEXT NOT NULL CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  duration_minutes INTEGER DEFAULT 0,
  price DECIMAL(10,2) DEFAULT 0.00,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  thumbnail_url TEXT,
  tags TEXT[]
);

-- Enable RLS
ALTER TABLE courses ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view published courses" ON courses
  FOR SELECT USING (is_published = true);

CREATE POLICY "Instructors can manage their courses" ON courses
  FOR ALL USING (auth.uid() = instructor_id);
```

#### Enrollments Table
```sql
-- Create enrollments table
CREATE TABLE enrollments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES users(id),
  course_id UUID REFERENCES courses(id),
  enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  progress_percentage DECIMAL(5,2) DEFAULT 0.00,
  completed_at TIMESTAMP WITH TIME ZONE,
  UNIQUE(user_id, course_id)
);

-- Enable RLS
ALTER TABLE enrollments ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their enrollments" ON enrollments
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can enroll in courses" ON enrollments
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their progress" ON enrollments
  FOR UPDATE USING (auth.uid() = user_id);
```

#### Lessons Table
```sql
-- Create lessons table
CREATE TABLE lessons (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  course_id UUID REFERENCES courses(id),
  title TEXT NOT NULL,
  description TEXT,
  content TEXT,
  video_url TEXT,
  duration_minutes INTEGER DEFAULT 0,
  order_index INTEGER NOT NULL,
  is_published BOOLEAN DEFAULT false,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE lessons ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Anyone can view published lessons" ON lessons
  FOR SELECT USING (is_published = true);

CREATE POLICY "Instructors can manage their lessons" ON lessons
  FOR ALL USING (
    auth.uid() IN (
      SELECT instructor_id FROM courses WHERE id = course_id
    )
  );
```

### 5. Configure Authentication

1. Go to **Authentication** → **Settings**
2. Configure email templates:
   - **Confirm signup**: Customize welcome email
   - **Reset password**: Customize reset email
3. Set up email provider (if needed)

### 6. Set Up Storage (Optional)

1. Go to **Storage**
2. Create buckets:
   - `avatars` - for user profile pictures
   - `course-thumbnails` - for course images
   - `lesson-content` - for lesson files

### 7. Update Your App Configuration

Update `mobile/lib/core/config/supabase_config.dart`:

```dart
static const String supabaseUrl = String.fromEnvironment(
  'SUPABASE_URL',
  defaultValue: 'https://your-project-id.supabase.co',
);

static const String supabaseAnonKey = String.fromEnvironment(
  'SUPABASE_ANON_KEY',
  defaultValue: 'your-anon-key',
);
```

### 8. Test Your Setup

1. Run the app: `flutter run -d chrome`
2. Try registering a new user
3. Check the Supabase dashboard to see the user created
4. Test login functionality

## 🔧 Environment Setup

### For Development
```bash
# Set environment variables
export SUPABASE_URL="https://your-project-id.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"

# Run the app
flutter run -d chrome
```

### For Production
1. Set environment variables in your deployment platform
2. Use production Supabase project
3. Configure custom domains if needed

## 📊 Database Schema Overview

### Users
- `id`: UUID (from auth.users)
- `email`: User's email
- `full_name`: User's full name
- `user_type`: 'student' or 'teacher'
- `created_at`: Account creation date
- `last_login`: Last login timestamp
- `is_active`: Account status
- `avatar_url`: Profile picture URL
- `bio`: User biography
- `preferences`: JSON preferences

### Courses
- `id`: Unique course ID
- `title`: Course title
- `description`: Course description
- `instructor_id`: Teacher's user ID
- `category`: Course category
- `level`: Difficulty level
- `duration_minutes`: Total course duration
- `price`: Course price
- `is_published`: Publication status
- `thumbnail_url`: Course image
- `tags`: Course tags

### Enrollments
- `id`: Enrollment ID
- `user_id`: Student's user ID
- `course_id`: Course ID
- `enrolled_at`: Enrollment date
- `progress_percentage`: Course progress
- `completed_at`: Completion date

### Lessons
- `id`: Lesson ID
- `course_id`: Parent course ID
- `title`: Lesson title
- `description`: Lesson description
- `content`: Lesson content
- `video_url`: Video URL
- `duration_minutes`: Lesson duration
- `order_index`: Lesson order
- `is_published`: Publication status

## 🔐 Security Features

- **Row Level Security (RLS)**: Users can only access their own data
- **Authentication**: Supabase Auth handles user management
- **Authorization**: Policies control data access
- **Real-time**: Live updates with subscriptions

## 🚀 Next Steps

1. **Test Authentication**: Register and login users
2. **Add Course Management**: Create CRUD operations for courses
3. **Implement Enrollments**: Allow students to enroll in courses
4. **Add Real-time Features**: Live chat, progress updates
5. **Set Up Storage**: Handle file uploads
6. **Add Analytics**: Track user engagement

## 📞 Support

- [Supabase Documentation](https://supabase.com/docs)
- [Flutter Supabase Package](https://pub.dev/packages/supabase_flutter)
- [Supabase Community](https://github.com/supabase/supabase/discussions)

---

**Your SmartStudy app is now powered by Supabase! 🚀** 