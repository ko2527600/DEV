class AppConstants {
  // App Information
  static const String appName = 'FarmLink Ghana';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Connecting farmers to buyers for sustainable agriculture';
  
  // Colors
  static const int primaryColor = 0xFF2E7D32; // Green - Agriculture
  static const int secondaryColor = 0xFFFF9800; // Orange - Harvest
  static const int accentColor = 0xFF2196F3; // Blue - Trust
  static const int backgroundColor = 0xFFF5F5F5; // Light Gray
  static const int textColor = 0xFF212121; // Dark Gray
  static const int textColorLight = 0xFF757575; // Light Gray for secondary text
  static const int successColor = 0xFF4CAF50; // Success Green
  static const int warningColor = 0xFFFF9800; // Warning Orange
  static const int errorColor = 0xFFF44336; // Error Red
  
  // Text Styles
  static const double fontSizeSmall = 12.0;
  static const double fontSizeNormal = 16.0;
  static const double fontSizeLarge = 20.0;
  static const double fontSizeExtraLarge = 24.0;
  
  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 12.0;
  static const double spacingNormal = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 32.0;
  
  // Border Radius
  static const double borderRadiusSmall = 4.0;
  static const double borderRadiusNormal = 8.0;
  static const double borderRadiusLarge = 16.0;
  
  // Animation Durations
  static const Duration animationDurationFast = Duration(milliseconds: 200);
  static const Duration animationDurationNormal = Duration(milliseconds: 300);
  static const Duration animationDurationSlow = Duration(milliseconds: 500);
  
  // API Configuration
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  
  // Image Configuration
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const double maxImageWidth = 1920.0;
  static const double maxImageHeight = 1080.0;
  static const int imageQuality = 80;
  static const int maxImagesPerProduct = 5;
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Validation
  static const int minPasswordLength = 6;
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  
  // Business Logic
  static const List<String> productCategories = [
    'Grains',
    'Vegetables',
    'Fruits',
    'Tubers',
    'Legumes',
    'Herbs',
    'Livestock',
    'Dairy',
    'Other'
  ];
  
  static const List<String> productUnits = [
    'kg',
    'pieces',
    'bags',
    'bunches',
    'liters',
    'dozens',
    'tons'
  ];
  
  static const List<String> businessTypes = [
    'Wholesaler',
    'Retailer',
    'Restaurant',
    'Processor',
    'Exporter',
    'Individual Consumer',
    'Other'
  ];
}
