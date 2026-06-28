// ============================================================
//  Nutrition Guide Screen – MaaCare
//  Smart Nutritional Guidance: Pregnancy → Early Childhood
// ============================================================

// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app_theme.dart';
import 'bmi_calculator_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// ─────────────────────────────────────────────
// Data Models
// ─────────────────────────────────────────────
class NutrientItem {
  final String name;
  final String emoji;
  final String description;
  final String sources;
  final String dailyNeed;
  final String deficiency;
  final String tip;
  final String imageUrl;

  const NutrientItem({
    required this.name,
    required this.emoji,
    required this.description,
    required this.sources,
    required this.dailyNeed,
    required this.deficiency,
    required this.tip,
    required this.imageUrl,
  });
}

class AgeStageSection {
  final String title;
  final String subtitle;
  final String emoji;
  final Color color;
  final String imageUrl;
  final List<Map<String, dynamic>> sections;

  const AgeStageSection({
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.color,
    required this.imageUrl,
    required this.sections,
  });
}

// ─────────────────────────────────────────────
// Pregnancy Nutrient Data (Detailed)
// ─────────────────────────────────────────────
const _pregnancyNutrients = [
  NutrientItem(
    name: 'Folic Acid',
    emoji: '🥦',
    description:
        'Folic acid (Vitamin B9) is critical in the first 12 weeks of pregnancy. It helps form the neural tube which becomes your baby\'s brain and spinal cord. A deficiency can lead to severe birth defects like spina bifida.',
    sources:
        'Spinach, kale, broccoli, lentils, chickpeas, fortified cereals, orange juice, prenatal vitamins.',
    dailyNeed: '600 mcg/day during pregnancy',
    deficiency:
        'Neural tube defects, anemia, fatigue, mouth sores.',
    tip:
        'Start taking folic acid supplements even before conception — ideally 1–3 months before trying to conceive.',
    imageUrl:
        'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=600&q=80',
  ),
  NutrientItem(
    name: 'Iron',
    emoji: '🥩',
    description:
        'Iron is needed to make hemoglobin — the protein in red blood cells that carries oxygen. During pregnancy, your blood volume increases by up to 50%, so you need significantly more iron to support both you and your growing baby.',
    sources:
        'Lean red meat, chicken, turkey, fish, lentils, kidney beans, tofu, fortified cereals, dark leafy greens.',
    dailyNeed: '27 mg/day during pregnancy (vs. 18 mg normally)',
    deficiency:
        'Iron-deficiency anemia, extreme fatigue, pale skin, increased infection risk, premature birth risk.',
    tip:
        'Eat iron-rich foods with Vitamin C (like lemon juice or tomatoes) to boost absorption. Avoid tea/coffee with meals as they block iron absorption.',
    imageUrl:
        'https://images.unsplash.com/photo-1607532941433-304659e8198a?w=600&q=80',
  ),
  NutrientItem(
    name: 'Calcium',
    emoji: '🥛',
    description:
        'Your baby needs calcium to build strong bones, teeth, a healthy heart, and nervous system. If you don\'t eat enough calcium, your body will draw it from your own bones — increasing your risk of osteoporosis later in life.',
    sources:
        'Milk, yogurt, cheese, paneer, broccoli, kale, bok choy, almonds, tofu, fortified orange juice, ragi (finger millet).',
    dailyNeed: '1,000 mg/day during pregnancy',
    deficiency:
        'Muscle cramps (especially at night), dental problems, bone density loss, leg pain.',
    tip:
        'Pair calcium with Vitamin D (sunlight, fortified milk) for optimal absorption. Ragi is an excellent Indian source with ~344 mg calcium per 100g.',
    imageUrl:
        'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=600&q=80',
  ),
  NutrientItem(
    name: 'Protein',
    emoji: '🥚',
    description:
        'Protein is the primary building block of every cell in your baby\'s body — organs, muscles, skin, and hair all depend on it. It also supports your expanding uterus, breasts, and the placenta.',
    sources:
        'Eggs, chicken, fish, lean beef, lentils (dal), chickpeas, paneer, tofu, nuts, seeds, full-fat yogurt.',
    dailyNeed: '70–100 g/day during pregnancy (25g more than usual)',
    deficiency:
        'Poor fetal growth, low birth weight, muscle weakness, weakened immune system.',
    tip:
        'A simple dal-rice combination provides a complete protein. Add a boiled egg or paneer to each meal to easily meet your daily needs.',
    imageUrl:
        'https://images.unsplash.com/photo-1506976785307-8732e854ad03?w=600&q=80',
  ),
  NutrientItem(
    name: 'DHA (Omega-3)',
    emoji: '🐟',
    description:
        'DHA (docosahexaenoic acid) is an essential omega-3 fatty acid that makes up 60% of the brain\'s fat content. It is critical for your baby\'s brain development, visual acuity, and nervous system formation — especially in the 3rd trimester when rapid brain growth occurs.',
    sources:
        'Salmon, sardines, mackerel (low-mercury fish), walnuts, flaxseed, chia seeds, hemp seeds, DHA-fortified eggs, algae-based supplements.',
    dailyNeed: '200–300 mg DHA/day during pregnancy',
    deficiency:
        'Poor cognitive development, vision problems, increased risk of postpartum depression.',
    tip:
        'Eat 2–3 servings of low-mercury fish per week. Vegetarians can take algae-based DHA supplements — the same source that fish get their DHA from!',
    imageUrl:
        'https://images.unsplash.com/photo-1519708227418-c8fd9a32b7a2?w=600&q=80',
  ),
];

const _hydrationHabits = [
  'Drink 8–10 glasses (2–2.5 liters) of water daily. Increase in hot weather or if exercising.',
  'Carry a reusable water bottle everywhere — it\'s easy to forget to drink when busy.',
  'Eat a wide variety of colorful fruits, vegetables, and whole grains every day.',
  'Avoid raw or undercooked meat, fish, and eggs due to risk of foodborne illness.',
  'Limit caffeine to less than 200 mg/day (about 1 small cup of coffee).',
  'Avoid alcohol completely — there is no known safe amount during pregnancy.',
  'Choose small, frequent meals if nausea is a problem (common in 1st trimester).',
  'Ginger tea or crackers can help with morning sickness naturally.',
];

// ─────────────────────────────────────────────
// Age Stage Data (Detailed)
// ─────────────────────────────────────────────
const _ageStages = [
  AgeStageSection(
    title: '0–6 Months',
    subtitle: 'Exclusive milk feeding',
    emoji: '🍼',
    color: Color(0xFF42A5F5),
    imageUrl:
        'https://images.unsplash.com/photo-1555252333-9f8e92e65df9?w=600&q=80',
    sections: [
      {
        'heading': '🤱 Breastfeeding',
        'color': Color(0xFF42A5F5),
        'points': [
          'The WHO recommends exclusive breastfeeding for the first 6 months — no water, juice, or other foods.',
          'Breast milk perfectly adapts to your baby\'s changing nutritional needs at every stage.',
          'It contains antibodies (IgA) that protect your baby from infections, allergies, and disease.',
          'Feed on demand, typically every 2–3 hours for newborns. Watch for hunger cues: rooting, sucking fists, turning head.',
          'Ensure a proper latch — your baby\'s mouth should cover the entire areola, not just the nipple.',
          'Colostrum (first milk) is liquid gold — thick, yellowish, and packed with immunity-building antibodies.',
        ],
      },
      {
        'heading': '🍶 Formula Feeding',
        'color': Color(0xFF7E57C2),
        'points': [
          'If breastfeeding is not possible, iron-fortified infant formula is a complete, healthy alternative.',
          'Follow mixing instructions exactly — too concentrated or too diluted can harm your baby.',
          'Hold your baby in a semi-upright position (45°) during feedings to reduce gas and prevent ear infections.',
          'Never prop a bottle — it is a choking hazard and may lead to dental problems and overfeeding.',
          'Sterilize all bottles and nipples until 6 months. After that, thorough washing with hot soapy water is enough.',
          'Formula-fed babies may need slightly less frequent feeds as formula digests more slowly.',
        ],
      },
    ],
  ),
  AgeStageSection(
    title: '6–12 Months',
    subtitle: 'Exciting world of solid foods',
    emoji: '🥣',
    color: Color(0xFF66BB6A),
    imageUrl:
        'https://images.unsplash.com/photo-1465433360938-e02f687f1db1?w=600&q=80',
    sections: [
      {
        'heading': '🥄 Signs of Readiness & Starting Solids',
        'color': Color(0xFF66BB6A),
        'points': [
          'Watch for readiness signs: sits up with minimal support, good head control, shows interest in food, lost tongue-thrust reflex.',
          'Start with single-ingredient smooth purees. Introduce one new food every 3–5 days and watch for allergic reactions.',
          'Best first foods: iron-fortified baby cereal, mashed avocado, pureed sweet potato, banana, pear, pumpkin.',
          'Aim for 2–3 small meals per day alongside breast milk or formula which remains the primary nutrition source.',
          'Do NOT add salt, sugar, honey (risk of botulism in babies under 1), or spices to baby food.',
          'Texture: Start smooth and thin, gradually thicken as your baby adjusts.',
        ],
      },
      {
        'heading': '🌈 Building a Varied Diet (8–12 months)',
        'color': Color(0xFFFF9800),
        'points': [
          'Gradually introduce pureed meats, poultry, fish (mashed), beans, full-fat yogurt, and egg yolk.',
          'Around 8–9 months, move to mashed and minced foods — soft lumps are fine and build chewing skills.',
          'Introduce soft finger foods at 9–10 months: cooked carrot sticks, banana pieces, soft pasta, toast strips.',
          'Offer water (small sips, ~120ml/day) from a sippy cup when starting solids.',
          'Common allergens (peanuts, eggs, fish) — introduce early (from 6 months) to reduce allergy risk, per new research.',
          'Gagging is normal; choking is not. Learn the difference and ensure safe food sizes.',
        ],
      },
    ],
  ),
  AgeStageSection(
    title: '1–3 Years',
    subtitle: 'Toddler nutrition & healthy habits',
    emoji: '🧒',
    color: Color(0xFFFF7043),
    imageUrl:
        'https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=600&q=80',
    sections: [
      {
        'heading': '🍽️ Balanced Meals & Portions',
        'color': Color(0xFFFF7043),
        'points': [
          'Offer 3 small meals + 2 healthy snacks per day. Toddler stomachs are about the size of their fist!',
          'A toddler-sized portion is roughly 1/4 of an adult portion — don\'t force more.',
          'Include all food groups at each meal: grain + protein + vegetable/fruit + dairy.',
          'Whole cow\'s milk (full fat) is recommended until age 2 — essential for brain development.',
          'After age 2, switch to low-fat or skimmed milk. Limit milk to 500ml/day to keep appetite for solid foods.',
          'Avoid giving juice as a drink — whole fruit is much healthier. If juice, max 120ml/day of 100% fruit juice.',
        ],
      },
      {
        'heading': '💚 Handling Picky Eating & Healthy Habits',
        'color': Color(0xFF26A69A),
        'points': [
          'Picky eating peaks between 18 months–3 years. It\'s a normal developmental phase — stay calm!',
          'Keep offering rejected foods — research shows it can take 10–15 exposures before a child accepts a new food.',
          'Never force feed. Respect your child\'s hunger and fullness signals from the start.',
          'Make mealtimes positive — eat together as a family, no phones, no TV.',
          'Involve toddlers in food prep (washing veggies, stirring) — they\'re more likely to eat what they helped make.',
          'Avoid using food as reward or punishment — it creates unhealthy emotional relationships with food.',
        ],
      },
    ],
  ),
  AgeStageSection(
    title: '3–5 Years',
    subtitle: 'Preschool energy & brain power',
    emoji: '🎒',
    color: Color(0xFFAB47BC),
    imageUrl:
        'https://images.unsplash.com/photo-1567620905732-2d1ec7ab7445?w=600&q=80',
    sections: [
      {
        'heading': '🥗 Key Nutrients for Growing Brains & Bodies',
        'color': Color(0xFFAB47BC),
        'points': [
          'Continue a varied diet with fruits, vegetables, whole grains, lean proteins, and dairy at every meal.',
          'Calcium (700–1000 mg/day): milk, yogurt, paneer, ragi. Critical for rapid bone growth in this phase.',
          'Vitamin D: daily outdoor play (15–20 min sunlight) + fortified milk or eggs. Essential for calcium absorption.',
          'Iron (10 mg/day): lentils, dark meat, fortified cereals. Iron deficiency can impair learning and attention.',
          'Fiber: whole grains, fruits, vegetables. Prevents constipation common in preschoolers.',
          'Omega-3 (DHA): walnuts, fatty fish, flaxseed. Continues to support brain development.',
        ],
      },
      {
        'heading': '🍎 Smart Snacking Strategy',
        'color': Color(0xFFEF5350),
        'points': [
          'Plan 2 nutritious snacks per day — mid-morning and mid-afternoon — to maintain steady energy.',
          'Great snack options: apple slices + peanut butter, yogurt + berries, cheese + whole-grain crackers, hummus + veggies.',
          'Avoid giving snacks within 1–1.5 hours of meals to preserve appetite.',
          'Avoid using sugary treats (chocolates, chips, biscuits) as rewards. Offer stickers, praise, or playtime instead.',
          'Preschoolers should drink 1.3–1.7 liters of fluids per day — mostly water.',
          'Limit screen time during snacks — mindless eating leads to overconsumption.',
        ],
      },
    ],
  ),
  AgeStageSection(
    title: '6–8 Years',
    subtitle: 'School-age concentration & growth',
    emoji: '📚',
    color: Color(0xFF26C6DA),
    imageUrl:
        'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600&q=80',
    sections: [
      {
        'heading': '⚡ Powering Through School Days',
        'color': Color(0xFF26C6DA),
        'points': [
          'NEVER skip breakfast — it is proven to improve concentration, memory, and academic performance.',
          'Ideal breakfasts: oatmeal with fruit, whole-wheat toast + eggs, idli + sambar, poha with vegetables.',
          'Pack a balanced school lunch: protein (egg/paneer/chicken) + whole grain (roti/rice) + vegetable + fruit.',
          'Send a water bottle — dehydration (even mild) impairs concentration and causes headaches.',
          'School-age children need 1,000 mg calcium/day (equivalent to 3 cups of milk).',
          'Iron needs increase at this age (8–10 mg/day) — key for energy and cognitive function.',
        ],
      },
      {
        'heading': '👨‍👩‍👧 Building Lifelong Food Relationships',
        'color': Color(0xFF42A5F5),
        'points': [
          'Eat together as a family at least once a day — studies show this leads to healthier diets in children.',
          'Teach them to listen to hunger and fullness cues — the foundation of intuitive eating.',
          'Talk about food in a neutral, positive way. Avoid labeling foods as "bad" or "junk".',
          'Take them grocery shopping and involve them in cooking age-appropriate tasks.',
          'Teach them where food comes from — farm visits, kitchen gardens, or simply cooking together.',
          'Limit ultra-processed foods, sugary drinks, and fast food. These are occasional treats, not daily staples.',
        ],
      },
    ],
  ),
];

// ─────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────
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
    _tabController = TabController(length: 3, vsync: this);
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
        title: Text(AppLocalizations.of(context).nutritionGuide),
        bottom: TabBar(
          controller: _tabController,
          labelColor: MaaColors.deepPink,
          unselectedLabelColor: MaaColors.textGrey,
          indicatorColor: MaaColors.deepPink,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: '🌿 Guidance'),
            Tab(text: '🍛 Recipes'),
            Tab(text: '🔢 Calorie Calc'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGuidance(),
          _buildRecipes(),
          _buildCalorieCalc(),
        ],
      ),
    );
  }

  // ──────────────────────────────────────
  // GUIDANCE TAB
  // ──────────────────────────────────────
  Widget _buildGuidance() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        // Hero Header
        Container(
          height: 160,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: MaaColors.primaryGradient,
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: CachedNetworkImage(
                  imageUrl:
                      'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&q=80',
                  width: double.infinity,
                  height: 160,
                  fit: BoxFit.cover,
                  color: Colors.black.withAlpha(120),
                  colorBlendMode: BlendMode.darken,
                  errorWidget: (_, __, ___) => Container(
                    color: MaaColors.deepPink.withAlpha(80),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('🌿 Smart Nutritional Guidance',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 6),
                    Text(
                      'Healthy eating from pregnancy through early childhood.\nEvery stage. Every nutrient. Covered.',
                      style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withAlpha(220),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Pregnancy Section ──
        const _StageChip(
          emoji: '🤰',
          title: 'Pregnancy Nutrition',
          subtitle: 'Key nutrients for you & your baby',
          color: Color(0xFFE91E8C),
        ),
        const SizedBox(height: 12),

        // Pregnancy nutrients
        ...List.generate(_pregnancyNutrients.length, (i) {
          final n = _pregnancyNutrients[i];
          return _NutrientCard(nutrient: n);
        }),

        // Hydration & Habits
        const SizedBox(height: 12),
        const _SectionCard(
          title: '💧 Hydration & Healthy Habits',
          color: Color(0xFF42A5F5),
          points: _hydrationHabits,
        ),

        const SizedBox(height: 24),

        // ── Age-wise Sections ──
        const _StageChip(
          emoji: '👶',
          title: 'Child Nutrition',
          subtitle: 'From birth through school age',
          color: Color(0xFF4CAF50),
        ),
        const SizedBox(height: 12),

        for (final stage in _ageStages) ...[
          _AgeStageCard(stage: stage),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 20),
      ],
    );
  }

  // ──────────────────────────────────────
  // RECIPES TAB
  // ──────────────────────────────────────
  Widget _buildRecipes() {
    final recipes = [
      {
        'name': 'Dal Palak (Iron-Rich)',
        'emoji': '🥬',
        'time': '25 min',
        'cal': '180 kcal',
        'tag': 'Iron',
        'desc':
            'Moong dal with spinach, turmeric, and cumin. Great for anemia prevention.',
        'ingredients': 'Moong dal, spinach, onion, garlic, cumin, turmeric',
        'imageUrl':
            'https://images.unsplash.com/photo-1547592166-23ac45744acd?w=400&q=80',
      },
      {
        'name': 'Ragi Porridge',
        'emoji': '🌾',
        'time': '10 min',
        'cal': '120 kcal',
        'tag': 'Calcium',
        'desc':
            'Finger millet porridge with jaggery and milk – excellent calcium source.',
        'ingredients': 'Ragi flour, milk, jaggery, cardamom',
        'imageUrl':
            'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400&q=80',
      },
      {
        'name': 'Masoor Dal Khichdi',
        'emoji': '🍚',
        'time': '30 min',
        'cal': '250 kcal',
        'tag': 'Protein',
        'desc':
            'Comforting one-pot meal rich in protein and easy on digestion.',
        'ingredients': 'Rice, masoor dal, ghee, cumin, bay leaf',
        'imageUrl':
            'https://images.unsplash.com/photo-1455619452474-d2be8b1e70cd?w=400&q=80',
      },
      {
        'name': 'Dahi Veggie Raita',
        'emoji': '🥛',
        'time': '5 min',
        'cal': '80 kcal',
        'tag': 'Probiotics',
        'desc':
            'Cooling curd with grated veggies. Great for digestion and gut health.',
        'ingredients': 'Curd, cucumber, carrot, cumin powder, salt',
        'imageUrl':
            'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=400&q=80',
      },
      {
        'name': 'Badam Milk (Almonds)',
        'emoji': '🥜',
        'time': '5 min',
        'cal': '150 kcal',
        'tag': 'Omega-3',
        'desc':
            'Nutrient-dense almond milk with saffron for brain development.',
        'ingredients': 'Almonds (soaked), milk, saffron, cardamom, honey',
        'imageUrl':
            'https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400&q=80',
      },
      {
        'name': 'Saag Paneer',
        'emoji': '🧀',
        'time': '35 min',
        'cal': '220 kcal',
        'tag': 'Calcium',
        'desc':
            'Spinach curry with cottage cheese – protein and calcium in one dish!',
        'ingredients': 'Paneer, spinach, cream, onion, garam masala',
        'imageUrl':
            'https://images.unsplash.com/photo-1567188040759-fb8a883dc6d8?w=400&q=80',
      },
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/nutrition_form'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  gradient: MaaColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: MaaColors.pink.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(AppLocalizations.of(context).personalAiNutritionPlan,
                      style: const TextStyle(
                          color: MaaColors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('For your entire family. Just 2 mins! 🔥',
                      style: TextStyle(color: MaaColors.white, fontSize: 14)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final r = recipes[i];
              return GestureDetector(
                onTap: () => _showRecipeDetail(r),
                child: Container(
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
                      // Food image thumbnail
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          bottomLeft: Radius.circular(20),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: r['imageUrl']!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            width: 80,
                            height: 80,
                            color: MaaColors.pink.withAlpha(30),
                            child: Center(
                              child: Text(r['emoji']!,
                                  style: const TextStyle(fontSize: 30)),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r['name']!,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text('⏱ ${r['time']!}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: MaaColors.textGrey)),
                                  const SizedBox(width: 12),
                                  Text('🔥 ${r['cal']!}',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: MaaColors.textGrey)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Container(
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
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecipeDetail(Map<String, String> recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: MaaColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // recipe image header
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  child: CachedNetworkImage(
                    imageUrl: recipe['imageUrl'] ?? '',
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      height: 180,
                      color: MaaColors.pink.withAlpha(40),
                      child: Center(
                        child: Text(recipe['emoji']!,
                            style: const TextStyle(fontSize: 80)),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(recipe['name']!,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _MiniTag('⏱ ${recipe['time']!}'),
                      const SizedBox(width: 8),
                      _MiniTag('🔥 ${recipe['cal']!}'),
                      const SizedBox(width: 8),
                      _MiniTag('💊 ${recipe['tag']!}'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(recipe['desc']!,
                      style: const TextStyle(
                          fontSize: 14,
                          color: MaaColors.textGrey,
                          height: 1.5)),
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
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────
  // CALORIE CALC TAB  →  BMI + Calorie
  // ──────────────────────────────────────
  Widget _buildCalorieCalc() {
    return const BmiCalorieCalculatorScreen();
  }
}

// ─────────────────────────────────────────────
// Helper Widgets
// ─────────────────────────────────────────────

class _MiniTag extends StatelessWidget {
  final String text;
  const _MiniTag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: MaaColors.deepPink.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              color: MaaColors.deepPink,
              fontWeight: FontWeight.w600)),
    );
  }
}

class _StageChip extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final Color color;

  const _StageChip({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color)),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 12, color: MaaColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _NutrientCard extends StatefulWidget {
  final NutrientItem nutrient;
  const _NutrientCard({required this.nutrient});

  @override
  State<_NutrientCard> createState() => _NutrientCardState();
}

class _NutrientCardState extends State<_NutrientCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accentColor = Color(0xFFE91E8C);
    final n = widget.nutrient;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: accentColor.withAlpha(20),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() => _expanded = !_expanded);
          _expanded ? _ctrl.forward() : _ctrl.reverse();
        },
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(n.emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.name,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700)),
                        Text(n.dailyNeed,
                            style: const TextStyle(
                                fontSize: 11,
                                color: accentColor,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: accentColor, size: 26),
                  ),
                ],
              ),
            ),

            // ── Expandable Detail ──
            SizeTransition(
              sizeFactor: _anim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Food image
                  ClipRRect(
                    child: CachedNetworkImage(
                      imageUrl: n.imageUrl,
                      width: double.infinity,
                      height: 150,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        height: 100,
                        color: accentColor.withAlpha(20),
                        child: Center(
                          child: Text(n.emoji,
                              style: const TextStyle(fontSize: 60)),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Description
                        Text(n.description,
                            style: const TextStyle(
                                fontSize: 13,
                                color: MaaColors.textGrey,
                                height: 1.5)),
                        const SizedBox(height: 14),

                        // Info chips row
                        _InfoRow(
                          icon: Icons.restaurant_rounded,
                          label: 'Food Sources',
                          value: n.sources,
                          color: const Color(0xFF4CAF50),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.warning_amber_rounded,
                          label: 'Deficiency Symptoms',
                          value: n.deficiency,
                          color: const Color(0xFFFF9800),
                        ),
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.lightbulb_rounded,
                          label: 'Pro Tip',
                          value: n.tip,
                          color: accentColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        color: MaaColors.textGrey,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color color;
  final List<String> points;

  const _SectionCard({
    required this.title,
    required this.color,
    required this.points,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color)),
          const SizedBox(height: 10),
          ...points.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 15, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(p,
                          style: const TextStyle(
                              fontSize: 12,
                              color: MaaColors.textGrey,
                              height: 1.4)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class _AgeStageCard extends StatefulWidget {
  final AgeStageSection stage;
  const _AgeStageCard({required this.stage});

  @override
  State<_AgeStageCard> createState() => _AgeStageCardState();
}

class _AgeStageCardState extends State<_AgeStageCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _expanded ? _ctrl.forward() : _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.stage;
    return Container(
      decoration: BoxDecoration(
        color: MaaColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: s.color.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // ── Header with image ──
          InkWell(
            onTap: _toggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            child: Row(
              children: [
                // Stage image
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: s.imageUrl,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 90,
                      color: s.color.withAlpha(40),
                      child: Center(
                        child: Text(s.emoji,
                            style: const TextStyle(fontSize: 36)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.title,
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: s.color)),
                      Text(s.subtitle,
                          style: const TextStyle(
                              fontSize: 12,
                              color: MaaColors.textGrey)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: s.color.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('${s.sections.length} topics',
                            style: TextStyle(
                                fontSize: 10,
                                color: s.color,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: s.color, size: 26),
                  ),
                ),
              ],
            ),
          ),

          // ── Expandable content ──
          SizeTransition(
            sizeFactor: _anim,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  Divider(color: s.color.withAlpha(40)),
                  const SizedBox(height: 8),
                  for (final sec in s.sections) ...[
                    _SectionCard(
                      title: sec['heading'] as String,
                      color: sec['color'] as Color,
                      points: List<String>.from(sec['points'] as List),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
