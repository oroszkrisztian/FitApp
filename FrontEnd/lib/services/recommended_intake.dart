import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RecommendedIntake {
  final double calorie;
  final double protein;
  final double fat;
  final double carbs;

  RecommendedIntake({
    required this.calorie,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  factory RecommendedIntake.fromJson(Map<String, dynamic> json) {
    return RecommendedIntake(
      calorie: (json['calorie'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }
}

class RecommendedIntakeService {
  static const String baseUrl = 'https://func-fitapp-backend.azurewebsites.net';

  Future<RecommendedIntake?> getRecommendedIntake() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('User ID not found');
        return null;
      }

      final uri = Uri.parse('$baseUrl/user/$userId/recommended');
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Recommended values:');
        print('Calories: ${data['calorie']}');
        print('Protein: ${data['protein']}');
        print('Fat: ${data['fat']}');
        print('Carbs: ${data['carbs']}');
        return RecommendedIntake.fromJson(data);
      } else if (response.statusCode == 404) {
        print('No recommended values found for user $userId');
        return null;
      } else {
        throw Exception('Failed to load recommended values');
      }
    } catch (e) {
      print('Error fetching recommended values: $e');
      return null;
    }
  }
}