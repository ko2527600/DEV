# Supabase Setup Guide for TAKE MEDICATION App

## 🚀 Why Supabase?

- **No WebAssembly Issues** - Works perfectly on web, mobile, and desktop
- **Real-time Sync** - Data syncs across all your devices
- **User Authentication** - Secure user accounts and data isolation
- **Automatic Backups** - Your data is always safe
- **Scalable** - Can handle thousands of users
- **Free Tier** - Generous free plan for development

## 📋 Step 1: Create Supabase Project

1. Go to [https://supabase.com](https://supabase.com)
2. Click "Start your project" or "Sign Up"
3. Create a new project
4. Choose a name (e.g., "take-medication-app")
5. Set a database password (save this!)
6. Choose a region close to you
7. Wait for setup to complete (2-3 minutes)

## 🗄️ Step 2: Create Database Tables

Run these SQL commands in your Supabase SQL Editor:

### Medications Table
```sql
CREATE TABLE medications (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  dosage TEXT NOT NULL,
  unit TEXT NOT NULL,
  form TEXT NOT NULL,
  instructions TEXT,
  quantity INTEGER NOT NULL,
  remaining_quantity INTEGER NOT NULL,
  refill_threshold INTEGER NOT NULL,
  is_active BOOLEAN DEFAULT true,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE medications ENABLE ROW LEVEL SECURITY;

-- Create policy for users to see only their medications
CREATE POLICY "Users can view own medications" ON medications
  FOR SELECT USING (auth.uid() = user_id);

-- Create policy for users to insert their own medications
CREATE POLICY "Users can insert own medications" ON medications
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create policy for users to update their own medications
CREATE POLICY "Users can update own medications" ON medications
  FOR UPDATE USING (auth.uid() = user_id);

-- Create policy for users to delete their own medications
CREATE POLICY "Users can delete own medications" ON medications
  FOR DELETE USING (auth.uid() = user_id);
```

### Medication Schedules Table
```sql
CREATE TABLE medication_schedules (
  id TEXT PRIMARY KEY,
  medication_id TEXT REFERENCES medications(id) ON DELETE CASCADE,
  time_of_day TIME NOT NULL,
  days_of_week INTEGER[] NOT NULL, -- [1,2,3,4,5,6,7] for Monday-Sunday
  is_active BOOLEAN DEFAULT true,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE medication_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own schedules" ON medication_schedules
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own schedules" ON medication_schedules
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own schedules" ON medication_schedules
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own schedules" ON medication_schedules
  FOR DELETE USING (auth.uid() = user_id);
```

### Medication Logs Table
```sql
CREATE TABLE medication_logs (
  id TEXT PRIMARY KEY,
  medication_id TEXT REFERENCES medications(id) ON DELETE CASCADE,
  scheduled_time TIMESTAMP WITH TIME ZONE NOT NULL,
  taken_time TIMESTAMP WITH TIME ZONE,
  action TEXT NOT NULL, -- 'taken', 'skipped', 'rescheduled'
  notes TEXT,
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE medication_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own logs" ON medication_logs
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own logs" ON medication_logs
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own logs" ON medication_logs
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own logs" ON medication_logs
  FOR DELETE USING (auth.uid() = user_id);
```

## 🔑 Step 3: Get API Keys

1. In your Supabase project dashboard, go to **Settings** → **API**
2. Copy the **Project URL** and **anon public** key
3. Update `lib/src/core/config/supabase_config.dart`:

```dart
class SupabaseConfig {
  static const String url = 'YOUR_ACTUAL_SUPABASE_URL';
  static const String anonKey = 'YOUR_ACTUAL_SUPABASE_ANON_KEY';
  // ... rest of the config
}
```

## 🔐 Step 4: Configure Authentication

1. Go to **Authentication** → **Settings** in your Supabase dashboard
2. Under **Site URL**, add your app's URL (for development: `http://localhost:3000`)
3. Under **Redirect URLs**, add: `http://localhost:3000/auth/callback`
4. **Optional**: Configure email templates for better user experience

## 🚀 Step 5: Test Your Setup

1. Run `flutter pub get` to install Supabase dependencies
2. Update your config file with real credentials
3. Run the app: `flutter run -d chrome`

## 📱 Features You Now Have:

✅ **User Authentication** - Sign up, sign in, sign out
✅ **Secure Data** - Each user only sees their own data
✅ **Real-time Updates** - Changes sync across devices instantly
✅ **Offline Support** - Works even without internet
✅ **Automatic Backups** - Your data is always safe
✅ **Scalable** - Can handle thousands of users

## 🛠️ Next Steps:

1. **Add Push Notifications** - Use Supabase Edge Functions
2. **Add Data Export** - Export medication history to PDF/CSV
3. **Add Family Sharing** - Share medication info with caregivers
4. **Add Analytics** - Track medication adherence over time

## 🔧 Troubleshooting:

- **"Invalid API key"** - Check your anon key in the config
- **"Table not found"** - Make sure you ran the SQL commands
- **"Permission denied"** - Check that RLS policies are enabled
- **"Connection failed"** - Verify your project URL

## 💰 Pricing:

- **Free Tier**: 50,000 monthly active users, 500MB database, 2GB bandwidth
- **Pro Plan**: $25/month for production apps
- **Enterprise**: Custom pricing for large organizations

Your app is now enterprise-ready! 🎉
