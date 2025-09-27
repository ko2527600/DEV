// External Health API Service
// This service provides integration with various health-related APIs

export interface NutritionInfo {
  food: string;
  calories: number;
  protein: number;
  carbs: number;
  fat: number;
  fiber: number;
  vitamins: string[];
}

export interface ExerciseRecommendation {
  name: string;
  type: 'cardio' | 'strength' | 'flexibility' | 'balance';
  duration: string;
  intensity: 'low' | 'medium' | 'high';
  benefits: string[];
  instructions: string;
}

export interface HealthNews {
  title: string;
  summary: string;
  source: string;
  publishedAt: string;
  url: string;
  category: string;
}

export class ExternalHealthAPI {
  // Nutrition API - Simulated data for common foods
  static async getNutritionInfo(food: string): Promise<NutritionInfo | null> {
    // Simulate API call delay
    await new Promise(resolve => setTimeout(resolve, 500));
    
    const nutritionDatabase: Record<string, NutritionInfo> = {
      'apple': {
        food: 'Apple',
        calories: 95,
        protein: 0.5,
        carbs: 25,
        fat: 0.3,
        fiber: 4.4,
        vitamins: ['Vitamin C', 'Vitamin K', 'Potassium']
      },
      'banana': {
        food: 'Banana',
        calories: 105,
        protein: 1.3,
        carbs: 27,
        fat: 0.4,
        fiber: 3.1,
        vitamins: ['Vitamin B6', 'Vitamin C', 'Potassium', 'Magnesium']
      },
      'chicken breast': {
        food: 'Chicken Breast',
        calories: 165,
        protein: 31,
        carbs: 0,
        fat: 3.6,
        fiber: 0,
        vitamins: ['Vitamin B6', 'Vitamin B12', 'Niacin', 'Selenium']
      },
      'salmon': {
        food: 'Salmon',
        calories: 208,
        protein: 25,
        carbs: 0,
        fat: 12,
        fiber: 0,
        vitamins: ['Vitamin D', 'Vitamin B12', 'Omega-3', 'Selenium']
      },
      'spinach': {
        food: 'Spinach',
        calories: 23,
        protein: 2.9,
        carbs: 3.6,
        fat: 0.4,
        fiber: 2.2,
        vitamins: ['Vitamin A', 'Vitamin C', 'Vitamin K', 'Iron', 'Folate']
      }
    };
    
    const normalizedFood = food.toLowerCase().trim();
    return nutritionDatabase[normalizedFood] || null;
  }

  // Exercise API - Simulated exercise recommendations
  static async getExerciseRecommendations(type?: string): Promise<ExerciseRecommendation[]> {
    await new Promise(resolve => setTimeout(resolve, 400));
    
    const exercises: ExerciseRecommendation[] = [
      {
        name: 'Walking',
        type: 'cardio',
        duration: '30-60 minutes',
        intensity: 'low',
        benefits: ['Improves cardiovascular health', 'Strengthens bones', 'Reduces stress'],
        instructions: 'Walk at a brisk pace, maintaining good posture. Aim for 10,000 steps daily.'
      },
      {
        name: 'Push-ups',
        type: 'strength',
        duration: '10-15 minutes',
        intensity: 'medium',
        benefits: ['Builds upper body strength', 'Improves core stability', 'No equipment needed'],
        instructions: 'Start in plank position, lower body until chest nearly touches floor, then push back up.'
      },
      {
        name: 'Yoga Stretches',
        type: 'flexibility',
        duration: '15-20 minutes',
        intensity: 'low',
        benefits: ['Improves flexibility', 'Reduces muscle tension', 'Promotes relaxation'],
        instructions: 'Hold each stretch for 15-30 seconds, breathe deeply, and don\'t force movements.'
      },
      {
        name: 'Running',
        type: 'cardio',
        duration: '20-45 minutes',
        intensity: 'high',
        benefits: ['Burns calories', 'Strengthens heart', 'Improves endurance'],
        instructions: 'Start with a warm-up, maintain proper form, and gradually increase distance.'
      },
      {
        name: 'Squats',
        type: 'strength',
        duration: '10-15 minutes',
        intensity: 'medium',
        benefits: ['Builds leg strength', 'Improves balance', 'Functional movement'],
        instructions: 'Stand with feet shoulder-width apart, lower body as if sitting back, then stand up.'
      }
    ];
    
    if (type) {
      return exercises.filter(exercise => exercise.type === type);
    }
    
    return exercises;
  }

  // Health News API - Simulated health news
  static async getHealthNews(category?: string): Promise<HealthNews[]> {
    await new Promise(resolve => setTimeout(resolve, 600));
    
    const news: HealthNews[] = [
      {
        title: 'New Study Shows Benefits of Mediterranean Diet for Heart Health',
        summary: 'Research indicates that following a Mediterranean diet can reduce the risk of cardiovascular disease by up to 30%.',
        source: 'Health Research Journal',
        publishedAt: '2024-01-15',
        url: '#',
        category: 'nutrition'
      },
      {
        title: 'Exercise Found to Improve Mental Health in Adults',
        summary: 'Regular physical activity has been linked to reduced symptoms of depression and anxiety across all age groups.',
        source: 'Mental Health Today',
        publishedAt: '2024-01-14',
        url: '#',
        category: 'mental-health'
      },
      {
        title: 'Sleep Quality Linked to Immune System Function',
        summary: 'New research suggests that getting 7-9 hours of quality sleep can significantly boost immune system effectiveness.',
        source: 'Sleep Science Review',
        publishedAt: '2024-01-13',
        url: '#',
        category: 'sleep'
      },
      {
        title: 'Walking 10,000 Steps Daily Reduces Disease Risk',
        summary: 'Study shows that achieving daily step goals can lower the risk of chronic diseases including diabetes and heart disease.',
        source: 'Fitness Research',
        publishedAt: '2024-01-12',
        url: '#',
        category: 'exercise'
      }
    ];
    
    if (category) {
      return news.filter(item => item.category === category);
    }
    
    return news;
  }

  // BMI Calculator
  static calculateBMI(weight: number, height: number): { bmi: number; category: string; healthRisk: string } {
    const heightInMeters = height / 100; // Convert cm to meters
    const bmi = weight / (heightInMeters * heightInMeters);
    
    let category: string;
    let healthRisk: string;
    
    if (bmi < 18.5) {
      category = 'Underweight';
      healthRisk = 'May indicate malnutrition or underlying health conditions';
    } else if (bmi < 25) {
      category = 'Normal weight';
      healthRisk = 'Low risk of health problems';
    } else if (bmi < 30) {
      category = 'Overweight';
      healthRisk = 'Increased risk of health problems';
    } else {
      category = 'Obese';
      healthRisk = 'High risk of serious health problems';
    }
    
    return { bmi: Math.round(bmi * 10) / 10, category, healthRisk };
  }

  // Calorie Calculator
  static calculateDailyCalories(age: number, gender: string, weight: number, height: number, activityLevel: string): number {
    // Basic BMR calculation using Mifflin-St Jeor Equation
    let bmr: number;
    
    if (gender.toLowerCase() === 'male') {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }
    
    // Activity level multipliers
    const activityMultipliers: Record<string, number> = {
      'sedentary': 1.2,      // Little or no exercise
      'light': 1.375,        // Light exercise 1-3 days/week
      'moderate': 1.55,      // Moderate exercise 3-5 days/week
      'active': 1.725,       // Hard exercise 6-7 days/week
      'very-active': 1.9     // Very hard exercise, physical job
    };
    
    const multiplier = activityMultipliers[activityLevel.toLowerCase()] || 1.2;
    return Math.round(bmr * multiplier);
  }
}
