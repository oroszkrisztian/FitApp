import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodDetails {
  final String name;
  final double calories;
  final double protein;
  final double fat;
  final double carbs;

  FoodDetails({
    required this.name,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  factory FoodDetails.fromJson(Map<String, dynamic> json) {
    return FoodDetails(
      name: json['name'] as String,
      calories: (json['calories'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }
}

class FoodService {
  static const String baseUrl = 'https://func-fitapp-backend.azurewebsites.net';

  Future<List<FoodDetails>> searchFoods(String query) async {
    if (query.isEmpty) return [];

    try {
      final uri = Uri.parse('$baseUrl/foods/search/').replace(
        queryParameters: {'name': query},
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => FoodDetails.fromJson(json)).toList();
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to search foods: ${response.statusCode}');
      }
    } catch (e) {
      print('Error searching foods: $e');
      return [];
    }
  }
}