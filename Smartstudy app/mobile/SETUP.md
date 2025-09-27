# SmartStudy Mobile App - Quick Setup Guide

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0 or higher)
- Android Studio / VS Code
- Android emulator or physical device
- Firebase project

### Quick Start

1. **Navigate to the mobile directory**
   ```bash
   cd mobile
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

   Or use the batch file:
   ```bash
   run_app.bat
   ```

## 🔧 Firebase Setup

### 1. Create Firebase Project
- Go to [Firebase Console](https://console.firebase.google.com/)
- Create a new project named "smartstudy-ghana"

### 2. Add Android App
- In Firebase Console, click "Add app" → Android
- Package name: `com.example.smartstudy`
- Download `google-services.json`
- Place it in `android/app/` directory

### 3. Enable Services
- **Authentication**: Enable Email/Password sign-in
- **Firestore Database**: Create database in test mode
- **Storage**: Enable (optional)

### 4. Update Firebase Configuration
- Update `lib/firebase_options.dart` with your project settings
- Replace the placeholder values with your actual Firebase config

## 📱 Running the App

### Option 1: Command Line
```bash
cd mobile
flutter run
```

### Option 2: Batch File
```bash
cd mobile
run_app.bat
```

### Option 3: IDE
- Open the `mobile` folder in your IDE
- Run `flutter run` from the terminal

## 🎯 What You'll See

1. **Splash Screen**: Beautiful animated welcome screen
2. **Login Screen**: Modern authentication with form validation
3. **Register Screen**: User registration with role selection
4. **Dashboard**: Personalized home screen with navigation

## 🔍 Troubleshooting

### Common Issues

1. **"No pubspec.yaml found"**
   - Make sure you're in the `mobile` directory
   - Run `cd mobile` first

2. **Firebase connection errors**
   - Check your `google-services.json` file
   - Verify Firebase project settings
   - Ensure services are enabled in Firebase Console

3. **Dependencies not found**
   - Run `flutter pub get`
   - Check your internet connection

4. **Build errors**
   - Run `flutter clean`
   - Then `flutter pub get`
   - Finally `flutter run`

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Review the main README.md file
3. Check Flutter and Firebase documentation

---

**Happy coding! 🎉** 