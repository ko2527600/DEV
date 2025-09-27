import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'core/config/supabase_config.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/app_provider.dart';
import 'core/providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'core/config/env_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: '.env');
    
    // Debug: Print loaded environment variables
    print('🔍 Environment Variables Loaded:');
    print('SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
    print('SUPABASE_ANON_KEY: ${dotenv.env['SUPABASE_ANON_KEY']?.substring(0, 20)}...');
    print('SUPABASE_SERVICE_ROLE_KEY: ${dotenv.env['SUPABASE_SERVICE_ROLE_KEY']?.substring(0, 20)}...');
    
    // Additional debug from EnvConfig
    print('🔍 Calling EnvConfig.debugEnvVars()...');
    EnvConfig.debugEnvVars();
    
    // Initialize Supabase
    await SupabaseConfig.initialize();
    
    runApp(const FarmLinkApp());
  } catch (e) {
    // Handle initialization errors gracefully
    print('❌ Main initialization error: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

class FarmLinkApp extends StatelessWidget {
  const FarmLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.green,
          primaryColor: Color(AppConstants.primaryColor),
          colorScheme: ColorScheme.fromSeed(
            seedColor: Color(AppConstants.primaryColor),
            brightness: Brightness.light,
          ),
          // fontFamily: 'Roboto',
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(AppConstants.primaryColor),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColor),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.spacingLarge,
                vertical: AppConstants.spacingNormal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
              borderSide: const BorderSide(
                color: Color(AppConstants.primaryColor),
                width: 2,
              ),
            ),
          ),
        ),
        home: const SplashScreen(),
      ),
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;
  
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FarmLink Ghana - Error',
      home: Scaffold(
        backgroundColor: Color(AppConstants.errorColor),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.spacingLarge),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 64,
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                const Text(
                  'Initialization Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppConstants.fontSizeExtraLarge,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppConstants.spacingNormal),
                Text(
                  error,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppConstants.fontSizeNormal,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppConstants.spacingLarge),
                const Text(
                  'Please check your configuration and try again.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: AppConstants.fontSizeSmall,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
