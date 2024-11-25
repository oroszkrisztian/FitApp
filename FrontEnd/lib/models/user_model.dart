import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserModel {
  final int userId;
  final String username;
  final String email;
  final double height;
  final double weight;
  final int age;
  final String gender;

  UserModel({
    required this.userId,
    required this.username,
    required this.email,
    required this.height,
    required this.weight,
    required this.age,
    required this.gender,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'],
      username: json['username'] ?? 'Unknown',  // Using 'username' from the API response
      email: json['user']['email'] ?? 'Unknown',
      height: (json['height'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
      age: json['age'] ?? 0,
      gender: json['gender'] ?? 'Other',
    );
  }

  static Future<UserModel?> fetchUser(int userId) async {
    final url = 'https://func-fitapp-backend.azurewebsites.net/users/$userId';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = UserModel.fromJson(data);

        // Save the username in SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', user.username);

        return user;
      } else {
        print('Failed to fetch user. Status code: ${response.statusCode}');
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
    } catch (error) {
      print('Error fetching user data: $error');
      return null; // Return null on error
    }
  }
}

