import 'package:flutter/material.dart';

class StudyTipCard extends StatelessWidget {
  final String title;
  final String tip;
  final String category;
  final int difficulty;

  const StudyTipCard({
    super.key,
    required this.title,
    required this.tip,
    required this.category,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with category and difficulty
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryDisplayName(),
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getDifficultyColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school,
                        color: _getDifficultyColor(),
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Level ${difficulty}',
                        style: TextStyle(
                          color: _getDifficultyColor(),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),

            // Tip content
            Text(
              tip,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),

            // Difficulty indicator
            Row(
              children: [
                Text(
                  'Difficulty: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                ...List.generate(5, (index) {
                  return Icon(
                    index < difficulty ? Icons.star : Icons.star_border,
                    color: index < difficulty ? Colors.orange : Colors.grey[300],
                    size: 16,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _getDifficultyDescription(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getDifficultyColor(),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryDisplayName() {
    switch (category.toLowerCase()) {
      case 'time_management':
        return 'TIME MGMT';
      case 'note_taking':
        return 'NOTES';
      case 'exam_prep':
        return 'EXAM PREP';
      case 'focus':
        return 'FOCUS';
      case 'motivation':
        return 'MOTIVATION';
      default:
        return category.toUpperCase();
    }
  }

  Color _getDifficultyColor() {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blue;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyDescription() {
    switch (difficulty) {
      case 1:
        return 'Beginner';
      case 2:
        return 'Easy';
      case 3:
        return 'Intermediate';
      case 4:
        return 'Advanced';
      case 5:
        return 'Expert';
      default:
        return 'Unknown';
    }
  }
}
