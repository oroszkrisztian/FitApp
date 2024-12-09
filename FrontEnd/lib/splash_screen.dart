import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart';
import 'macro_tracking_page.dart';
import 'models/user_model.dart'; // Import the User model

import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _animationController.forward();

    // Add minimum splash screen duration
    Timer(const Duration(seconds: 2), () {
      _fetchUserAndNavigate();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserAndNavigate() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');
    print(userId);
    if (userId != null) {
      try {
        final user = await UserModel.fetchUser(userId); // Fetch user data
        if (user != null && mounted) {
          // Log the user data
          print('Fetched User Data:');
          print('User ID: ${user.userId}');
          print('Name: ${user.username}');
          print('Email: ${user.email}');
          print('Height: ${user.height}');
          print('Weight: ${user.weight}');
          print('Age: ${user.age}');
          print('Gender: ${user.gender}');
          print('Activity: ${user.activity}');

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const MacroTrackingPage(),
            ),
          );
          return;
        }
      } catch (error) {
        print('Error fetching user: $error');
      }
    }


    // Navigate to login screen if no user is found or error occurs
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.inversePrimary,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fitness_center,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'FitApp',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
