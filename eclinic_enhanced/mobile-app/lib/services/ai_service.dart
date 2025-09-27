import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class AIService extends ChangeNotifier {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Analyzes patient symptoms using AI
  Future<Map<String, dynamic>> analyzeSymptoms({
    required String symptoms,
    required int age,
    required String gender,
    required String duration,
    required String severity,
  }) async {
    try {
      final callable = _functions.httpsCallable('analyzeSymptoms');
      final result = await callable.call({
        'symptoms': symptoms,
        'age': age,
        'gender': gender,
        'duration': duration,
        'severity': severity,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error analyzing symptoms: $e');
      rethrow;
    }
  }

  /// Sends a message to the medical chatbot
  Future<Map<String, dynamic>> sendChatbotMessage({
    required String message,
    String? conversationId,
  }) async {
    try {
      final callable = _functions.httpsCallable('medicalChatbot');
      final result = await callable.call({
        'message': message,
        'conversationId': conversationId,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error sending chatbot message: $e');
      rethrow;
    }
  }

  /// Performs appointment triage to determine priority
  Future<Map<String, dynamic>> triageAppointment({
    required String symptoms,
    required String urgency,
    required int patientAge,
    String? medicalHistory,
  }) async {
    try {
      final callable = _functions.httpsCallable('triageAppointment');
      final result = await callable.call({
        'symptoms': symptoms,
        'urgency': urgency,
        'patientAge': patientAge,
        'medicalHistory': medicalHistory,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error triaging appointment: $e');
      rethrow;
    }
  }

  /// Checks for drug interactions
  Future<Map<String, dynamic>> checkDrugInteractions({
    required List<Map<String, dynamic>> medications,
  }) async {
    try {
      final callable = _functions.httpsCallable('checkDrugInteractions');
      final result = await callable.call({
        'medications': medications,
      });

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error checking drug interactions: $e');
      rethrow;
    }
  }

  /// Generates personalized health insights
  Future<Map<String, dynamic>> generateHealthInsights() async {
    try {
      final callable = _functions.httpsCallable('generateHealthInsights');
      final result = await callable.call();

      return Map<String, dynamic>.from(result.data);
    } catch (e) {
      debugPrint('Error generating health insights: $e');
      rethrow;
    }
  }

  /// Gets AI-powered appointment recommendations
  Future<List<Map<String, dynamic>>> getAppointmentRecommendations({
    required String symptoms,
    required String urgency,
  }) async {
    try {
      // This would typically call a Firebase Function
      // For now, returning mock recommendations
      await Future.delayed(const Duration(seconds: 1)); // Simulate API call

      final recommendations = <Map<String, dynamic>>[];

      if (symptoms.toLowerCase().contains('heart') || symptoms.toLowerCase().contains('chest')) {
        recommendations.add({
          'specialization': 'Cardiology',
          'urgency': 'high',
          'reason': 'Symptoms may require cardiac evaluation',
          'recommendedTimeframe': 'within 24 hours'
        });
      }

      if (symptoms.toLowerCase().contains('skin') || symptoms.toLowerCase().contains('rash')) {
        recommendations.add({
          'specialization': 'Dermatology',
          'urgency': 'medium',
          'reason': 'Skin-related symptoms detected',
          'recommendedTimeframe': 'within 1 week'
        });
      }

      if (symptoms.toLowerCase().contains('mental') || symptoms.toLowerCase().contains('anxiety')) {
        recommendations.add({
          'specialization': 'Mental Health',
          'urgency': 'medium',
          'reason': 'Mental health support may be beneficial',
          'recommendedTimeframe': 'within 3 days'
        });
      }

      // Default recommendation
      if (recommendations.isEmpty) {
        recommendations.add({
          'specialization': 'General Practice',
          'urgency': urgency,
          'reason': 'General medical evaluation recommended',
          'recommendedTimeframe': urgency == 'high' ? 'within 24 hours' : 'within 1 week'
        });
      }

      return recommendations;
    } catch (e) {
      debugPrint('Error getting appointment recommendations: $e');
      rethrow;
    }
  }

  /// Analyzes health trends from patient data
  Future<Map<String, dynamic>> analyzeHealthTrends({
    required List<Map<String, dynamic>> healthData,
  }) async {
    try {
      // Mock health trend analysis
      await Future.delayed(const Duration(seconds: 1));

      final trends = {
        'overallTrend': 'improving',
        'keyInsights': [
          'Your appointment frequency has been consistent',
          'Symptoms have been decreasing over time',
          'Consider maintaining current treatment plan'
        ],
        'recommendations': [
          'Continue regular check-ups',
          'Monitor symptoms daily',
          'Maintain healthy lifestyle habits'
        ],
        'riskFactors': [],
        'nextSteps': [
          'Schedule follow-up appointment in 3 months',
          'Continue current medications as prescribed'
        ]
      };

      return trends;
    } catch (e) {
      debugPrint('Error analyzing health trends: $e');
      rethrow;
    }
  }

  /// Gets AI-powered medication reminders and information
  Future<Map<String, dynamic>> getMedicationInsights({
    required List<Map<String, dynamic>> medications,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final insights = {
        'adherenceScore': 85,
        'reminders': [
          {
            'medication': 'Morning medications',
            'time': '08:00',
            'importance': 'high'
          },
          {
            'medication': 'Evening medications',
            'time': '20:00',
            'importance': 'medium'
          }
        ],
        'interactions': [],
        'sideEffects': [
          'Monitor for dizziness',
          'Take with food to reduce stomach upset'
        ],
        'tips': [
          'Set daily alarms for medication times',
          'Use a pill organizer for better tracking',
          'Keep medications in a visible location'
        ]
      };

      return insights;
    } catch (e) {
      debugPrint('Error getting medication insights: $e');
      rethrow;
    }
  }

  /// Provides AI-powered health education content
  Future<Map<String, dynamic>> getHealthEducation({
    required String topic,
    String? userAge,
    String? userGender,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final educationContent = {
        'title': 'Understanding $topic',
        'summary': 'Learn about $topic and how it affects your health.',
        'keyPoints': [
          'What is $topic?',
          'Common symptoms and signs',
          'Prevention strategies',
          'When to seek medical help'
        ],
        'resources': [
          {
            'title': 'Mayo Clinic - $topic',
            'url': 'https://mayoclinic.org',
            'type': 'article'
          },
          {
            'title': 'WebMD - $topic Guide',
            'url': 'https://webmd.com',
            'type': 'guide'
          }
        ],
        'relatedTopics': [
          'Prevention',
          'Treatment options',
          'Lifestyle changes'
        ]
      };

      return educationContent;
    } catch (e) {
      debugPrint('Error getting health education: $e');
      rethrow;
    }
  }
}

