import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodAnalysisResponse {
  final String foodName;
  final int calories;
  final double protein;
  final double carbs;
  final double fat;
  final String servingSize;

  FoodAnalysisResponse({
    required this.foodName, required this.calories,
    required this.protein, required this.carbs,
    required this.fat, required this.servingSize,
  });

  factory FoodAnalysisResponse.fromJson(Map<String, dynamic> j) =>
    FoodAnalysisResponse(
      foodName: j['food_name'], calories: j['calories'],
      protein: j['protein'].toDouble(), carbs: j['carbs'].toDouble(),
      fat: j['fat'].toDouble(), servingSize: j['serving_size'],
    );
}

class FoodAPIService {
  static const baseURL = 'https://web-production-f32bc.up.railway.app';

  static Future<FoodAnalysisResponse> analyzeFood({
    required String description,
    required String quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseURL/analyze-food'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'food_description': description,
        'quantity': quantity.isEmpty ? '1 serving' : quantity,
      }),
    );

    if (response.statusCode == 200) {
      return FoodAnalysisResponse.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to analyze food');
    }
  }
}