import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Repeat, 
  Play, 
  Pause, 
  Calendar, 
  MoreHorizontal,
  Plus,
  RefreshCw,
  Clock,
  User,
  Settings
} from 'lucide-react';
import { collection, query, where, onSnapshot, doc, updateDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function RecurringAppointments() {
  const { currentUser } = useAuth();
  const [recurringAppointments, setRecurringAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTab, setSelectedTab] = useState('all');

  useEffect(() => {
    if (!currentUser) return;

    const q = query(
      collection(db, 'recurring_appointments'),
      where('patientId', '==', currentUser.uid)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const appointmentData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setRecurringAppointments(appointmentData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [currentUser]);

  const getFilteredAppointments = () => {
    switch (selectedTab) {
      case 'active':
        return recurringAppointments.filter(apt => apt.status === 'active');
      case 'paused':
        return recurringAppointments.filter(apt => apt.status === 'paused');
      case 'completed':
        return recurringAppointments.filter(apt => apt.status === 'completed');
      case 'cancelled':
        return recurringAppointments.filter(apt => apt.status === 'cancelled');
      default:
        return recurringAppointments;
    }
  };

  const getStatistics = () => {
    const total = recurringAppointments.length;
    const active = recurringAppointments.filter(apt => apt.status === 'active').length;
    const paused = recurringAppointments.filter(apt => apt.status === 'paused').length;
    const completed = recurringAppointments.filter(apt => apt.status === 'completed').length;
    const cancelled = recurringAppointments.filter(apt => apt.status === 'cancelled').length;

    return { total, active, paused, completed, cancelled };
  };

  const pauseAppointment = async (appointmentId, reason) => {
    try {
      await updateDoc(doc(db, 'recurring_appointments', appointmentId), {
        status: 'paused',
        reason: reason,
        pausedAt: serverTimestamp()
      });
    } catch (error) {
      console.error('Error pausing appointment:', error);
    }
  };

  const resumeAppointment = async (appointmentId) => {
    try {
      await updateDoc(doc(db, 'recurring_appointments', appointmentId), {
        status: 'active',
        reason: null,
        resumedAt: serverTimestamp()
      });
    } catch (error) {
      console.error('Error resuming appointment:', error);
    }
  };

  const cancelAppointment = async (appointmentId, reason) => {
    try {
      await updateDoc(doc(db, 'recurring_appointments', appointmentId), {
        status: 'cancelled',
        reason: reason,
        cancelledAt: serverTimestamp()
      });
    } catch (error) {
      console.error('Error cancelling appointment:', error);
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active': return 'bg-green-100 text-green-800';
      case 'paused': return 'bg-yellow-100 text-yellow-800';
      case 'completed': return 'bg-blue-100 text-blue-800';
      case 'cancelled': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getRecurrenceDescription = (appointment) => {
    const { recurrenceType, recurrenceInterval, daysOfWeek } = appointment;
    
    switch (recurrenceType) {
      case 'daily':
        return recurrenceInterval === 1 ? 'Daily' : `Every ${recurrenceInterval} days`;
      case 'weekly':
        if (daysOfWeek && daysOfWeek.length > 0) {
          const dayNames = daysOfWeek.map(day => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][day - 1]);
          return `Weekly on ${dayNames.join(', ')}`;
        }
        return recurrenceInterval === 1 ? 'Weekly' : `Every ${recurrenceInterval} weeks`;
      case 'biweekly':
        return recurrenceInterval === 1 ? 'Every 2 weeks' : `Every ${recurrenceInterval * 2} weeks`;
      case 'monthly':
        return recurrenceInterval === 1 ? 'Monthly' : `Every ${recurrenceInterval} months`;
      default:
        return 'Custom pattern';
    }
  };

  const getEndDescription = (appointment) => {
    const { endType, maxOccurrences, endDate } = appointment;
    
    switch (endType) {
      case 'never':
        return 'Never ends';
      case 'afterOccurrences':
        return `After ${maxOccurrences} appointments`;
      case 'onDate':
        return `Ends on ${new Date(endDate.seconds * 1000).toLocaleDateString()}`;
      default:
        return 'Unknown';
    }
  };

  const filteredAppointments = getFilteredAppointments();
  const stats = getStatistics();

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
          <h1 className="text-3xl font-bold text-gray-900">Recurring Appointments</h1>
          <p className="text-gray-600">Manage your regular appointment schedules</p>
        </div>
        <div className="flex space-x-2">
          <Button variant="outline" onClick={() => window.location.reload()}>
            <RefreshCw className="h-4 w-4 mr-2" />
            Refresh
          </Button>
          <Button>
            <Plus className="h-4 w-4 mr-2" />
            Create Recurring
          </Button>
        </div>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-blue-100 rounded-full p-2">
                <Repeat className="h-4 w-4 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-blue-600">{stats.total}</p>
                <p className="text-sm text-gray-600">Total</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-green-100 rounded-full p-2">
                <Play className="h-4 w-4 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-green-600">{stats.active}</p>
                <p className="text-sm text-gray-600">Active</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-yellow-100 rounded-full p-2">
                <Pause className="h-4 w-4 text-yellow-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-yellow-600">{stats.paused}</p>
                <p className="text-sm text-gray-600">Paused</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-blue-100 rounded-full p-2">
                <Calendar className="h-4 w-4 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-blue-600">{stats.completed}</p>
                <p className="text-sm text-gray-600">Completed</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-red-100 rounded-full p-2">
                <Settings className="h-4 w-4 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-red-600">{stats.cancelled}</p>
                <p className="text-sm text-gray-600">Cancelled</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Appointments List */}
      <Card>
        <CardHeader>
          <CardTitle>Your Recurring Appointments</CardTitle>
          <CardDescription>
            Manage your regular appointment schedules and patterns
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={selectedTab} onValueChange={setSelectedTab}>
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="all">All ({stats.total})</TabsTrigger>
              <TabsTrigger value="active">Active ({stats.active})</TabsTrigger>
              <TabsTrigger value="paused">Paused ({stats.paused})</TabsTrigger>
              <TabsTrigger value="completed">Completed ({stats.completed})</TabsTrigger>
              <TabsTrigger value="cancelled">Cancelled ({stats.cancelled})</TabsTrigger>
            </TabsList>

            <TabsContent value={selectedTab} className="mt-6">
              {filteredAppointments.length === 0 ? (
                <div className="text-center py-12">
                  <Repeat className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No recurring appointments found</h3>
                  <p className="text-gray-600 mb-4">Set up recurring appointments for regular check-ups.</p>
                  <Button>
                    <Plus className="h-4 w-4 mr-2" />
                    Create Recurring Appointment
                  </Button>
                </div>
              ) : (
                <div className="space-y-4">
                  {filteredAppointments.map((appointment) => (
                    <Card key={appointment.id} className="border-l-4" style={{
                      borderLeftColor: appointment.status === 'active' ? '#10b981' :
                                      appointment.status === 'paused' ? '#f59e0b' :
                                      appointment.status === 'completed' ? '#3b82f6' : '#ef4444'
                    }}>
                      <CardContent className="p-6">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-3 mb-3">
                              <div className="flex items-center space-x-2">
                                <User className="h-5 w-5 text-gray-500" />
                                <h3 className="text-lg font-semibold">{appointment.doctorName}</h3>
                              </div>
                              <Badge className={getStatusColor(appointment.status)}>
                                {appointment.status?.toUpperCase()}
                              </Badge>
                            </div>

                            <p className="text-gray-600 mb-3">
                              <strong>Specialization:</strong> {appointment.specialization}
                            </p>

                            <div className="bg-blue-50 p-4 rounded-lg mb-4">
                              <div className="flex items-center space-x-2 mb-2">
                                <Repeat className="h-4 w-4 text-blue-600" />
                                <span className="font-medium text-blue-800">Recurring Pattern</span>
                              </div>
                              <div className="grid grid-cols-1 md:grid-cols-3 gap-2 text-sm">
                                <div>
                                  <span className="font-medium">Pattern:</span> {getRecurrenceDescription(appointment)}
                                </div>
                                <div>
                                  <span className="font-medium">Time:</span> {appointment.timeSlot}
                                </div>
                                <div>
                                  <span className="font-medium">End:</span> {getEndDescription(appointment)}
                                </div>
                              </div>
                              {appointment.generatedCount > 0 && (
                                <div className="mt-2 text-sm text-blue-700">
                                  <span className="font-medium">Generated:</span> {appointment.generatedCount} appointments
                                </div>
                              )}
                            </div>

                            <div className="flex space-x-2">
                              {appointment.status === 'active' && (
                                <Button 
                                  size="sm" 
                                  variant="outline"
                                  onClick={() => {
                                    const reason = prompt('Why are you pausing this recurring appointment?');
                                    if (reason) pauseAppointment(appointment.id, reason);
                                  }}
                                >
                                  <Pause className="h-4 w-4 mr-1" />
                                  Pause
                                </Button>
                              )}
                              
                              {appointment.status === 'paused' && (
                                <Button 
                                  size="sm" 
                                  onClick={() => resumeAppointment(appointment.id)}
                                >
                                  <Play className="h-4 w-4 mr-1" />
                                  Resume
                                </Button>
                              )}

                              <Button variant="outline" size="sm">
                                <Calendar className="h-4 w-4 mr-1" />
                                View Upcoming
                              </Button>

                              <Button variant="outline" size="sm">
                                <MoreHorizontal className="h-4 w-4 mr-1" />
                                Options
                              </Button>
                            </div>
                          </div>

                          <div className="text-right">
                            <p className="text-sm text-gray-500">
                              Created: {new Date(appointment.createdAt.seconds * 1000).toLocaleDateString()}
                            </p>
                            {appointment.reason && (
                              <p className="text-sm text-gray-600 mt-1">
                                <strong>Reason:</strong> {appointment.reason}
                              </p>
                            )}
                          </div>
                        </div>
                      </CardContent>
                    </Card>
                  ))}
                </div>
              )}
            </TabsContent>
          </Tabs>
        </CardContent>
      </Card>

      {/* Info Alert */}
      <Alert>
        <Clock className="h-4 w-4" />
        <AlertDescription>
          Recurring appointments automatically generate individual appointments based on your pattern. 
          You can pause, resume, or cancel the recurring schedule at any time.
        </AlertDescription>
      </Alert>
    </div>
  );
}

