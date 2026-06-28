// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app_theme.dart';
import '../../providers/user_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../services/maacare_backend_service.dart';
import '../../utils/error_helper.dart';
import '../../widgets/premium_paywall_sheet.dart';
import 'nutrition_plan_result_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class UniversalNutritionFormScreen extends StatefulWidget {
  const UniversalNutritionFormScreen({super.key});

  @override
  State<UniversalNutritionFormScreen> createState() =>
      _UniversalNutritionFormScreenState();
}

class _UniversalNutritionFormScreenState
    extends State<UniversalNutritionFormScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 6;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<UserProvider>().user?.id ?? '';
      if (userId.isNotEmpty) {
        context.read<NutritionProvider>().loadCounts(userId);
      }
    });
  }

  // Form State
  String? _selectedProfileType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  // Step 3 & 5 State
  String? _selectedActivityLevel;
  double _waterIntakeGoal = 8.0;
  bool _useLocalIngredients = true;
  bool _generateShoppingList = true;
  bool _enableMealReminders = false;

  final List<Map<String, String>> _profileTypes = [
    {'title': 'Pregnant Mother', 'emoji': '🤰'},
    {'title': 'Lactating Mother', 'emoji': '🤱'},
    {'title': 'Postpartum Mother', 'emoji': '💆‍♀️'},
    {'title': 'Unmarried Girl', 'emoji': '👩‍🦱'},
    {'title': 'Baby (0-6 months)', 'emoji': '👶'},
    {'title': 'Child (1-3 years)', 'emoji': '🧒'},
    {'title': 'Teen (13-18 years)', 'emoji': '🧑'},
    {'title': 'Adult', 'emoji': '👩‍🦱'},
    {'title': 'Senior Citizen', 'emoji': '👵'},
  ];

  final List<Map<String, String>> _dietaryPrefs = [
    {'title': 'Pure Veg', 'emoji': '🥬'},
    {'title': 'Eggitarian', 'emoji': '🥚'},
    {'title': 'Non-Veg', 'emoji': '🍗'},
    {'title': 'Vegan', 'emoji': '🌱'},
  ];
  String? _selectedDiet;

  final List<Map<String, String>> _goals = [
    {'title': 'Immunity Boost', 'emoji': '🛡️'},
    {'title': 'Brain Development', 'emoji': '🧠'},
    {'title': 'Strong Bones', 'emoji': '🦴'},
    {'title': 'Weight Management', 'emoji': '⚖️'},
    {'title': 'Iron Rich', 'emoji': '🩸'},
    {'title': 'Cycle Regulation', 'emoji': '🌙'},
    {'title': 'Hormone Balance', 'emoji': '⚗️'},
    {'title': 'PMS Relief', 'emoji': '💚'},
    {'title': 'Skin & Hair Health', 'emoji': '✨'},
    {'title': 'Energy & Focus', 'emoji': '⚡'},
  ];
  final Set<String> _selectedGoals = {};

  void _nextStep() {
    if (_currentStep == 0 &&
        (_selectedProfileType == null || _nameController.text.trim().isEmpty)) {
      ErrorHelper.showError(
          context, "Please select a profile and enter your name.");
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _submitForm() async {
    final userProvider = context.read<UserProvider>();
    final nutritionProvider = context.read<NutritionProvider>();
    final isPremium = userProvider.user?.isPremium ?? false;
    final userId = userProvider.user?.id ?? '';

    final isMaternal = _selectedProfileType == 'Pregnant Mother' || 
                       _selectedProfileType == 'Lactating Mother' || 
                       _selectedProfileType == 'Postpartum Mother';

    if (!isPremium) {
      if (isMaternal) {
        if (nutritionProvider.freePregnancyGenerationCount >= 6) {
          PremiumPaywallSheet.show(context);
          return;
        }
      } else {
        if (nutritionProvider.freeCycleGenerationCount >= 6) {
          PremiumPaywallSheet.show(context);
          return;
        }
      }
    }

    setState(() => _isLoading = true);
    try {
      final payload = {
        'profileType': _selectedProfileType,
        'fullName': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'diet': _selectedDiet ?? 'Not specified',
        'goals': _selectedGoals.toList(),
        'activityLevel': _selectedActivityLevel ?? 'Sedentary (Little/No exercise)',
        'waterIntakeGoal': _waterIntakeGoal.toInt(),
        'useLocalIngredients': _useLocalIngredients,
        'generateShoppingList': _generateShoppingList,
        'enableMealReminders': _enableMealReminders,
      };

      final response =
          await MaaCareBackendService.instance.invokeNutritionPlan(payload);

      if (response == null || response['error'] != null) {
        throw Exception(response?['error'] ?? 'Unknown API error');
      }

      final data = response['data'];
      if (data != null && mounted) {
        if (!isPremium) {
          if (isMaternal) {
            await nutritionProvider.incrementPregnancyCount(userId);
          } else {
            await nutritionProvider.incrementCycleCount(userId);
          }
        }

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => NutritionPlanResultScreen(planData: data),
          ),
        );
      } else {
        throw Exception('Invalid AI response payload.');
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showError(
            context, 'Failed to generate plan: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MaaColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context).aiNutritionPlanner,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: _prevStep,
              )
            : const BackButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                children: List.generate(_totalSteps, (index) {
                  final isActive = index <= _currentStep;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.only(right: 6),
                      height: 6,
                      decoration: BoxDecoration(
                        color:
                            isActive ? MaaColors.deepPink : MaaColors.cardDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentStep = index),
                children: [
                  _buildStep1BasicInfo(),
                  _buildStep2Health(),
                  _buildStep3Lifestyle(),
                  _buildStep4Goals(),
                  _buildStep5Customisation(),
                  _buildStep6Consent(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              MaaColors.background.withValues(alpha: 0.0),
              MaaColors.background,
            ],
          ),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 18),
            backgroundColor: MaaColors.deepPink,
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: MaaColors.deepPink.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 3))
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _currentStep == _totalSteps - 1
                          ? 'Generate Magic Plan ✨'
                          : 'Continue',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (_currentStep < _totalSteps - 1) ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ]
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return _StepWrapper(
      title: 'Who is this for?',
      subtitle:
          'Tell us who we are generating this plan for so AI can perfectly tailor the nutrients.',
      content: [
        // Unmarried Girl highlight banner
        if (_selectedProfileType == null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  MaaColors.deepPink.withValues(alpha: 0.15),
                  Colors.purple.withValues(alpha: 0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: MaaColors.deepPink.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Text('👩‍🦱', style: TextStyle(fontSize: 22)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Select “Unmarried Girl” for a cycle-specific nutrition plan tailored to your hormonal needs.',
                    style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.2,
          ),
          itemCount: _profileTypes.length,
          itemBuilder: (context, index) {
            final type = _profileTypes[index];
            final isSelected = _selectedProfileType == type['title'];
            return GestureDetector(
              onTap: () => setState(() => _selectedProfileType = type['title']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MaaColors.deepPink.withValues(alpha: 0.15)
                      : MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? MaaColors.deepPink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Text(type['emoji']!, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        type['title']!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? MaaColors.deepPink
                              : MaaColors.textGrey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 32),
        _CustomTextField(
            controller: _nameController,
            label: 'Full Name *',
            icon: Icons.person_rounded),
        const SizedBox(height: 16),
        _CustomTextField(
            controller: _ageController,
            label: 'Age *',
            icon: Icons.cake_rounded,
            isNumber: true),
      ],
    );
  }

  Widget _buildStep2Health() {
    return _StepWrapper(
      title: 'Body & Diet',
      subtitle: 'Help AI calculate the perfect caloric and macro requirements.',
      content: [
        Row(
          children: [
            Expanded(
                child: _CustomTextField(
                    controller: _heightController,
                    label: 'Height (cm)',
                    icon: Icons.height_rounded,
                    isNumber: true)),
            const SizedBox(width: 16),
            Expanded(
                child: _CustomTextField(
                    controller: _weightController,
                    label: 'Weight (kg)',
                    icon: Icons.monitor_weight_rounded,
                    isNumber: true)),
          ],
        ),
        const SizedBox(height: 32),
        Text(AppLocalizations.of(context).dietaryPreference,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _dietaryPrefs.map((diet) {
            final isSelected = _selectedDiet == diet['title'];
            return GestureDetector(
              onTap: () => setState(() => _selectedDiet = diet['title']),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MaaColors.deepPink.withValues(alpha: 0.15)
                      : MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color:
                          isSelected ? MaaColors.deepPink : Colors.transparent,
                      width: 2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(diet['emoji']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(diet['title']!,
                        style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep3Lifestyle() {
    return _StepWrapper(
      title: 'Lifestyle',
      subtitle: 'Activity levels completely change nutritional needs.',
      content: [
        Text(AppLocalizations.of(context).dailyPhysicalActivity,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: MaaColors.cardDark,
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text('Select Activity Level'),
              isExpanded: true,
              dropdownColor: MaaColors.cardDark,
              value: _selectedActivityLevel,
              items: [
                'Sedentary (Little/No exercise)',
                'Light (1-3 days/week)',
                'Moderate (3-5 days/week)',
                'Active (6-7 days/week)'
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                setState(() => _selectedActivityLevel = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(AppLocalizations.of(context).waterIntakeGoal,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        Row(
          children: [
            const Icon(Icons.water_drop_rounded, color: Colors.blue),
            Expanded(
              child: Slider(
                value: _waterIntakeGoal,
                min: 1,
                max: 15,
                divisions: 14,
                label: '${_waterIntakeGoal.toInt()} glasses',
                activeColor: Colors.blue,
                onChanged: (val) {
                  setState(() => _waterIntakeGoal = val);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep4Goals() {
    return _StepWrapper(
      title: 'Primary Goals',
      subtitle: 'What exactly do you want to achieve with this nutrition plan?',
      content: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _goals.map((goal) {
            final isSelected = _selectedGoals.contains(goal['title']);
            return GestureDetector(
              onTap: () {
                setState(() {
                  isSelected
                      ? _selectedGoals.remove(goal['title'])
                      : _selectedGoals.add(goal['title']!);
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? MaaColors.deepPink : MaaColors.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: MaaColors.deepPink.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(goal['emoji']!, style: const TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(goal['title']!,
                        style: TextStyle(
                            color:
                                isSelected ? Colors.white : MaaColors.textGrey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep5Customisation() {
    return _StepWrapper(
      title: 'Magic Features',
      subtitle: 'Let MaaCare AI handle the heavy lifting.',
      content: [
        _FeatureToggle(
          title: 'Local Ingredients',
          subtitle:
              'Prioritize Assam/NE ingredients like bamboo shoot & local greens',
          icon: Icons.eco_rounded,
          value: _useLocalIngredients,
          onChanged: (v) {
            setState(() => _useLocalIngredients = v);
          },
        ),
        const SizedBox(height: 16),
        _FeatureToggle(
          title: 'Auto Shopping List',
          subtitle: 'Generate a ready-to-use grocery list for this plan',
          icon: Icons.shopping_basket_rounded,
          value: _generateShoppingList,
          onChanged: (v) {
            setState(() => _generateShoppingList = v);
          },
        ),
        const SizedBox(height: 16),
        _FeatureToggle(
          title: 'Meal Reminders',
          subtitle: 'Send push notifications when it\'s time to eat',
          icon: Icons.notifications_active_rounded,
          value: _enableMealReminders,
          onChanged: (v) {
            setState(() => _enableMealReminders = v);
          },
        ),
      ],
    );
  }

  Widget _buildStep6Consent() {
    return _StepWrapper(
      title: 'Almost Done! 🎉',
      subtitle: 'Review your preferences and generate your personalized plan.',
      content: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: MaaColors.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: MaaColors.deepPink.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white),
                  const SizedBox(width: 12),
                  Text(AppLocalizations.of(context).aiGenerationReady,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'MaaCare AI will now analyze your profile, calculate macro/micro nutrients, and generate a day-wise meal plan specifically for you.',
                style: TextStyle(color: Colors.white, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StepWrapper extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> content;

  const _StepWrapper(
      {required this.title, required this.subtitle, required this.content});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: MaaColors.white)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 15, color: MaaColors.textGrey, height: 1.4)),
        const SizedBox(height: 32),
        ...content,
      ],
    );
  }
}

class _CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isNumber;

  const _CustomTextField(
      {required this.controller,
      required this.label,
      required this.icon,
      this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style:
          const TextStyle(color: MaaColors.white, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: MaaColors.textGrey),
        prefixIcon: Icon(icon, color: MaaColors.deepPink),
        filled: true,
        fillColor: MaaColors.cardDark,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: MaaColors.deepPink, width: 2)),
      ),
    );
  }
}

class _FeatureToggle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool) onChanged;

  const _FeatureToggle(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MaaColors.cardDark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: MaaColors.deepPink.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(icon, color: MaaColors.deepPink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: MaaColors.textGrey)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: MaaColors.deepPink,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
