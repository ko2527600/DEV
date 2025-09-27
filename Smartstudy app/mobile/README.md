# SmartStudy Mobile App

A comprehensive educational platform built with Flutter that empowers both students and teachers with modern learning tools and features.

## 🚀 Features

### Core Features
- **User Authentication**: Secure login and registration with Firebase Auth
- **User Types**: Support for both students and teachers
- **Modern UI/UX**: Beautiful Material 3 design with dark/light theme support
- **Responsive Design**: Optimized for various screen sizes
- **Real-time Data**: Firebase Firestore integration for live data updates

### Educational Features
- **Dashboard**: Personalized home screen with quick actions and progress tracking
- **Course Management**: Browse and enroll in courses (coming soon)
- **Progress Tracking**: Monitor learning progress and achievements (coming soon)
- **Study Groups**: Collaborative learning spaces (coming soon)
- **Resources Library**: Access to educational materials (coming soon)

### Technical Features
- **State Management**: Riverpod for efficient state management
- **Navigation**: Go Router for type-safe navigation
- **Firebase Integration**: Authentication, Firestore, Storage, and Messaging
- **Offline Support**: Local data caching with Hive
- **Media Support**: Video player, PDF viewer, and image handling
- **Analytics**: Charts and progress visualization

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Riverpod
- **Navigation**: Go Router
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Local Storage**: Hive
- **UI Components**: Material 3, Google Fonts, Lottie Animations
- **Media**: Video Player, PDF Viewer, Image Picker
- **Charts**: FL Chart

## 📱 Screenshots

### Authentication Screens
- Beautiful splash screen with animations
- Modern login screen with form validation
- Comprehensive registration with user type selection

### Dashboard
- Personalized welcome section
- Quick action cards for easy navigation
- Recent activity feed
- Recommended courses carousel
- Bottom navigation with 4 main tabs

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Dart SDK
- Android Studio / VS Code
- Firebase project setup

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android app to Firebase project
   - Download `google-services.json` and place it in `android/app/`
   - Enable Authentication and Firestore in Firebase console

4. **Run the app**
   ```bash
   flutter run
   ```

### Firebase Configuration

1. **Authentication**
   - Enable Email/Password authentication
   - Configure sign-in methods

2. **Firestore Database**
   - Create database in test mode
   - Set up security rules

3. **Storage** (optional)
   - Enable Firebase Storage
   - Configure storage rules

## 📁 Project Structure

```
lib/
├── core/
│   ├── providers/
│   │   └── auth_provider.dart
│   ├── routes/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       └── screens/
│   │           ├── login_screen.dart
│   │           └── register_screen.dart
│   ├── dashboard/
│   │   └── presentation/
│   │       └── screens/
│   │           └── dashboard_screen.dart
│   └── splash/
│       └── presentation/
│           └── screens/
│               └── splash_screen.dart
├── shared/
└── main.dart
```

## 🎨 Design System

### Colors
- **Primary**: Indigo (#6366F1)
- **Secondary**: Emerald (#10B981)
- **Accent**: Amber (#F59E0B)
- **Error**: Red (#EF4444)
- **Success**: Green (#22C55E)
- **Info**: Blue (#3B82F6)

### Typography
- **Font Family**: Inter (Google Fonts)
- **Headings**: Bold weights for emphasis
- **Body**: Regular weights for readability

### Components
- **Cards**: Rounded corners with subtle shadows
- **Buttons**: Elevated and outlined variants
- **Input Fields**: Modern design with validation states
- **Navigation**: Bottom navigation with icons and labels

## 🔧 Configuration

### Environment Variables
Create a `.env` file in the root directory:
```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
```

### Firebase Rules
Set up Firestore security rules:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🚀 Deployment

### Android
1. **Build APK**
   ```bash
   flutter build apk --release
   ```

2. **Build App Bundle**
   ```bash
   flutter build appbundle --release
   ```

### iOS
1. **Build for iOS**
   ```bash
   flutter build ios --release
   ```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

For support and questions:
- Create an issue in the repository
- Contact the development team
- Check the documentation

## 🔮 Roadmap

### Phase 1 (Current)
- ✅ User authentication
- ✅ Basic dashboard
- ✅ Navigation structure

### Phase 2 (Next)
- [ ] Course management system
- [ ] Progress tracking
- [ ] Study groups
- [ ] Notifications

### Phase 3 (Future)
- [ ] Advanced analytics
- [ ] AI-powered recommendations
- [ ] Video conferencing
- [ ] Mobile payments

---

**Built with ❤️ for education**
