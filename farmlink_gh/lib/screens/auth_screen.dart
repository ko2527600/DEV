import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../core/providers/auth_provider.dart';
import '../core/providers/app_provider.dart';
import '../screens/splash_screen.dart'; // Added import for SplashScreen

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _farmNameController = TextEditingController();
  final TextEditingController _farmLocationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _businessTypeController = TextEditingController();
  
  bool _isLogin = true;
  String _selectedUserType = 'farmer';

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final appProvider = Provider.of<AppProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Login' : 'Register'),
        backgroundColor: Color(AppConstants.primaryColor),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacingNormal),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo and Title
            Icon(
              Icons.agriculture,
              size: 80,
              color: Color(AppConstants.primaryColor),
            ),
            const SizedBox(height: AppConstants.spacingNormal),
            
            Text(
              AppConstants.appName,
              style: TextStyle(
                fontSize: AppConstants.fontSizeExtraLarge,
                fontWeight: FontWeight.bold,
                color: Color(AppConstants.primaryColor),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConstants.spacingSmall),
            
            Text(
              AppConstants.appDescription,
              style: TextStyle(
                fontSize: AppConstants.fontSizeNormal,
                color: Color(AppConstants.textColor),
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: AppConstants.spacingExtraLarge),
            
            // User Type Selection (only for registration)
            if (!_isLogin) ...[
              Text(
                'Choose Your Role',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.textColor),
                ),
              ),
              const SizedBox(height: AppConstants.spacingNormal),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildUserTypeChip('farmer', 'Farmer', Icons.agriculture),
                  _buildUserTypeChip('buyer', 'Buyer', Icons.shopping_cart),
                ],
              ),
              const SizedBox(height: AppConstants.spacingLarge),
            ],
            
            // Basic Fields
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppConstants.spacingNormal),
            
            if (!_isLogin) ...[
              TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: AppConstants.spacingNormal),
              
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppConstants.spacingNormal),
            ],
            
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            
            // Profile-specific fields for registration
            if (!_isLogin) ...[
              const SizedBox(height: AppConstants.spacingLarge),
              Text(
                _selectedUserType == 'farmer' ? 'Farm Details' : 'Business Details',
                style: TextStyle(
                  fontSize: AppConstants.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: Color(AppConstants.textColor),
                ),
              ),
              const SizedBox(height: AppConstants.spacingNormal),
              
              if (_selectedUserType == 'farmer') ...[
                TextField(
                  controller: _farmNameController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.agriculture),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingNormal),
                
                TextField(
                  controller: _farmLocationController,
                  decoration: const InputDecoration(
                    labelText: 'Farm Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _companyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Company Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: AppConstants.spacingNormal),
                
                TextField(
                  controller: _businessTypeController,
                  decoration: const InputDecoration(
                    labelText: 'Business Type',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.store),
                  ),
                ),
              ],
            ],
            
            const SizedBox(height: AppConstants.spacingExtraLarge),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: authProvider.isLoading ? null : _handleAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColor),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: AppConstants.spacingNormal,
                  ),
                ),
                child: authProvider.isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isLogin ? 'Login' : 'Register'),
              ),
            ),
            
            const SizedBox(height: AppConstants.spacingNormal),
            
            // Toggle between Login/Register
            TextButton(
              onPressed: () {
                setState(() {
                  _isLogin = !_isLogin;
                  _clearControllers();
                });
              },
              child: Text(
                _isLogin
                    ? "Don't have an account? Register"
                    : "Already have an account? Login",
                style: TextStyle(
                  color: Color(AppConstants.accentColor),
                ),
              ),
            ),
            
            // Error Display
            if (authProvider.errorMessage != null) ...[
              const SizedBox(height: AppConstants.spacingNormal),
              Container(
                padding: const EdgeInsets.all(AppConstants.spacingNormal),
                decoration: BoxDecoration(
                  color: Color(AppConstants.errorColor).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.borderRadiusNormal),
                  border: Border.all(
                    color: Color(AppConstants.errorColor),
                    width: 1,
                  ),
                ),
                child: Text(
                  authProvider.errorMessage!,
                  style: TextStyle(
                    color: Color(AppConstants.errorColor),
                    fontSize: AppConstants.fontSizeSmall,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedUserType == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserType = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingNormal,
          vertical: AppConstants.spacingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected 
              ? Color(AppConstants.primaryColor) 
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusLarge),
          border: Border.all(
            color: isSelected 
                ? Color(AppConstants.primaryColor) 
                : Colors.grey.shade400,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: AppConstants.spacingSmall),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _clearControllers() {
    _fullNameController.clear();
    _phoneController.clear();
    _farmNameController.clear();
    _farmLocationController.clear();
    _companyNameController.clear();
    _businessTypeController.clear();
    _selectedUserType = 'farmer';
  }

  Future<void> _handleAuth() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    if (_isLogin) {
      await _handleLogin(authProvider);
    } else {
      await _handleRegistration(authProvider);
    }
  }

  Future<void> _handleLogin(AuthProvider authProvider) async {
    // Validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }

    try {
      final success = await authProvider.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (success && mounted) {
        _showSuccess('Login successful!');
        
        // Navigate to splash screen which will handle routing
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          ),
        );
      }
    } catch (e) {
      _showError('Login failed: ${e.toString()}');
    }
  }

  Future<void> _handleRegistration(AuthProvider authProvider) async {
    // Validation
    if (_emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _fullNameController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showError('Please fill in all required fields');
      return;
    }
    
    // Profile-specific validation
    if (_selectedUserType == 'farmer') {
      if (_farmNameController.text.isEmpty || _farmLocationController.text.isEmpty) {
        _showError('Please fill in all farm details');
        return;
      }
    } else {
      if (_companyNameController.text.isEmpty || _businessTypeController.text.isEmpty) {
        _showError('Please fill in all business details');
        return;
      }
    }

    try {
      final success = await authProvider.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        userType: _selectedUserType,
        location: _selectedUserType == 'farmer' 
            ? _farmLocationController.text.trim()
            : _companyNameController.text.trim(),
      );
      
      if (success && mounted) {
        _showSuccess('Registration successful! Welcome to FarmLink Ghana.');
        
        // Navigate to splash screen which will handle routing
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          ),
        );
      }
    } catch (e) {
      _showError('Registration failed: ${e.toString()}');
    }
  }

  void _showError(String message) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setError(message);
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Color(AppConstants.successColor),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _phoneController.dispose();
    _farmNameController.dispose();
    _farmLocationController.dispose();
    _companyNameController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }
}
