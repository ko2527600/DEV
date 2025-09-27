import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Card, CardContent } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { 
  Video, 
  VideoOff, 
  Mic, 
  MicOff, 
  Phone, 
  PhoneOff,
  ScreenShare,
  StopScreenShare,
  MessageSquare,
  Settings,
  Users,
  Signal,
  X,
  Send
} from 'lucide-react';
import { doc, getDoc, updateDoc, collection, addDoc, onSnapshot, serverTimestamp } from 'firebase/firestore';
import { db } from '../lib/firebase';
import '../App.css';

export default function VideoConsultation() {
  const { consultationId } = useParams();
  const navigate = useNavigate();
  const { currentUser } = useAuth();
  
  const [consultation, setConsultation] = useState(null);
  const [participants, setParticipants] = useState([]);
  const [messages, setMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [isAudioEnabled, setIsAudioEnabled] = useState(true);
  const [isVideoEnabled, setIsVideoEnabled] = useState(true);
  const [isScreenSharing, setIsScreenSharing] = useState(false);
  const [isChatVisible, setIsChatVisible] = useState(false);
  const [connectionQuality, setConnectionQuality] = useState('good');
  const [newMessage, setNewMessage] = useState('');
  const [showEndDialog, setShowEndDialog] = useState(false);
  const [consultationNotes, setConsultationNotes] = useState('');
  const [prescription, setPrescription] = useState('');
  
  const chatScrollRef = useRef(null);
  const isDoctor = currentUser?.role === 'doctor';

  useEffect(() => {
    loadConsultation();
    listenToMessages();
  }, [consultationId]);

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const loadConsultation = async () => {
    try {
      const docRef = doc(db, 'video_consultations', consultationId);
      const docSnap = await getDoc(docRef);
      
      if (docSnap.exists()) {
        setConsultation({ id: docSnap.id, ...docSnap.data() });
      }
    } catch (error) {
      console.error('Error loading consultation:', error);
    } finally {
      setLoading(false);
    }
  };

  const listenToMessages = () => {
    const messagesRef = collection(db, 'video_consultations', consultationId, 'messages');
    
    return onSnapshot(messagesRef, (snapshot) => {
      const messageList = snapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data()
      })).sort((a, b) => a.timestamp?.toDate() - b.timestamp?.toDate());
      
      setMessages(messageList);
    });
  };

  const scrollToBottom = () => {
    if (chatScrollRef.current) {
      chatScrollRef.current.scrollTop = chatScrollRef.current.scrollHeight;
    }
  };

  const joinConsultation = async () => {
    try {
      await updateDoc(doc(db, 'video_consultations', consultationId), {
        status: 'waiting',
        updatedAt: serverTimestamp()
      });
      
      // Add participant
      await addDoc(collection(db, 'video_consultations', consultationId, 'participants'), {
        userId: currentUser.uid,
        name: currentUser.displayName || 'User',
        role: isDoctor ? 'doctor' : 'patient',
        joinedAt: serverTimestamp(),
        isActive: true,
        audioEnabled: true,
        videoEnabled: true,
        connectionQuality: 'good'
      });
      
      await loadConsultation();
    } catch (error) {
      console.error('Error joining consultation:', error);
    }
  };

  const startConsultation = async () => {
    try {
      await updateDoc(doc(db, 'video_consultations', consultationId), {
        status: 'inProgress',
        startTime: serverTimestamp(),
        updatedAt: serverTimestamp()
      });
      
      await loadConsultation();
    } catch (error) {
      console.error('Error starting consultation:', error);
    }
  };

  const endConsultation = async () => {
    try {
      const updateData = {
        status: 'completed',
        endTime: serverTimestamp(),
        updatedAt: serverTimestamp()
      };
      
      if (consultationNotes.trim()) {
        updateData.notes = consultationNotes.trim();
      }
      
      if (prescription.trim()) {
        updateData.prescription = prescription.trim();
      }
      
      await updateDoc(doc(db, 'video_consultations', consultationId), updateData);
      
      navigate('/dashboard');
    } catch (error) {
      console.error('Error ending consultation:', error);
    }
  };

  const toggleAudio = async () => {
    const newState = !isAudioEnabled;
    setIsAudioEnabled(newState);
    
    // Update participant status in Firestore
    // This would typically update the participant document
  };

  const toggleVideo = async () => {
    const newState = !isVideoEnabled;
    setIsVideoEnabled(newState);
    
    // Update participant status in Firestore
    // This would typically update the participant document
  };

  const toggleScreenShare = async () => {
    const newState = !isScreenSharing;
    setIsScreenSharing(newState);
    
    // Update participant status in Firestore
    // This would typically update the participant document
  };

  const sendMessage = async () => {
    if (!newMessage.trim()) return;
    
    try {
      await addDoc(collection(db, 'video_consultations', consultationId, 'messages'), {
        consultationId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName || 'User',
        senderRole: isDoctor ? 'doctor' : 'patient',
        message: newMessage.trim(),
        timestamp: serverTimestamp(),
        isSystemMessage: false
      });
      
      setNewMessage('');
    } catch (error) {
      console.error('Error sending message:', error);
    }
  };

  const getConnectionQualityColor = (quality) => {
    switch (quality) {
      case 'excellent':
      case 'good':
        return 'bg-green-500';
      case 'fair':
        return 'bg-yellow-500';
      case 'poor':
      case 'disconnected':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  const getStatusColor = (status) => {
    switch (status) {
      case 'scheduled':
        return 'bg-blue-500';
      case 'waiting':
        return 'bg-yellow-500';
      case 'inProgress':
        return 'bg-green-500';
      case 'completed':
        return 'bg-gray-500';
      case 'cancelled':
        return 'bg-red-500';
      default:
        return 'bg-gray-500';
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen bg-black">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-white"></div>
      </div>
    );
  }

  if (!consultation) {
    return (
      <div className="flex items-center justify-center h-screen bg-black text-white">
        <div className="text-center">
          <h2 className="text-2xl font-bold mb-4">Consultation Not Found</h2>
          <Button onClick={() => navigate('/dashboard')} variant="outline">
            Back to Dashboard
          </Button>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen bg-black text-white flex flex-col">
      {/* Top Bar */}
      <div className="flex items-center justify-between p-4 bg-gradient-to-b from-black/70 to-transparent absolute top-0 left-0 right-0 z-10">
        <div className="flex items-center space-x-4">
          <Button
            variant="ghost"
            size="sm"
            onClick={() => navigate('/dashboard')}
            className="text-white hover:bg-white/20"
          >
            ← Back
          </Button>
          <div>
            <h1 className="font-semibold">
              {isDoctor ? consultation.patientName : consultation.doctorName}
            </h1>
            <div className="flex items-center space-x-2">
              <Badge className={`${getStatusColor(consultation.status)} text-white`}>
                {consultation.status}
              </Badge>
              {consultation.status === 'inProgress' && (
                <Badge className="bg-red-500 text-white animate-pulse">
                  LIVE
                </Badge>
              )}
            </div>
          </div>
        </div>
        
        <div className="flex items-center space-x-2">
          <div className={`w-2 h-2 rounded-full ${getConnectionQualityColor(connectionQuality)}`}></div>
          <span className="text-sm capitalize">{connectionQuality}</span>
        </div>
      </div>

      {/* Main Video Area */}
      <div className="flex-1 relative">
        {/* Main Video */}
        <div className="w-full h-full bg-gray-800 flex items-center justify-center">
          <div className="text-center">
            {isVideoEnabled ? (
              <Video className="w-16 h-16 mb-4 mx-auto text-white/50" />
            ) : (
              <VideoOff className="w-16 h-16 mb-4 mx-auto text-white/50" />
            )}
            <h3 className="text-xl font-semibold mb-2">
              {isDoctor ? consultation.patientName : consultation.doctorName}
            </h3>
            <p className="text-white/70">
              {isVideoEnabled ? 'Video On' : 'Video Off'}
            </p>
          </div>
        </div>

        {/* Self Video (Picture-in-Picture) */}
        <div className="absolute top-20 right-4 w-32 h-40 bg-gray-700 rounded-lg border-2 border-white flex items-center justify-center">
          <div className="text-center">
            {isVideoEnabled ? (
              <Video className="w-8 h-8 mb-2 mx-auto text-white/50" />
            ) : (
              <VideoOff className="w-8 h-8 mb-2 mx-auto text-white/50" />
            )}
            <p className="text-xs font-semibold">You</p>
          </div>
        </div>

        {/* Participants List */}
        {participants.length > 2 && (
          <div className="absolute top-20 left-4 bg-black/50 rounded-lg p-3">
            <h4 className="font-semibold mb-2 flex items-center">
              <Users className="w-4 h-4 mr-2" />
              Participants
            </h4>
            <div className="space-y-1">
              {participants.slice(0, 5).map((participant) => (
                <div key={participant.userId} className="text-sm text-white/70">
                  {participant.name}
                </div>
              ))}
              {participants.length > 5 && (
                <div className="text-sm text-white/70">
                  +{participants.length - 5} more
                </div>
              )}
            </div>
          </div>
        )}

        {/* Chat Overlay */}
        {isChatVisible && (
          <div className="absolute right-4 top-20 bottom-32 w-80 bg-black/90 rounded-lg flex flex-col">
            {/* Chat Header */}
            <div className="flex items-center justify-between p-4 border-b border-white/20">
              <div className="flex items-center space-x-2">
                <MessageSquare className="w-5 h-5" />
                <span className="font-semibold">Chat</span>
              </div>
              <Button
                variant="ghost"
                size="sm"
                onClick={() => setIsChatVisible(false)}
                className="text-white hover:bg-white/20"
              >
                <X className="w-4 h-4" />
              </Button>
            </div>

            {/* Messages */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3" ref={chatScrollRef}>
              {messages.map((message) => {
                const isOwnMessage = message.senderId === currentUser.uid;
                return (
                  <div
                    key={message.id}
                    className={`flex ${isOwnMessage ? 'justify-end' : 'justify-start'}`}
                  >
                    <div className={`max-w-xs rounded-lg p-3 ${
                      isOwnMessage 
                        ? 'bg-blue-600 text-white' 
                        : 'bg-white/20 text-white'
                    }`}>
                      {!isOwnMessage && (
                        <p className="text-xs font-semibold mb-1 opacity-70">
                          {message.senderName}
                        </p>
                      )}
                      <p className="text-sm">{message.message}</p>
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Message Input */}
            <div className="p-4 border-t border-white/20">
              <div className="flex space-x-2">
                <Input
                  value={newMessage}
                  onChange={(e) => setNewMessage(e.target.value)}
                  placeholder="Type a message..."
                  className="flex-1 bg-white/10 border-white/20 text-white placeholder:text-white/50"
                  onKeyPress={(e) => e.key === 'Enter' && sendMessage()}
                />
                <Button
                  onClick={sendMessage}
                  size="sm"
                  className="bg-blue-600 hover:bg-blue-700"
                >
                  <Send className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Bottom Controls */}
      <div className="p-6 bg-gradient-to-t from-black/70 to-transparent">
        {/* Action Buttons */}
        {consultation.status === 'scheduled' && (
          <div className="mb-4">
            <Button
              onClick={isDoctor ? startConsultation : joinConsultation}
              className="w-full bg-green-600 hover:bg-green-700 text-white"
              size="lg"
            >
              <Video className="w-5 h-5 mr-2" />
              {isDoctor ? 'Start Consultation' : 'Join Consultation'}
            </Button>
          </div>
        )}

        {/* Control Buttons */}
        <div className="flex items-center justify-center space-x-4">
          {/* Audio Toggle */}
          <Button
            onClick={toggleAudio}
            variant={isAudioEnabled ? "default" : "destructive"}
            size="lg"
            className="w-14 h-14 rounded-full"
          >
            {isAudioEnabled ? (
              <Mic className="w-6 h-6" />
            ) : (
              <MicOff className="w-6 h-6" />
            )}
          </Button>

          {/* Video Toggle */}
          <Button
            onClick={toggleVideo}
            variant={isVideoEnabled ? "default" : "destructive"}
            size="lg"
            className="w-14 h-14 rounded-full"
          >
            {isVideoEnabled ? (
              <Video className="w-6 h-6" />
            ) : (
              <VideoOff className="w-6 h-6" />
            )}
          </Button>

          {/* Screen Share */}
          <Button
            onClick={toggleScreenShare}
            variant={isScreenSharing ? "default" : "outline"}
            size="lg"
            className="w-14 h-14 rounded-full"
          >
            {isScreenSharing ? (
              <StopScreenShare className="w-6 h-6" />
            ) : (
              <ScreenShare className="w-6 h-6" />
            )}
          </Button>

          {/* Chat */}
          <Button
            onClick={() => setIsChatVisible(!isChatVisible)}
            variant={isChatVisible ? "default" : "outline"}
            size="lg"
            className="w-14 h-14 rounded-full relative"
          >
            <MessageSquare className="w-6 h-6" />
            {messages.length > 0 && (
              <Badge className="absolute -top-2 -right-2 bg-red-500 text-white text-xs">
                {messages.length}
              </Badge>
            )}
          </Button>

          {/* End Call */}
          <Button
            onClick={isDoctor ? () => setShowEndDialog(true) : () => navigate('/dashboard')}
            variant="destructive"
            size="lg"
            className="w-14 h-14 rounded-full"
          >
            <PhoneOff className="w-6 h-6" />
          </Button>
        </div>
      </div>

      {/* End Consultation Dialog */}
      {showEndDialog && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50">
          <Card className="w-full max-w-md mx-4">
            <CardContent className="p-6">
              <h3 className="text-lg font-semibold mb-4">End Consultation</h3>
              
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Consultation Notes
                  </label>
                  <Textarea
                    value={consultationNotes}
                    onChange={(e) => setConsultationNotes(e.target.value)}
                    placeholder="Enter your notes about this consultation..."
                    rows={3}
                  />
                </div>
                
                <div>
                  <label className="block text-sm font-medium mb-2">
                    Prescription (Optional)
                  </label>
                  <Textarea
                    value={prescription}
                    onChange={(e) => setPrescription(e.target.value)}
                    placeholder="Enter prescription details..."
                    rows={2}
                  />
                </div>
              </div>
              
              <div className="flex space-x-3 mt-6">
                <Button
                  variant="outline"
                  onClick={() => setShowEndDialog(false)}
                  className="flex-1"
                >
                  Cancel
                </Button>
                <Button
                  onClick={endConsultation}
                  className="flex-1 bg-red-600 hover:bg-red-700"
                >
                  End Consultation
                </Button>
              </div>
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  );
}

