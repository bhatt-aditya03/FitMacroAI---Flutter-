import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/food_api_service.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  List<FoodItem> _foodItems = [];
  int _calorieGoal = 2000;
  bool _showAddSheet = false;

  final _descCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  bool _isLoading = false;

  int get _totalCalories => _foodItems.fold(0, (s, i) => s + i.calories);
  double get _totalProtein => _foodItems.fold(0.0, (s, i) => s + i.protein);
  double get _totalCarbs => _foodItems.fold(0.0, (s, i) => s + i.carbs);
  double get _totalFat => _foodItems.fold(0.0, (s, i) => s + i.fat);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final shouldReset = await UserPrefsManager.shouldResetForNewDay();
    if (shouldReset) {
      await UserPrefsManager.clearFoodItems();
      setState(() => _foodItems = []);
    } else {
      final items = await UserPrefsManager.loadFoodItems();
      setState(() => _foodItems = items);
    }
    await UserPrefsManager.updateLastLogDate();
    final goal = await UserPrefsManager.loadCalorieGoal();
    setState(() => _calorieGoal = goal);
  }

  Future<void> _addFood() async {
    if (_descCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final result = await FoodAPIService.analyzeFood(
        description: _descCtrl.text,
        quantity: _qtyCtrl.text,
      );
      final newItem = FoodItem(
        name: result.foodName,
        calories: result.calories,
        protein: result.protein,
        carbs: result.carbs,
        fat: result.fat,
        servingSize: result.servingSize,
      );
      setState(() {
        _foodItems.add(newItem);
        _isLoading = false;
        _showAddSheet = false;
        _descCtrl.clear();
        _qtyCtrl.clear();
      });
      await UserPrefsManager.saveFoodItems(_foodItems);
    } catch (_) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not analyze food. Check your connection.')),
        );
      }
    }
  }

  void _deleteItem(int index) async {
    setState(() => _foodItems.removeAt(index));
    await UserPrefsManager.saveFoodItems(_foodItems);
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_totalCalories / _calorieGoal).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
        backgroundColor: const Color(0xFF2E7D32),
        elevation: 0,
      ),
      body: Column(
        children: [
          // ── Green Summary Card ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF2E7D32),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                const Text("Today's Log",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                const SizedBox(height: 12),

                // 4 Macros Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _MacroCell(value: '$_totalCalories', label: 'Cal'),
                    _Divider(),
                    _MacroCell(value: '${_totalProtein.toStringAsFixed(1)}g', label: 'Protein'),
                    _Divider(),
                    _MacroCell(value: '${_totalCarbs.toStringAsFixed(1)}g', label: 'Carbs'),
                    _Divider(),
                    _MacroCell(value: '${_totalFat.toStringAsFixed(1)}g', label: 'Fat'),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress Bar
                Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.3),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('$_totalCalories / $_calorieGoal cal',
                        style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),

          // ── Food List ──────────────────────────────────────────────────────
          Expanded(
            child: _foodItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.restaurant, size: 50, color: Colors.grey.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        const Text('No food logged yet', style: TextStyle(color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Tap + to add food',
                            style: TextStyle(color: Colors.grey.withOpacity(0.7), fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _foodItems.length,
                    itemBuilder: (context, index) {
                      final item = _foodItems[index];
                      return Dismissible(
                        key: Key(item.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) => _deleteItem(index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: Row(
                            children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.restaurant,
                                    color: Color(0xFF2E7D32), size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600, fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(
                                      'P: ${item.protein.toStringAsFixed(1)}g  C: ${item.carbs.toStringAsFixed(1)}g  F: ${item.fat.toStringAsFixed(1)}g',
                                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text('${item.calories}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Color(0xFF2E7D32))),
                                  const Text('cal',
                                      style: TextStyle(color: Colors.grey, fontSize: 11)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // ── Add Food Button ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => setState(() => _showAddSheet = true),
                icon: const Icon(Icons.add_circle),
                label: const Text('Add Food',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),

      // ── Add Food Bottom Sheet ──────────────────────────────────────────────
      bottomSheet: _showAddSheet ? _buildAddSheet() : null,
    );
  }

  Widget _buildAddSheet() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 30,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle + Header
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add Food',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                onPressed: () {
                  setState(() => _showAddSheet = false);
                  _descCtrl.clear();
                  _qtyCtrl.clear();
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),

          // AI Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFF2E7D32), size: 16),
                SizedBox(width: 6),
                Text('AI-Powered Analysis',
                    style: TextStyle(
                        color: Color(0xFF2E7D32),
                        fontWeight: FontWeight.w500,
                        fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Food Description
          const Text('What did you eat?',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _descCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'e.g. rajma chawal, dal makhani, oats',
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 16),

          // Quantity
          const Text('How much? (optional)',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 6),
          TextField(
            controller: _qtyCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. 1 katori, 2 rotis, 1 plate',
              filled: true,
              fillColor: const Color(0xFFF2F2F7),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),

          // Analyze Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isLoading || _descCtrl.text.isEmpty) ? null : _addFood,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : const Color(0xFF2E7D32),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text('Analyzing...', style: TextStyle(fontSize: 16)),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome),
                        SizedBox(width: 8),
                        Text('Analyze & Add',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroCell extends StatelessWidget {
  final String value, label;
  const _MacroCell({required this.value, required this.label});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      const SizedBox(height: 2),
      Text(label,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
    ],
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    height: 35, width: 1,
    color: Colors.white.withOpacity(0.4),
  );
}