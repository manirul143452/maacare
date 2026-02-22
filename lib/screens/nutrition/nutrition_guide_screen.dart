// ============================================================
//  Nutrition Guide Screen – MaaCare
// ============================================================

import 'package:flutter/material.dart';
import '../../app_theme.dart';

class NutritionGuideScreen extends StatefulWidget {
  const NutritionGuideScreen({super.key});

  @override
  State<NutritionGuideScreen> createState() => _NutritionGuideScreenState();
}

class _NutritionGuideScreenState extends State<NutritionGuideScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Guide 🍱'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MaaColors.deepPink,
          unselectedLabelColor: MaaColors.textGrey,
          indicatorColor: MaaColors.deepPink,
          tabs: const [
            Tab(text: '🍛 Recipes'),
            Tab(text: '🔢 Calorie Calc'),
          ],
        ),
      ),
      body: PopScope(
        canPop: true,
        onPopInvoked: (didPop) {
          debugPrint('Mama, eat healthy and stay strong! 🍱');
        },
        child: TabBarView(
          controller: _tabController,
          children: [_buildRecipes(), _buildCalorieCalc()],
        ),
      ),
    );
  }

  Widget _buildRecipes() {
    final recipes = [
      {
        'name': 'Dal Palak (Iron-Rich)',
        'emoji': '🥬',
        'time': '25 min',
        'cal': '180 kcal',
        'tag': 'Iron',
        'desc': 'Moong dal with spinach, turmeric, and cumin. Great for anemia prevention.',
        'ingredients': 'Moong dal, spinach, onion, garlic, cumin, turmeric',
      },
      {
        'name': 'Ragi Porridge',
        'emoji': '🌾',
        'time': '10 min',
        'cal': '120 kcal',
        'tag': 'Calcium',
        'desc': 'Finger millet porridge with jaggery and milk – excellent calcium source.',
        'ingredients': 'Ragi flour, milk, jaggery, cardamom',
      },
      {
        'name': 'Masoor Dal Khichdi',
        'emoji': '🍚',
        'time': '30 min',
        'cal': '250 kcal',
        'tag': 'Protein',
        'desc': 'Comforting one-pot meal rich in protein and easy on digestion.',
        'ingredients': 'Rice, masoor dal, ghee, cumin, bay leaf',
      },
      {
        'name': 'Dahi Veggie Raita',
        'emoji': '🥛',
        'time': '5 min',
        'cal': '80 kcal',
        'tag': 'Probiotics',
        'desc': 'Cooling curd with grated veggies. Great for digestion and gut health.',
        'ingredients': 'Curd, cucumber, carrot, cumin powder, salt',
      },
      {
        'name': 'Badam Milk (Almonds)',
        'emoji': '🥜',
        'time': '5 min',
        'cal': '150 kcal',
        'tag': 'Omega-3',
        'desc': 'Nutrient-dense almond milk with saffron for brain development.',
        'ingredients': 'Almonds (soaked), milk, saffron, cardamom, honey',
      },
      {
        'name': 'Saag Paneer',
        'emoji': '🧀',
        'time': '35 min',
        'cal': '220 kcal',
        'tag': 'Calcium',
        'desc': 'Spinach curry with cottage cheese – protein and calcium in one dish!',
        'ingredients': 'Paneer, spinach, cream, onion, garam masala',
      },
    ];

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final r = recipes[i];
        return GestureDetector(
          onTap: () => _showRecipeDetail(r),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: MaaColors.cardShadow,
                    blurRadius: 12,
                    offset: const Offset(0, 3))
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: MaaColors.cardGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(r['emoji']!,
                        style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name']!,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text('⏱ ${r['time']!}',
                              style: const TextStyle(
                                  fontSize: 11, color: MaaColors.textGrey)),
                          const SizedBox(width: 12),
                          Text('🔥 ${r['cal']!}',
                              style: const TextStyle(
                                  fontSize: 11, color: MaaColors.textGrey)),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: MaaColors.deepPink.withAlpha(30),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(r['tag']!,
                      style: const TextStyle(
                          fontSize: 11,
                          color: MaaColors.deepPink,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRecipeDetail(Map<String, String> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: MaaColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(recipe['emoji']!,
                  style: const TextStyle(fontSize: 60)),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(recipe['name']!,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 16),
            Text(recipe['desc']!,
                style: const TextStyle(
                    fontSize: 14, color: MaaColors.textGrey, height: 1.5)),
            const SizedBox(height: 16),
            const Text('Ingredients:',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(recipe['ingredients']!,
                style: const TextStyle(
                    fontSize: 13, color: MaaColors.textGrey)),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieCalc() {
    final TextEditingController _weightController =
        TextEditingController(text: '60');
    double? result;

    return StatefulBuilder(builder: (_, setInner) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: MaaColors.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                '💡 During pregnancy, you need approximately 300-340 extra calories per day in the 2nd & 3rd trimester.',
                style: TextStyle(
                    fontSize: 13, color: MaaColors.textGrey, height: 1.5),
              ),
            ),
            const SizedBox(height: 20),
            Text('Your pre-pregnancy weight (kg):',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  hintText: 'e.g. 60',
                  suffixText: 'kg'),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final w = double.tryParse(_weightController.text);
                  if (w != null) {
                    setInner(() =>
                        result = (w * 25 + 340));
                  }
                },
                child: const Text('Calculate Daily Need'),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text('Daily Calorie Need',
                        style: TextStyle(
                            color: MaaColors.white, fontSize: 14)),
                    Text(
                      '${result!.toStringAsFixed(0)} kcal',
                      style: const TextStyle(
                          color: MaaColors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Including ~340 extra kcal for your baby 👶',
                      style: TextStyle(
                          color: MaaColors.white.withAlpha(200),
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
