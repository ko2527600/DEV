import { useState, useEffect } from 'react';
import { useParams } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { Input } from '@/components/ui/input';
import { 
  Pill, 
  Plus, 
  Search, 
  Download,
  Edit,
  Eye,
  RefreshCw,
  Calendar,
  User,
  Clock,
  AlertTriangle,
  Info,
  CheckCircle,
  XCircle,
  Timer
} from 'lucide-react';
import { 
  collection, 
  query, 
  where, 
  orderBy, 
  getDocs, 
  doc, 
  updateDoc,
  addDoc,
  serverTimestamp 
} from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function PrescriptionManagement() {
  const { patientId } = useParams();
  const { currentUser } = useAuth();
  
  const [prescriptions, setPrescriptions] = useState([]);
  const [refillRequests, setRefillRequests] = useState([]);
  const [analytics, setAnalytics] = useState(null);
  const [loading, setLoading] = useState(true);
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState('active');
  
  const isDoctorView = currentUser?.role === 'doctor';

  useEffect(() => {
    loadData();
  }, [patientId]);

  const loadData = async () => {
    try {
      setLoading(true);
      
      // Load prescriptions
      const prescriptionsQuery = query(
        collection(db, 'prescriptions'),
        where('patientId', '==', patientId),
        orderBy('prescribedDate', 'desc')
      );
      const prescriptionsSnapshot = await getDocs(prescriptionsQuery);
      const prescriptionsData = prescriptionsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      // Load refill requests
      const refillsQuery = query(
        collection(db, 'refill_requests'),
        where('patientId', '==', patientId),
        orderBy('requestedDate', 'desc')
      );
      const refillsSnapshot = await getDocs(refillsQuery);
      const refillsData = refillsSnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      }));

      setPrescriptions(prescriptionsData);
      setRefillRequests(refillsData);
      
      // Calculate analytics
      const analyticsData = calculateAnalytics(prescriptionsData);
      setAnalytics(analyticsData);
      
    } catch (error) {
      console.error('Error loading prescription data:', error);
    } finally {
      setLoading(false);
    }
  };

  const calculateAnalytics = (prescriptions) => {
    const total = prescriptions.length;
    const active = prescriptions.filter(p => p.status === 'active').length;
    const completed = prescriptions.filter(p => p.status === 'completed').length;
    const cancelled = prescriptions.filter(p => p.status === 'cancelled').length;
    const expired = prescriptions.filter(p => p.status === 'expired').length;
    
    // Calculate common medications
    const medicationCounts = {};
    prescriptions.forEach(p => {
      medicationCounts[p.medicationName] = (medicationCounts[p.medicationName] || 0) + 1;
    });
    
    const commonMedications = Object.entries(medicationCounts)
      .sort(([,a], [,b]) => b - a)
      .slice(0, 5);

    return {
      totalPrescriptions: total,
      activePrescriptions: active,
      completedPrescriptions: completed,
      cancelledPrescriptions: cancelled,
      expiredPrescriptions: expired,
      commonMedications: Object.fromEntries(commonMedications),
      averageAdherenceRate: 85.5 // Mock data - would be calculated from adherence records
    };
  };

  const formatDate = (timestamp) => {
    if (!timestamp) return 'N/A';
    const date = new Date(timestamp.seconds * 1000);
    return date.toLocaleDateString();
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'active':
        return 'bg-green-100 text-green-800';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800';
      case 'completed':
        return 'bg-blue-100 text-blue-800';
      case 'cancelled':
        return 'bg-red-100 text-red-800';
      case 'expired':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const getRefillStatusColor = (status) => {
    switch (status) {
      case 'available':
        return 'bg-green-100 text-green-800';
      case 'requested':
        return 'bg-yellow-100 text-yellow-800';
      case 'approved':
        return 'bg-blue-100 text-blue-800';
      case 'denied':
        return 'bg-red-100 text-red-800';
      case 'noRefillsLeft':
        return 'bg-gray-100 text-gray-800';
      default:
        return 'bg-gray-100 text-gray-800';
    }
  };

  const canRefill = (prescription) => {
    return prescription.status === 'active' && 
           prescription.refillsRemaining > 0 &&
           (!prescription.expiryDate || new Date(prescription.expiryDate.seconds * 1000) > new Date());
  };

  const requestRefill = async (prescription) => {
    try {
      const refillRequest = {
        prescriptionId: prescription.id,
        patientId: prescription.patientId,
        patientName: prescription.patientName,
        doctorId: prescription.doctorId,
        doctorName: prescription.doctorName,
        medicationName: prescription.medicationName,
        status: 'requested',
        requestedDate: serverTimestamp(),
        pharmacyId: prescription.pharmacyId,
        pharmacyName: prescription.pharmacyName,
        createdAt: serverTimestamp()
      };

      await addDoc(collection(db, 'refill_requests'), refillRequest);
      
      // Show success message
      alert('Refill request submitted successfully');
      loadData();
    } catch (error) {
      console.error('Error requesting refill:', error);
      alert('Error requesting refill');
    }
  };

  const approveRefill = async (refillRequest) => {
    try {
      // Update refill request
      await updateDoc(doc(db, 'refill_requests', refillRequest.id), {
        status: 'approved',
        approvedDate: serverTimestamp(),
        updatedAt: serverTimestamp()
      });

      // Update prescription refills remaining
      const prescriptionRef = doc(db, 'prescriptions', refillRequest.prescriptionId);
      const prescription = prescriptions.find(p => p.id === refillRequest.prescriptionId);
      await updateDoc(prescriptionRef, {
        refillsRemaining: prescription.refillsRemaining - 1,
        updatedAt: serverTimestamp()
      });

      alert('Refill approved successfully');
      loadData();
    } catch (error) {
      console.error('Error approving refill:', error);
      alert('Error approving refill');
    }
  };

  const denyRefill = async (refillRequest, reason) => {
    try {
      await updateDoc(doc(db, 'refill_requests', refillRequest.id), {
        status: 'denied',
        deniedDate: serverTimestamp(),
        denialReason: reason,
        updatedAt: serverTimestamp()
      });

      alert('Refill denied');
      loadData();
    } catch (error) {
      console.error('Error denying refill:', error);
      alert('Error denying refill');
    }
  };

  const filteredPrescriptions = prescriptions.filter(prescription => {
    const matchesSearch = searchQuery === '' || 
      prescription.medicationName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      prescription.doctorName.toLowerCase().includes(searchQuery.toLowerCase());
    
    if (activeTab === 'active') {
      return matchesSearch && prescription.status === 'active';
    }
    
    return matchesSearch;
  });

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
          <h1 className="text-3xl font-bold text-gray-900">
            {isDoctorView ? 'Patient Prescriptions' : 'My Prescriptions'}
          </h1>
          <p className="text-gray-600">Manage prescriptions and refill requests</p>
        </div>
        
        <div className="flex space-x-2">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 h-4 w-4" />
            <Input
              placeholder="Search prescriptions..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10 w-64"
            />
          </div>
          {isDoctorView && (
            <Button>
              <Plus className="h-4 w-4 mr-2" />
              New Prescription
            </Button>
          )}
          <Button variant="outline">
            <Download className="h-4 w-4 mr-2" />
            Export
          </Button>
        </div>
      </div>

      {/* Quick Stats */}
      {analytics && (
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <Pill className="h-5 w-5 text-blue-600" />
                <div>
                  <p className="text-2xl font-bold">{analytics.totalPrescriptions}</p>
                  <p className="text-sm text-gray-600">Total</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <CheckCircle className="h-5 w-5 text-green-600" />
                <div>
                  <p className="text-2xl font-bold">{analytics.activePrescriptions}</p>
                  <p className="text-sm text-gray-600">Active</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <RefreshCw className="h-5 w-5 text-orange-600" />
                <div>
                  <p className="text-2xl font-bold">{refillRequests.filter(r => r.status === 'requested').length}</p>
                  <p className="text-sm text-gray-600">Pending Refills</p>
                </div>
              </div>
            </CardContent>
          </Card>
          
          <Card>
            <CardContent className="p-6">
              <div className="flex items-center space-x-2">
                <Timer className="h-5 w-5 text-purple-600" />
                <div>
                  <p className="text-2xl font-bold">{analytics.averageAdherenceRate.toFixed(1)}%</p>
                  <p className="text-sm text-gray-600">Adherence</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>
      )}

      {/* Main Content */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="active">Active</TabsTrigger>
          <TabsTrigger value="all">All Prescriptions</TabsTrigger>
          <TabsTrigger value="refills">Refill Requests</TabsTrigger>
          {isDoctorView && <TabsTrigger value="analytics">Analytics</TabsTrigger>}
        </TabsList>

        {/* Active Prescriptions Tab */}
        <TabsContent value="active" className="space-y-4">
          {filteredPrescriptions.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <Pill className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Active Prescriptions</h3>
                <p className="text-gray-600">There are no active prescriptions to display.</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4">
              {filteredPrescriptions.map((prescription) => (
                <Card key={prescription.id}>
                  <CardContent className="p-6">
                    <div className="flex items-start justify-between mb-4">
                      <div className="flex-1">
                        <h3 className="text-lg font-semibold text-gray-900">
                          {prescription.medicationName}
                          {prescription.genericName && ` (${prescription.genericName})`}
                        </h3>
                        <p className="text-gray-600">
                          {prescription.dosage} {prescription.strength} {prescription.form}
                        </p>
                      </div>
                      <Badge className={getStatusColor(prescription.status)}>
                        {prescription.status.toUpperCase()}
                      </Badge>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-4">
                      <div className="flex items-center space-x-2">
                        <User className="h-4 w-4 text-gray-500" />
                        <span className="text-sm">Dr. {prescription.doctorName}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Clock className="h-4 w-4 text-gray-500" />
                        <span className="text-sm">{prescription.frequency}</span>
                      </div>
                      <div className="flex items-center space-x-2">
                        <Calendar className="h-4 w-4 text-gray-500" />
                        <span className="text-sm">Prescribed: {formatDate(prescription.prescribedDate)}</span>
                      </div>
                    </div>

                    {prescription.indication && (
                      <div className="mb-4 p-3 bg-blue-50 rounded-lg">
                        <div className="flex items-center space-x-2">
                          <Info className="h-4 w-4 text-blue-600" />
                          <span className="text-sm font-medium">Indication:</span>
                        </div>
                        <p className="text-sm text-gray-700 mt-1">{prescription.indication}</p>
                      </div>
                    )}

                    {prescription.instructions && (
                      <div className="mb-4 p-3 bg-gray-50 rounded-lg">
                        <div className="flex items-center space-x-2">
                          <Info className="h-4 w-4 text-gray-600" />
                          <span className="text-sm font-medium">Instructions:</span>
                        </div>
                        <p className="text-sm text-gray-700 mt-1">{prescription.instructions}</p>
                      </div>
                    )}

                    {prescription.warnings && prescription.warnings.length > 0 && (
                      <div className="mb-4 p-3 bg-orange-50 rounded-lg">
                        <div className="flex items-center space-x-2">
                          <AlertTriangle className="h-4 w-4 text-orange-600" />
                          <span className="text-sm font-medium">Warnings:</span>
                        </div>
                        <ul className="text-sm text-gray-700 mt-1 list-disc list-inside">
                          {prescription.warnings.map((warning, index) => (
                            <li key={index}>{warning}</li>
                          ))}
                        </ul>
                      </div>
                    )}

                    {prescription.refillsRemaining !== undefined && (
                      <div className="mb-4">
                        <span className="text-sm text-gray-600">
                          Refills remaining: <span className="font-medium">{prescription.refillsRemaining}</span>
                        </span>
                      </div>
                    )}

                    <div className="flex space-x-2">
                      {canRefill(prescription) && !isDoctorView && (
                        <Button 
                          size="sm" 
                          onClick={() => requestRefill(prescription)}
                          className="bg-green-600 hover:bg-green-700"
                        >
                          <RefreshCw className="h-4 w-4 mr-2" />
                          Request Refill
                        </Button>
                      )}
                      
                      <Button variant="outline" size="sm">
                        <Eye className="h-4 w-4 mr-2" />
                        View Details
                      </Button>
                      
                      {isDoctorView && (
                        <Button variant="outline" size="sm">
                          <Edit className="h-4 w-4 mr-2" />
                          Edit
                        </Button>
                      )}
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* All Prescriptions Tab */}
        <TabsContent value="all" className="space-y-4">
          <div className="grid gap-4">
            {filteredPrescriptions.map((prescription) => (
              <Card key={prescription.id}>
                <CardContent className="p-6">
                  <div className="flex items-start justify-between">
                    <div className="flex-1">
                      <h3 className="text-lg font-semibold text-gray-900">
                        {prescription.medicationName}
                      </h3>
                      <p className="text-gray-600">
                        {prescription.dosage} • {prescription.frequency}
                      </p>
                      <p className="text-sm text-gray-500">
                        Prescribed by Dr. {prescription.doctorName} on {formatDate(prescription.prescribedDate)}
                      </p>
                    </div>
                    <Badge className={getStatusColor(prescription.status)}>
                      {prescription.status.toUpperCase()}
                    </Badge>
                  </div>
                </CardContent>
              </Card>
            ))}
          </div>
        </TabsContent>

        {/* Refill Requests Tab */}
        <TabsContent value="refills" className="space-y-4">
          {refillRequests.length === 0 ? (
            <Card>
              <CardContent className="p-12 text-center">
                <RefreshCw className="h-12 w-12 text-gray-400 mx-auto mb-4" />
                <h3 className="text-lg font-medium text-gray-900 mb-2">No Refill Requests</h3>
                <p className="text-gray-600">There are no refill requests to display.</p>
              </CardContent>
            </Card>
          ) : (
            <div className="grid gap-4">
              {refillRequests.map((refill) => (
                <Card key={refill.id}>
                  <CardContent className="p-6">
                    <div className="flex items-start justify-between">
                      <div className="flex-1">
                        <h3 className="text-lg font-semibold text-gray-900">
                          {refill.medicationName}
                        </h3>
                        <p className="text-gray-600">
                          Requested on {formatDate(refill.requestedDate)}
                        </p>
                        <p className="text-sm text-gray-500">
                          Patient: {refill.patientName} • Doctor: Dr. {refill.doctorName}
                        </p>
                        {refill.denialReason && (
                          <p className="text-sm text-red-600 mt-2">
                            Denial reason: {refill.denialReason}
                          </p>
                        )}
                      </div>
                      <div className="flex items-center space-x-2">
                        <Badge className={getRefillStatusColor(refill.status)}>
                          {refill.status.toUpperCase()}
                        </Badge>
                        {isDoctorView && refill.status === 'requested' && (
                          <div className="flex space-x-2">
                            <Button 
                              size="sm" 
                              onClick={() => approveRefill(refill)}
                              className="bg-green-600 hover:bg-green-700"
                            >
                              Approve
                            </Button>
                            <Button 
                              size="sm" 
                              variant="outline"
                              onClick={() => {
                                const reason = prompt('Enter reason for denial:');
                                if (reason) denyRefill(refill, reason);
                              }}
                            >
                              Deny
                            </Button>
                          </div>
                        )}
                      </div>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* Analytics Tab */}
        {isDoctorView && (
          <TabsContent value="analytics" className="space-y-6">
            {analytics && (
              <>
                {/* Overview Stats */}
                <Card>
                  <CardHeader>
                    <CardTitle>Prescription Overview</CardTitle>
                    <CardDescription>Summary of prescription statistics</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
                      <div className="text-center p-4 bg-blue-50 rounded-lg">
                        <p className="text-2xl font-bold text-blue-600">{analytics.totalPrescriptions}</p>
                        <p className="text-sm text-gray-600">Total</p>
                      </div>
                      <div className="text-center p-4 bg-green-50 rounded-lg">
                        <p className="text-2xl font-bold text-green-600">{analytics.activePrescriptions}</p>
                        <p className="text-sm text-gray-600">Active</p>
                      </div>
                      <div className="text-center p-4 bg-blue-50 rounded-lg">
                        <p className="text-2xl font-bold text-blue-600">{analytics.completedPrescriptions}</p>
                        <p className="text-sm text-gray-600">Completed</p>
                      </div>
                      <div className="text-center p-4 bg-red-50 rounded-lg">
                        <p className="text-2xl font-bold text-red-600">{analytics.cancelledPrescriptions}</p>
                        <p className="text-sm text-gray-600">Cancelled</p>
                      </div>
                    </div>
                  </CardContent>
                </Card>

                {/* Adherence Rate */}
                <Card>
                  <CardHeader>
                    <CardTitle>Medication Adherence</CardTitle>
                    <CardDescription>Patient medication compliance rate</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="text-center">
                      <p className="text-4xl font-bold text-green-600 mb-2">
                        {analytics.averageAdherenceRate.toFixed(1)}%
                      </p>
                      <p className="text-gray-600">Average Adherence Rate</p>
                    </div>
                  </CardContent>
                </Card>

                {/* Common Medications */}
                <Card>
                  <CardHeader>
                    <CardTitle>Most Prescribed Medications</CardTitle>
                    <CardDescription>Frequently prescribed medications for this patient</CardDescription>
                  </CardHeader>
                  <CardContent>
                    <div className="space-y-3">
                      {Object.entries(analytics.commonMedications).map(([medication, count]) => (
                        <div key={medication} className="flex justify-between items-center">
                          <span className="font-medium">{medication}</span>
                          <Badge variant="outline">{count} times</Badge>
                        </div>
                      ))}
                    </div>
                  </CardContent>
                </Card>
              </>
            )}
          </TabsContent>
        )}
      </Tabs>
    </div>
  );
}

