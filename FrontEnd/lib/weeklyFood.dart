
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:foodex/services/recommended_intake.dart';
import 'package:foodex/services/weekly_food_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:math' show max;



class CalorieBarChart extends StatelessWidget {
  final List<DailyNutrition> dailyNutrition;
  final double recommendedCalories;

  const CalorieBarChart({
    super.key,
    required this.dailyNutrition,
    required this.recommendedCalories,
  });

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }

  List<MapEntry<int, DailyNutrition?>> _getWeekData() {
    Map<int, DailyNutrition?> weekData = {};

    // Initialize all days with null
    for (int i = 1; i <= 7; i++) {
      weekData[i] = null;
    }

    // Fill in actual data
    // Fill in actual data
    for (var nutrition in dailyNutrition) {
      try {
        final date = DateTime.parse(nutrition.date);
        print('Date: ${nutrition.date}, Weekday: ${date.weekday}, Calories: ${nutrition.totalCalories}');
        weekData[date.weekday] = nutrition;
      } catch (e) {
        print('Error parsing date: ${nutrition.date}, Error: $e');
      }
    }

    // Debug print all days
    weekData.forEach((weekday, nutrition) {
      print('Weekday $weekday: ${nutrition?.totalCalories ?? 'no data'}');
    });

    // Convert to sorted list
    return weekData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
  }

  @override
  Widget build(BuildContext context) {
    final weekData = _getWeekData();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Calorie Intake',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.flag_outlined,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${recommendedCalories.toStringAsFixed(0)} kcal',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: recommendedCalories * 1.2,
                minY: 0,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipMargin: 8,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final nutrition = weekData[groupIndex].value;
                      if (nutrition == null) return null;

                      return BarTooltipItem(
                        '${nutrition.totalCalories.toStringAsFixed(0)} kcal\n',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: '${(nutrition.totalCalories / recommendedCalories * 100).toStringAsFixed(1)}% of goal',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value >= weekData.length) return const Text('');
                        final weekday = weekData[value.toInt()].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _getDayName(weekday),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: (recommendedCalories / 4).roundToDouble(),
                      getTitlesWidget: (value, meta) {
                        if (value <= recommendedCalories) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: recommendedCalories / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[200],
                      strokeWidth: 1,
                    );
                  },
                ),
                barGroups: List.generate(
                  weekData.length,
                      (index) {
                    final nutrition = weekData[index].value;
                    // Only show bar if we have actual data
                    if (nutrition == null || nutrition.totalCalories <= 0) {
                      // Return a completely empty bar
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: 0,
                            color: Colors.grey[300],
                            width: 12,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(2),
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: recommendedCalories,
                              color: Colors.grey[100],
                            ),
                          ),
                        ],
                      );
                    }

                    final calories = nutrition.totalCalories;
                    final percentage = calories / recommendedCalories;
                    Color barColor;

                    if (percentage >= 1) {
                      barColor = Colors.green[400]!;
                    } else if (percentage >= 0.8) {
                      barColor = Colors.blue[400]!;
                    } else {
                      barColor = Colors.orange[400]!;
                    }

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: calories,
                          color: barColor.withOpacity(0.85),
                          width: 12,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                            bottom: Radius.circular(2),
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: recommendedCalories,
                            color: Colors.grey[100],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(Colors.green[400]!, '≥ 100%'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.blue[400]!, '≥ 80%'),
              const SizedBox(width: 16),
              _buildLegendItem(Colors.orange[400]!, '< 80%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class MacroBalanceChart extends StatelessWidget {
  final double proteinGoal;
  final double carbsGoal;
  final double fatGoal;
  final double currentProtein;
  final double currentCarbs;
  final double currentFat;

  const MacroBalanceChart({
    super.key,
    required this.proteinGoal,
    required this.carbsGoal,
    required this.fatGoal,
    required this.currentProtein,
    required this.currentCarbs,
    required this.currentFat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 270, // Increased height
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Macro Balance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16), // Reduced spacing
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Goals section
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to evenly space items
                    children: [
                      const Text(
                        'Diet Goals',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _buildGoalRow('Protein', proteinGoal, Colors.red[400]!),
                      _buildGoalRow('Carbs', carbsGoal, Colors.blue[400]!),
                      _buildGoalRow('Fat', fatGoal, Colors.green[400]!),
                    ],
                  ),
                ),
                // Progress Bars section
                const SizedBox(width: 24),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Changed to evenly space items
                    children: [
                      const Text(
                        'Weekly Average',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      _buildProgressBar(currentProtein, proteinGoal, Colors.red[400]!),
                      _buildProgressBar(currentCarbs, carbsGoal, Colors.blue[400]!),
                      _buildProgressBar(currentFat, fatGoal, Colors.green[400]!),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow(String label, double value, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          '${value.toInt()}g',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(double current, double goal, Color color) {
    final percentage = (current / goal * 100).clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${current.toInt()}g',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${percentage.toInt()}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4), // Reduced spacing
        Container(
          width: double.infinity,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: percentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class MacroLineChart extends StatefulWidget {
  final List<DailyNutrition> dailyNutrition;
  final RecommendedIntake recommendedIntake;

  const MacroLineChart({
    super.key,
    required this.dailyNutrition,
    required this.recommendedIntake,
  });

  @override
  State<MacroLineChart> createState() => _MacroLineChartState();
}

class _MacroLineChartState extends State<MacroLineChart> {
  String selectedMacro = 'protein';

  Color get selectedColor {
    switch (selectedMacro) {
      case 'protein':
        return Colors.red;
      case 'carbs':
        return Colors.blue;
      case 'fat':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  double getMacroValue(DailyNutrition nutrition) {
    switch (selectedMacro) {
      case 'protein':
        return nutrition.totalProtein;
      case 'carbs':
        return nutrition.totalCarbs;
      case 'fat':
        return nutrition.totalFat;
      default:
        return 0;
    }
  }

  double getRecommendedValue() {
    switch (selectedMacro) {
      case 'protein':
        return widget.recommendedIntake.protein;
      case 'carbs':
        return widget.recommendedIntake.carbs;
      case 'fat':
        return widget.recommendedIntake.fat;
      default:
        return 0;
    }
  }

  double getMaxY(List<FlSpot> spots, double recommendedValue) {
    // Get max value from data points
    double maxDataValue = spots.map((spot) => spot.y).fold(0.0, max);

    // Always use recommended value if data doesn't exceed it

      // Add small padding above recommended value
    //return recommendedValue + (recommendedValue * 0.1); // 10% padding

    // Only for cases where data exceeds recommended value
    return maxDataValue + (maxDataValue * 0.1);
  }

  @override
  Widget build(BuildContext context) {
    final recommendedValue = getRecommendedValue();

    final sortedData = List<DailyNutrition>.from(widget.dailyNutrition)
      ..sort((a, b) => DateTime.parse(a.date).compareTo(DateTime.parse(b.date)));

    final spots = List<FlSpot>.generate(
      sortedData.length,
          (i) => FlSpot(i.toDouble(), getMacroValue(sortedData[i])),
    );

    final maxY = getMaxY(spots, recommendedValue);
    final interval = maxY <= 100 ? 20.0 : 40.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${selectedMacro.substring(0, 1).toUpperCase()}${selectedMacro.substring(1)} intake',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  _buildButton('Protein', 'protein', Colors.red),
                  const SizedBox(width: 8),
                  _buildButton('Carbs', 'carbs', Colors.blue),
                  const SizedBox(width: 8),
                  _buildButton('Fat', 'fat', Colors.green),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: selectedColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Recommended: ${recommendedValue.toInt()}g',
                  style: TextStyle(
                    color: selectedColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[300],
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= sortedData.length) {
                          return const Text('');
                        }
                        final date = DateTime.parse(sortedData[value.toInt()].date);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(date),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (sortedData.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: false,
                    color: selectedColor,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: selectedColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: selectedColor.withOpacity(0.1),
                    ),
                  ),
                ],
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: recommendedValue,
                      color: selectedColor.withOpacity(0.7),
                      strokeWidth: 2,
                      dashArray: [8, 4],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton(String label, String value, Color color) {
    final isSelected = selectedMacro == value;
    return GestureDetector(
      onTap: () => setState(() => selectedMacro = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : Colors.grey[600],
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}



class WeeklyFoodLogs extends StatefulWidget {
  const WeeklyFoodLogs({super.key});

  @override
  _WeeklyFoodLogsState createState() => _WeeklyFoodLogsState();
}

class _WeeklyFoodLogsState extends State<WeeklyFoodLogs> {
  final WeeklyFoodService _weeklyService = WeeklyFoodService();
  bool _isLoading = true;
  List<DailyNutrition> _dailyNutrition = [];
  late DateTime _currentWeekStart;
  late DateTime _currentWeekEnd;

  final RecommendedIntakeService _recommendedService = RecommendedIntakeService();
  RecommendedIntake? _recommendedIntake;

  @override
  void initState() {
    super.initState();
    _currentWeekStart = _getWeekStart(DateTime.now());
    _currentWeekEnd = _getWeekEnd(_currentWeekStart);
    _fetchWeeklyFoods();
    _loadRecommendedIntake();
  }

  double _getAverageNutrient(List<DailyNutrition> dailyNutrition, String nutrient) {
    if (dailyNutrition.isEmpty) return 0;

    double sum = 0;
    for (var day in dailyNutrition) {
      switch (nutrient) {
        case 'protein':
          sum += day.totalProtein;
          break;
        case 'carbs':
          sum += day.totalCarbs;
          break;
        case 'fat':
          sum += day.totalFat;
          break;
      }
    }
    return sum / dailyNutrition.length;
  }

  Future<void> _loadRecommendedIntake() async {
    final recommended = await _recommendedService.getRecommendedIntake();
    if (recommended != null) {
      setState(() {
        _recommendedIntake = recommended;
      });
    }
  }
  DateTime _getWeekStart(DateTime date) {
    return date.subtract(Duration(days: date.weekday - 1));
  }

  DateTime _getWeekEnd(DateTime date) {
    return date.add(Duration(days: 7 - date.weekday));
  }

  void _navigateWeek(bool forward) {
    setState(() {
      if (forward) {
        _currentWeekStart = _currentWeekStart.add(const Duration(days: 7));
      } else {
        _currentWeekStart = _currentWeekStart.subtract(const Duration(days: 7));
      }
      _currentWeekEnd = _getWeekEnd(_currentWeekStart);
      _fetchWeeklyFoods();
    });
  }

  String _formatDateRange() {
    final DateFormat formatter = DateFormat('MMM d');
    return '${formatter.format(_currentWeekStart)} - ${formatter.format(_currentWeekEnd)}';
  }

  Future<void> _fetchWeeklyFoods() async {
    setState(() => _isLoading = true);

    try {
      final foodsByDate = await _weeklyService.fetchWeeklyFoodLogs(
        _currentWeekStart,
        _currentWeekEnd,
      );
      final dailyNutrition = _weeklyService.calculateDailyNutrition(foodsByDate);

      setState(() {
        _dailyNutrition = dailyNutrition;
        _isLoading = false;
      });

      // Print foods by date
      for (var day in _dailyNutrition) {
        print('\nDate: ${day.date}');
        print('Foods consumed:');
        for (var food in day.foods) {
          print('- ${food.food.name}');
          print('  Amount: ${food.grams}g');
          print('  Per serving:');
          print('    Calories: ${food.food.calories}');
          print('    Protein: ${food.food.protein}g');
          print('    Carbs: ${food.food.carbs}g');
          print('    Fat: ${food.food.fat}g');
          print('  Consumed at: ${food.consumedAt}');
          print('------------------------');
        }
      }
    } catch (e) {
      print('Error fetching weekly foods: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Food Logs'),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
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
        child: SingleChildScrollView(  // Add this
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => _navigateWeek(false),
                      tooltip: 'Previous week',
                    ),
                    Text(
                      _formatDateRange(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: () => _navigateWeek(true),
                      tooltip: 'Next week',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 350,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dailyNutrition.isEmpty
                    ? const Center(child: Text('No food logs for this week'))
                    : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CalorieBarChart(
                    dailyNutrition: _dailyNutrition,
                    recommendedCalories: _recommendedIntake?.calorie ?? 2348,
                  ),
                ),
              ),

              // Macro balance chart
              SizedBox(
                height: 270,
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dailyNutrition.isEmpty
                    ? const Center(child: Text('No food logs for this week'))
                    : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MacroBalanceChart(
                    proteinGoal: _recommendedIntake?.protein ?? 78,
                    carbsGoal: _recommendedIntake?.carbs ?? 215,
                    fatGoal: _recommendedIntake?.fat ?? 65,
                    currentProtein: _getAverageNutrient(_dailyNutrition, 'protein'),
                    currentCarbs: _getAverageNutrient(_dailyNutrition, 'carbs'),
                    currentFat: _getAverageNutrient(_dailyNutrition, 'fat'),
                  ),
                ),
              ),

              // Macro line chart
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _dailyNutrition.isEmpty
                    ? const Center(child: Text('No food logs for this week'))
                    : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: MacroLineChart(
                    dailyNutrition: _dailyNutrition,
                    recommendedIntake: _recommendedIntake!,
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