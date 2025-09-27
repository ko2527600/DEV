import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Avatar, AvatarFallback } from '@/components/ui/avatar';
import { 
  User, 
  Heart, 
  AlertTriangle, 
  Pill, 
  FileText,
  Download,
  Edit,
  Plus,
  Phone,
  Mail,
  MapPin,
  Shield,
  Calendar,
  Activity,
  TrendingUp,
  TrendingDown,
  Minus
} from 'lucide-react';
import { doc, getDoc, collection, query, where, orderBy, getDocs, limit } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function PatientEHR() {
  const { patientId } = useParams();
  const { currentUser } = useAuth();
  
  const [patient, setPatient] = useState(null);
  const [patientSummary, setPatientSummary] = useState(null);
  const [loading, setLoading] = useState(true);
  const [activeTab, setActiveTab] = useState('overview');
  
  const isDoctor = currentUser?.role === 'doctor';

  useEffect(() => {
    loadPatientData();
  }, [patientId]);

  const loadPatientData = async () => {
    try {
      // Load patient profile
      const patientDoc = await getDoc(doc(db, 'patient_profiles', patientId));
      if (patientDoc.exists()) {
        setPatient({ id: patientDoc.id, ...patientDoc.data() });
      }

      // Load patient summary data
      const summary = await loadPatientSummary(patientId);
      setPatientSummary(summary);
    } catch (error) {
      console.error('Error loading patient data:', error);
    } finally {
      setLoading(false);
    }
  };

  const loadPatientSummary = async (patientId) => {
    try {
      // Load allergies
      const allergiesQuery = query(
        collection(db, 'allergies'),
        where('patientId', '==', patientId),
        where('isActive', '==', true)
      );
      const allergiesSnapshot = await getDocs(allergiesQuery);
      const allergies = allergiesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // Load active diagnoses
      const diagnosesQuery = query(
        collection(db, 'diagnoses'),
        where('patientId', '==', patientId),
        where('status', 'in', ['active', 'chronic'])
      );
      const diagnosesSnapshot = await getDocs(diagnosesQuery);
      const activeDiagnoses = diagnosesSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // Load active medications
      const medicationsQuery = query(
        collection(db, 'medications'),
        where('patientId', '==', patientId),
        where('status', '==', 'active')
      );
      const medicationsSnapshot = await getDocs(medicationsQuery);
      const activeMedications = medicationsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      // Load latest vital signs
      const vitalsQuery = query(
        collection(db, 'vital_signs'),
        where('patientId', '==', patientId),
        orderBy('recordedAt', 'desc'),
        limit(1)
      );
      const vitalsSnapshot = await getDocs(vitalsQuery);
      const latestVitals = vitalsSnapshot.docs.length > 0 
        ? { id: vitalsSnapshot.docs[0].id, ...vitalsSnapshot.docs[0].data() }
        : null;

      // Load recent medical history
      const historyQuery = query(
        collection(db, 'medical_history'),
        where('patientId', '==', patientId),
        orderBy('date', 'desc'),
        limit(5)
      );
      const historySnapshot = await getDocs(historyQuery);
      const recentHistory = historySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

      return {
        allergies,
        activeDiagnoses,
        activeMedications,
        latestVitals,
        recentHistory
      };
    } catch (error) {
      console.error('Error loading patient summary:', error);
      return {};
    }
  };

  const calculateAge = (dateOfBirth) => {
    const today = new Date();
    const birthDate = new Date(dateOfBirth.seconds * 1000);
    let age = today.getFullYear() - birthDate.getFullYear();
    const monthDiff = today.getMonth() - birthDate.getMonth();
    
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birthDate.getDate())) {
      age--;
    }
    
    return age;
  };

  const formatBloodType = (bloodType) => {
    const bloodTypeMap = {
      'aPositive': 'A+',
      'aNegative': 'A-',
      'bPositive': 'B+',
      'bNegative': 'B-',
      'abPositive': 'AB+',
      'abNegative': 'AB-',
      'oPositive': 'O+',
      'oNegative': 'O-',
      'unknown': 'Unknown'
    };
    return bloodTypeMap[bloodType] || 'Unknown';
  };

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = new Date(timestamp.seconds * 1000);
    return date.toLocaleDateString();
  };

  const getSeverityColor = (severity) => {
    switch (severity) {
      case 'mild':
        return 'bg-green-100 text-green-800';
      case 'moderate':
        return 'bg-yellow-100 text-yellow-800';
      case 'severe':
        return 'bg-red-100 text-red-800';
      case 'lifeThreatening':
        return 'bg-red-200 text-red-900';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'bg-red-100 text-red-800';
      case 'chronic':
        return 'bg-orange-100 text-orange-800';
      case 'resolved':
        return 'bg-green-100 text-green-800';
      case 'suspected':
        return 'bg-blue-100 text-blue-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  if (!patient) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Patient Not Found</h2>
          <p className="text-gray-600">The requested patient record could not be found.</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-7xl mx-auto space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div className="flex items-center space-x-4">
          <Avatar className="h-16 w-16">
            <AvatarFallback className="bg-blue-600 text-white text-xl">
              {patient.firstName?.[0]}{patient.lastName?.[0]}
            </AvatarFallback>
          </Avatar>
          <div>
            <h1 className="text-3xl font-bold text-gray-900">
              {patient.firstName} {patient.lastName}
            </h1>
            <p className="text-gray-600">
              {calculateAge(patient.dateOfBirth)} years old • {patient.gender} • Blood Type: {formatBloodType(patient.bloodType)}
            </p>
          </div>
        </div>
        
        <div className="flex space-x-2">
          {isDoctor && (
            <Button variant="outline">
              <Edit className="h-4 w-4 mr-2" />
              Edit
            </Button>
          )}
          <Button variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <AlertTriangle className="h-5 w-5 text-orange-600" />
              <div>
                <p className="text-2xl font-bold">{patientSummary?.allergies?.length || 0}</p>
                <p className="text-sm text-gray-600">Allergies</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <FileText className="h-5 w-5 text-red-600" />
              <div>
                <p className="text-2xl font-bold">{patientSummary?.activeDiagnoses?.length || 0}</p>
                <p className="text-sm text-gray-600">Active Diagnoses</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <Pill className="h-5 w-5 text-blue-600" />
              <div>
                <p className="text-2xl font-bold">{patientSummary?.activeMedications?.length || 0}</p>
                <p className="text-sm text-gray-600">Medications</p>
              </div>
            </div>
          </CardContent>
        </Card>
        
        <Card>
          <CardContent className="p-6">
            <div className="flex items-center space-x-2">
              <Heart className="h-5 w-5 text-green-600" />
              <div>
                <p className="text-2xl font-bold">
                  {patientSummary?.latestVitals ? 
                    `${Math.floor((Date.now() - patientSummary.latestVitals.recordedAt.seconds * 1000) / (1000 * 60 * 60 * 24))}d` : 
                    'None'
                  }
                </p>
                <p className="text-sm text-gray-600">Last Vitals</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Main Content */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-6">
          <TabsTrigger value="overview">Overview</TabsTrigger>
          <TabsTrigger value="vitals">Vitals</TabsTrigger>
          <TabsTrigger value="allergies">Allergies</TabsTrigger>
          <TabsTrigger value="diagnoses">Diagnoses</TabsTrigger>
          <TabsTrigger value="medications">Medications</TabsTrigger>
          <TabsTrigger value="history">History</TabsTrigger>
        </TabsList>

        {/* Overview Tab */}
        <TabsContent value="overview" className="space-y-6">
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Patient Information */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <User className="h-5 w-5" />
                  <span>Patient Information</span>
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="flex items-center space-x-2">
                  <Phone className="h-4 w-4 text-gray-500" />
                  <span className="text-sm">Phone:</span>
                  <span className="text-sm font-medium">{patient.phoneNumber || 'Not provided'}</span>
                </div>
                
                <div className="flex items-center space-x-2">
                  <Mail className="h-4 w-4 text-gray-500" />
                  <span className="text-sm">Email:</span>
                  <span className="text-sm font-medium">{patient.email || 'Not provided'}</span>
                </div>
                
                {patient.address && (
                  <div className="flex items-center space-x-2">
                    <MapPin className="h-4 w-4 text-gray-500" />
                    <span className="text-sm">Address:</span>
                    <span className="text-sm font-medium">
                      {patient.address.street}, {patient.address.city}, {patient.address.state} {patient.address.zipCode}
                    </span>
                  </div>
                )}
                
                {patient.insuranceProvider && (
                  <div className="flex items-center space-x-2">
                    <Shield className="h-4 w-4 text-gray-500" />
                    <span className="text-sm">Insurance:</span>
                    <span className="text-sm font-medium">{patient.insuranceProvider}</span>
                  </div>
                )}
                
                {patient.emergencyContact && (
                  <div className="mt-4 p-3 bg-gray-50 rounded-lg">
                    <h4 className="font-medium text-sm mb-2">Emergency Contact</h4>
                    <p className="text-sm">{patient.emergencyContact.name} ({patient.emergencyContact.relationship})</p>
                    <p className="text-sm text-gray-600">{patient.emergencyContact.phoneNumber}</p>
                  </div>
                )}
              </CardContent>
            </Card>

            {/* Recent Activity */}
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Activity className="h-5 w-5" />
                  <span>Recent Activity</span>
                </CardTitle>
              </CardHeader>
              <CardContent>
                {patientSummary?.recentHistory?.length > 0 ? (
                  <div className="space-y-3">
                    {patientSummary.recentHistory.slice(0, 3).map((item) => (
                      <div key={item.id} className="flex items-start space-x-3">
                        <div className="w-2 h-2 bg-blue-600 rounded-full mt-2"></div>
                        <div className="flex-1">
                          <p className="font-medium text-sm">{item.title}</p>
                          <p className="text-xs text-gray-600">{formatDate(item.date)}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                ) : (
                  <p className="text-gray-500 text-sm">No recent activity</p>
                )}
              </CardContent>
            </Card>
          </div>

          {/* Latest Vitals */}
          {patientSummary?.latestVitals && (
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center space-x-2">
                  <Heart className="h-5 w-5" />
                  <span>Latest Vital Signs</span>
                  <Badge variant="outline">{formatDate(patientSummary.latestVitals.recordedAt)}</Badge>
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                  {patientSummary.latestVitals.systolicBP && patientSummary.latestVitals.diastolicBP && (
                    <div className="text-center p-3 bg-red-50 rounded-lg">
                      <p className="text-2xl font-bold text-red-600">
                        {Math.round(patientSummary.latestVitals.systolicBP)}/{Math.round(patientSummary.latestVitals.diastolicBP)}
                      </p>
                      <p className="text-sm text-gray-600">Blood Pressure</p>
                    </div>
                  )}
                  
                  {patientSummary.latestVitals.heartRate && (
                    <div className="text-center p-3 bg-pink-50 rounded-lg">
                      <p className="text-2xl font-bold text-pink-600">
                        {Math.round(patientSummary.latestVitals.heartRate)}
                      </p>
                      <p className="text-sm text-gray-600">Heart Rate (bpm)</p>
                    </div>
                  )}
                  
                  {patientSummary.latestVitals.temperature && (
                    <div className="text-center p-3 bg-orange-50 rounded-lg">
                      <p className="text-2xl font-bold text-orange-600">
                        {patientSummary.latestVitals.temperature.toFixed(1)}°F
                      </p>
                      <p className="text-sm text-gray-600">Temperature</p>
                    </div>
                  )}
                  
                  {patientSummary.latestVitals.weight && (
                    <div className="text-center p-3 bg-blue-50 rounded-lg">
                      <p className="text-2xl font-bold text-blue-600">
                        {patientSummary.latestVitals.weight.toFixed(1)} kg
                      </p>
                      <p className="text-sm text-gray-600">Weight</p>
                    </div>
                  )}
                </div>
              </CardContent>
            </Card>
          )}
        </TabsContent>

        {/* Vitals Tab */}
        <TabsContent value="vitals">
          <Card>
            <CardHeader>
              <CardTitle>Vital Signs History</CardTitle>
              <CardDescription>Track patient's vital signs over time</CardDescription>
            </CardHeader>
            <CardContent>
              <p className="text-gray-500">Vitals chart and history would be displayed here</p>
              {/* TODO: Implement vitals chart and history */}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Allergies Tab */}
        <TabsContent value="allergies">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Allergies</span>
                {isDoctor && (
                  <Button size="sm">
                    <Plus className="h-4 w-4 mr-2" />
                    Add Allergy
                  </Button>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {patientSummary?.allergies?.length > 0 ? (
                <div className="space-y-3">
                  {patientSummary.allergies.map((allergy) => (
                    <div key={allergy.id} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex items-center space-x-3">
                        <AlertTriangle className="h-5 w-5 text-orange-600" />
                        <div>
                          <p className="font-medium">{allergy.allergen}</p>
                          <p className="text-sm text-gray-600">
                            {allergy.type} • {allergy.reaction || 'No reaction specified'}
                          </p>
                        </div>
                      </div>
                      <Badge className={getSeverityColor(allergy.severity)}>
                        {allergy.severity}
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500">No known allergies</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Diagnoses Tab */}
        <TabsContent value="diagnoses">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Active Diagnoses</span>
                {isDoctor && (
                  <Button size="sm">
                    <Plus className="h-4 w-4 mr-2" />
                    Add Diagnosis
                  </Button>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {patientSummary?.activeDiagnoses?.length > 0 ? (
                <div className="space-y-3">
                  {patientSummary.activeDiagnoses.map((diagnosis) => (
                    <div key={diagnosis.id} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex items-center space-x-3">
                        <FileText className="h-5 w-5 text-red-600" />
                        <div>
                          <p className="font-medium">{diagnosis.condition}</p>
                          <p className="text-sm text-gray-600">
                            Diagnosed: {formatDate(diagnosis.diagnosedDate)}
                            {diagnosis.diagnosedBy && ` by ${diagnosis.diagnosedBy}`}
                          </p>
                        </div>
                      </div>
                      <Badge className={getStatusColor(diagnosis.status)}>
                        {diagnosis.status}
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500">No active diagnoses</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* Medications Tab */}
        <TabsContent value="medications">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Current Medications</span>
                {isDoctor && (
                  <Button size="sm">
                    <Plus className="h-4 w-4 mr-2" />
                    Add Medication
                  </Button>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {patientSummary?.activeMedications?.length > 0 ? (
                <div className="space-y-3">
                  {patientSummary.activeMedications.map((medication) => (
                    <div key={medication.id} className="flex items-center justify-between p-3 border rounded-lg">
                      <div className="flex items-center space-x-3">
                        <Pill className="h-5 w-5 text-blue-600" />
                        <div>
                          <p className="font-medium">
                            {medication.medicationName}
                            {medication.genericName && ` (${medication.genericName})`}
                          </p>
                          <p className="text-sm text-gray-600">
                            {medication.dosage} • {medication.frequency} • {medication.route}
                          </p>
                          {medication.prescribedBy && (
                            <p className="text-xs text-gray-500">Prescribed by: {medication.prescribedBy}</p>
                          )}
                        </div>
                      </div>
                      <Badge className="bg-green-100 text-green-800">
                        Active
                      </Badge>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500">No current medications</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* History Tab */}
        <TabsContent value="history">
          <Card>
            <CardHeader>
              <CardTitle className="flex items-center justify-between">
                <span>Medical History</span>
                {isDoctor && (
                  <Button size="sm">
                    <Plus className="h-4 w-4 mr-2" />
                    Add Entry
                  </Button>
                )}
              </CardTitle>
            </CardHeader>
            <CardContent>
              {patientSummary?.recentHistory?.length > 0 ? (
                <div className="space-y-3">
                  {patientSummary.recentHistory.map((item) => (
                    <div key={item.id} className="p-3 border rounded-lg">
                      <div className="flex items-center justify-between mb-2">
                        <h4 className="font-medium">{item.title}</h4>
                        <span className="text-sm text-gray-500">{formatDate(item.date)}</span>
                      </div>
                      <p className="text-sm text-gray-600 mb-2">{item.description}</p>
                      {item.doctorName && (
                        <p className="text-xs text-gray-500">By: {item.doctorName}</p>
                      )}
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-gray-500">No medical history available</p>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}

