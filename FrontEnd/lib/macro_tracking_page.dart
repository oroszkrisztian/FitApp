import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:foodex/services/food_services.dart';
import 'package:foodex/services/recommended_intake.dart';
import 'package:foodex/services/weekly_food_service.dart';
import 'package:foodex/user_page.dart';
import 'package:foodex/weeklyFood.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'package:image_picker/image_picker.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dailyPast.dart';
import 'login_screen.dart';



class ThemeConstants {
  static final inputDecoration = (BuildContext context) => InputDecoration(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.black.withOpacity(0.3)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.green, width: 2),
    ),
    filled: true,
    fillColor: Colors.white,
    contentPadding:
    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    labelStyle: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
  );

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.black.withOpacity(0.2)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static const buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    color: Colors.black,
  );
}

class MacroTrackingPage extends StatefulWidget {
  const MacroTrackingPage({super.key});

  @override
  State<MacroTrackingPage> createState() => _MacroTrackingPageState();
}

class _MacroTrackingPageState extends State<MacroTrackingPage> {
  // Services
  final ImagePicker _picker = ImagePicker();
  final WeeklyFoodService _weeklyFoodService = WeeklyFoodService();
  final RecommendedIntakeService _recommendedService = RecommendedIntakeService();
  late final GenerativeModel _geminiModel;

  // Loading and state variables
  bool _isLoading = false;
  bool _isProcessingImage = false;
  String _username = 'User';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  RecommendedIntake? _recommendedIntake;

  // Nutrition totals
  double carbs = 0;
  double protein = 0;
  double calories = 0;
  double fat = 0;

  // Current meal values
  double mealCarbs = 0;
  double mealProtein = 0;
  double mealCalories = 0;
  double mealFat = 0;

  // Data storage
  List<FoodLog> todaysMeals = [];
  List<Map<String, dynamic>> meals = [];

  // Controllers
  final per100gCarbsController = TextEditingController();
  final per100gProteinController = TextEditingController();
  final per100gCaloriesController = TextEditingController();
  final per100gFatController = TextEditingController();
  final searchController = TextEditingController();
  final quantityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadRecommendedIntake();
    _fetchTodaysFoods();
  }


  @override
  void dispose() {
    // Dispose controllers
    per100gCarbsController.dispose();
    per100gProteinController.dispose();
    per100gCaloriesController.dispose();
    per100gFatController.dispose();
    searchController.dispose();
    quantityController.dispose();
    super.dispose();
  }

  // Initial data loading methods
  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    if (username != null) {
      setState(() {
        _username = username;
      });
    }
  }

  Future<void> _loadRecommendedIntake() async {
    final recommended = await _recommendedService.getRecommendedIntake();
    if (recommended != null) {
      setState(() {
        _recommendedIntake = recommended;
      });
    }
  }

  void _clearTextFields() {
    per100gCarbsController.clear();
    per100gProteinController.clear();
    per100gCaloriesController.clear();
    per100gFatController.clear();
    searchController.clear();
    quantityController.clear();
  }


  // AI Processing Methods

  Future<void> _processImageWithAI(BuildContext dialogContext) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (image != null) {
        // Show loading dialog
        if (dialogContext.mounted) {
          showDialog(
            context: dialogContext,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Processing nutrition label...'),
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        final bytes = await image.readAsBytes();
        final base64Image = base64Encode(bytes);

        final apiKey = 'AIzaSyDI7Bjn6HTZllGHPEtxdmLas9HNlNLnOco';
        final url = Uri.parse('https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key=$apiKey');

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            "contents": [{
              "parts": [
                {
                  "text": "Extract nutritional information from this image. Return only the numbers in this format: carbs: X, protein: X, calories: X, fat: X, where X represents values per 100 grams per serving."
                },
                {
                  "inlineData": {
                    "mimeType": "image/jpeg",
                    "data": base64Image
                  }
                }
              ]
            }]
          }),
        );



        print('Status code: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final textResponse = data['candidates'][0]['content']['parts'][0]['text'];
          final nutritionInfo = _parseGeminiResponse(textResponse);

          // Update UI
          if (dialogContext.mounted) {
            Navigator.pop(dialogContext);  // Close loading dialog
            setState(() {
              per100gCarbsController.text = nutritionInfo['carbs']?.toString() ?? '0';
              per100gProteinController.text = nutritionInfo['protein']?.toString() ?? '0';
              per100gCaloriesController.text = nutritionInfo['calories']?.toString() ?? '0';
              per100gFatController.text = nutritionInfo['fat']?.toString() ?? '0';
              calculateNutritionForQuantity();
            });
          }
        } else {
          print('Error: ${response.statusCode}');
          print('Response: ${response.body}');
          throw Exception('Failed to process image');
        }
      }
    } catch (e) {
      if (dialogContext.mounted) {
        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Error processing image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Helper method to parse Gemini response
  Map<String, double> _parseGeminiResponse(String response) {
    Map<String, double> nutritionValues = {
      'carbs': 0,
      'protein': 0,
      'calories': 0,
      'fat': 0,
    };

    try {
      // Split response by commas and process each part
      final parts = response.split(',').map((s) => s.trim()).toList();

      for (var part in parts) {
        // Remove any non-essential characters and split by colon
        final keyValue = part.replaceAll(RegExp(r'[^a-zA-Z0-9:.]'), '').split(':');
        if (keyValue.length == 2) {
          final key = keyValue[0].trim().toLowerCase();
          final value = double.tryParse(keyValue[1].trim()) ?? 0;

          if (nutritionValues.containsKey(key)) {
            nutritionValues[key] = value;
          }
        }
      }

      print('Parsed values: $nutritionValues'); // Debug print
    } catch (e) {
      print('Error parsing Gemini response: $e');
    }
    return nutritionValues;
  }

  double _extractNumberFromString(String text) {
    final regex = RegExp(r'\d+\.?\d*');
    final match = regex.firstMatch(text);
    return match != null ? double.tryParse(match.group(0) ?? '0') ?? 0 : 0;
  }

// Dialog Methods
  void _showAddMealDialog() {
    // Variables for meal data
    String mealName = '';
    double mealQuantity = 0;
    bool showNutritionFields = false;
    List<FoodDetails> searchResults = [];
    Timer? _debounce;
    final FoodService _foodService = FoodService();

    void calculateNutritionForQuantity() {
      if (mealQuantity > 0) {
        setState(() {
          mealCarbs = double.parse(per100gCarbsController.text) * (mealQuantity / 100);
          mealProtein = double.parse(per100gProteinController.text) * (mealQuantity / 100);
          mealCalories = double.parse(per100gCaloriesController.text) * (mealQuantity / 100);
          mealFat = double.parse(per100gFatController.text) * (mealQuantity / 100);
        });
      }
    }

    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                constraints: const BoxConstraints(maxWidth: 400),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      _buildDialogHeader(context),
                      const SizedBox(height: 24),

                      // Search and Food Name Field
                      _buildSearchField(setDialogState, _debounce, _foodService, searchResults),

                      // Search Results List
                      if (searchResults.isNotEmpty)
                        _buildSearchResults(searchResults, setDialogState),

                      // Quantity Field
                      _buildQuantityField(setDialogState, mealQuantity),

                      // Camera Section
                      if (!showNutritionFields)
                        _buildCameraSection(dialogContext),

                      // Nutrition Value Fields
                      _buildNutritionFields(setDialogState),

                      // Calculated Values Display
                      if (_shouldShowCalculatedValues())
                        _buildCalculatedValues(),

                      // Action Buttons
                      _buildActionButtons(dialogContext, mealName, mealQuantity),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _shouldShowCalculatedValues() {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    final hasQuantity = quantity > 0;

    final hasAnyNutrition =
        (double.tryParse(per100gCarbsController.text) ?? 0) > 0 ||
            (double.tryParse(per100gProteinController.text) ?? 0) > 0 ||
            (double.tryParse(per100gCaloriesController.text) ?? 0) > 0 ||
            (double.tryParse(per100gFatController.text) ?? 0) > 0;

    return hasQuantity && hasAnyNutrition;
  }

  void calculateNutritionForQuantity() {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    if (quantity > 0) {
      final ratio = quantity / 100;
      mealCarbs = (double.tryParse(per100gCarbsController.text) ?? 0) * ratio;
      mealProtein = (double.tryParse(per100gProteinController.text) ?? 0) * ratio;
      mealCalories = (double.tryParse(per100gCaloriesController.text) ?? 0) * ratio;
      mealFat = (double.tryParse(per100gFatController.text) ?? 0) * ratio;
    }
  }

// Helper widgets for the dialog
  Widget _buildDialogHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Add Meal',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildSearchField(
      StateSetter setDialogState,
      Timer? debounce,
      FoodService foodService,
      List<FoodDetails> searchResults) {
    return TextFormField(
      controller: searchController,
      decoration: ThemeConstants.inputDecoration(context).copyWith(
        labelText: 'Food Name',
        hintText: 'Type to search or add new food',
        prefixIcon: const Icon(Icons.restaurant_menu),
      ),
      onChanged: (value) {
        if (debounce?.isActive ?? false) debounce!.cancel();
        debounce = Timer(const Duration(milliseconds: 500), () async {
          final results = await foodService.searchFoods(value);
          setDialogState(() {
            searchResults.clear();
            searchResults.addAll(results);
          });
        });
      },
    );
  }

  Widget _buildSearchResults(List<FoodDetails> searchResults, StateSetter setDialogState) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final food = searchResults[index];
          return ListTile(
            title: Text(food.name),
            subtitle: Text(
              'per 100g: ${food.calories}kcal, P:${food.protein}g, C:${food.carbs}g, F:${food.fat}g',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              setDialogState(() {
                searchController.text = food.name;
                per100gCarbsController.text = food.carbs.toString();
                per100gProteinController.text = food.protein.toString();
                per100gCaloriesController.text = food.calories.toString();
                per100gFatController.text = food.fat.toString();
                searchResults.clear();
              });
            },
          );
        },
      ),
    );
  }

  Widget _buildQuantityField(StateSetter setDialogState, double mealQuantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: TextField(
        controller: quantityController,
        decoration: ThemeConstants.inputDecoration(context).copyWith(
          labelText: 'Quantity (g)',
          hintText: 'Enter amount in grams',
          prefixIcon: const Icon(Icons.scale),
        ),
        keyboardType: TextInputType.number,
        onChanged: (value) {
          mealQuantity = double.tryParse(value) ?? 0;
          if (mealQuantity > 0) {
            calculateNutritionForQuantity();
            setDialogState(() {});
          }
        },
      ),
    );
  }

  Widget _buildCameraSection(BuildContext dialogContext) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scan Nutrition Label',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use your camera to scan the nutrition label',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _processImageWithAI(dialogContext),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Scan Label'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildNutritionFields(StateSetter setDialogState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Text(
            'Nutrition Values (per 100g):',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        _buildNutritionField(
          controller: per100gCarbsController,
          label: 'Carbs',
          icon: Icons.grain,
          onChanged: (value) => setDialogState(() {}),
        ),
        const SizedBox(height: 12),
        _buildNutritionField(
          controller: per100gProteinController,
          label: 'Protein',
          icon: Icons.egg,
          onChanged: (value) => setDialogState(() {}),
        ),
        const SizedBox(height: 12),
        _buildNutritionField(
          controller: per100gCaloriesController,
          label: 'Calories',
          icon: Icons.local_fire_department,
          onChanged: (value) => setDialogState(() {}),
        ),
        const SizedBox(height: 12),
        _buildNutritionField(
          controller: per100gFatController,
          label: 'Fat',
          icon: Icons.opacity,
          onChanged: (value) => setDialogState(() {}),
        ),
      ],
    );
  }

  Widget _buildNutritionField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return TextFormField(
      controller: controller,
      decoration: ThemeConstants.inputDecoration(context).copyWith(
        labelText: '$label per 100g',
        prefixIcon: Icon(icon),
        suffixText: label == 'Calories' ? 'kcal' : 'g',
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: onChanged,
    );
  }

  Widget _buildCalculatedValues() {
    final quantity = double.tryParse(quantityController.text) ?? 0;
    if (quantity <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Calculated values for ${quantity}g:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _buildCalculatedValueRow('Carbs', mealCarbs),
          _buildCalculatedValueRow('Protein', mealProtein),
          _buildCalculatedValueRow('Calories', mealCalories),
          _buildCalculatedValueRow('Fat', mealFat),
        ],
      ),
    );
  }

  Widget _buildCalculatedValueRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '${value.toStringAsFixed(1)}${label == 'Calories' ? ' kcal' : 'g'}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, String mealName, double mealQuantity) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _isLoading ? null : () => _handleAddMeal(context, mealName, mealQuantity),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Add Meal'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAddMeal(BuildContext context, String mealName, double mealQuantity) async {
    if (searchController.text.isEmpty || quantityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in food name and quantity'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => Dialog(
          backgroundColor: Colors.white,
          child: Container(
            padding: const EdgeInsets.all(20),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Adding meal...'),
              ],
            ),
          ),
        ),
      );

      await _addMeal(
        searchController.text,
        per100gCarbsController.text,
        per100gProteinController.text,
        per100gCaloriesController.text,
        per100gFatController.text,
        quantityController.text,
      );

      // Clean up
      _clearTextFields();
      setState(() => _isLoading = false);

      // Close all dialogs and show success message
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.of(context).pop(); // Close add meal dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add meal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addMeal(
      String name,
      String carbs,
      String protein,
      String calories,
      String fat,
      String grams,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final uri = Uri.parse('https://func-fitapp-backend.azurewebsites.net/foods/')
        .replace(queryParameters: {
      'user_id': userId.toString(),
      'grams': double.tryParse(grams)?.toString(),
    });

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'name': name.toLowerCase(),
        'carbs': double.tryParse(carbs) ?? 0.0,
        'protein': double.tryParse(protein) ?? 0.0,
        'calories': double.tryParse(calories) ?? 0.0,
        'fat': double.tryParse(fat) ?? 0.0,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add meal to server');
    }

    await _fetchTodaysFoods(); // Refresh the foods list
  }

  Future<void> _fetchTodaysFoods() async {
    setState(() => _isLoading = true);

    try {
      final today = DateTime.now();
      final foodsByDate = await _weeklyFoodService.fetchWeeklyFoodLogs(today, today);

      if (foodsByDate.containsKey(today.toIso8601String().split('T')[0])) {
        final foods = foodsByDate[today.toIso8601String().split('T')[0]]!;
        foods.sort((a, b) => b.consumedAt.compareTo(a.consumedAt)); // Sort by most recent
        _updateTotals(foods);
        setState(() {
          todaysMeals = foods;
          _isLoading = false;
        });
      } else {
        setState(() {
          todaysMeals = [];
          _resetTotals();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching today\'s foods: $e');
      setState(() => _isLoading = false);
    }
  }

  void _updateTotals(List<FoodLog> foods) {
    _resetTotals();
    for (var food in foods) {
      final ratio = food.grams / 100;
      carbs += food.food.carbs * ratio;
      protein += food.food.protein * ratio;
      calories += food.food.calories * ratio;
      fat += food.food.fat * ratio;
    }
  }

  void _resetTotals() {
    carbs = 0;
    protein = 0;
    calories = 0;
    fat = 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: _buildDrawer(),
      appBar: _buildAppBar(),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary.withOpacity(0.4),
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
            // Overview Section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOverviewHeader(),
                  const SizedBox(height: 20),
                  if (todaysMeals.isNotEmpty)
                    _buildMacroOverview()
                  else
                    _buildEmptyState(),
                ],
              ),
            ),

            // Meals List
            if (todaysMeals.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: todaysMeals.length,
                  itemBuilder: (context, index) => _buildMealCard(
                    todaysMeals[todaysMeals.length - 1 - index],
                    index,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        'Macro Tracker',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildOverviewHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Today\'s Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        if (todaysMeals.isNotEmpty)
          TextButton.icon(
            icon: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
            ),
            label: const Text(
              'Add Meal',
              style: TextStyle(color: Colors.black),
            ),
            onPressed: _showAddMealDialog,
          ),
      ],
    );
  }

  Widget _buildMacroOverview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade400,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
          _buildMacroCard('Carbs', carbs, Colors.blue),
          _buildMacroCard('Protein', protein, Colors.red),
          _buildMacroCard('Calories', calories, Colors.orange),
          _buildMacroCard('Fat', fat, Colors.green),
        ],
      ),
    );
  }

  Widget _buildMacroCard(String title, double value, Color color) {
    double getGoalValue(String title) {
      if (title == 'Carbs') {
        return _recommendedIntake?.carbs ?? 0;
      } else if (title == 'Protein') {
        return _recommendedIntake?.protein ?? 0;
      } else if (title == 'Calories') {
        return _recommendedIntake?.calorie ?? 0;
      } else if (title == 'Fat') {
        return _recommendedIntake?.fat ?? 0;
      }
      return 0;
    }

    final double goalValue = getGoalValue(title);

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Text(
                'Goal: ${goalValue.toStringAsFixed(0)}${title == 'Calories' ? 'kcal' : 'g'}',
                style: TextStyle(
                  color: color.withOpacity(1),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: goalValue > 0 ? (value / goalValue).clamp(0.0, 1.0) : 0,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            goalValue > 0
                ? '${((value / goalValue) * 100).toStringAsFixed(0)}%'
                : '0%',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
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
              'No meals added yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Meal'),
              onPressed: _showAddMealDialog,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(FoodLog meal, int index) {
    final ratio = meal.grams / 100;
    final actualCarbs = meal.food.carbs * ratio;
    final actualProtein = meal.food.protein * ratio;
    final actualCalories = meal.food.calories * ratio;
    final actualFat = meal.food.fat * ratio;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade100,
            Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
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
                  meal.food.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${meal.grams}g',
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
                _buildMealNutrient('Carbs', actualCarbs, Colors.blue),
                _buildMealNutrient('Protein', actualProtein, Colors.red),
                _buildMealNutrient('Calories', actualCalories, Colors.orange),
                _buildMealNutrient('Fat', actualFat, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealNutrient(String label, double value, Color color) {
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

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade900,
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Text(
                  'Welcome, $_username!',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.person,
            title: 'Profile',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Calendar',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DailyPastPage()),
              );
            },
          ),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WeeklyFoodLogs()),
              );
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.logout,
            title: 'Logout',
            color: Colors.red,
            onTap: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_id');
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: color == null ? FontWeight.normal : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

}


