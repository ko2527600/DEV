import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Switch } from '@/components/ui/switch';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Calendar, 
  Clock, 
  Coffee, 
  Plus, 
  Trash2, 
  Eye, 
  Save,
  Info,
  Settings
} from 'lucide-react';
import { collection, doc, setDoc, getDocs, query, where } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function AvailabilityManagement() {
  const { currentUser, userProfile } = useAuth();
  const [weeklySchedule, setWeeklySchedule] = useState({});
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const daysOfWeek = [
    { key: 'monday', label: 'Monday' },
    { key: 'tuesday', label: 'Tuesday' },
    { key: 'wednesday', label: 'Wednesday' },
    { key: 'thursday', label: 'Thursday' },
    { key: 'friday', label: 'Friday' },
    { key: 'saturday', label: 'Saturday' },
    { key: 'sunday', label: 'Sunday' }
  ];

  const timeOptions = [
    '06:00', '07:00', '08:00', '09:00', '10:00', '11:00',
    '12:00', '13:00', '14:00', '15:00', '16:00', '17:00',
    '18:00', '19:00', '20:00', '21:00', '22:00'
  ];

  useEffect(() => {
    if (currentUser && userProfile?.role === 'doctor') {
      loadCurrentAvailability();
    }
  }, [currentUser, userProfile]);

  const loadCurrentAvailability = async () => {
    setLoading(true);
    try {
      const q = query(
        collection(db, 'doctor_availability'),
        where('doctorId', '==', currentUser.uid),
        where('isActive', '==', true)
      );
      
      const snapshot = await getDocs(q);
      const availabilities = {};
      
      // Initialize default schedule
      daysOfWeek.forEach(day => {
        availabilities[day.key] = {
          id: `${currentUser.uid}_${day.key}`,
          doctorId: currentUser.uid,
          dayOfWeek: day.key,
          startTime: '09:00',
          endTime: '17:00',
          breakTimes: ['12:00-13:00'],
          slotDuration: 30,
          isActive: day.key !== 'saturday' && day.key !== 'sunday'
        };
      });

      // Override with existing data
      snapshot.docs.forEach(doc => {
        const data = doc.data();
        availabilities[data.dayOfWeek] = data;
      });

      setWeeklySchedule(availabilities);
    } catch (error) {
      console.error('Error loading availability:', error);
    } finally {
      setLoading(false);
    }
  };

  const saveAvailability = async () => {
    setSaving(true);
    try {
      const promises = Object.values(weeklySchedule).map(availability => 
        setDoc(doc(db, 'doctor_availability', availability.id), availability)
      );
      
      await Promise.all(promises);
      alert('Availability updated successfully!');
    } catch (error) {
      console.error('Error saving availability:', error);
      alert('Error saving availability. Please try again.');
    } finally {
      setSaving(false);
    }
  };

  const updateDayAvailability = (day, updates) => {
    setWeeklySchedule(prev => ({
      ...prev,
      [day]: {
        ...prev[day],
        ...updates
      }
    }));
  };

  const addBreakTime = (day, startTime, endTime) => {
    const breakTime = `${startTime}-${endTime}`;
    const current = weeklySchedule[day];
    updateDayAvailability(day, {
      breakTimes: [...current.breakTimes, breakTime]
    });
  };

  const removeBreakTime = (day, breakTime) => {
    const current = weeklySchedule[day];
    updateDayAvailability(day, {
      breakTimes: current.breakTimes.filter(bt => bt !== breakTime)
    });
  };

  const generateTimeSlots = (availability) => {
    if (!availability.isActive) return [];

    const slots = [];
    const start = parseTime(availability.startTime);
    const end = parseTime(availability.endTime);
    
    let current = new Date(start);
    while (current < end) {
      const timeString = formatTime(current);
      
      // Check if this time conflicts with break times
      const isBreakTime = availability.breakTimes.some(breakTime => {
        const [breakStart, breakEnd] = breakTime.split('-');
        const breakStartTime = parseTime(breakStart);
        const breakEndTime = parseTime(breakEnd);
        return current >= breakStartTime && current < breakEndTime;
      });
      
      if (!isBreakTime) {
        slots.push(timeString);
      }
      
      current = new Date(current.getTime() + availability.slotDuration * 60000);
    }
    
    return slots;
  };

  const parseTime = (timeString) => {
    const [hours, minutes] = timeString.split(':').map(Number);
    const date = new Date();
    date.setHours(hours, minutes, 0, 0);
    return date;
  };

  const formatTime = (date) => {
    return date.toTimeString().slice(0, 5);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Manage Availability</h1>
          <p className="text-gray-600">Set your weekly schedule and appointment preferences</p>
        </div>
        <Button onClick={saveAvailability} disabled={saving}>
          {saving ? (
            <>
              <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
              Saving...
            </>
          ) : (
            <>
              <Save className="h-4 w-4 mr-2" />
              Save Changes
            </>
          )}
        </Button>
      </div>

      {/* Info Alert */}
      <Alert>
        <Info className="h-4 w-4" />
        <AlertDescription>
          Set your weekly availability to let patients know when you're available for appointments. 
          Patients will only see and book available time slots.
        </AlertDescription>
      </Alert>

      {/* Weekly Schedule */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {daysOfWeek.map(day => (
          <DayAvailabilityCard
            key={day.key}
            day={day}
            availability={weeklySchedule[day.key]}
            timeOptions={timeOptions}
            onUpdate={(updates) => updateDayAvailability(day.key, updates)}
            onAddBreakTime={(start, end) => addBreakTime(day.key, start, end)}
            onRemoveBreakTime={(breakTime) => removeBreakTime(day.key, breakTime)}
            generateTimeSlots={generateTimeSlots}
          />
        ))}
      </div>
    </div>
  );
}

function DayAvailabilityCard({ 
  day, 
  availability, 
  timeOptions, 
  onUpdate, 
  onAddBreakTime, 
  onRemoveBreakTime,
  generateTimeSlots 
}) {
  const [showBreakDialog, setShowBreakDialog] = useState(false);
  const [breakStart, setBreakStart] = useState('12:00');
  const [breakEnd, setBreakEnd] = useState('13:00');
  const [showPreview, setShowPreview] = useState(false);

  const handleAddBreak = () => {
    onAddBreakTime(breakStart, breakEnd);
    setShowBreakDialog(false);
    setBreakStart('12:00');
    setBreakEnd('13:00');
  };

  return (
    <Card>
      <CardHeader>
        <div className="flex items-center justify-between">
          <CardTitle className="flex items-center space-x-2">
            <Calendar className="h-5 w-5" />
            <span>{day.label}</span>
          </CardTitle>
          <Switch
            checked={availability?.isActive || false}
            onCheckedChange={(checked) => onUpdate({ isActive: checked })}
          />
        </div>
      </CardHeader>
      
      <CardContent className="space-y-4">
        {availability?.isActive ? (
          <>
            {/* Working Hours */}
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Start Time</Label>
                <Select 
                  value={availability.startTime} 
                  onValueChange={(value) => onUpdate({ startTime: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {timeOptions.map(time => (
                      <SelectItem key={time} value={time}>{time}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
              
              <div className="space-y-2">
                <Label>End Time</Label>
                <Select 
                  value={availability.endTime} 
                  onValueChange={(value) => onUpdate({ endTime: value })}
                >
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {timeOptions.map(time => (
                      <SelectItem key={time} value={time}>{time}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Slot Duration */}
            <div className="space-y-2">
              <Label>Appointment Duration</Label>
              <Select 
                value={availability.slotDuration?.toString()} 
                onValueChange={(value) => onUpdate({ slotDuration: parseInt(value) })}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="15">15 minutes</SelectItem>
                  <SelectItem value="30">30 minutes</SelectItem>
                  <SelectItem value="45">45 minutes</SelectItem>
                  <SelectItem value="60">1 hour</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Break Times */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label>Break Times</Label>
                <Button 
                  variant="outline" 
                  size="sm"
                  onClick={() => setShowBreakDialog(true)}
                >
                  <Plus className="h-4 w-4 mr-1" />
                  Add Break
                </Button>
              </div>
              
              {availability.breakTimes?.length > 0 ? (
                <div className="space-y-2">
                  {availability.breakTimes.map((breakTime, index) => (
                    <div key={index} className="flex items-center justify-between p-2 bg-gray-50 rounded">
                      <div className="flex items-center space-x-2">
                        <Coffee className="h-4 w-4 text-brown-600" />
                        <span>{breakTime}</span>
                      </div>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => onRemoveBreakTime(breakTime)}
                      >
                        <Trash2 className="h-4 w-4 text-red-500" />
                      </Button>
                    </div>
                  ))}
                </div>
              ) : (
                <div className="p-3 bg-gray-50 rounded text-gray-500 text-sm">
                  No break times set
                </div>
              )}
            </div>

            {/* Preview Time Slots */}
            <div className="space-y-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowPreview(!showPreview)}
                className="w-full"
              >
                <Eye className="h-4 w-4 mr-2" />
                {showPreview ? 'Hide' : 'Preview'} Time Slots
              </Button>
              
              {showPreview && (
                <div className="p-3 bg-blue-50 rounded">
                  <div className="flex flex-wrap gap-2">
                    {generateTimeSlots(availability).map((slot, index) => (
                      <Badge key={index} variant="secondary" className="bg-green-100 text-green-800">
                        {slot}
                      </Badge>
                    ))}
                  </div>
                  {generateTimeSlots(availability).length === 0 && (
                    <p className="text-gray-500 text-sm">No available time slots</p>
                  )}
                </div>
              )}
            </div>

            {/* Break Time Dialog */}
            {showBreakDialog && (
              <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
                <div className="bg-white p-6 rounded-lg max-w-md w-full mx-4">
                  <h3 className="text-lg font-semibold mb-4">Add Break Time</h3>
                  
                  <div className="grid grid-cols-2 gap-4 mb-4">
                    <div className="space-y-2">
                      <Label>Start Time</Label>
                      <Select value={breakStart} onValueChange={setBreakStart}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {timeOptions.map(time => (
                            <SelectItem key={time} value={time}>{time}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                    
                    <div className="space-y-2">
                      <Label>End Time</Label>
                      <Select value={breakEnd} onValueChange={setBreakEnd}>
                        <SelectTrigger>
                          <SelectValue />
                        </SelectTrigger>
                        <SelectContent>
                          {timeOptions.map(time => (
                            <SelectItem key={time} value={time}>{time}</SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                    </div>
                  </div>
                  
                  <div className="flex space-x-2">
                    <Button variant="outline" onClick={() => setShowBreakDialog(false)}>
                      Cancel
                    </Button>
                    <Button onClick={handleAddBreak}>
                      Add Break
                    </Button>
                  </div>
                </div>
              </div>
            )}
          </>
        ) : (
          <div className="p-4 bg-gray-50 rounded text-center text-gray-500">
            <Settings className="h-8 w-8 mx-auto mb-2 text-gray-400" />
            <p>Not available on this day</p>
          </div>
        )}
      </CardContent>
    </Card>
  );
}

