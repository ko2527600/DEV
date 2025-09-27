// Firebase Cloud Functions for AI-powered features
// This file contains the backend logic for AI integration

const functions = require('firebase-functions');
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

// OpenAI Configuration (set in Firebase Functions config)
// Run: firebase functions:config:set openai.key="your-openai-api-key"

/**
 * AI-Powered Symptom Checker
 * Analyzes patient symptoms and provides preliminary assessment
 */
exports.analyzeSymptoms = functions.https.onCall(async (data, context) => {
  // Verify user authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { symptoms, age, gender, duration, severity } = data;

  // Validate input
  if (!symptoms || !age) {
    throw new functions.https.HttpsError('invalid-argument', 'Symptoms and age are required');
  }

  try {
    // OpenAI API call would go here
    // For now, returning a mock response
    const mockAnalysis = {
      urgencyLevel: severity === 'severe' ? 'high' : severity === 'moderate' ? 'medium' : 'low',
      recommendations: [
        'Monitor symptoms closely',
        'Stay hydrated',
        'Get adequate rest'
      ],
      possibleCauses: [
        'Common cold',
        'Viral infection',
        'Stress-related symptoms'
      ],
      shouldSeeDoctor: severity === 'severe' || duration > '7 days',
      emergencyWarning: severity === 'severe' && symptoms.includes('chest pain'),
      disclaimer: 'This is not a medical diagnosis. Please consult with a healthcare professional for proper medical advice.'
    };

    // Log the analysis for audit purposes
    await admin.firestore().collection('symptom_analyses').add({
      userId: context.auth.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      input: { symptoms, age, gender, duration, severity },
      analysis: mockAnalysis
    });

    return mockAnalysis;
  } catch (error) {
    console.error('Error analyzing symptoms:', error);
    throw new functions.https.HttpsError('internal', 'Failed to analyze symptoms');
  }
});

/**
 * Medical Chatbot
 * Handles general health questions and provides information
 */
exports.medicalChatbot = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { message, conversationId } = data;

  if (!message) {
    throw new functions.https.HttpsError('invalid-argument', 'Message is required');
  }

  try {
    // Mock chatbot response
    const responses = {
      'appointment': 'I can help you book an appointment. Would you like to see available doctors?',
      'medication': 'For medication information, please consult with your doctor or pharmacist.',
      'symptoms': 'I can help analyze your symptoms. Please use our symptom checker feature.',
      'emergency': 'If this is a medical emergency, please call emergency services immediately.',
      'default': 'I\'m here to help with general health questions. How can I assist you today?'
    };

    let response = responses.default;
    const lowerMessage = message.toLowerCase();

    if (lowerMessage.includes('appointment') || lowerMessage.includes('book')) {
      response = responses.appointment;
    } else if (lowerMessage.includes('medication') || lowerMessage.includes('medicine')) {
      response = responses.medication;
    } else if (lowerMessage.includes('symptom') || lowerMessage.includes('pain')) {
      response = responses.symptoms;
    } else if (lowerMessage.includes('emergency') || lowerMessage.includes('urgent')) {
      response = responses.emergency;
    }

    // Store conversation
    await admin.firestore().collection('chatbot_conversations').add({
      userId: context.auth.uid,
      conversationId: conversationId || 'default',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      userMessage: message,
      botResponse: response
    });

    return { response, timestamp: new Date().toISOString() };
  } catch (error) {
    console.error('Error in chatbot:', error);
    throw new functions.https.HttpsError('internal', 'Chatbot service unavailable');
  }
});

/**
 * Appointment Triage
 * Analyzes appointment requests and assigns priority levels
 */
exports.triageAppointment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { symptoms, urgency, patientAge, medicalHistory } = data;

  try {
    // Mock triage logic
    let priority = 'routine';
    let recommendedTimeframe = 'within 1 week';
    let suggestedSpecialist = 'General Practice';

    // Simple triage rules
    if (urgency === 'high' || symptoms.includes('chest pain') || symptoms.includes('difficulty breathing')) {
      priority = 'urgent';
      recommendedTimeframe = 'same day';
    } else if (urgency === 'medium' || symptoms.includes('fever') || symptoms.includes('severe pain')) {
      priority = 'priority';
      recommendedTimeframe = 'within 3 days';
    }

    // Specialist recommendations
    if (symptoms.includes('heart') || symptoms.includes('chest')) {
      suggestedSpecialist = 'Cardiology';
    } else if (symptoms.includes('skin') || symptoms.includes('rash')) {
      suggestedSpecialist = 'Dermatology';
    } else if (symptoms.includes('mental') || symptoms.includes('anxiety')) {
      suggestedSpecialist = 'Mental Health';
    }

    const triageResult = {
      priority,
      recommendedTimeframe,
      suggestedSpecialist,
      urgencyScore: priority === 'urgent' ? 5 : priority === 'priority' ? 3 : 1,
      notes: 'Automated triage assessment. Final decision by healthcare provider.'
    };

    // Log triage result
    await admin.firestore().collection('appointment_triage').add({
      userId: context.auth.uid,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      input: { symptoms, urgency, patientAge, medicalHistory },
      result: triageResult
    });

    return triageResult;
  } catch (error) {
    console.error('Error in appointment triage:', error);
    throw new functions.https.HttpsError('internal', 'Triage service unavailable');
  }
});

/**
 * Send Appointment Reminders
 * Triggered function to send appointment reminders
 */
exports.sendAppointmentReminders = functions.pubsub
  .schedule('every day 09:00')
  .timeZone('America/New_York')
  .onRun(async (context) => {
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    tomorrow.setHours(0, 0, 0, 0);

    const dayAfterTomorrow = new Date(tomorrow);
    dayAfterTomorrow.setDate(dayAfterTomorrow.getDate() + 1);

    try {
      // Get appointments for tomorrow
      const appointmentsSnapshot = await admin.firestore()
        .collection('appointments')
        .where('appointmentDate', '>=', tomorrow.toISOString())
        .where('appointmentDate', '<', dayAfterTomorrow.toISOString())
        .where('status', '==', 'confirmed')
        .get();

      const reminderPromises = appointmentsSnapshot.docs.map(async (doc) => {
        const appointment = doc.data();
        
        // Create notification
        await admin.firestore().collection('notifications').add({
          userId: appointment.patientId,
          type: 'appointment_reminder',
          title: 'Appointment Reminder',
          message: `You have an appointment tomorrow with Dr. ${appointment.doctorName} at ${appointment.timeSlot}`,
          appointmentId: doc.id,
          timestamp: admin.firestore.FieldValue.serverTimestamp(),
          read: false
        });

        // Here you would also send push notifications, emails, or SMS
        console.log(`Reminder sent for appointment ${doc.id}`);
      });

      await Promise.all(reminderPromises);
      console.log(`Sent ${appointmentsSnapshot.size} appointment reminders`);
    } catch (error) {
      console.error('Error sending appointment reminders:', error);
    }
  });

/**
 * Drug Interaction Checker
 * Checks for potential drug interactions in prescriptions
 */
exports.checkDrugInteractions = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { medications } = data;

  if (!medications || !Array.isArray(medications)) {
    throw new functions.https.HttpsError('invalid-argument', 'Medications array is required');
  }

  try {
    // Mock drug interaction checking
    const interactions = [];
    const warnings = [];

    // Simple mock logic for common interactions
    const medicationNames = medications.map(med => med.name.toLowerCase());

    if (medicationNames.includes('warfarin') && medicationNames.includes('aspirin')) {
      interactions.push({
        medications: ['Warfarin', 'Aspirin'],
        severity: 'high',
        description: 'Increased risk of bleeding',
        recommendation: 'Monitor closely and consider alternative'
      });
    }

    if (medicationNames.includes('metformin') && medicationNames.includes('alcohol')) {
      warnings.push({
        medication: 'Metformin',
        warning: 'Avoid alcohol consumption',
        reason: 'Increased risk of lactic acidosis'
      });
    }

    return {
      interactions,
      warnings,
      safetyScore: interactions.length === 0 ? 'safe' : interactions.some(i => i.severity === 'high') ? 'high_risk' : 'moderate_risk',
      timestamp: new Date().toISOString()
    };
  } catch (error) {
    console.error('Error checking drug interactions:', error);
    throw new functions.https.HttpsError('internal', 'Drug interaction service unavailable');
  }
});

/**
 * Generate Health Insights
 * Analyzes patient data to provide health insights
 */
exports.generateHealthInsights = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  try {
    // Get patient's recent data
    const userId = context.auth.uid;
    const userDoc = await admin.firestore().collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found');
    }

    // Mock health insights
    const insights = [
      {
        type: 'appointment_frequency',
        title: 'Regular Check-ups',
        message: 'You\'re doing great with regular appointments! Keep up the good work.',
        priority: 'low'
      },
      {
        type: 'health_trend',
        title: 'Health Monitoring',
        message: 'Consider tracking your daily symptoms to help your doctor provide better care.',
        priority: 'medium'
      }
    ];

    return {
      insights,
      generatedAt: new Date().toISOString(),
      userId
    };
  } catch (error) {
    console.error('Error generating health insights:', error);
    throw new functions.https.HttpsError('internal', 'Health insights service unavailable');
  }
});

