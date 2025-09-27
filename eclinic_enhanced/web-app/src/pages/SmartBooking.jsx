import { useState } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { Badge } from '@/components/ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { 
  Brain, 
  AlertTriangle, 
  CheckCircle, 
  Clock, 
  Star,
  Calendar,
  Stethoscope,
  TrendingUp,
  Info,
  Target
} from 'lucide-react';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { collection, addDoc } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function SmartBooking() {
  const { currentUser } = useAuth();
  const [formData, setFormData] = useState({
    symptoms: '',
    age: '',
    urgency: 'medium',
    medicalHistory: ''
  });
  const [isAnalyzing, setIsAnalyzing] = useState(false);
  const [triageResult, setTriageResult] = useState(null);
  const [recommendations, setRecommendations] = useState([]);
  const [error, setError] = useState('');

  const handleInputChange = (field, value) => {
    setFormData(prev => ({
      ...prev,
      [field]: value
    }));
  };

  const performTriage = async () => {
    if (!formData.symptoms.trim() || !formData.age) {
      setError('Please fill in all required fields');
      return;
    }

    setIsAnalyzing(true);
    setError('');
    setTriageResult(null);
    setRecommendations([]);

    try {
      const functions = getFunctions();
      const triageAppointment = httpsCallable(functions, 'triageAppointment');
      
      // Perform triage analysis
      const triageResponse = await triageAppointment({
        symptoms: formData.symptoms,
        urgency: formData.urgency,
        patientAge: parseInt(formData.age),
        medicalHistory: formData.medicalHistory
      });

      setTriageResult(triageResponse.data);

      // Mock appointment recommendations (in real app, this would be another Firebase Function)
      const mockRecommendations = generateRecommendations(formData.symptoms, formData.urgency);
      setRecommendations(mockRecommendations);

    } catch (err) {
      console.error('Error performing triage:', err);
      setError('Failed to analyze symptoms. Please try again.');
    } finally {
      setIsAnalyzing(false);
    }
  };

  const generateRecommendations = (symptoms, urgency) => {
    const recommendations = [];
    const symptomsLower = symptoms.toLowerCase();

    if (symptomsLower.includes('heart') || symptomsLower.includes('chest')) {
      recommendations.push({
        specialization: 'Cardiology',
        urgency: 'high',
        reason: 'Symptoms may require cardiac evaluation',
        recommendedTimeframe: 'within 24 hours',
        confidence: 95
      });
    }

    if (symptomsLower.includes('skin') || symptomsLower.includes('rash')) {
      recommendations.push({
        specialization: 'Dermatology',
        urgency: 'medium',
        reason: 'Skin-related symptoms detected',
        recommendedTimeframe: 'within 1 week',
        confidence: 88
      });
    }

    if (symptomsLower.includes('mental') || symptomsLower.includes('anxiety') || symptomsLower.includes('depression')) {
      recommendations.push({
        specialization: 'Mental Health',
        urgency: 'medium',
        reason: 'Mental health support may be beneficial',
        recommendedTimeframe: 'within 3 days',
        confidence: 92
      });
    }

    if (symptomsLower.includes('eye') || symptomsLower.includes('vision')) {
      recommendations.push({
        specialization: 'Ophthalmology',
        urgency: 'medium',
        reason: 'Vision-related symptoms require specialist evaluation',
        recommendedTimeframe: 'within 1 week',
        confidence: 85
      });
    }

    // Default recommendation
    if (recommendations.length === 0) {
      recommendations.push({
        specialization: 'General Practice',
        urgency: urgency,
        reason: 'General medical evaluation recommended',
        recommendedTimeframe: urgency === 'high' ? 'within 24 hours' : 'within 1 week',
        confidence: 80
      });
    }

    return recommendations;
  };

  const bookAppointment = async (specialization, urgency) => {
    try {
      const appointmentData = {
        patientId: currentUser.uid,
        specialization,
        urgency,
        symptoms: formData.symptoms,
        status: 'pending',
        triageData: triageResult,
        requestedDate: new Date(),
        createdAt: new Date()
      };

      await addDoc(collection(db, 'appointments'), appointmentData);
      
      alert('Appointment request submitted successfully!');
    } catch (err) {
      console.error('Error booking appointment:', err);
      setError('Failed to book appointment. Please try again.');
    }
  };

  const getPriorityColor = (priority) => {
    switch (priority?.toLowerCase()) {
      case 'urgent': return 'bg-red-100 text-red-800';
      case 'priority': return 'bg-orange-100 text-orange-800';
      case 'routine': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getUrgencyColor = (urgency) => {
    switch (urgency?.toLowerCase()) {
      case 'high': return 'bg-red-100 text-red-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'low': return 'bg-green-100 text-green-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const getScoreColor = (score) => {
    if (score >= 4) return 'text-red-600';
    if (score >= 3) return 'text-orange-600';
    return 'text-green-600';
  };

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* Header */}
      <div className="text-center">
        <div className="flex justify-center mb-4">
          <div className="bg-blue-100 rounded-full p-3">
            <Brain className="h-8 w-8 text-blue-600" />
          </div>
        </div>
        <h1 className="text-3xl font-bold text-gray-900 mb-2">Smart Appointment Booking</h1>
        <p className="text-gray-600 max-w-2xl mx-auto">
          Our AI analyzes your symptoms and recommends the best specialist and urgency level for your appointment.
        </p>
      </div>

      {/* Input Form */}
      <Card>
        <CardHeader>
          <CardTitle>Tell Us About Your Symptoms</CardTitle>
          <CardDescription>
            Provide detailed information for the most accurate triage assessment and specialist recommendations.
          </CardDescription>
        </CardHeader>
        <CardContent className="space-y-6">
          {error && (
            <Alert variant="destructive">
              <AlertTriangle className="h-4 w-4" />
              <AlertDescription>{error}</AlertDescription>
            </Alert>
          )}

          {/* Symptoms Description */}
          <div className="space-y-2">
            <Label htmlFor="symptoms">Symptoms & Concerns *</Label>
            <Textarea
              id="symptoms"
              placeholder="Describe your symptoms, pain level, duration, and any specific concerns in detail"
              value={formData.symptoms}
              onChange={(e) => handleInputChange('symptoms', e.target.value)}
              rows={4}
            />
          </div>

          {/* Patient Information */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="age">Age *</Label>
              <Input
                id="age"
                type="number"
                placeholder="Enter your age"
                value={formData.age}
                onChange={(e) => handleInputChange('age', e.target.value)}
                min="1"
                max="120"
              />
            </div>

            <div className="space-y-2">
              <Label htmlFor="urgency">How urgent do you feel this is?</Label>
              <Select value={formData.urgency} onValueChange={(value) => handleInputChange('urgency', value)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="low">Low - Can wait</SelectItem>
                  <SelectItem value="medium">Medium - Should be seen soon</SelectItem>
                  <SelectItem value="high">High - Urgent attention needed</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          {/* Medical History */}
          <div className="space-y-2">
            <Label htmlFor="medicalHistory">Relevant Medical History (Optional)</Label>
            <Textarea
              id="medicalHistory"
              placeholder="Any relevant medical conditions, medications, allergies, or previous treatments"
              value={formData.medicalHistory}
              onChange={(e) => handleInputChange('medicalHistory', e.target.value)}
              rows={3}
            />
          </div>

          {/* Analyze Button */}
          <Button 
            onClick={performTriage} 
            disabled={isAnalyzing || !formData.symptoms.trim() || !formData.age}
            className="w-full"
          >
            {isAnalyzing ? (
              <>
                <div className="animate-spin rounded-full h-4 w-4 border-b-2 border-white mr-2"></div>
                Analyzing Symptoms...
              </>
            ) : (
              <>
                <Brain className="h-4 w-4 mr-2" />
                Analyze & Get Recommendations
              </>
            )}
          </Button>
        </CardContent>
      </Card>

      {/* Triage Results */}
      {triageResult && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <Target className="h-5 w-5 text-blue-600" />
              <span>Triage Assessment</span>
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-6">
            {/* Priority Level */}
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <AlertTriangle className="h-5 w-5 text-orange-600" />
                <span className="font-medium">Priority Level:</span>
              </div>
              <Badge className={getPriorityColor(triageResult.priority)}>
                {triageResult.priority?.toUpperCase()}
              </Badge>
            </div>

            {/* Recommended Timeframe */}
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <Clock className="h-5 w-5 text-blue-600" />
                <span className="font-medium">Recommended Timeframe:</span>
              </div>
              <span className="font-semibold text-blue-600">
                {triageResult.recommendedTimeframe}
              </span>
            </div>

            {/* Suggested Specialist */}
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <Stethoscope className="h-5 w-5 text-green-600" />
                <span className="font-medium">Suggested Specialist:</span>
              </div>
              <span className="font-semibold text-green-600">
                {triageResult.suggestedSpecialist}
              </span>
            </div>

            {/* Urgency Score */}
            <div className="flex items-center justify-between p-4 bg-gray-50 rounded-lg">
              <div className="flex items-center space-x-3">
                <TrendingUp className="h-5 w-5 text-orange-600" />
                <span className="font-medium">Urgency Score:</span>
              </div>
              <div className="flex items-center space-x-2">
                <span className={`font-bold text-lg ${getScoreColor(triageResult.urgencyScore)}`}>
                  {triageResult.urgencyScore}/5
                </span>
                <div className="flex space-x-1">
                  {[1, 2, 3, 4, 5].map((star) => (
                    <Star
                      key={star}
                      className={`h-4 w-4 ${
                        star <= triageResult.urgencyScore
                          ? 'text-yellow-400 fill-current'
                          : 'text-gray-300'
                      }`}
                    />
                  ))}
                </div>
              </div>
            </div>

            {/* Notes */}
            {triageResult.notes && (
              <div className="bg-blue-50 p-4 rounded-lg">
                <div className="flex items-start space-x-3">
                  <Info className="h-5 w-5 text-blue-600 mt-0.5" />
                  <div>
                    <h3 className="font-medium text-blue-800 mb-1">Assessment Notes</h3>
                    <p className="text-blue-700 text-sm">{triageResult.notes}</p>
                  </div>
                </div>
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* Recommendations */}
      {recommendations.length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center space-x-2">
              <CheckCircle className="h-5 w-5 text-green-600" />
              <span>Recommended Appointments</span>
            </CardTitle>
            <CardDescription>
              Based on your symptoms and triage assessment, here are our AI-powered recommendations:
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {recommendations.map((recommendation, index) => (
              <div key={index} className="border rounded-lg p-6 space-y-4">
                <div className="flex items-center justify-between">
                  <h3 className="text-lg font-semibold">{recommendation.specialization}</h3>
                  <div className="flex items-center space-x-2">
                    <Badge className={getUrgencyColor(recommendation.urgency)}>
                      {recommendation.urgency?.toUpperCase()}
                    </Badge>
                    <Badge variant="outline">
                      {recommendation.confidence}% match
                    </Badge>
                  </div>
                </div>

                <p className="text-gray-600">{recommendation.reason}</p>

                <div className="flex items-center space-x-4 text-sm text-gray-500">
                  <div className="flex items-center space-x-1">
                    <Clock className="h-4 w-4" />
                    <span>Recommended: {recommendation.recommendedTimeframe}</span>
                  </div>
                </div>

                <Button 
                  onClick={() => bookAppointment(recommendation.specialization, recommendation.urgency)}
                  className="w-full"
                >
                  <Calendar className="h-4 w-4 mr-2" />
                  Book {recommendation.specialization} Appointment
                </Button>
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* Important Notice */}
      <Card className="border-yellow-200 bg-yellow-50">
        <CardContent className="pt-6">
          <div className="flex items-start space-x-3">
            <AlertTriangle className="h-5 w-5 text-yellow-600 mt-0.5" />
            <div>
              <h3 className="font-semibold text-yellow-800 mb-2">AI Triage Notice</h3>
              <p className="text-yellow-700 text-sm">
                This AI triage system provides recommendations based on symptom analysis and should not replace 
                professional medical judgment. Final appointment scheduling and medical decisions will be made by 
                qualified healthcare providers. In case of emergency, contact emergency services immediately.
              </p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
}

