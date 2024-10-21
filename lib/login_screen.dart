import 'package:flutter/material.dart';
import 'macro_tracking_page.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

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
                  onPressed: () => _navigateToMacroTracking(context),
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
}
