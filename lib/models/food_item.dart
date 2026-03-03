import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class FoodItem {
  final String id;
  final String name;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;

  FoodItem({
    String? id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.servingSize,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'calories': calories,
    'protein': protein, 'carbs': carbs, 'fat': fat, 'servingSize': servingSize,
  };

  factory FoodItem.fromJson(Map<String, dynamic> j) => FoodItem(
    id: j['id'], name: j['name'], calories: j['calories'],
    protein: j['protein'].toDouble(), carbs: j['carbs'].toDouble(),
    fat: j['fat'].toDouble(), servingSize: j['servingSize'],
  );
}

class UserPrefsManager {
  static Future<void> saveFoodItems(List<FoodItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_food_items', jsonEncode(items.map((e) => e.toJson()).toList()));
  }

  static Future<List<FoodItem>> loadFoodItems() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('saved_food_items');
    if (data == null) return [];
    return (jsonDecode(data) as List).map((e) => FoodItem.fromJson(e)).toList();
  }

  static Future<void> clearFoodItems() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_food_items');
  }

  static Future<void> saveCalorieGoal(int goal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('calorie_goal', goal);
  }

  static Future<int> loadCalorieGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('calorie_goal') ?? 2000;
  }

  static Future<bool> shouldResetForNewDay() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStr = prefs.getString('last_log_date');
    if (savedStr == null) return false;
    final saved = DateTime.parse(savedStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    return saved.isBefore(today);
  }

  static Future<void> updateLastLogDate() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    await prefs.setString('last_log_date', today.toIso8601String());
  }

  static Future<void> setOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_onboarding_complete', true);
  }

  static Future<void> saveUserProfile({
    required String currentWeight,
    required String targetWeight,
    required String selectedGoal,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_weight', currentWeight);
    await prefs.setString('target_weight', targetWeight);
    await prefs.setString('selected_goal', selectedGoal);
  }

  static Future<String> loadCurrentWeight() async =>
      (await SharedPreferences.getInstance()).getString('current_weight') ?? '';

  static Future<String> loadTargetWeight() async =>
      (await SharedPreferences.getInstance()).getString('target_weight') ?? '';

  static Future<String> loadSelectedGoal() async =>
      (await SharedPreferences.getInstance()).getString('selected_goal') ?? 'Lose Weight';
}