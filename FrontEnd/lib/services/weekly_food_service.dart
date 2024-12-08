import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'food_services.dart';


class FoodLog {
  final FoodDetails food;
  final double grams;
  final String consumedAt;

  FoodLog({
    required this.food,
    required this.grams,
    required this.consumedAt,
  });

  factory FoodLog.fromJson(Map<String, dynamic> json) {
    return FoodLog(
      food: FoodDetails.fromJson(json['food']),
      grams: (json['grams'] as num).toDouble(),
      consumedAt: json['consumed_at'],
    );
  }
}

class DailyNutrition {
  final String date;
  final List<FoodLog> foods;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;

  DailyNutrition({
    required this.date,
    required this.foods,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });
}

class WeeklyFoodService {
  static const String baseUrl = 'https://func-fitapp-backend.azurewebsites.net';

  Future<Map<String, List<FoodLog>>> fetchWeeklyFoodLogs(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final uri = Uri.parse("$baseUrl/user-foods/$userId").replace(
        queryParameters: {
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
        },
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        Map<String, List<FoodLog>> foodsByDate = {};

        for (var item in data) {
          final log = FoodLog.fromJson(item);
          final date = log.consumedAt.split('T')[0];

          if (!foodsByDate.containsKey(date)) {
            foodsByDate[date] = [];
          }
          foodsByDate[date]!.add(log);
        }

        return foodsByDate;
      } else {
        throw Exception("Failed to load data: ${response.reasonPhrase}");
      }
    } catch (error) {
      print('Error fetching user logs: $error');
      return {};
    }
  }

  List<DailyNutrition> calculateDailyNutrition(Map<String, List<FoodLog>> foodsByDate) {
    List<DailyNutrition> dailyNutrition = [];

    foodsByDate.forEach((date, foods) {
      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (var food in foods) {
        final ratio = food.grams / 100;
        totalCalories += food.food.calories * ratio;
        totalProtein += food.food.protein * ratio;
        totalCarbs += food.food.carbs * ratio;
        totalFat += food.food.fat * ratio;
      }

      dailyNutrition.add(DailyNutrition(
        date: date,
        foods: foods,
        totalCalories: totalCalories,
        totalProtein: totalProtein,
        totalCarbs: totalCarbs,
        totalFat: totalFat,
      ));
    });

    return dailyNutrition..sort((a, b) => b.date.compareTo(a.date));
  }
}