import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'macro_tracking_page.dart';

// Constants for styling
class RegistrationConstants {
  static const double horizontalPadding = 24.0;
  static const double verticalSpacing = 16.0;
  static const double sectionSpacing = 32.0;

  static const TextStyle headerStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static const TextStyle sectionHeaderStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Colors.grey,
    letterSpacing: 1.2,
  );

  static const TextStyle buttonTextStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for text fields
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _confirmEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  // Form state
  String _selectedGender = 'Male';
  String _selectedActivity = '1';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Activity levels mapping
  final Map<String, String> activityLevels = {
    '1': 'Sedentary',
    '2': 'Lightly Active',
    '3': 'Moderately Active',
    '4': 'Very Active',
    '5': 'Extra Active',
  };

// And add a map for detailed descriptions
  final Map<String, String> activityDescriptions = {
    '1': 'Little or no exercise',
    '2': 'Light exercise 1-3 days/week',
    '3': 'Moderate exercise 3-5 days/week',
    '4': 'Hard exercise 6-7 days/week',
    '5': 'Very hard exercise & physical job',
  };

  // Helper method to build consistent input decoration
  InputDecoration _buildInputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, size: 22),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      labelStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildAccountInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ACCOUNT INFORMATION',
          style: RegistrationConstants.sectionHeaderStyle,
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        // Username Field
        TextFormField(
          controller: _usernameController,
          decoration: _buildInputDecoration(
            'Username',
            Icons.person_outline,
            'Choose a username',
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a username';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        // Email Fields
        TextFormField(
          controller: _emailController,
          decoration: _buildInputDecoration(
            'Email',
            Icons.email_outlined,
            'Enter your email address',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        TextFormField(
          controller: _confirmEmailController,
          decoration: _buildInputDecoration(
            'Confirm Email',
            Icons.email_outlined,
            'Re-enter your email address',
          ),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your email';
            }
            if (value != _emailController.text) {
              return 'Emails do not match';
            }
            return null;
          },
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        // Password Fields
        TextFormField(
          controller: _passwordController,
          decoration: _buildInputDecoration(
            'Password',
            Icons.lock_outline,
            'Enter your password',
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          obscureText: _obscurePassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            if (value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            if (!RegExp(r'[A-Z]').hasMatch(value)) {
              return 'Password must contain at least one uppercase letter';
            }
            if (!RegExp(r'[0-9]').hasMatch(value)) {
              return 'Password must contain at least one number';
            }
            return null;
          },
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        TextFormField(
          controller: _confirmPasswordController,
          decoration: _buildInputDecoration(
            'Confirm Password',
            Icons.lock_outline,
            'Re-enter your password',
          ).copyWith(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
          obscureText: _obscureConfirmPassword,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please confirm your password';
            }
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPersonalInformationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PERSONAL INFORMATION',
          style: RegistrationConstants.sectionHeaderStyle,
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        // Height and Weight Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _heightController,
                decoration: _buildInputDecoration(
                  'Height',
                  Icons.height,
                  'cm',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final height = double.tryParse(value);
                  if (height == null || height <= 0 || height > 300) {
                    return 'Invalid height';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: RegistrationConstants.verticalSpacing),
            Expanded(
              child: TextFormField(
                controller: _weightController,
                decoration: _buildInputDecoration(
                  'Weight',
                  Icons.monitor_weight_outlined,
                  'kg',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final weight = double.tryParse(value);
                  if (weight == null || weight <= 0 || weight > 500) {
                    return 'Invalid weight';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        // Age and Gender Row
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _ageController,
                decoration: _buildInputDecoration(
                  'Age',
                  Icons.calendar_today_outlined,
                  'years',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age <= 0 || age > 120) {
                    return 'Invalid age';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: RegistrationConstants.verticalSpacing),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedGender,
                decoration: _buildInputDecoration(
                  'Gender',
                  Icons.person_outline,
                  'Select',
                ),
                items: ['Male', 'Female', 'Other']
                    .map((gender) => DropdownMenuItem(
                  value: gender,
                  child: Text(gender),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: RegistrationConstants.verticalSpacing),

        // Activity Level Dropdown
        DropdownButtonFormField<String>(
          value: _selectedActivity,
          decoration: _buildInputDecoration(
            'Activity Level',
            Icons.directions_run,
            'Select your activity level',
          ),
          selectedItemBuilder: (BuildContext context) {
            // This builds the selected item display
            return activityLevels.entries.map<Widget>((entry) {
              return Text(
                entry.value,
                style: const TextStyle(fontSize: 14),
              );
            }).toList();
          },
          items: activityLevels.entries.map((entry) {
            // This builds the dropdown menu items with descriptions
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    activityDescriptions[entry.key]!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedActivity = value!;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your activity level';
            }
            return null;
          },
          isExpanded: true,
          menuMaxHeight: 300,
          itemHeight: 60,
        ),

      ],
    );
  }

  Future<void> _register(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 16),
                  CircularProgressIndicator(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Creating your account...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please wait while we set up your profile',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      );

      // Prepare API request
      final baseUrl = 'https://func-fitapp-backend.azurewebsites.net/register/';
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
          'height': _heightController.text,
          'weight': _weightController.text,
          'age': _ageController.text,
          'gender': _selectedGender.toLowerCase(),
          'username': _usernameController.text.trim(),
          'activity': _selectedActivity,
        },
      );

      // Make API request
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
      );

      // Remove loading dialog
      if (context.mounted) {
        Navigator.pop(context);
      }

      // Handle response
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);

        // Save user data locally
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', data['user_id']);
        await prefs.setString('username', _usernameController.text.trim());

        if (context.mounted) {
          _showSuccessDialog(context);
        }
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body);
        if (context.mounted) {
          _showErrorDialog(context, error['detail'] ?? 'Registration failed');
        }
      } else {
        throw Exception('Registration failed with status: ${response.statusCode}');
      }
    } catch (e) {
      print('Error during registration: $e');
      if (context.mounted) {
        _showErrorDialog(context, 'An unexpected error occurred. Please try again.');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Welcome Aboard! 🎉',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Welcome, ${_usernameController.text}!',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your account has been created successfully.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MacroTrackingPage(),
                        ),
                            (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Start Your Journey',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 64,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registration Failed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard on tap
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.inversePrimary.withOpacity(0.2),
                Colors.white,
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: RegistrationConstants.horizontalPadding,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 40),

                      // Header Section
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios),
                            onPressed: () => Navigator.pop(context),
                          ),
                          const Expanded(
                            child: Text(
                              'Create Account',
                              style: RegistrationConstants.headerStyle,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 48), // Balance for back button
                        ],
                      ),

                      const SizedBox(height: RegistrationConstants.sectionSpacing),

                      // Account Information Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: RegistrationConstants.cardDecoration,
                        child: _buildAccountInformationSection(),
                      ),

                      const SizedBox(height: RegistrationConstants.sectionSpacing),

                      // Personal Information Section
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: RegistrationConstants.cardDecoration,
                        child: _buildPersonalInformationSection(),
                      ),

                      const SizedBox(height: RegistrationConstants.sectionSpacing),

                      // Register Button
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _register(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                            : const Text(
                          'Create Account',
                          style: RegistrationConstants.buttonTextStyle,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Terms and Privacy
                      Center(
                        child: Text(
                          'By creating an account, you agree to our\nTerms of Service and Privacy Policy',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose of controllers
    _emailController.dispose();
    _confirmEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }
}