# eClinic - Modern Healthcare Platform

A comprehensive healthcare platform built with Flutter (mobile) and React (web) using Firebase as the backend. The platform enables seamless communication between patients and healthcare providers through appointment booking, real-time chat, and AI-powered health assistance.

## 🏥 Features

### For Patients
- **User Registration & Authentication** - Secure account creation and login
- **Appointment Booking** - Schedule appointments with available doctors
- **Real-time Chat** - Communicate directly with healthcare providers
- **Dashboard** - View upcoming appointments and medical history
- **AI Health Assistant** - Get preliminary symptom assessments and health guidance

### For Doctors
- **Professional Dashboard** - Manage appointments and patient communications
- **Appointment Management** - Accept, decline, and schedule patient appointments
- **Patient Communication** - Real-time messaging with patients
- **Schedule Overview** - View daily and weekly appointment schedules
- **Patient Records** - Access patient information and appointment history

### Technical Features
- **Cross-Platform** - Flutter mobile app and React web application
- **Real-time Updates** - Firebase Firestore for live data synchronization
- **Secure Authentication** - Firebase Auth with role-based access control
- **Responsive Design** - Optimized for desktop, tablet, and mobile devices
- **AI Integration Ready** - Built-in support for AI-powered features

## 🛠 Technology Stack

### Mobile App (Flutter)
- **Framework**: Flutter 3.x
- **Language**: Dart
- **State Management**: Provider
- **Navigation**: GoRouter
- **UI Components**: Material Design 3

### Web App (React)
- **Framework**: React 18
- **Language**: JavaScript (JSX)
- **Styling**: Tailwind CSS
- **UI Components**: shadcn/ui
- **Icons**: Lucide React
- **Routing**: React Router DOM

### Backend & Database
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **Hosting**: Firebase Hosting
- **Functions**: Firebase Cloud Functions

## 📁 Project Structure

```
eclinic_complete/
├── mobile-app/                 # Flutter mobile application
│   ├── lib/
│   │   ├── models/            # Data models
│   │   ├── screens/           # UI screens
│   │   ├── services/          # Business logic and API calls
│   │   ├── widgets/           # Reusable UI components
│   │   ├── utils/             # Utilities and themes
│   │   └── main.dart          # App entry point
│   └── pubspec.yaml           # Flutter dependencies
├── web-app/                   # React web application
│   ├── src/
│   │   ├── components/        # Reusable React components
│   │   ├── contexts/          # React contexts
│   │   ├── lib/               # Utilities and configurations
│   │   ├── pages/             # Page components
│   │   └── App.jsx            # Main app component
│   └── package.json           # Node.js dependencies
├── firebase-config/           # Firebase configuration files
│   ├── firebase-config.js     # Firebase project configuration
│   └── firestore.rules        # Firestore security rules
├── docs/                      # Documentation
│   └── ai_prompt_guide.md     # AI integration guide
└── README.md                  # This file
```

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** (3.0 or higher)
- **Node.js** (18 or higher)
- **Firebase CLI**
- **Git**

### Firebase Setup

1. **Create a Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project
   - Enable Authentication, Firestore, and Storage

2. **Configure Authentication**
   - Enable Email/Password authentication
   - Set up authorized domains

3. **Set up Firestore**
   - Create a Firestore database
   - Apply the security rules from `firebase-config/firestore.rules`

4. **Get Configuration**
   - Add your web app to Firebase project
   - Copy the configuration object
   - Replace placeholders in `firebase-config/firebase-config.js`

### Mobile App Setup (Flutter)

1. **Navigate to mobile app directory**
   ```bash
   cd mobile-app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Follow [FlutterFire setup guide](https://firebase.flutter.dev/docs/overview)
   - Add `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)

4. **Run the app**
   ```bash
   flutter run
   ```

### Web App Setup (React)

1. **Navigate to web app directory**
   ```bash
   cd web-app
   ```

2. **Install dependencies**
   ```bash
   pnpm install
   ```

3. **Configure Firebase**
   - Update `src/lib/firebase.js` with your Firebase configuration

4. **Start development server**
   ```bash
   pnpm run dev
   ```

5. **Build for production**
   ```bash
   pnpm run build
   ```

## 🔧 Configuration

### Firebase Configuration

Update the Firebase configuration in both applications:

**Mobile App**: `lib/firebase_options.dart` (generated by FlutterFire CLI)

**Web App**: `src/lib/firebase.js`
```javascript
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};
```

### Firestore Security Rules

Apply the security rules from `firebase-config/firestore.rules` to your Firestore database:

```bash
firebase deploy --only firestore:rules
```

## 📱 Usage

### Patient Workflow

1. **Registration**: Create account as a patient
2. **Browse Doctors**: View available healthcare providers
3. **Book Appointment**: Schedule appointment with preferred doctor
4. **Chat**: Communicate with doctor before/after appointment
5. **AI Assistant**: Get preliminary health assessments

### Doctor Workflow

1. **Registration**: Create account as a healthcare provider
2. **Dashboard**: View appointment requests and schedule
3. **Manage Appointments**: Accept or decline appointment requests
4. **Patient Communication**: Chat with patients
5. **Schedule Management**: View daily and weekly schedules

## 🤖 AI Integration

The platform is designed to support AI-powered features. See `docs/ai_prompt_guide.md` for detailed implementation guidance including:

- Symptom checking and health assessments
- Medical chatbot implementation
- Appointment triage and prioritization
- Integration with OpenAI and other AI services
- Security and privacy considerations

## 🔒 Security Features

- **Authentication**: Secure user authentication with Firebase Auth
- **Authorization**: Role-based access control (Patient/Doctor)
- **Data Encryption**: All data encrypted in transit and at rest
- **Security Rules**: Comprehensive Firestore security rules
- **Input Validation**: Client and server-side input validation
- **Privacy Controls**: User data privacy and consent management

## 🧪 Testing

### Mobile App Testing
```bash
cd mobile-app
flutter test
```

### Web App Testing
```bash
cd web-app
pnpm test
```

## 📦 Deployment

### Mobile App Deployment

**Android**:
```bash
flutter build apk --release
```

**iOS**:
```bash
flutter build ios --release
```

### Web App Deployment

**Firebase Hosting**:
```bash
cd web-app
pnpm run build
firebase deploy --only hosting
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:

- **Documentation**: Check the `docs/` directory
- **Issues**: Create an issue on GitHub
- **AI Integration**: Refer to `docs/ai_prompt_guide.md`

## 🗺 Roadmap

### Phase 1 (Current)
- ✅ Basic authentication and user management
- ✅ Appointment booking system
- ✅ Real-time chat functionality
- ✅ Responsive web and mobile interfaces

### Phase 2 (Planned)
- 🔄 AI-powered symptom checker
- 🔄 Advanced appointment scheduling
- 🔄 Medical record management
- 🔄 Prescription management

### Phase 3 (Future)
- 📋 Telemedicine video calls
- 📋 Integration with health devices
- 📋 Advanced analytics and reporting
- 📋 Multi-language support

## 🙏 Acknowledgments

- Firebase for backend infrastructure
- Flutter team for the mobile framework
- React and Tailwind CSS communities
- shadcn/ui for beautiful UI components
- All contributors and testers

---

**eClinic** - Your Health, Our Priority 🏥

