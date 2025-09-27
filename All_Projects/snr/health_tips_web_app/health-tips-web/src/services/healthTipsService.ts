export interface HealthTip {
  id: number;
  title: string;
  content: string;
  category: string;
  tags: string[];
  created_at: string;
  source?: string;
  verified: boolean;
}

export interface HealthCategory {
  id: string;
  name: string;
  description: string;
  icon: string;
}

export const healthCategories: HealthCategory[] = [
  {
    id: 'nutrition',
    name: 'Nutrition',
    description: 'Healthy eating habits and dietary advice',
    icon: '🥗'
  },
  {
    id: 'exercise',
    name: 'Exercise',
    description: 'Physical activity and fitness tips',
    icon: '💪'
  },
  {
    id: 'mental-health',
    name: 'Mental Health',
    description: 'Psychological well-being and stress management',
    icon: '🧠'
  },
  {
    id: 'sleep',
    name: 'Sleep',
    description: 'Sleep hygiene and rest optimization',
    icon: '😴'
  },
  {
    id: 'prevention',
    name: 'Prevention',
    description: 'Disease prevention and health maintenance',
    icon: '🛡️'
  },
  {
    id: 'hydration',
    name: 'Hydration',
    description: 'Water intake and hydration tips',
    icon: '💧'
  }
];

export const sampleHealthTips: HealthTip[] = [
  {
    id: 1,
    title: "Stay Hydrated Throughout the Day",
    content: "Drink at least 8 glasses of water daily. Start your morning with a glass of water and keep a water bottle with you. Dehydration can cause fatigue, headaches, and poor concentration. Add lemon or cucumber for flavor.",
    category: "hydration",
    tags: ["water", "hydration", "daily-habits"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 2,
    title: "Eat the Rainbow",
    content: "Include colorful fruits and vegetables in your diet. Different colors provide different nutrients: red foods (tomatoes, strawberries) contain lycopene, orange foods (carrots, sweet potatoes) have beta-carotene, and green vegetables (spinach, broccoli) are rich in folate and iron.",
    category: "nutrition",
    tags: ["fruits", "vegetables", "nutrients", "balanced-diet"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 3,
    title: "Take Regular Walking Breaks",
    content: "If you work at a desk, take a 5-minute walking break every hour. Walking improves circulation, reduces stress, and helps maintain a healthy weight. Aim for at least 10,000 steps per day for optimal health benefits.",
    category: "exercise",
    tags: ["walking", "desk-job", "daily-activity", "steps"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 4,
    title: "Practice Deep Breathing",
    content: "Take 5-10 deep breaths when feeling stressed. Inhale slowly through your nose for 4 counts, hold for 4 counts, then exhale slowly for 6 counts. This activates your parasympathetic nervous system and reduces cortisol levels.",
    category: "mental-health",
    tags: ["stress-relief", "breathing", "meditation", "relaxation"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 5,
    title: "Establish a Sleep Routine",
    content: "Go to bed and wake up at the same time every day, even on weekends. Avoid screens 1 hour before bedtime, keep your bedroom cool and dark, and create a relaxing pre-sleep ritual like reading or gentle stretching.",
    category: "sleep",
    tags: ["sleep-hygiene", "routine", "bedtime", "rest"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 6,
    title: "Wash Your Hands Regularly",
    content: "Wash your hands with soap and water for at least 20 seconds, especially before eating, after using the bathroom, and after touching public surfaces. This simple habit prevents the spread of germs and reduces illness.",
    category: "prevention",
    tags: ["hygiene", "germs", "illness-prevention", "cleanliness"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 7,
    title: "Include Protein in Every Meal",
    content: "Protein helps build and repair tissues, supports immune function, and keeps you feeling full longer. Good sources include lean meats, fish, eggs, legumes, nuts, and dairy products. Aim for 0.8-1.2 grams per kilogram of body weight.",
    category: "nutrition",
    tags: ["protein", "muscle-building", "satiety", "immune-support"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 8,
    title: "Practice Mindful Eating",
    content: "Eat slowly and pay attention to your food. Notice the taste, texture, and aroma. Stop eating when you're 80% full. This helps prevent overeating and improves digestion while making meals more enjoyable.",
    category: "nutrition",
    tags: ["mindful-eating", "portion-control", "digestion", "enjoyment"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 9,
    title: "Stretch Daily",
    content: "Spend 10-15 minutes stretching each day to improve flexibility, reduce muscle tension, and prevent injuries. Focus on major muscle groups and hold each stretch for 15-30 seconds without bouncing.",
    category: "exercise",
    tags: ["flexibility", "stretching", "muscle-tension", "injury-prevention"],
    created_at: new Date().toISOString(),
    verified: true
  },
  {
    id: 10,
    title: "Limit Added Sugars",
    content: "Keep added sugars to less than 10% of your daily calories. Read food labels and avoid products with sugar, corn syrup, or other sweeteners listed in the first few ingredients. Natural sugars in fruits are fine.",
    category: "nutrition",
    tags: ["sugar", "added-sugars", "food-labels", "healthy-eating"],
    created_at: new Date().toISOString(),
    verified: true
  }
];

export class HealthTipsService {
  static async getHealthTips(category?: string): Promise<HealthTip[]> {
    // Simulate API delay
    await new Promise(resolve => setTimeout(resolve, 300));
    
    if (category) {
      return sampleHealthTips.filter(tip => tip.category === category);
    }
    return sampleHealthTips;
  }

  static async getHealthTip(id: number): Promise<HealthTip | null> {
    await new Promise(resolve => setTimeout(resolve, 200));
    return sampleHealthTips.find(tip => tip.id === id) || null;
  }

  static async getCategories(): Promise<HealthCategory[]> {
    await new Promise(resolve => setTimeout(resolve, 100));
    return healthCategories;
  }

  static async searchHealthTips(query: string): Promise<HealthTip[]> {
    await new Promise(resolve => setTimeout(resolve, 400));
    const lowercaseQuery = query.toLowerCase();
    return sampleHealthTips.filter(tip => 
      tip.title.toLowerCase().includes(lowercaseQuery) ||
      tip.content.toLowerCase().includes(lowercaseQuery) ||
      tip.tags.some(tag => tag.toLowerCase().includes(lowercaseQuery))
    );
  }

  static async getRandomTip(): Promise<HealthTip> {
    await new Promise(resolve => setTimeout(resolve, 200));
    const randomIndex = Math.floor(Math.random() * sampleHealthTips.length);
    return sampleHealthTips[randomIndex];
  }
}
