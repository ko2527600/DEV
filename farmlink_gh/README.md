# FarmLink Ghana - Mobile App

A complete Flutter mobile application for connecting farmers and buyers in Ghana using Supabase backend services.

## 🚀 Project Status: **PHASE 1 COMPLETED - 45% OVERALL PROGRESS**

### ✅ **Completed Features (Phase 1 + 2 Partial)**
- **Project Setup & Configuration** - Complete Flutter project with Supabase integration
- **Database Schema Implementation** - Full database structure with all required tables
- **Authentication System** - Complete user registration, login, and profile management
- **Farmer Dashboard** - Full dashboard with product management and analytics
- **Product Management System** - Complete CRUD operations for products with image handling
- **Buyer Experience** - Product browsing, search, filtering, and detailed views
- **Messaging System** - Real-time chat between farmers and buyers
- **Location Services** - GPS integration and location-based features
- **Image Management** - Image picking, compression, and storage

### 🔄 **In Progress (Phase 2)**
- **Search & Filtering** - Advanced search and filtering capabilities
- **Offline Support** - Local data storage and offline functionality
- **Performance Optimization** - Query optimization and lazy loading

### 📋 **Remaining Features (Phase 3)**
- **UI/UX Polish** - Final design refinements and animations
- **Testing & Bug Fixes** - Comprehensive testing and bug resolution
- **Documentation & Deployment** - Final documentation and app store preparation

## 🏗️ Architecture

### **Frontend (Flutter)**
- **State Management**: Provider pattern for app-wide state
- **UI Framework**: Material Design 3 with custom theming
- **Navigation**: Stack-based navigation with proper routing
- **Responsive Design**: Adaptive layouts for different screen sizes

### **Backend (Supabase)**
- **Database**: PostgreSQL with Row Level Security (RLS)
- **Authentication**: Supabase Auth with email/password
- **Storage**: Supabase Storage for image management
- **Real-time**: WebSocket connections for live messaging
- **API**: RESTful API with automatic CRUD operations

## 📱 Screens & Features

### **Authentication Screens**
- **Splash Screen**: App initialization and loading
- **User Type Selection**: Choose between farmer and buyer roles
- **Registration**: Complete user profile creation
- **Login**: Secure authentication system
- **Profile Management**: Edit user information and preferences

### **Farmer Dashboard**
- **Main Dashboard**: Overview with statistics and quick actions
- **Add Product**: Multi-image upload with product details
- **Edit Product**: Modify existing products and images
- **Product Management**: View, edit, and delete products
- **Analytics**: Basic statistics and insights

### **Buyer Experience**
- **Product Browser**: Grid/list view of all available products
- **Search & Filter**: Advanced search with category filtering
- **Product Details**: Comprehensive product information
- **Farmer Contact**: Direct messaging to product owners
- **Favorites**: Save products for later (coming soon)

### **Messaging System**
- **Conversations List**: All user conversations
- **Chat Interface**: Real-time messaging with read receipts
- **Message Notifications**: Unread message indicators
- **User Profiles**: View other user information

## 🛠️ Technical Implementation

### **Core Services**
- **AuthService**: User authentication and session management
- **UserService**: User profile and type-specific data management
- **ProductService**: Product CRUD operations and image handling
- **MessageService**: Real-time messaging and conversation management
- **LocationService**: GPS integration and location utilities
- **ImageService**: Image picking, compression, and validation

### **Data Models**
- **UserModel**: Base user information and authentication
- **FarmerModel**: Farmer-specific profile data
- **BuyerModel**: Buyer-specific profile data
- **ProductModel**: Product information and metadata
- **MessageModel**: Chat message structure

### **Key Widgets**
- **ProductCard**: Reusable product display component
- **StatsCard**: Dashboard statistics display
- **SearchBarWidget**: Debounced search functionality
- **CategoryFilterWidget**: Product category filtering
- **ImageCarouselWidget**: Product image carousel
- **Custom Form Fields**: Validated input components

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK 3.8.1+
- Dart SDK 3.8.1+
- Android Studio / VS Code
- Supabase account and project

### **Installation**

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/farmlink_gh.git
   cd farmlink_gh
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Supabase**
   - Create a new Supabase project
   - Run the SQL scripts from `storage_setup.sql`
   - Create storage buckets for product images
   - Set up Row Level Security policies

4. **Environment Configuration**
   - Copy `env_template.txt` to `.env`
   - Add your Supabase URL and anon key
   - Configure storage bucket names

5. **Run the app**
   ```bash
   flutter run
   ```

### **Database Setup**

Run these SQL commands in your Supabase SQL editor:

```sql
-- Users table (extends Supabase auth.users)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    phone_number TEXT,
    user_type TEXT CHECK (user_type IN ('farmer', 'buyer')),
    profile_image_url TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Farmers table
CREATE TABLE IF NOT EXISTS public.farmers (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    farm_name TEXT,
    farm_location TEXT,
    farm_size TEXT,
    description TEXT,
    verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Buyers table
CREATE TABLE IF NOT EXISTS public.buyers (
    id UUID PRIMARY KEY REFERENCES public.users(id) ON DELETE CASCADE,
    company_name TEXT,
    business_type TEXT,
    location TEXT,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Products table
CREATE TABLE IF NOT EXISTS public.products (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    farmer_id UUID REFERENCES public.farmers(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2),
    quantity_available INTEGER,
    category TEXT,
    images TEXT[],
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table
CREATE TABLE IF NOT EXISTS public.messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    receiver_id UUID REFERENCES public.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT FALSE
);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.farmers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buyers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
```

## 📱 App Features

### **For Farmers**
- ✅ Complete product management system
- ✅ Multi-image upload and management
- ✅ Dashboard with analytics
- ✅ Real-time messaging with buyers
- ✅ Profile and farm information management

### **For Buyers**
- ✅ Browse all available products
- ✅ Advanced search and filtering
- ✅ Product details and farmer information
- ✅ Direct messaging to farmers
- ✅ User profile management

### **General Features**
- ✅ Secure authentication system
- ✅ Real-time messaging
- ✅ Image compression and optimization
- ✅ Location services integration
- ✅ Responsive design for all devices

## 🔧 Configuration

### **Environment Variables**
```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_supabase_anon_key
SUPABASE_STORAGE_BUCKET=product-images
```

### **App Constants**
- **Colors**: Custom color scheme for agriculture theme
- **Spacing**: Consistent spacing system throughout the app
- **Typography**: Standardized font sizes and weights
- **Validation**: Input validation rules and limits

## 🧪 Testing

### **Current Test Coverage**
- Unit tests for core services (coming soon)
- Integration tests for key workflows (coming soon)
- UI tests for critical user paths (coming soon)

### **Testing Strategy**
- **Unit Tests**: Service layer and business logic
- **Integration Tests**: API interactions and data flow
- **Widget Tests**: UI component behavior
- **End-to-End Tests**: Complete user workflows

## 🚀 Deployment

### **Android**
- Configure signing keys
- Update version in `pubspec.yaml`
- Build APK: `flutter build apk --release`
- Build App Bundle: `flutter build appbundle --release`

### **iOS**
- Configure signing and provisioning
- Update version in `pubspec.yaml`
- Build: `flutter build ios --release`
- Archive and upload to App Store Connect

## 📊 Performance Metrics

### **Target Performance**
- **App Launch**: < 3 seconds
- **Image Loading**: < 2 seconds
- **Search Response**: < 1 second
- **Message Delivery**: < 500ms

### **Optimization Features**
- Image compression and caching
- Lazy loading for product lists
- Pagination for large datasets
- Efficient database queries

## 🔒 Security Features

### **Authentication & Authorization**
- Secure password handling
- JWT token management
- Row Level Security (RLS)
- User role validation

### **Data Protection**
- Input validation and sanitization
- SQL injection prevention
- XSS protection
- Secure file upload validation

## 🌟 Future Enhancements

### **Phase 3 Features**
- **Advanced Analytics**: Detailed insights and reporting
- **Payment Integration**: Secure payment processing
- **Push Notifications**: Real-time alerts and updates
- **Social Features**: User reviews and ratings
- **Market Insights**: Price trends and market analysis

### **Advanced Features**
- **AI-Powered Recommendations**: Smart product suggestions
- **Blockchain Integration**: Transparent supply chain tracking
- **Multi-language Support**: Local language interfaces
- **Advanced Search**: AI-powered product discovery

## 🤝 Contributing

### **Development Workflow**
1. Fork the repository
2. Create a feature branch
3. Implement your changes
4. Add tests and documentation
5. Submit a pull request

### **Code Standards**
- Follow Flutter/Dart style guidelines
- Use meaningful variable and function names
- Add comprehensive comments for complex logic
- Ensure proper error handling

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Flutter Team** for the amazing framework
- **Supabase** for the powerful backend services
- **Ghanaian Farmers** for inspiring this project
- **Open Source Community** for the tools and libraries

## 📞 Support

### **Documentation**
- [Project Documentation](PROJECT_DOCUMENTATION.md)
- [Design Specifications](DESIGN.md)
- [Requirements](REQUIREMENTS.md)
- [Task Tracking](TASKS.md)

### **Contact**
- **Project Issues**: [GitHub Issues](https://github.com/yourusername/farmlink_gh/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/yourusername/farmlink_gh/discussions)
- **Support**: [Email Support](mailto:support@farmlinkgh.com)

---

**FarmLink Ghana** - Connecting farmers to buyers for sustainable agriculture in Ghana 🇬🇭
