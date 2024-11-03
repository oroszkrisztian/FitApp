import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'macro_tracking_page.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers for username and password
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _login(BuildContext context) async {
  final String username = _usernameController.text;
  final String password = _passwordController.text;

  // Base URL with query parameters
  final String baseUrl = 'http://192.168.15.160:1234/login/';
  final uri = Uri.parse(baseUrl).replace(queryParameters: {
    'email': username,
    'password': password,
  });

  try {
    final response = await http.post(
      uri,  // Using URI with query parameters
      headers: {
        'Content-Type': 'application/json',
      },
    );

    print("username: "+username);
    print("password: "+password);
    print("Response status: ${response.statusCode}");
    print("Response body: ${response.body}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      print('Login successful: $data');
      _navigateToMacroTracking(context);
    } else if (response.statusCode == 401) {
      print('Login failed: Invalid credentials');
      _showErrorDialog(context, 'Invalid email or password');
    } else {
      print('Login failed: ${response.body}');
      _showErrorDialog(context, 'Login failed: ${response.body}');
    }
  } catch (e) {
    print('Error: $e');
    _showErrorDialog(context, 'Error connecting to server');
  }
}

  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToMacroTracking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MacroTrackingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gym App Login'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to FitPro!',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 20),

              // Username TextField
              TextField(
                controller: _usernameController, // Use the controller
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: TextStyle(color: Colors.grey[400]), // Lighter hint text color
                  prefixIcon: Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                  filled: true, // Fill color
                  fillColor: Colors.white, // Background color of the TextField
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5), // Border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // Border when focused
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Password TextField
              TextField(
                controller: _passwordController, // Use the controller
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: TextStyle(color: Colors.grey[400]), // Lighter hint text color
                  prefixIcon: Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
                  filled: true, // Fill color
                  fillColor: Colors.white, // Background color of the TextField
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0), // Rounded corners
                    borderSide: BorderSide(color: Colors.grey.shade400, width: 1.5), // Border color
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2), // Border when focused
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              SizedBox(
                width: double.infinity, // Ensures the button stretches across the available width
                child: ElevatedButton(
                  onPressed: () => _login(context), // Call the login function
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Increased vertical padding
                    backgroundColor: Theme.of(context).colorScheme.primary, // Use primary color from theme
                    foregroundColor: Colors.white, // Text color
                    minimumSize: const Size(0, 48), // Minimum height
                    shape: RoundedRectangleBorder( // Rounded corners
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4, // Shadow effect
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Increased font size and bold
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Register Button
              SizedBox(
                width: double.infinity, // Ensures the button stretches across the available width
                child: ElevatedButton(
                  onPressed: () {
                    print('Register');
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0), // Increased vertical padding
                    backgroundColor: Theme.of(context).colorScheme.secondary, // Use secondary color from theme
                    foregroundColor: Colors.white, // Text color
                    minimumSize: const Size(0, 48), // Minimum height
                    shape: RoundedRectangleBorder( // Rounded corners
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    elevation: 4, // Shadow effect
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold), // Increased font size and bold
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}