import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// API Service
class ApiService {
  final String baseUrl = "https://func-fitapp-backend.azurewebsites.net"; // Replace with your backend URL

  Future<List<dynamic>> fetchUserFoodLogs({
    required int userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? userId = prefs.getInt('user_id');
    try {

      final Map<String, String> queryParams = {};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }

      // Construct full URL
      final Uri uri = Uri.parse("$baseUrl/user-foods/$userId")
          .replace(queryParameters: queryParams);

      // Make HTTP GET request
      final response = await http.get(uri);

      // Handle response
      if (response.statusCode == 200) {
        return json.decode(response.body); // Expecting a list of food logs
      } else {
        throw Exception("Failed to load data: ${response.reasonPhrase}");
      }
    } catch (error) {
      throw Exception("Error fetching user logs: $error");
    }
  }
}

// Main Widget
class DailyPastPage extends StatefulWidget {
  @override
  _DailyPastPageState createState() => _DailyPastPageState();
}

class _DailyPastPageState extends State<DailyPastPage> {
  DateTime selectedDate = DateTime.now();
  List<Map<String, dynamic>> foodLogs = [];
  bool isLoading = false;
  int? userId;
  final ApiService apiService = ApiService();

  // Calculate totals for the day
  Map<String, double> get dailyTotals {
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;

    for (var log in foodLogs) {
      final food = log['food'];
      final grams = log['grams'] as double;
      totalCalories += (food['calories'] ?? 0) * grams / 100;
      totalProtein += (food['protein'] ?? 0) * grams / 100;
      totalCarbs += (food['carbs'] ?? 0) * grams / 100;
      totalFat += (food['fat'] ?? 0) * grams / 100;
    }

    return {
      'calories': totalCalories,
      'protein': totalProtein,
      'carbs': totalCarbs,
      'fat': totalFat,
    };
  }

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? storedUserId = prefs.getInt('user_id');

    if (storedUserId == null) {
      print("User ID not found. Redirecting to login or handling error.");
    } else {
      setState(() {
        userId = storedUserId;
      });
      fetchDailyIntake(selectedDate);
    }
  }

  Future<void> fetchDailyIntake(DateTime date) async {
    if (userId == null) {
      print("User ID is null. Cannot fetch data.");
      return;
    }

    setState(() => isLoading = true);

    try {
      final List<dynamic> response = await apiService.fetchUserFoodLogs(
        userId: userId!,
        startDate: date,
        endDate: date,
      );

      setState(() {
        foodLogs = List<Map<String, dynamic>>.from(response);
      });
    } catch (error) {
      print("Error fetching data: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $error")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
      fetchDailyIntake(picked);
    }
  }

  Widget _buildMacroCard(String title, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              children: [
                Text(
                  value.toStringAsFixed(1),
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 2),
                Text(
                  title == 'Calories' ? 'kcal' : 'g',
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLogCard(Map<String, dynamic> log) {
    final food = log['food'];
    final grams = log['grams'] as double;
    final calories = (food['calories'] ?? 0) * grams / 100;
    final protein = (food['protein'] ?? 0) * grams / 100;
    final carbs = (food['carbs'] ?? 0) * grams / 100;
    final fat = (food['fat'] ?? 0) * grams / 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 0,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  food['name'] ?? 'Unknown Food',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${grams.toStringAsFixed(0)}g',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientInfo('Carbs', carbs, Colors.blue),
                _buildNutrientInfo('Protein', protein, Colors.red),
                _buildNutrientInfo('Calories', calories, Colors.orange),
                _buildNutrientInfo('Fat', fat, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}${label == 'Calories' ? 'kcal' : 'g'}',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final totals = dailyTotals;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text(
          'Daily History',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
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
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(selectedDate),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: const Text('Change Date'),
                        onPressed: () => selectDate(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (foodLogs.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.6,
                        children: [
                          _buildMacroCard('Carbs', totals['carbs']!, Colors.blue),
                          _buildMacroCard('Protein', totals['protein']!, Colors.red),
                          _buildMacroCard('Calories', totals['calories']!, Colors.orange),
                          _buildMacroCard('Fat', totals['fat']!, Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Meals This Day',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.restaurant_menu,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'No meals recorded for this day',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (foodLogs.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: foodLogs.length,
                  itemBuilder: (context, index) =>
                      _buildFoodLogCard(foodLogs[index]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
