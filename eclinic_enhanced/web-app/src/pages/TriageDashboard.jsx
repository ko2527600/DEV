import { useState, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  AlertTriangle, 
  Clock, 
  CheckCircle, 
  Eye, 
  Calendar,
  TrendingUp,
  Users,
  Activity,
  Star,
  RefreshCw
} from 'lucide-react';
import { collection, query, where, onSnapshot, doc, updateDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function TriageDashboard() {
  const { currentUser, userProfile } = useAuth();
  const [appointments, setAppointments] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedTab, setSelectedTab] = useState('all');

  useEffect(() => {
    if (!currentUser || userProfile?.role !== 'doctor') return;

    const q = query(
      collection(db, 'appointments'),
      where('doctorId', '==', currentUser.uid)
    );

    const unsubscribe = onSnapshot(q, (snapshot) => {
      const appointmentData = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));
      setAppointments(appointmentData);
      setLoading(false);
    });

    return () => unsubscribe();
  }, [currentUser, userProfile]);

  const getFilteredAppointments = () => {
    switch (selectedTab) {
      case 'urgent':
        return appointments.filter(apt => apt.urgency === 'high' || apt.urgency === 'urgent');
      case 'priority':
        return appointments.filter(apt => apt.urgency === 'medium' || apt.urgency === 'priority');
      case 'routine':
        return appointments.filter(apt => apt.urgency === 'low' || apt.urgency === 'routine');
      case 'pending':
        return appointments.filter(apt => apt.status === 'pending');
      default:
        return appointments;
    }
  };

  const getStatistics = () => {
    const urgent = appointments.filter(apt => apt.urgency === 'high' || apt.urgency === 'urgent').length;
    const priority = appointments.filter(apt => apt.urgency === 'medium' || apt.urgency === 'priority').length;
    const routine = appointments.filter(apt => apt.urgency === 'low' || apt.urgency === 'routine').length;
    const pending = appointments.filter(apt => apt.status === 'pending').length;

    return { urgent, priority, routine, pending };
  };

  const acceptAppointment = async (appointmentId) => {
    try {
      await updateDoc(doc(db, 'appointments', appointmentId), {
        status: 'confirmed',
        confirmedAt: new Date()
      });
    } catch (error) {
      console.error('Error accepting appointment:', error);
    }
  };

  const getUrgencyColor = (urgency) => {
    switch (urgency?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return 'bg-red-100 text-red-800';
      case 'medium':
      case 'priority':
        return 'bg-yellow-100 text-yellow-800';
      case 'low':
      case 'routine':
        return 'bg-green-100 text-green-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getUrgencyScore = (urgency) => {
    switch (urgency?.toLowerCase()) {
      case 'high':
      case 'urgent':
        return 5;
      case 'medium':
      case 'priority':
        return 3;
      case 'low':
      case 'routine':
        return 1;
      default:
        return 2;
    }
  };

  const getScoreColor = (score) => {
    if (score >= 4) return 'text-red-600';
    if (score >= 3) return 'text-yellow-600';
    return 'text-green-600';
  };

  const sortedAppointments = getFilteredAppointments().sort((a, b) => {
    const aScore = getUrgencyScore(a.urgency);
    const bScore = getUrgencyScore(b.urgency);
    return bScore - aScore;
  });

  const stats = getStatistics();

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Triage Dashboard</h1>
          <p className="text-gray-600">AI-powered appointment prioritization and management</p>
        </div>
        <Button variant="outline" onClick={() => window.location.reload()}>
          <RefreshCw className="h-4 w-4 mr-2" />
          Refresh
        </Button>
      </div>

      {/* Statistics Cards */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-red-100 rounded-full p-2">
                <AlertTriangle className="h-4 w-4 text-red-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-red-600">{stats.urgent}</p>
                <p className="text-sm text-gray-600">Urgent</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-yellow-100 rounded-full p-2">
                <Clock className="h-4 w-4 text-yellow-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-yellow-600">{stats.priority}</p>
                <p className="text-sm text-gray-600">Priority</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-green-100 rounded-full p-2">
                <CheckCircle className="h-4 w-4 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-green-600">{stats.routine}</p>
                <p className="text-sm text-gray-600">Routine</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <div className="bg-blue-100 rounded-full p-2">
                <Users className="h-4 w-4 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-blue-600">{stats.pending}</p>
                <p className="text-sm text-gray-600">Pending</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Appointments List */}
      <Card>
        <CardHeader>
          <CardTitle>Appointment Queue</CardTitle>
          <CardDescription>
            Appointments sorted by AI triage priority. Urgent cases appear first.
          </CardDescription>
        </CardHeader>
        <CardContent>
          <Tabs value={selectedTab} onValueChange={setSelectedTab}>
            <TabsList className="grid w-full grid-cols-5">
              <TabsTrigger value="all">All ({appointments.length})</TabsTrigger>
              <TabsTrigger value="urgent">Urgent ({stats.urgent})</TabsTrigger>
              <TabsTrigger value="priority">Priority ({stats.priority})</TabsTrigger>
              <TabsTrigger value="routine">Routine ({stats.routine})</TabsTrigger>
              <TabsTrigger value="pending">Pending ({stats.pending})</TabsTrigger>
            </TabsList>

            <TabsContent value={selectedTab} className="mt-6">
              {sortedAppointments.length === 0 ? (
                <div className="text-center py-12">
                  <Activity className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                  <h3 className="text-lg font-medium text-gray-900 mb-2">No appointments found</h3>
                  <p className="text-gray-600">Appointments will appear here when patients book them.</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {sortedAppointments.map((appointment) => (
                    <Card key={appointment.id} className="border-l-4" style={{
                      borderLeftColor: appointment.urgency === 'high' || appointment.urgency === 'urgent' ? '#ef4444' :
                                      appointment.urgency === 'medium' || appointment.urgency === 'priority' ? '#f59e0b' : '#10b981'
                    }}>
                      <CardContent className="p-6">
                        <div className="flex items-start justify-between">
                          <div className="flex-1">
                            <div className="flex items-center space-x-3 mb-3">
                              <h3 className="text-lg font-semibold">Patient ID: {appointment.patientId}</h3>
                              <Badge className={getUrgencyColor(appointment.urgency)}>
                                {appointment.urgency?.toUpperCase() || 'MEDIUM'}
                              </Badge>
                              {appointment.triageData?.urgencyScore && (
                                <div className="flex items-center space-x-1">
                                  <Star className={`h-4 w-4 ${getScoreColor(appointment.triageData.urgencyScore)}`} />
                                  <span className={`text-sm font-medium ${getScoreColor(appointment.triageData.urgencyScore)}`}>
                                    {appointment.triageData.urgencyScore}/5
                                  </span>
                                </div>
                              )}
                            </div>

                            <p className="text-gray-600 mb-2">
                              <strong>Specialization:</strong> {appointment.specialization || 'General Practice'}
                            </p>

                            {appointment.symptoms && (
                              <div className="mb-4">
                                <p className="text-sm font-medium text-gray-700 mb-1">Symptoms:</p>
                                <p className="text-gray-600">{appointment.symptoms}</p>
                              </div>
                            )}

                            {appointment.triageData && (
                              <div className="bg-blue-50 p-4 rounded-lg mb-4">
                                <h4 className="font-medium text-blue-800 mb-2">AI Triage Assessment:</h4>
                                <div className="grid grid-cols-1 md:grid-cols-3 gap-2 text-sm">
                                  {appointment.triageData.priority && (
                                    <div>
                                      <span className="font-medium">Priority:</span> {appointment.triageData.priority}
                                    </div>
                                  )}
                                  {appointment.triageData.recommendedTimeframe && (
                                    <div>
                                      <span className="font-medium">Timeframe:</span> {appointment.triageData.recommendedTimeframe}
                                    </div>
                                  )}
                                  {appointment.triageData.suggestedSpecialist && (
                                    <div>
                                      <span className="font-medium">Specialist:</span> {appointment.triageData.suggestedSpecialist}
                                    </div>
                                  )}
                                </div>
                                {appointment.triageData.notes && (
                                  <p className="text-blue-700 text-sm mt-2">{appointment.triageData.notes}</p>
                                )}
                              </div>
                            )}

                            <div className="flex space-x-2">
                              <Button 
                                size="sm" 
                                onClick={() => acceptAppointment(appointment.id)}
                                disabled={appointment.status === 'confirmed'}
                              >
                                <CheckCircle className="h-4 w-4 mr-1" />
                                {appointment.status === 'confirmed' ? 'Accepted' : 'Accept'}
                              </Button>
                              <Button variant="outline" size="sm">
                                <Eye className="h-4 w-4 mr-1" />
                                View Details
                              </Button>
                              <Button variant="outline" size="sm">
                                <Calendar className="h-4 w-4 mr-1" />
                                Reschedule
                              </Button>
                            </div>
                          </div>

                          <div className="text-right">
                            <p className="text-sm text-gray-500">
                              {appointment.requestedDate && new Date(appointment.requestedDate.seconds * 1000).toLocaleDateString()}
                            </p>
                            <Badge variant="outline" className="mt-1">
                              {appointment.status}
                            </Badge>
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

      {/* AI Insights */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center space-x-2">
            <TrendingUp className="h-5 w-5" />
            <span>AI Insights</span>
          </CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Alert>
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>
                <strong>High Priority Cases:</strong> {stats.urgent} urgent appointments require immediate attention.
              </AlertDescription>
            </Alert>
            <Alert>
              <Clock className="h-4 w-4" />
              <AlertDescription>
                <strong>Workload Distribution:</strong> {stats.priority} priority cases can be scheduled within 3 days.
              </AlertDescription>
            </Alert>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

