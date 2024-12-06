import 'dart:async';
import 'dart:convert';
import 'package:fit_app/chat_page.dart';
import 'package:fit_app/login_screen.dart';
import 'package:fit_app/services/food_services.dart';
import 'package:fit_app/services/recommended_intake.dart';
import 'package:fit_app/services/weekly_food_service.dart';
import 'package:fit_app/user_page.dart';
import 'package:fit_app/weeklyFood.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'dailyPast.dart';



class ThemeConstants {
  static final inputDecoration = (BuildContext context) => InputDecoration(
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
              color: Theme.of(context).colorScheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );

  static final cardDecoration = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.shade200,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static const buttonStyle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
}

class MacroTrackingPage extends StatefulWidget {
  const MacroTrackingPage({super.key});

  @override
  State<MacroTrackingPage> createState() => _MacroTrackingPageState();
}

class _MacroTrackingPageState extends State<MacroTrackingPage> {
  bool _isLoading = false;
  double carbs = 0;
  double protein = 0;
  double calories = 0;
  List<FoodLog> todaysMeals = [];
  double fat = 0;
  List<Map<String, dynamic>> meals = [];
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  SharedPreferences? _preferences;
  DateTime _lastSavedDate = DateTime.now();
  bool _isInitialized = false;
  String _username = 'User';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WeeklyFoodService _weeklyFoodService = WeeklyFoodService();

  late final GenerativeModel _geminiModel;
  String nutritionData = '';

  final FoodService _foodService = FoodService();

  final RecommendedIntakeService _recommendedService = RecommendedIntakeService();
  RecommendedIntake? _recommendedIntake;

  double mealCarbs = 0;
  double mealProtein = 0;
  double mealCalories = 0;
  double mealFat = 0;

  static const String KEY_LAST_SAVED_DATE = 'last_saved_date';
  static const String KEY_DAILY_MEALS = 'meals';
  static const String KEY_DAILY_CARBS = 'carbs';
  static const String KEY_DAILY_PROTEIN = 'protein';
  static const String KEY_DAILY_CALORIES = 'calories';
  static const String KEY_DAILY_FAT = 'fat';

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadUsername();
    _loadRecommendedIntake();
    _fetchTodaysFoods();
  }

  Future<void> _loadRecommendedIntake() async {
    final recommended = await _recommendedService.getRecommendedIntake();
    if (recommended != null) {
      setState(() {
        _recommendedIntake = recommended;
      });
    }
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs
        .getString('username'); // Fetch the username from SharedPreferences
    if (username != null) {
      setState(() {
        _username = username; // Update the state with the loaded username
      });
    }
  }

  void _initializeGemini() {
    _geminiModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'AIzaSyDI7Bjn6HTZllGHPEtxdmLas9HNlNLnOco',
    );
  }



  Future<void> _fetchTodaysFoods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final today = DateTime.now();
      final foodsByDate = await _weeklyFoodService.fetchWeeklyFoodLogs(
        today,
        today,
      );

      if (foodsByDate.containsKey(today.toIso8601String().split('T')[0])) {
        final foods = foodsByDate[today.toIso8601String().split('T')[0]]!;
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
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _resetTotals() {
    carbs = 0;
    protein = 0;
    calories = 0;
    fat = 0;
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

  Future<Map<String, double>> _extractNutritionWithGemini(String text) async {
    try {
      final prompt = '''
      Extract the following nutritional information from this text and return it in a structured format:
      - Carbohydrates (in grams)
      - Protein (in grams)
      - Calories
      - Fat (in grams)
      
      Text to analyze:
      $text
      
      Return only the numbers for each category. If a value is not found, return 0.
      ''';

      final content = [Content.text(prompt)];
      final response = await _geminiModel.generateContent(content);
      final responseText = response.text;

      nutritionData = responseText!;
      print('Raw Gemini Response: $nutritionData');

      return _parseGeminiResponse(responseText);
    } catch (e) {
      print('Error using Gemini AI: $e');
      return {
        'carbs': 0,
        'protein': 0,
        'calories': 0,
        'fat': 0,
      };
    }
  }

  Map<String, double> _parseGeminiResponse(String response) {
    Map<String, double> nutritionValues = {
      'carbs': 0,
      'protein': 0,
      'calories': 0,
      'fat': 0,
    };

    try {
      final lines = response.split('\n');
      for (var line in lines) {
        line = line.toLowerCase();
        if (line.contains('carb')) {
          nutritionValues['carbs'] = _extractNumberFromString(line);
        } else if (line.contains('protein')) {
          nutritionValues['protein'] = _extractNumberFromString(line);
        } else if (line.contains('calor')) {
          nutritionValues['calories'] = _extractNumberFromString(line);
        } else if (line.contains('fat')) {
          nutritionValues['fat'] = _extractNumberFromString(line);
        }
      }
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

  Future<void> _addMeal(
      String name,
      double mealCarbs,
      double mealProtein,
      double mealCalories,
      double mealFat, {
        double grams = 0.0,
      }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('user_id');

      if (userId == null) {
        print('User ID not found, logging out...');
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
          );
        }
        return;
      }

      final baseUrl = 'https://func-fitapp-backend.azurewebsites.net/foods/';
      final uri = Uri.parse(baseUrl).replace(
        queryParameters: {
          'user_id': userId.toString(),
          'grams': '100',
          //user grams
        },
      );
      //macros per 100g
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name.toLowerCase(),
          'carbs': mealCarbs,
          'protein': mealProtein,
          'calories': mealCalories,
          'fat': mealFat,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _fetchTodaysFoods(); // Refresh the foods list from backend
      } else {
        throw Exception('Failed to add meal to server');
      }
    } catch (e) {
      print('Error adding meal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add meal: $e')),
        );
      }
    }
  }


  Widget _buildMacroCard(String title, double value, double percentage, Color color) {
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'Goal: ${goalValue.toStringAsFixed(0)}${title == 'Calories' ? 'kcal' : 'g'}',
                style: TextStyle(
                  color: color.withOpacity(0.7),
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

  Widget _buildMealCard(FoodLog meal, int index) {
    // Calculate nutrition values based on the grams consumed
    final ratio = meal.grams / 100;
    final actualCarbs = meal.food.carbs * ratio;
    final actualProtein = meal.food.protein * ratio;
    final actualCalories = meal.food.calories * ratio;
    final actualFat = meal.food.fat * ratio;

    return Dismissible(
      key: Key(meal.food.name + index.toString()),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Container(
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


  void _showAddMealDialog() {
    // Variables for meal data
    String mealName = '';
    double mealQuantity = 0;
    bool showNutritionFields = false;
    List<FoodDetails> searchResults = [];
    Timer? _debounce;

    // Controllers
    final per100gCarbsController = TextEditingController();
    final per100gProteinController = TextEditingController();
    final per100gCaloriesController = TextEditingController();
    final per100gFatController = TextEditingController();
    final searchController = TextEditingController();
    final quantityController = TextEditingController();

    // Services
    final FoodService _foodService = FoodService();

    // Nutrition values
    double per100gCarbs = 0;
    double per100gProtein = 0;
    double per100gCalories = 0;
    double per100gFat = 0;

    // Helper function to calculate nutrition based on quantity
    void calculateNutritionForQuantity() {
      if (mealQuantity > 0) {
        double ratio = mealQuantity / 100;
        mealCarbs = per100gCarbs * ratio;
        mealProtein = per100gProtein * ratio;
        mealCalories = per100gCalories * ratio;
        mealFat = per100gFat * ratio;
      }
    }

    // Helper function to update nutrition values from search results
    void updateNutritionValues(FoodDetails food) {
      per100gCarbs = food.carbs;
      per100gProtein = food.protein;
      per100gCalories = food.calories;
      per100gFat = food.fat;

      per100gCarbsController.text = food.carbs.toString();
      per100gProteinController.text = food.protein.toString();
      per100gCaloriesController.text = food.calories.toString();
      per100gFatController.text = food.fat.toString();

      mealName = food.name;
      searchController.text = food.name;

      // Calculate values if quantity is already entered
      if (mealQuantity > 0) {
        calculateNutritionForQuantity();
      }
    }


    showDialog(
      context: context,
      barrierColor: Colors.black26,
      builder: (BuildContext context) {
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
                      Row(
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
                      ),
                      const SizedBox(height: 24),

                      // Search Field with Auto-complete
                      TextFormField(
                        controller: searchController,
                        decoration:
                            ThemeConstants.inputDecoration(context).copyWith(
                          labelText: 'Food Name',
                          hintText: 'Type to search or add new food',
                          prefixIcon: const Icon(Icons.restaurant_menu),
                        ),
                        onChanged: (value) {
                          mealName = value;
                          if (_debounce?.isActive ?? false) _debounce!.cancel();
                          _debounce = Timer(const Duration(milliseconds: 500),
                              () async {
                            final results =
                                await _foodService.searchFoods(value);
                            setDialogState(() {
                              searchResults = results;
                            });
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Search Results
                      if (searchResults.isNotEmpty) ...[
                        Container(
                          constraints: const BoxConstraints(maxHeight: 200),
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
                                    updateNutritionValues(food);
                                    showNutritionFields = true;
                                    searchResults = [];
                                    calculateNutritionForQuantity();
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Quantity Field
                      TextField(
                        controller: quantityController,
                        decoration:
                            ThemeConstants.inputDecoration(context).copyWith(
                          labelText: 'Quantity',
                          hintText: 'Enter quantity in grams',
                          prefixIcon: const Icon(Icons.scale),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          mealQuantity = double.tryParse(value) ?? 0;
                          calculateNutritionForQuantity();
                          setDialogState(() {});
                        },
                      ),
                      const SizedBox(height: 24),
                      // Camera Scanning Section
                      if (!showNutritionFields) ...[
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
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
                              Text(
                                'Use your camera to scan the nutrition label from your food package',
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  final XFile? image = await _picker.pickImage(
                                    source: ImageSource.camera,
                                  );
                                  if (image != null) {
                                    final inputImage =
                                        InputImage.fromFilePath(image.path);
                                    final RecognizedText recognizedText =
                                        await _textRecognizer
                                            .processImage(inputImage);

                                    final nutritionInfo =
                                        await _extractNutritionWithGemini(
                                            recognizedText.text);

                                    setDialogState(() {
                                      per100gCarbs =
                                          nutritionInfo['carbs'] ?? 0;
                                      per100gProtein =
                                          nutritionInfo['protein'] ?? 0;
                                      per100gCalories =
                                          nutritionInfo['calories'] ?? 0;
                                      per100gFat = nutritionInfo['fat'] ?? 0;

                                      per100gCarbsController.text =
                                          per100gCarbs.toString();
                                      per100gProteinController.text =
                                          per100gProtein.toString();
                                      per100gCaloriesController.text =
                                          per100gCalories.toString();
                                      per100gFatController.text =
                                          per100gFat.toString();

                                      showNutritionFields = true;
                                      calculateNutritionForQuantity();
                                    });
                                  }
                                },
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Scan Nutrition Label'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
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
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Or enter values manually:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],

                      // Nutrition Fields
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: per100gCarbsController,
                          decoration:
                              ThemeConstants.inputDecoration(context).copyWith(
                            labelText: 'Carbs per 100g',
                            prefixIcon: const Icon(Icons.grain),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            per100gCarbs = double.tryParse(value) ?? 0;
                            calculateNutritionForQuantity();
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: per100gProteinController,
                          decoration:
                              ThemeConstants.inputDecoration(context).copyWith(
                            labelText: 'Protein per 100g',
                            prefixIcon: const Icon(Icons.egg),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            per100gProtein = double.tryParse(value) ?? 0;
                            calculateNutritionForQuantity();
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: per100gCaloriesController,
                          decoration:
                              ThemeConstants.inputDecoration(context).copyWith(
                            labelText: 'Calories per 100g',
                            prefixIcon: const Icon(Icons.local_fire_department),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            per100gCalories = double.tryParse(value) ?? 0;
                            calculateNutritionForQuantity();
                            setDialogState(() {});
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: per100gFatController,
                          decoration:
                              ThemeConstants.inputDecoration(context).copyWith(
                            labelText: 'Fat per 100g',
                            prefixIcon: const Icon(Icons.opacity),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            per100gFat = double.tryParse(value) ?? 0;
                            calculateNutritionForQuantity();
                            setDialogState(() {});
                          },
                        ),

                      // Calculated Values Display
                      if (mealQuantity > 0 &&
                          (per100gCarbs > 0 ||
                              per100gProtein > 0 ||
                              per100gCalories > 0 ||
                              per100gFat > 0)) ...[
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: ThemeConstants.cardDecoration,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Calculated values for ${mealQuantity}g:',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Carbs: ${mealCarbs.toStringAsFixed(1)}g',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Protein: ${mealProtein.toStringAsFixed(1)}g',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Calories: ${mealCalories.toStringAsFixed(1)} kcal',
                                style: const TextStyle(fontSize: 14),
                              ),
                              Text(
                                'Fat: ${mealFat.toStringAsFixed(1)}g',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Action Buttons
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () async {
                                    if (mealName.isNotEmpty &&
                                        mealQuantity > 0) {
                                      await _addMeal(
                                        mealName,
                                        mealCarbs,
                                        mealProtein,
                                        mealCalories,
                                        mealFat,
                                        grams: mealQuantity,
                                      );
                                      if (context.mounted) {
                                        Navigator.of(context).pop();
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Add Meal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    // Cleanup
    addPostFrameCallback((_) {
      _debounce?.cancel();
    });
  }

// Helper method for cleanup
  void addPostFrameCallback(void Function(Duration) callback) {
    WidgetsBinding.instance.addPostFrameCallback(callback);
  }

  double get totalMacros => carbs + protein + fat;

  @override
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    double carbsPercentage = protein + carbs + fat > 0 ? (carbs / (protein + carbs + fat)) * 100 : 0;
    double proteinPercentage = protein + carbs + fat > 0 ? (protein / (protein + carbs + fat)) * 100 : 0;
    double fatPercentage = protein + carbs + fat > 0 ? (fat / (protein + carbs + fat)) * 100 : 0;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inversePrimary,
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
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Calendar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DailyPastPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => WeeklyFoodLogs()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Chat'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChatPage()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
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
      ),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
            );
          },
        ),
        title: const Text(
          'Macro Tracker',
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Today\'s Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (todaysMeals.isNotEmpty) ...[
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
                          _buildMacroCard('Carbs', carbs, carbsPercentage, Colors.blue),
                          _buildMacroCard('Protein', protein, proteinPercentage, Colors.red),
                          _buildMacroCard('Calories', calories, 0, Colors.orange),
                          _buildMacroCard('Fat', fat, fatPercentage, Colors.green),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Meals Today',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                        ),
                        TextButton.icon(
                          icon: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          label: Text(
                            'Add Meal',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          onPressed: _showAddMealDialog,
                        ),
                      ],
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
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (todaysMeals.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: todaysMeals.length,
                  itemBuilder: (context, index) => _buildMealCard(todaysMeals[index], index),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }
}
