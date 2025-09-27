import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Switch } from '@/components/ui/switch';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Bell, 
  Mail, 
  MessageSquare, 
  Smartphone,
  Clock,
  Calendar,
  Settings,
  TestTube,
  RotateCcw,
  Save,
  Moon,
  Sun
} from 'lucide-react';
import { doc, getDoc, setDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function ReminderSettings() {
  const { currentUser } = useAuth();
  const [preferences, setPreferences] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const defaultPreferences = {
    enableAppointmentReminders: true,
    enableMedicationReminders: true,
    enableFollowUpReminders: true,
    preferredMethods: ['push', 'email'],
    reminderTiming: {
      appointment: [24, 2] // 24 hours and 2 hours before
    },
    quietHoursEnabled: false,
    quietHoursStart: 22, // 10 PM
    quietHoursEnd: 8, // 8 AM
    enabledDays: [1, 2, 3, 4, 5, 6, 7], // All days
    timezone: 'UTC'
  };

  useEffect(() => {
    loadPreferences();
  }, [currentUser]);

  const loadPreferences = async () => {
    if (!currentUser) return;

    try {
      const docRef = doc(db, 'reminder_preferences', currentUser.uid);
      const docSnap = await getDoc(docRef);

      if (docSnap.exists()) {
        setPreferences({ ...defaultPreferences, ...docSnap.data() });
      } else {
        setPreferences(defaultPreferences);
      }
    } catch (error) {
      console.error('Error loading preferences:', error);
      setPreferences(defaultPreferences);
    } finally {
      setLoading(false);
    }
  };

  const savePreferences = async () => {
    if (!currentUser || !preferences) return;

    setSaving(true);
    try {
      await setDoc(doc(db, 'reminder_preferences', currentUser.uid), {
        ...preferences,
        updatedAt: serverTimestamp()
      }, { merge: true });

      // Show success message
      alert('Preferences saved successfully!');
    } catch (error) {
      console.error('Error saving preferences:', error);
      alert('Error saving preferences. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const updatePreference = (key, value) => {
    setPreferences(prev => ({
      ...prev,
      [key]: value
    }));
  };

  const updateMethod = (method, enabled) => {
    const methods = [...preferences.preferredMethods];
    if (enabled && !methods.includes(method)) {
      methods.push(method);
    } else if (!enabled && methods.includes(method)) {
      methods.splice(methods.indexOf(method), 1);
    }
    updatePreference('preferredMethods', methods);
  };

  const updateReminderTiming = (hours, enabled) => {
    const timing = [...preferences.reminderTiming.appointment];
    if (enabled && !timing.includes(hours)) {
      timing.push(hours);
    } else if (!enabled && timing.includes(hours)) {
      timing.splice(timing.indexOf(hours), 1);
    }
    timing.sort((a, b) => b - a); // Sort descending
    updatePreference('reminderTiming', { ...preferences.reminderTiming, appointment: timing });
  };

  const updateEnabledDay = (day, enabled) => {
    const days = [...preferences.enabledDays];
    if (enabled && !days.includes(day)) {
      days.push(day);
    } else if (!enabled && days.includes(day)) {
      days.splice(days.indexOf(day), 1);
    }
    days.sort();
    updatePreference('enabledDays', days);
  };

  const resetToDefaults = () => {
    if (confirm('Are you sure you want to reset all settings to defaults?')) {
      setPreferences(defaultPreferences);
    }
  };

  const sendTestNotification = () => {
    alert('Test notification sent! Check your notifications.');
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const timingOptions = [
    { label: '24 hours before', hours: 24 },
    { label: '12 hours before', hours: 12 },
    { label: '6 hours before', hours: 6 },
    { label: '2 hours before', hours: 2 },
    { label: '1 hour before', hours: 1 },
    { label: '30 minutes before', hours: 0.5 }
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Reminder Settings</h1>
          <p className="text-gray-600">Customize your notification preferences</p>
        </div>
        <Button onClick={savePreferences} disabled={saving}>
          {saving ? (
            <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
          ) : (
            <Save className="h-4 w-4 mr-2" />
          )}
          Save Settings
        </Button>
      </div>

      <Tabs defaultValue="general" className="space-y-6">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="general">General</TabsTrigger>
          <TabsTrigger value="methods">Methods</TabsTrigger>
          <TabsTrigger value="timing">Timing</TabsTrigger>
          <TabsTrigger value="advanced">Advanced</TabsTrigger>
        </TabsList>

        {/* General Settings */}
        <TabsContent value="general">
          <Card>
            <CardHeader>
              <CardTitle>General Settings</CardTitle>
              <CardDescription>
                Enable or disable different types of reminders
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <Calendar className="h-4 w-4 text-blue-600" />
                    <span className="font-medium">Appointment Reminders</span>
                  </div>
                  <p className="text-sm text-gray-600">Get notified about upcoming appointments</p>
                </div>
                <Switch
                  checked={preferences.enableAppointmentReminders}
                  onCheckedChange={(checked) => updatePreference('enableAppointmentReminders', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <TestTube className="h-4 w-4 text-green-600" />
                    <span className="font-medium">Medication Reminders</span>
                  </div>
                  <p className="text-sm text-gray-600">Get notified about medication schedules</p>
                </div>
                <Switch
                  checked={preferences.enableMedicationReminders}
                  onCheckedChange={(checked) => updatePreference('enableMedicationReminders', checked)}
                />
              </div>

              <div className="flex items-center justify-between">
                <div className="space-y-1">
                  <div className="flex items-center space-x-2">
                    <Clock className="h-4 w-4 text-purple-600" />
                    <span className="font-medium">Follow-up Reminders</span>
                  </div>
                  <p className="text-sm text-gray-600">Get notified about follow-up appointments</p>
                </div>
                <Switch
                  checked={preferences.enableFollowUpReminders}
                  onCheckedChange={(checked) => updatePreference('enableFollowUpReminders', checked)}
                />
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Notification Methods */}
        <TabsContent value="methods">
          <Card>
            <CardHeader>
              <CardTitle>Notification Methods</CardTitle>
              <CardDescription>
                Choose how you want to receive reminders
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-3">
                    <Bell className="h-5 w-5 text-blue-600" />
                    <div>
                      <span className="font-medium">Push Notifications</span>
                      <p className="text-sm text-gray-600">Receive notifications on your device</p>
                    </div>
                  </div>
                  <Switch
                    checked={preferences.preferredMethods.includes('push')}
                    onCheckedChange={(checked) => updateMethod('push', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-3">
                    <Mail className="h-5 w-5 text-green-600" />
                    <div>
                      <span className="font-medium">Email</span>
                      <p className="text-sm text-gray-600">Receive reminders via email</p>
                    </div>
                  </div>
                  <Switch
                    checked={preferences.preferredMethods.includes('email')}
                    onCheckedChange={(checked) => updateMethod('email', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-3">
                    <MessageSquare className="h-5 w-5 text-purple-600" />
                    <div>
                      <span className="font-medium">SMS</span>
                      <p className="text-sm text-gray-600">Receive text message reminders</p>
                    </div>
                  </div>
                  <Switch
                    checked={preferences.preferredMethods.includes('sms')}
                    onCheckedChange={(checked) => updateMethod('sms', checked)}
                  />
                </div>

                <div className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-3">
                    <Smartphone className="h-5 w-5 text-orange-600" />
                    <div>
                      <span className="font-medium">In-App</span>
                      <p className="text-sm text-gray-600">Show notifications within the app</p>
                    </div>
                  </div>
                  <Switch
                    checked={preferences.preferredMethods.includes('inApp')}
                    onCheckedChange={(checked) => updateMethod('inApp', checked)}
                  />
                </div>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Reminder Timing */}
        <TabsContent value="timing">
          <Card>
            <CardHeader>
              <CardTitle>Reminder Timing</CardTitle>
              <CardDescription>
                Choose when to receive appointment reminders
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-6">
              <div>
                <h4 className="font-medium mb-3">Appointment Reminders</h4>
                <div className="grid grid-cols-2 md:grid-cols-3 gap-3">
                  {timingOptions.map((option) => (
                    <div key={option.hours} className="flex items-center space-x-2">
                      <input
                        type="checkbox"
                        id={`timing-${option.hours}`}
                        checked={preferences.reminderTiming.appointment.includes(option.hours)}
                        onChange={(e) => updateReminderTiming(option.hours, e.target.checked)}
                        className="rounded border-gray-300"
                      />
                      <label htmlFor={`timing-${option.hours}`} className="text-sm">
                        {option.label}
                      </label>
                    </div>
                  ))}
                </div>
              </div>

              <Alert>
                <Clock className="h-4 w-4" />
                <AlertDescription>
                  Selected timing: {preferences.reminderTiming.appointment.length > 0 
                    ? preferences.reminderTiming.appointment
                        .sort((a, b) => b - a)
                        .map(h => h >= 1 ? `${h}h` : '30m')
                        .join(', ') + ' before appointment'
                    : 'No reminders selected'}
                </AlertDescription>
              </Alert>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Advanced Settings */}
        <TabsContent value="advanced">
          <div className="space-y-6">
            {/* Quiet Hours */}
            <Card>
              <CardHeader>
                <CardTitle>Quiet Hours</CardTitle>
                <CardDescription>
                  Avoid sending reminders during specified hours
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <Moon className="h-4 w-4 text-indigo-600" />
                    <span className="font-medium">Enable Quiet Hours</span>
                  </div>
                  <Switch
                    checked={preferences.quietHoursEnabled}
                    onCheckedChange={(checked) => updatePreference('quietHoursEnabled', checked)}
                  />
                </div>

                {preferences.quietHoursEnabled && (
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium mb-1">Start Time</label>
                      <select
                        value={preferences.quietHoursStart}
                        onChange={(e) => updatePreference('quietHoursStart', parseInt(e.target.value))}
                        className="w-full p-2 border rounded-md"
                      >
                        {Array.from({ length: 24 }, (_, i) => (
                          <option key={i} value={i}>
                            {i.toString().padStart(2, '0')}:00
                          </option>
                        ))}
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium mb-1">End Time</label>
                      <select
                        value={preferences.quietHoursEnd}
                        onChange={(e) => updatePreference('quietHoursEnd', parseInt(e.target.value))}
                        className="w-full p-2 border rounded-md"
                      >
                        {Array.from({ length: 24 }, (_, i) => (
                          <option key={i} value={i}>
                            {i.toString().padStart(2, '0')}:00
                          </option>
                        ))}
                      </select>
                    </div>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Active Days */}
            <Card>
              <CardHeader>
                <CardTitle>Active Days</CardTitle>
                <CardDescription>
                  Select days when you want to receive reminders
                </CardDescription>
              </CardHeader>
              <CardContent>
                <div className="flex flex-wrap gap-2">
                  {dayNames.map((day, index) => {
                    const dayIndex = index + 1;
                    const isSelected = preferences.enabledDays.includes(dayIndex);
                    
                    return (
                      <Badge
                        key={day}
                        variant={isSelected ? "default" : "outline"}
                        className={`cursor-pointer ${isSelected ? 'bg-blue-600' : ''}`}
                        onClick={() => updateEnabledDay(dayIndex, !isSelected)}
                      >
                        {day}
                      </Badge>
                    );
                  })}
                </div>
              </CardContent>
            </Card>

            {/* Other Settings */}
            <Card>
              <CardHeader>
                <CardTitle>Other Settings</CardTitle>
                <CardDescription>
                  Additional reminder configuration options
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="font-medium">Timezone</span>
                    <p className="text-sm text-gray-600">{preferences.timezone}</p>
                  </div>
                  <Button variant="outline" size="sm">
                    Change
                  </Button>
                </div>

                <div className="flex items-center justify-between">
                  <div>
                    <span className="font-medium">Test Notifications</span>
                    <p className="text-sm text-gray-600">Send a test reminder to verify settings</p>
                  </div>
                  <Button variant="outline" size="sm" onClick={sendTestNotification}>
                    <Bell className="h-4 w-4 mr-1" />
                    Test
                  </Button>
                </div>

                <div className="flex items-center justify-between">
                  <div>
                    <span className="font-medium">Reset to Defaults</span>
                    <p className="text-sm text-gray-600">Restore default reminder settings</p>
                  </div>
                  <Button variant="outline" size="sm" onClick={resetToDefaults}>
                    <RotateCcw className="h-4 w-4 mr-1" />
                    Reset
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>
        </TabsContent>
      </Tabs>
    </div>
  );
}

