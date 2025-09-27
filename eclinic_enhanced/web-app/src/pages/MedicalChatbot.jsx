import { useState, useRef, useEffect } from 'react';
import { useAuth } from '../contexts/AuthContext';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Alert, AlertDescription } from '@/components/ui/alert';
import { 
  Bot, 
  User, 
  Send, 
  Info, 
  Calendar,
  Pill,
  Search,
  Phone,
  Heart,
  UserCheck
} from 'lucide-react';
import { getFunctions, httpsCallable } from 'firebase/functions';
import { v4 as uuidv4 } from 'uuid';
import '../App.css';

export default function MedicalChatbot() {
  const { currentUser } = useAuth();
  const [messages, setMessages] = useState([]);
  const [inputMessage, setInputMessage] = useState('');
  const [isTyping, setIsTyping] = useState(false);
  const [conversationId] = useState(uuidv4());
  const messagesEndRef = useRef(null);
  const inputRef = useRef(null);

  const quickReplies = [
    { text: 'Book an appointment', icon: Calendar },
    { text: 'Medication information', icon: Pill },
    { text: 'Symptom checker', icon: Search },
    { text: 'Emergency contacts', icon: Phone },
    { text: 'Health tips', icon: Heart },
    { text: 'Find a doctor', icon: UserCheck },
  ];

  useEffect(() => {
    // Add welcome message
    setMessages([{
      id: uuidv4(),
      text: "Hello! I'm your AI health assistant. I can help you with general health questions, appointment booking, medication information, and more. How can I assist you today?",
      isUser: false,
      timestamp: new Date(),
    }]);
  }, []);

  useEffect(() => {
    scrollToBottom();
  }, [messages, isTyping]);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  const sendMessage = async (messageText = inputMessage) => {
    if (!messageText.trim()) return;

    const userMessage = {
      id: uuidv4(),
      text: messageText,
      isUser: true,
      timestamp: new Date(),
    };

    setMessages(prev => [...prev, userMessage]);
    setInputMessage('');
    setIsTyping(true);

    try {
      const functions = getFunctions();
      const medicalChatbot = httpsCallable(functions, 'medicalChatbot');
      
      const result = await medicalChatbot({
        message: messageText,
        conversationId: conversationId
      });

      const botMessage = {
        id: uuidv4(),
        text: result.data.response || "I apologize, but I couldn't process your request.",
        isUser: false,
        timestamp: new Date(),
      };

      setMessages(prev => [...prev, botMessage]);
    } catch (error) {
      console.error('Error sending message:', error);
      const errorMessage = {
        id: uuidv4(),
        text: "I'm sorry, I'm having trouble connecting right now. Please try again later.",
        isUser: false,
        timestamp: new Date(),
        isError: true,
      };
      setMessages(prev => [...prev, errorMessage]);
    } finally {
      setIsTyping(false);
    }
  };

  const handleKeyPress = (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      e.preventDefault();
      sendMessage();
    }
  };

  const formatTime = (timestamp) => {
    const now = new Date();
    const diff = now - timestamp;
    const minutes = Math.floor(diff / 60000);
    
    if (minutes < 1) return 'Just now';
    if (minutes < 60) return `${minutes}m ago`;
    
    return timestamp.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  };

  const TypingIndicator = () => (
    <div className="flex items-start space-x-3 mb-4">
      <div className="bg-green-100 rounded-full p-2">
        <Bot className="h-4 w-4 text-green-600" />
      </div>
      <div className="bg-gray-100 rounded-lg rounded-bl-sm px-4 py-3 max-w-xs">
        <div className="flex space-x-1">
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce"></div>
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.1s' }}></div>
          <div className="w-2 h-2 bg-gray-400 rounded-full animate-bounce" style={{ animationDelay: '0.2s' }}></div>
        </div>
      </div>
    </div>
  );

  return (
    <div className="max-w-4xl mx-auto h-[calc(100vh-8rem)] flex flex-col">
      {/* Header */}
      <Card className="mb-4">
        <CardHeader className="pb-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-3">
              <div className="bg-green-100 rounded-full p-2">
                <Bot className="h-6 w-6 text-green-600" />
              </div>
              <div>
                <CardTitle className="text-xl">AI Health Assistant</CardTitle>
                <p className="text-sm text-gray-600">Available 24/7 for your health questions</p>
              </div>
            </div>
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                // Show info dialog
                alert('This AI assistant can help you with:\n\n• General health questions\n• Appointment booking guidance\n• Medication information\n• Health tips and advice\n• Emergency contact information\n\nPlease note: This is not a substitute for professional medical advice. Always consult with a healthcare provider for medical concerns.');
              }}
            >
              <Info className="h-4 w-4" />
            </Button>
          </div>
        </CardHeader>
      </Card>

      {/* Chat Messages */}
      <Card className="flex-1 flex flex-col">
        <CardContent className="flex-1 overflow-y-auto p-4 space-y-4">
          {messages.map((message) => (
            <div
              key={message.id}
              className={`flex items-start space-x-3 ${
                message.isUser ? 'flex-row-reverse space-x-reverse' : ''
              }`}
            >
              <div className={`rounded-full p-2 ${
                message.isUser 
                  ? 'bg-blue-100' 
                  : message.isError 
                    ? 'bg-red-100' 
                    : 'bg-green-100'
              }`}>
                {message.isUser ? (
                  <User className="h-4 w-4 text-blue-600" />
                ) : (
                  <Bot className={`h-4 w-4 ${message.isError ? 'text-red-600' : 'text-green-600'}`} />
                )}
              </div>
              
              <div className={`max-w-xs lg:max-w-md ${message.isUser ? 'text-right' : ''}`}>
                <div className={`rounded-lg px-4 py-3 ${
                  message.isUser
                    ? 'bg-blue-600 text-white rounded-br-sm'
                    : message.isError
                      ? 'bg-red-50 text-red-800 rounded-bl-sm border border-red-200'
                      : 'bg-gray-100 text-gray-800 rounded-bl-sm'
                }`}>
                  <p className="text-sm whitespace-pre-wrap">{message.text}</p>
                </div>
                <p className={`text-xs text-gray-500 mt-1 ${message.isUser ? 'text-right' : ''}`}>
                  {formatTime(message.timestamp)}
                </p>
              </div>
            </div>
          ))}
          
          {isTyping && <TypingIndicator />}
          
          {/* Quick Replies - Show when conversation is new */}
          {messages.length <= 1 && !isTyping && (
            <div className="space-y-3">
              <p className="text-sm text-gray-600 font-medium">Quick questions:</p>
              <div className="grid grid-cols-2 gap-2">
                {quickReplies.map((reply, index) => {
                  const IconComponent = reply.icon;
                  return (
                    <Button
                      key={index}
                      variant="outline"
                      size="sm"
                      className="justify-start h-auto py-3 px-3"
                      onClick={() => sendMessage(reply.text)}
                    >
                      <IconComponent className="h-4 w-4 mr-2" />
                      <span className="text-xs">{reply.text}</span>
                    </Button>
                  );
                })}
              </div>
            </div>
          )}
          
          <div ref={messagesEndRef} />
        </CardContent>

        {/* Message Input */}
        <div className="border-t p-4">
          <div className="flex space-x-2">
            <Input
              ref={inputRef}
              value={inputMessage}
              onChange={(e) => setInputMessage(e.target.value)}
              onKeyPress={handleKeyPress}
              placeholder="Type your health question..."
              className="flex-1"
              disabled={isTyping}
            />
            <Button 
              onClick={() => sendMessage()}
              disabled={!inputMessage.trim() || isTyping}
              size="sm"
            >
              <Send className="h-4 w-4" />
            </Button>
          </div>
        </div>
      </Card>

      {/* Disclaimer */}
      <Alert className="mt-4">
        <Info className="h-4 w-4" />
        <AlertDescription className="text-sm">
          This AI assistant provides general health information and should not replace professional medical advice. 
          For medical emergencies, contact emergency services immediately.
        </AlertDescription>
      </Alert>
    </div>
  );
}

