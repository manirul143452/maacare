// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_theme.dart';

class NutritionPlanResultScreen extends StatelessWidget {
  final Map<String, dynamic> planData;

  const NutritionPlanResultScreen({super.key, required this.planData});

  @override
  Widget build(BuildContext context) {
    final summary = planData['profile_summary'] ?? 'Nutrition Plan Generated';
    final needs = planData['calculated_needs'] ?? {};
    final dailyPlan = planData['daily_plan'] ?? {};
    final shoppingList = planData['shopping_list'] as List<dynamic>? ?? [];
    final tips = planData['tips'] ?? '';

    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        title: const Text('Your Personalized Plan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: MaaColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Plan Summary', style: TextStyle(color: MaaColors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(
                    summary.toString(),
                    style: const TextStyle(color: MaaColors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Macros
            if (needs.isNotEmpty) ...[
              const Text('Daily Calculated Needs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildMacroTile('Calories', '\${needs["calories"]}', '🔥'),
                  const SizedBox(width: 12),
                  _buildMacroTile('Protein', '\${needs["protein"]}', '🥩'),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // Daily Plan
            const Text('Daily Schedule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildMealCard('Morning Wake Up', dailyPlan['morning_wake_up'], '🌅'),
            _buildMealCard('Breakfast', dailyPlan['breakfast'], '🍳'),
            _buildMealCard('Mid-Morning', dailyPlan['mid_morning'], '🍏'),
            _buildMealCard('Lunch', dailyPlan['lunch'], '🍛'),
            _buildMealCard('Evening Snack', dailyPlan['evening_snack'], '☕'),
            _buildMealCard('Dinner', dailyPlan['dinner'], '🥗'),
            _buildMealCard('Bedtime', dailyPlan['bedtime'], '🌙'),

            const SizedBox(height: 24),

            // Shopping List
            if (shoppingList.isNotEmpty) ...[
              const Text('Shopping List', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaaColors.glassBorder),
                ),
                child: Column(
                  children: shoppingList.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: MaaColors.deepPink, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text(item.toString())),
                      ],
                    ),
                  )).toList(),
                ),
              ),
              const SizedBox(height: 24),
            ],

            if (tips.toString().isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: MaaColors.pink.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💡', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(tips.toString(), style: const TextStyle(fontWeight: FontWeight.w500))),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to Home'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMacroTile(String label, String value, String icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 30)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(String mealName, dynamic content, String icon) {
    if (content == null || content.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mealName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(content.toString(), style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
