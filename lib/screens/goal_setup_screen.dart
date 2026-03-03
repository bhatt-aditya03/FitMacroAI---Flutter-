import 'package:flutter/material.dart';
import '../models/food_item.dart';
import 'food_log_screen.dart';

class GoalSetupScreen extends StatefulWidget {
  const GoalSetupScreen({super.key});

  @override
  State<GoalSetupScreen> createState() => _GoalSetupScreenState();
}

class _GoalSetupScreenState extends State<GoalSetupScreen> {
  final _currentWeightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();
  final _calorieGoalCtrl = TextEditingController(text: '2000');
  String _selectedGoal = 'Lose Weight';
  final _goals = ['Lose Weight', 'Gain Muscle', 'Stay Fit'];

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    _currentWeightCtrl.text = await UserPrefsManager.loadCurrentWeight();
    _targetWeightCtrl.text = await UserPrefsManager.loadTargetWeight();
    _selectedGoal = await UserPrefsManager.loadSelectedGoal();
    final goal = await UserPrefsManager.loadCalorieGoal();
    _calorieGoalCtrl.text = goal.toString();
    setState(() {});
  }

  Future<void> _onContinue() async {
    final goal = int.tryParse(_calorieGoalCtrl.text) ?? 2000;
    await UserPrefsManager.saveCalorieGoal(goal);
    await UserPrefsManager.saveUserProfile(
      currentWeight: _currentWeightCtrl.text,
      targetWeight: _targetWeightCtrl.text,
      selectedGoal: _selectedGoal,
    );
    await UserPrefsManager.setOnboardingComplete();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const FoodLogScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Goals'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const Text('Setup Your Goal',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Tell us about yourself',
                style: TextStyle(color: Colors.grey, fontSize: 15)),
            const SizedBox(height: 28),

            const Text('Your Stats',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),

            _buildLabel('Current Weight (kg)'),
            _buildTextField(_currentWeightCtrl, 'e.g. 70',
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            _buildLabel('Target Weight (kg)'),
            _buildTextField(_targetWeightCtrl, 'e.g. 65',
                keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            _buildLabel('Daily Calorie Goal'),
            _buildTextField(_calorieGoalCtrl, 'e.g. 2000',
                keyboardType: TextInputType.number),
            const SizedBox(height: 28),

            const Text('Your Goal',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            ..._goals.map((goal) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGoal = goal),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _selectedGoal == goal
                        ? const Color(0xFF2E7D32).withOpacity(0.1)
                        : const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                    border: _selectedGoal == goal
                        ? Border.all(color: const Color(0xFF2E7D32), width: 1.5)
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(goal, style: const TextStyle(fontSize: 16)),
                      const Spacer(),
                      if (_selectedGoal == goal)
                        const Icon(Icons.check_circle, color: Color(0xFF2E7D32)),
                    ],
                  ),
                ),
              ),
            )),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Continue',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 13)),
  );

  Widget _buildTextField(TextEditingController ctrl, String hint,
      {TextInputType? keyboardType}) =>
    TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF2F2F7),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
}