import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';

class StudyGroupsScreen extends ConsumerWidget {
  const StudyGroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Groups'),
        backgroundColor: AppTheme.accentColor,
      ),
      body: const Center(
        child: Text(
          'Study Groups Screen - Coming Soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
