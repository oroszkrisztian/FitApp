import 'dart:convert';
import 'package:fit_app/chat_page.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

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
  double fat = 0;
  List<Map<String, dynamic>> meals = [];
  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = GoogleMlKit.vision.textRecognizer();
  SharedPreferences? _preferences;
  DateTime _lastSavedDate = DateTime.now();
  bool _isInitialized = false;

  late final GenerativeModel _geminiModel;
  String nutritionData = '';

  double mealCarbs = 0;
  double mealProtein = 0;
  double mealCalories = 0;
  double mealFat = 0;

  @override
  void initState() {
    super.initState();
    _initializeGemini();
    _loadSavedData();
    _initializeApp();
  }

  void _initializeGemini() {
    _geminiModel = GenerativeModel(
      model: 'gemini-pro',
      apiKey: 'AIzaSyDI7Bjn6HTZllGHPEtxdmLas9HNlNLnOco',
    );
  }

  Future<void> _initializeApp() async {
    try {
      await _loadSavedData();
    } catch (e) {
      print('Error initializing app: $e');
      // Initialize with default values if SharedPreferences fails
      _preferences = null;
      setState(() {
        meals = [];
        carbs = 0;
        protein = 0;
        calories = 0;
        fat = 0;
      });
    } finally {
      setState(() {
        _isInitialized = true;
      });
    }
  }

  Future<void> _loadSavedData() async {
    try {
      _preferences = await SharedPreferences.getInstance();

      final savedDateStr = _preferences?.getString('last_saved_date');
      if (savedDateStr != null) {
        _lastSavedDate = DateTime.parse(savedDateStr);

        // Check if it's a new day
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final savedDate = DateTime(
            _lastSavedDate.year, _lastSavedDate.month, _lastSavedDate.day);

        if (today.isAfter(savedDate)) {
          print('New day detected, resetting data');
          await _resetData();
          return;
        }
      }

      final savedMealsJson = _preferences?.getString('meals');
      if (savedMealsJson != null) {
        final savedMeals = List<Map<String, dynamic>>.from(json
            .decode(savedMealsJson)
            .map((x) => Map<String, dynamic>.from(x)));

        setState(() {
          meals = savedMeals;
          carbs = _preferences?.getDouble('carbs') ?? 0;
          protein = _preferences?.getDouble('protein') ?? 0;
          calories = _preferences?.getDouble('calories') ?? 0;
          fat = _preferences?.getDouble('fat') ?? 0;
        });
      }
    } catch (e) {
      print('Error loading saved data: $e');
      rethrow;
    }
  }

  Future<void> _saveData() async {
    if (_preferences == null) return;

    try {
      final now = DateTime.now();
      await _preferences?.setString('last_saved_date', now.toIso8601String());
      await _preferences?.setString('meals', json.encode(meals));
      await _preferences?.setDouble('carbs', carbs);
      await _preferences?.setDouble('protein', protein);
      await _preferences?.setDouble('calories', calories);
      await _preferences?.setDouble('fat', fat);

      _lastSavedDate = now; // Update the in-memory date after successful save
    } catch (e) {
      print('Error saving data: $e');
    }
  }

  Future<void> _resetData() async {
    print('Resetting data at ${DateTime.now()}');
    setState(() {
      meals = [];
      carbs = 0;
      protein = 0;
      calories = 0;
      fat = 0;
      _lastSavedDate = DateTime.now(); // Update the last saved date
    });
    await _saveData();
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
    double mealFat,
  ) async {
    if (!_isInitialized) {
      return;
    }

    setState(() {
      meals.add({
        'name': name,
        'carbs': mealCarbs,
        'protein': mealProtein,
        'calories': mealCalories,
        'fat': mealFat,
      });

      carbs += mealCarbs;
      protein += mealProtein;
      calories += mealCalories;
      fat += mealFat;

      _isLoading = false;
    });

    await _saveData();
  }

  Future<void> _deleteMeal(int index) async {
    if (!_isInitialized) {
      return;
    }

    setState(() {
      final meal = meals[index];
      carbs -= meal['carbs'];
      protein -= meal['protein'];
      calories -= meal['calories'];
      fat -= meal['fat'];
      meals.removeAt(index);
    });

    await _saveData();
  }

  Widget _buildMacroCard(
      String title, double value, double percentage, Color color) {
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
          const SizedBox(height: 2),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              color: color.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealCard(Map<String, dynamic> meal, int index) {
    return Dismissible(
      key: Key(meal['name'] + index.toString()),
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
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteMeal(index);
      },
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
                    meal['name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: Colors.grey[600],
                    ),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: Colors.red[700]),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deleteMeal(index);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMealNutrient('Carbs', meal['carbs'], Colors.blue),
                  _buildMealNutrient('Protein', meal['protein'], Colors.red),
                  _buildMealNutrient(
                      'Calories', meal['calories'], Colors.orange),
                  _buildMealNutrient('Fat', meal['fat'], Colors.green),
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
    String mealName = '';
    double mealQuantity = 0;
    bool showNutritionFields = false;

    final per100gCarbsController = TextEditingController();
    final per100gProteinController = TextEditingController();
    final per100gCaloriesController = TextEditingController();
    final per100gFatController = TextEditingController();

    double per100gCarbs = 0;
    double per100gProtein = 0;
    double per100gCalories = 0;
    double per100gFat = 0;

    void calculateNutritionForQuantity() {
      if (mealQuantity > 0) {
        double ratio = mealQuantity / 100;
        mealCarbs = per100gCarbs * ratio;
        mealProtein = per100gProtein * ratio;
        mealCalories = per100gCalories * ratio;
        mealFat = per100gFat * ratio;
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
                      TextField(
                        decoration:
                            ThemeConstants.inputDecoration(context).copyWith(
                          labelText: 'Meal Name',
                          hintText: 'Enter meal name',
                          prefixIcon: const Icon(Icons.restaurant_menu),
                        ),
                        onChanged: (value) {
                          mealName = value;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        decoration:
                            ThemeConstants.inputDecoration(context).copyWith(
                          labelText: 'Quantity (grams)',
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
                      if (!showNutritionFields) ...[
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            if (mealName.isNotEmpty && mealQuantity > 0) {
                              setDialogState(() {
                                showNutritionFields = true;
                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Next',
                            style: ThemeConstants.buttonStyle,
                          ),
                        ),
                      ],
                      if (showNutritionFields) ...[
                        const SizedBox(height: 24),
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
                        const SizedBox(height: 16),
                        TextField(
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
                        TextField(
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
                        TextField(
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
                        TextField(
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
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading
                                  ? null
                                  : () async {
                                      if (mealName.isNotEmpty) {
                                        await _addMeal(
                                          mealName,
                                          mealCarbs,
                                          mealProtein,
                                          mealCalories,
                                          mealFat,
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
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Add Meal',
                                      style: ThemeConstants.buttonStyle,
                                    ),
                            ),
                          ],
                        ),
                      ],
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

  double get totalMacros => carbs + protein + fat;

  @override
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final now = DateTime.now();
    if (!_isSameDay(_lastSavedDate, now)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _resetData();
      });
    }

    double carbsPercentage = totalMacros > 0 ? (carbs / totalMacros) * 100 : 0;
    double proteinPercentage =
        totalMacros > 0 ? (protein / totalMacros) * 100 : 0;
    double fatPercentage = totalMacros > 0 ? (fat / totalMacros) * 100 : 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Macro Tracker',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () {
              // Add date picker functionality
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () {
              // Add analytics/stats view
            },
          ),
        ],
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
                      TextButton.icon(
                        icon: Icon(
                          Icons.insights,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        label: Text(
                          'Details',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        onPressed: () {
                          // Add detailed stats view
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (meals.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 0,
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
                          _buildMacroCard(
                              'Carbs', carbs, carbsPercentage, Colors.blue),
                          _buildMacroCard('Protein', protein, proteinPercentage,
                              Colors.red),
                          _buildMacroCard('Calories', calories, 0,
                              Colors.orange), // Changed percentage for calories
                          _buildMacroCard(
                              'Fat', fat, fatPercentage, Colors.green),
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
                            Text(
                              'Start tracking your nutrition by adding a meal',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Meal'),
                              onPressed: _showAddMealDialog,
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                textStyle: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
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
            if (meals.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: meals.length,
                  itemBuilder: (context, index) =>
                      _buildMealCard(meals[index], index),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: meals.isEmpty
          ? null
          : Container(
              margin: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FloatingActionButton(
                    heroTag: 'chat',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ChatPage()),
                      );
                    },
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.chat),
                    elevation: 4,
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
