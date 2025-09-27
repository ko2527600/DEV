class Loan {
  final String id;
  final String userId;
  final String bookId;
  final DateTime loanDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final String status; // 'borrowed', 'returned', 'overdue'
  final DateTime createdAt;
  final DateTime updatedAt;

  // Additional fields for display
  final String? bookTitle;
  final String? bookAuthor;
  final String? userName;

  Loan({
    required this.id,
    required this.userId,
    required this.bookId,
    required this.loanDate,
    required this.dueDate,
    this.returnDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.bookTitle,
    this.bookAuthor,
    this.userName,
  });

  bool get isOverdue => DateTime.now().isAfter(dueDate) && status == 'borrowed';
  bool get isReturned => status == 'returned';
  bool get isActive => status == 'borrowed';
  
  int get daysOverdue {
    if (!isOverdue) return 0;
    return DateTime.now().difference(dueDate).inDays;
  }

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'],
      userId: json['user_id'],
      bookId: json['book_id'],
      loanDate: DateTime.parse(json['loan_date']),
      dueDate: DateTime.parse(json['due_date']),
      returnDate: json['return_date'] != null 
          ? DateTime.parse(json['return_date']) 
          : null,
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      bookTitle: json['book_title'],
      bookAuthor: json['book_author'],
      userName: json['user_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'book_id': bookId,
      'loan_date': loanDate.toIso8601String(),
      'due_date': dueDate.toIso8601String(),
      'return_date': returnDate?.toIso8601String(),
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'book_title': bookTitle,
      'book_author': bookAuthor,
      'user_name': userName,
    };
  }
}
