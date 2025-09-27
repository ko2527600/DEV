import 'package:flutter/material.dart';
import '../models/academic_guide.dart';
import '../widgets/academic_card.dart';
import '../widgets/conduct_rule_card.dart';
import '../widgets/relationship_card.dart';
import '../widgets/study_tip_card.dart';

class AcademicGrowthScreen extends StatefulWidget {
  const AcademicGrowthScreen({super.key});

  @override
  State<AcademicGrowthScreen> createState() => _AcademicGrowthScreenState();
}

class _AcademicGrowthScreenState extends State<AcademicGrowthScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // Beautiful Header
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.indigo,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Academic Growth',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.indigo, Colors.purple],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      Icon(
                        Icons.school,
                        size: 48,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your Path to Academic Excellence',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Category Tabs
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.indigo,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Conduct'),
                  Tab(text: 'Relations'),
                  Tab(text: 'Study Tips'),
                  Tab(text: 'Resources'),
                ],
              ),
            ),
          ),

          // Content based on selected tab
          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildConductTab(),
                  _buildRelationsTab(),
                  _buildStudyTipsTab(),
                  _buildResourcesTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWelcomeCard(),
          const SizedBox(height: 16),
          _buildQuickStats(),
          const SizedBox(height: 16),
          _buildFeaturedContent(),
        ],
      ),
    );
  }

  Widget _buildConductTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Academic Conduct Rules',
            'Essential guidelines for maintaining academic integrity and proper behavior',
            Icons.gavel,
            Colors.red,
          ),
          const SizedBox(height: 16),
          _buildConductRules(),
        ],
      ),
    );
  }

  Widget _buildRelationsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Teacher-Member Relationships',
            'Building positive and productive relationships with educators',
            Icons.people,
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildRelationshipGuidelines(),
        ],
      ),
    );
  }

  Widget _buildStudyTipsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Study Tips & Strategies',
            'Proven methods to enhance your learning and academic performance',
            Icons.lightbulb,
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildStudyTips(),
        ],
      ),
    );
  }

  Widget _buildResourcesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Academic Resources',
            'Tools, links, and materials to support your educational journey',
            Icons.link,
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildAcademicResources(),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.indigo, Colors.purple],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome to Academic Growth!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Discover tools and guidance to excel in your studies',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Conduct Rules',
            '15',
            Icons.gavel,
            Colors.red,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Study Tips',
            '25+',
            Icons.lightbulb,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Resources',
            '30+',
            Icons.link,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Featured Content',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 12),
        _buildFeaturedCard(
          'Academic Integrity',
          'Understanding plagiarism and proper citation',
          Icons.verified_user,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildFeaturedCard(
          'Effective Communication',
          'How to approach teachers and ask for help',
          Icons.chat_bubble,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConductRules() {
    // Comprehensive conduct rules for academic integrity
    final rules = [
      {
        'title': 'Academic Honesty & Integrity',
        'rule': 'Maintain the highest standards of academic integrity. All submitted work must be your own original creation. Properly cite all sources using approved citation formats. Plagiarism, cheating, or any form of academic dishonesty is strictly prohibited.',
        'severity': 'critical',
        'category': 'academic_integrity',
      },
      {
        'title': 'Classroom Behavior & Respect',
        'rule': 'Demonstrate respect for instructors, peers, and the learning environment. Arrive on time, be prepared, participate constructively, and maintain appropriate classroom decorum. Electronic devices should be used only for educational purposes.',
        'severity': 'high',
        'category': 'classroom',
      },
      {
        'title': 'Examination & Assessment Conduct',
        'rule': 'Follow all examination rules and procedures. No unauthorized materials, communication, or assistance during assessments. Maintain silence and focus. Report any suspected violations immediately to the instructor.',
        'severity': 'critical',
        'category': 'examination',
      },
      {
        'title': 'Assignment & Project Guidelines',
        'rule': 'Submit assignments by specified deadlines. Follow formatting and submission requirements. Group work must reflect equal contribution from all members. Late submissions may result in grade penalties.',
        'severity': 'medium',
        'category': 'assignments',
      },
      {
        'title': 'Library & Resource Usage',
        'rule': 'Respect library resources and facilities. Return borrowed materials on time. Maintain quiet study environments. Follow computer lab and equipment usage policies. Report damaged or missing resources.',
        'severity': 'medium',
        'category': 'resources',
      },
      {
        'title': 'Digital Citizenship & Online Behavior',
        'rule': 'Use technology responsibly and ethically. Respect digital privacy and intellectual property. Maintain professional online communication. Report cyberbullying or inappropriate online behavior.',
        'severity': 'high',
        'category': 'digital',
      },
    ];

    return Column(
      children: rules.map((rule) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: ConductRuleCard(
            title: rule['title']!,
            rule: rule['rule']!,
            severity: rule['severity']!,
            category: rule['category']!,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRelationshipGuidelines() {
    // Professional teacher-student relationship guidelines
    final guidelines = [
      {
        'title': 'Professional Communication',
        'description': 'Establish and maintain respectful, professional communication with educators',
        'tips': [
          'Use appropriate titles (Dr., Professor, Mr., Ms.)',
          'Maintain formal language in written communication',
          'Be concise and specific in your requests',
          'Show appreciation for their time and expertise'
        ],
        'dos': [
          'Schedule appointments during office hours',
          'Prepare specific questions before meetings',
          'Follow up on discussions and recommendations',
          'Express gratitude for assistance received'
        ],
        'donts': [
          'Use informal or disrespectful language',
          'Make demands or expect immediate responses',
          'Interrupt during class or meetings',
          'Share personal information inappropriately'
        ],
      },
      {
        'title': 'Seeking Academic Support',
        'description': 'How to effectively request help and support from educators',
        'tips': [
          'Attempt the work independently first',
          'Identify specific areas of difficulty',
          'Bring your attempted solutions',
          'Ask for clarification on concepts'
        ],
        'dos': [
          'Show evidence of your effort',
          'Be specific about what you need help with',
          'Ask for additional resources or examples',
          'Follow through on suggested strategies'
        ],
        'donts': [
          'Ask for answers without trying',
          'Expect others to do your work',
          'Complain about grades without understanding',
          'Make excuses for incomplete work'
        ],
      },
      {
        'title': 'Building Academic Relationships',
        'description': 'Developing positive, productive relationships with faculty members',
        'tips': [
          'Participate actively in class discussions',
          'Show genuine interest in the subject matter',
          'Attend office hours regularly',
          'Seek feedback on your work'
        ],
        'dos': [
          'Demonstrate consistent effort and improvement',
          'Take initiative in your learning',
          'Respect different perspectives and opinions',
          'Contribute positively to the learning environment'
        ],
        'donts': [
          'Be passive or disengaged in class',
          'Argue aggressively about grades',
          'Make personal attacks or complaints',
          'Expect special treatment or exceptions'
        ],
      },
      {
        'title': 'Conflict Resolution',
        'description': 'Handling disagreements or concerns professionally',
        'tips': [
          'Address issues promptly and privately',
          'Focus on the specific problem, not the person',
          'Listen to the other perspective',
          'Seek common ground and solutions'
        ],
        'dos': [
          'Use "I" statements to express concerns',
          'Provide specific examples and evidence',
          'Request clarification when needed',
          'Follow established grievance procedures'
        ],
        'donts': [
          'Make accusations without evidence',
          'Discuss issues publicly or on social media',
          'Let problems escalate unnecessarily',
          'Refuse to consider alternative viewpoints'
        ],
      },
    ];

    return Column(
      children: guidelines.map((guideline) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: RelationshipCard(
            title: guideline['title']!.toString(),
            description: guideline['description']!.toString(),
            tips: List<String>.from((guideline['tips'] as List).cast<String>()),
            dos: List<String>.from((guideline['dos'] as List).cast<String>()),
            donts: List<String>.from((guideline['donts'] as List).cast<String>()),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStudyTips() {
    // Professional study strategies and tips
    final tips = [
      {
        'title': 'Effective Time Management',
        'tip': 'Implement the Pomodoro Technique: 25 minutes of focused work followed by 5-minute breaks. Use time-blocking to allocate specific periods for different subjects. Prioritize tasks using the Eisenhower Matrix (urgent vs. important).',
        'category': 'time_management',
        'difficulty': 2,
      },
      {
        'title': 'Advanced Note-Taking Methods',
        'tip': 'Utilize the Cornell Method: divide your paper into sections for notes, key points, and summaries. Use mind mapping for complex topics. Implement the Feynman Technique: explain concepts in simple terms to identify knowledge gaps.',
        'category': 'note_taking',
        'difficulty': 3,
      },
      {
        'title': 'Active Learning Strategies',
        'tip': 'Practice active recall by testing yourself instead of passive re-reading. Use spaced repetition techniques to review material at optimal intervals. Create practice questions and teach concepts to others.',
        'category': 'learning_methods',
        'difficulty': 3,
      },
      {
        'title': 'Critical Thinking Development',
        'tip': 'Question assumptions and evaluate evidence critically. Analyze arguments for logical fallacies. Consider multiple perspectives and alternative explanations. Practice metacognition by reflecting on your thinking process.',
        'category': 'critical_thinking',
        'difficulty': 4,
      },
      {
        'title': 'Research & Information Literacy',
        'tip': 'Evaluate sources for credibility, accuracy, and relevance. Use multiple sources to verify information. Understand different types of research methodologies. Practice proper citation and avoid plagiarism.',
        'category': 'research_skills',
        'difficulty': 3,
      },
      {
        'title': 'Stress Management & Wellness',
        'tip': 'Maintain regular sleep, exercise, and nutrition schedules. Practice mindfulness and relaxation techniques. Set realistic goals and celebrate small achievements. Seek support when feeling overwhelmed.',
        'category': 'wellness',
        'difficulty': 2,
      },
    ];

    return Column(
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: StudyTipCard(
            title: tip['title']!.toString(),
            tip: tip['tip']!.toString(),
            category: tip['category']!.toString(),
            difficulty: int.parse(tip['difficulty']!.toString()),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAcademicResources() {
    return Column(
      children: [
        _buildResourceCard(
          'Study Apps',
          'Recommended apps for productivity and learning',
          Icons.phone_android,
          Colors.blue,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Online Libraries',
          'Access to digital books and research materials',
          Icons.library_books,
          Colors.green,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Tutoring Services',
          'Get help from peer tutors and academic support',
          Icons.school,
          Colors.orange,
        ),
        const SizedBox(height: 12),
        _buildResourceCard(
          'Academic Calendar',
          'Important dates and deadlines',
          Icons.calendar_today,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildResourceCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
        ],
      ),
    );
  }
}
