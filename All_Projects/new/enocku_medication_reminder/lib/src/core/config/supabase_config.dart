class SupabaseConfig {
  // Real Supabase credentials
  static const String url = 'https://vwvbyrnypzmkmvwnixso.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ3dmJ5cm55cHpta212d25peHNvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTU5OTAzNTUsImV4cCI6MjA3MTU2NjM1NX0.831MbFv3I8X3iUSqpUve7ZzqyQMU2A8ozj3McC9c26c';
  
  // Table names
  static const String medicationsTable = 'medications';
  static const String medicationSchedulesTable = 'medication_schedules';
  static const String medicationLogsTable = 'medication_logs';
  
  // RLS policies will be set up in Supabase dashboard
  static const String schema = 'public';
}
