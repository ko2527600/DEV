import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../models/category.dart' as app_category;
import '../models/user.dart' as app_user;
import '../services/supabase_service.dart';

class TaskProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Task> _tasks = [];
  List<app_category.Category> _categories = [];
  app_user.User? _currentUser;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Task> get tasks => _tasks;
  List<app_category.Category> get categories => _categories;
  app_user.User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Filtered task getters
  List<Task> get todoTasks => _tasks.where((task) => task.status == TaskStatus.todo).toList();
  List<Task> get inProgressTasks => _tasks.where((task) => task.status == TaskStatus.inProgress).toList();
  List<Task> get completedTasks => _tasks.where((task) => task.status == TaskStatus.completed).toList();
  List<Task> get overdueTasks => _tasks.where((task) => task.isOverdue).toList();
  List<Task> get dueSoonTasks => _tasks.where((task) => task.isDueSoon).toList();

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _loadUser();
      if (_currentUser != null) {
        await Future.wait([
          _loadTasks(),
          _loadCategories(),
        ]);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Load current user
  Future<void> _loadUser() async {
    print('TaskProvider: Loading user profile...');
    _currentUser = await _supabaseService.getCurrentUserProfile();
    print('TaskProvider: User profile loaded: ${_currentUser?.id}');
    notifyListeners();
  }

  // Load tasks from Supabase
  Future<void> _loadTasks() async {
    try {
      _tasks = await _supabaseService.getTasks();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tasks: $e');
    }
  }

  // Load categories from Supabase
  Future<void> _loadCategories() async {
    try {
      _categories = await _supabaseService.getCategories();
      notifyListeners();
    } catch (e) {
      _setError('Failed to load categories: $e');
    }
  }

  // Authentication methods
  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      await _supabaseService.signIn(email: email, password: password);
      await _loadUser();
      if (_currentUser != null) {
        await Future.wait([
          _loadTasks(),
          _loadCategories(),
        ]);
      }
      _setError(null);
    } catch (e) {
      _setError('Sign in failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signUp(String email, String password, String? fullName) async {
    _setLoading(true);
    try {
      print('TaskProvider: Starting signup...');
      
      await _supabaseService.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      print('TaskProvider: Signup completed, loading user profile...');
      
      // Wait a bit for the profile to be created
      await Future.delayed(Duration(seconds: 1));
      
      // Load the user profile after successful signup
      await _loadUser();
      print('TaskProvider: User profile loaded: ${_currentUser?.id}');
      
      if (_currentUser != null) {
        print('TaskProvider: Loading tasks and categories...');
        await Future.wait([
          _loadTasks(),
          _loadCategories(),
        ]);
        print('TaskProvider: Tasks and categories loaded');
      } else {
        print('TaskProvider: No current user found after signup!');
        _setError('Profile creation failed. Please try signing in instead.');
      }
      
      _setError(null);
    } catch (e) {
      print('TaskProvider: Signup error: $e');
      _setError('Sign up failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabaseService.signOut();
      _currentUser = null;
      _tasks.clear();
      _categories.clear();
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Create a new task
  Future<void> createTask(Task task) async {
    _setLoading(true);
    try {
      final newTask = await _supabaseService.createTask(task);
      _tasks.insert(0, newTask);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create task: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing task
  Future<void> updateTask(Task task) async {
    _setLoading(true);
    try {
      final updatedTask = await _supabaseService.updateTask(task);
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updatedTask;
        _setError(null);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update task: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    _setLoading(true);
    try {
      await _supabaseService.deleteTask(taskId);
      _tasks.removeWhere((task) => task.id == taskId);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete task: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle task completion
  Future<void> toggleTaskCompletion(Task task) async {
    final updatedTask = task.copyWith(
      status: task.status == TaskStatus.completed 
          ? TaskStatus.todo 
          : TaskStatus.completed,
      completedAt: task.status == TaskStatus.completed 
          ? null 
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  // Create a new category
  Future<void> createCategory(app_category.Category category) async {
    _setLoading(true);
    try {
      final newCategory = await _supabaseService.createCategory(category);
      _categories.add(newCategory);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to create category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Update an existing category
  Future<void> updateCategory(app_category.Category category) async {
    _setLoading(true);
    try {
      final updatedCategory = await _supabaseService.updateCategory(category);
      final index = _categories.indexWhere((c) => c.id == category.id);
      if (index != -1) {
        _categories[index] = updatedCategory;
        _setError(null);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to update category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Delete a category
  Future<void> deleteCategory(String categoryId) async {
    _setLoading(true);
    try {
      await _supabaseService.deleteCategory(categoryId);
      _categories.removeWhere((category) => category.id == categoryId);
      _setError(null);
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete category: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get tasks by category
  List<Task> getTasksByCategory(String categoryId) {
    return _tasks.where((task) => task.categoryId == categoryId).toList();
  }

  // Get tasks by priority
  List<Task> getTasksByPriority(TaskPriority priority) {
    return _tasks.where((task) => task.priority == priority).toList();
  }

  // Get tasks by status
  List<Task> getTasksByStatus(TaskStatus status) {
    return _tasks.where((task) => task.status == status).toList();
  }

  // Search tasks
  List<Task> searchTasks(String query) {
    if (query.isEmpty) return _tasks;
    
    final lowercaseQuery = query.toLowerCase();
    return _tasks.where((task) {
      return task.title.toLowerCase().contains(lowercaseQuery) ||
             (task.description?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             task.tags.any((tag) => tag.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  // Mark task as complete
  Future<void> completeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      status: TaskStatus.completed,
      completedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  // Mark task as in progress
  Future<void> startTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      status: TaskStatus.inProgress,
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }

  // Reset task to todo
  Future<void> resetTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);
    final updatedTask = task.copyWith(
      status: TaskStatus.todo,
      completedAt: null,
      updatedAt: DateTime.now(),
    );
    await updateTask(updatedTask);
  }
}
