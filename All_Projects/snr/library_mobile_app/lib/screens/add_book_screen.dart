import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/books_provider.dart';
import '../models/book.dart';

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorController = TextEditingController();
  final _isbnController = TextEditingController();
  final _courseCodeController = TextEditingController();
  final _courseNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverImageUrlController = TextEditingController();
  final _totalCopiesController = TextEditingController(text: '1');
  final _locationController = TextEditingController();
  final _publicationYearController = TextEditingController();

  String _selectedCategory = 'course';
  String _selectedSubject = 'Mathematics';
  bool _isLoading = false;

  final List<String> _categories = ['course', 'life'];
  final List<String> _courseSubjects = [
    'Mathematics',
    'Science',
    'Computer Science',
    'History',
    'Literature',
    'Geography',
    'Economics',
    'Psychology',
    'Philosophy',
    'Art',
    'Music',
    'Physical Education',
  ];
  final List<String> _lifeSubjects = [
    'Self-Help',
    'Business',
    'Finance',
    'Health & Fitness',
    'Cooking',
    'Travel',
    'Biography',
    'Fiction',
    'Non-Fiction',
    'Religion',
    'Politics',
    'Technology',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _isbnController.dispose();
    _courseCodeController.dispose();
    _courseNameController.dispose();
    _descriptionController.dispose();
    _coverImageUrlController.dispose();
    _totalCopiesController.dispose();
    _locationController.dispose();
    _publicationYearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Add New Book',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor.withOpacity(0.1),
                      Theme.of(context).primaryColor.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      size: 48,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Add a New Book to Your Library',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Fill in the details below to add a new book to your collection',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Basic Information Section
              _buildSectionHeader('Basic Information', Icons.book),
              const SizedBox(height: 16),

              // Title
              _buildTextField(
                controller: _titleController,
                label: 'Book Title *',
                hint: 'Enter the book title',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a book title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Author
              _buildTextField(
                controller: _authorController,
                label: 'Author *',
                hint: 'Enter the author name',
                icon: Icons.person,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an author name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category and Subject
              Row(
                children: [
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Category *',
                      value: _selectedCategory,
                      items: _categories.map((cat) => 
                        DropdownMenuItem(
                          value: cat,
                          child: Text(cat.capitalize()),
                        )
                      ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          // Reset subject when category changes
                          _selectedSubject = _selectedCategory == 'course' 
                              ? _courseSubjects.first 
                              : _lifeSubjects.first;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildDropdownField(
                      label: 'Subject *',
                      value: _selectedSubject,
                      items: (_selectedCategory == 'course' ? _courseSubjects : _lifeSubjects)
                          .map((subject) => 
                            DropdownMenuItem(
                              value: subject,
                              child: Text(subject),
                            )
                          ).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedSubject = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Additional Details Section
              _buildSectionHeader('Additional Details', Icons.info),
              const SizedBox(height: 16),

              // ISBN
              _buildTextField(
                controller: _isbnController,
                label: 'ISBN',
                hint: 'Enter ISBN (optional)',
                icon: Icons.qr_code,
              ),
              const SizedBox(height: 16),

              // Course Information (if course book)
              if (_selectedCategory == 'course') ...[
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _courseCodeController,
                        label: 'Course Code',
                        hint: 'e.g., MATH101',
                        icon: Icons.code,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        controller: _courseNameController,
                        label: 'Course Name',
                        hint: 'e.g., Calculus I',
                        icon: Icons.school,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Description
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Enter book description (optional)',
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Cover Image URL
              _buildTextField(
                controller: _coverImageUrlController,
                label: 'Cover Image URL',
                hint: 'Enter cover image URL (optional)',
                icon: Icons.image,
              ),
              const SizedBox(height: 24),

              // Library Information Section
              _buildSectionHeader('Library Information', Icons.library_books),
              const SizedBox(height: 16),

              // Total Copies and Location
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalCopiesController,
                      label: 'Total Copies *',
                      hint: '1',
                      icon: Icons.copy,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter number of copies';
                        }
                        final copies = int.tryParse(value);
                        if (copies == null || copies < 1) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _locationController,
                      label: 'Shelf Location *',
                      hint: 'e.g., A1-B2',
                      icon: Icons.place,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter shelf location';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Publication Year
              _buildTextField(
                controller: _publicationYearController,
                label: 'Publication Year',
                hint: 'e.g., 2023',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Add Book to Library',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[300]!, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
          ),
        ),
      ],
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await context.read<BooksProvider>().addBook(
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        category: _selectedCategory,
        subjectName: _selectedSubject,
        isbn: _isbnController.text.trim().isEmpty ? null : _isbnController.text.trim(),
        courseCode: _courseCodeController.text.trim().isEmpty ? null : _courseCodeController.text.trim(),
        courseName: _courseNameController.text.trim().isEmpty ? null : _courseNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty ? null : _descriptionController.text.trim(),
        coverImageUrl: _coverImageUrlController.text.trim().isEmpty ? null : _coverImageUrlController.text.trim(),
        totalCopies: int.parse(_totalCopiesController.text.trim()),
        location: _locationController.text.trim(),
        publicationYear: _publicationYearController.text.trim().isEmpty 
            ? null 
            : DateTime(int.parse(_publicationYearController.text.trim())),
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Book added successfully!'),
              backgroundColor: Colors.green[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.read<BooksProvider>().error ?? 'Failed to add book'),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
