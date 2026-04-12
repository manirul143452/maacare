// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import '../../app_theme.dart';
import '../../services/insforge_service.dart';
import '../../utils/error_helper.dart';
import 'nutrition_plan_result_screen.dart';

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

  // Form State
  String? _selectedProfileType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  final List<String> _profileTypes = [
    'Pregnant Mother',
    'Lactating Mother',
    'Postpartum Mother',
    'Baby (0-6 months)',
    'Child (1-3 years)',
    'Teen (13-18 years)',
    'Adult',
    'Senior Citizen (60+)'
  ];

  final List<String> _dietaryPrefs = [
    'Pure Veg',
    'Eggitarian',
    'Non-Veg',
    'Jain',
    'Vegan'
  ];
  String? _selectedDiet;

  final List<String> _goals = [
    'Immunity Boost',
    'Brain Development',
    'Strong Bones',
    'Weight Management',
    'Iron Rich',
  ];
  final Set<String> _selectedGoals = {};

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Final Submit
      _submitForm();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitForm() async {
    if (_selectedProfileType == null || _nameController.text.trim().isEmpty) {
      ErrorHelper.showError(context, "Please complete Step 1 (Profile & Name).");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final payload = {
        'profileType': _selectedProfileType,
        'fullName': _nameController.text.trim(),
        'age': _ageController.text.trim(),
        'height': _heightController.text.trim(),
        'weight': _weightController.text.trim(),
        'diet': _selectedDiet,
        'goals': _selectedGoals.toList(),
      };

      final response = await InsForgeService.instance.invokeNutritionPlan(payload);

      if (response == null || response['error'] != null) {
        throw Exception(response?['error'] ?? 'Unknown API error');
      }

      final data = response['data'];
      if (data != null) {
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
        ErrorHelper.showError(context, 'Failed to generate plan: \${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MaaCare Nutrition Form'),
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _prevStep,
              )
            : null,
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: MaaColors.cardDark,
            color: MaaColors.deepPink,
            minHeight: 8,
          ),
          const SizedBox(height: 16),
          Text(
            'Step ${_currentStep + 1} of $_totalSteps',
            style: const TextStyle(
                color: MaaColors.deepPink, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
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
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: MaaColors.cardDark,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _nextStep,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: MaaColors.deepPink,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isLoading 
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(
            _currentStep == _totalSteps - 1
                ? '🔥 Generate Plan Now'
                : 'Next Step',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  Widget _buildStep1BasicInfo() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Who is this plan for?',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _profileTypes.map((type) {
            final isSelected = _selectedProfileType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              selectedColor: MaaColors.deepPink.withOpacity(0.2),
              onSelected: (selected) {
                setState(() {
                  _selectedProfileType = type;
                });
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Full Name *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ageController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Age *',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Health() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Health & Body Assessment',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Height (cm)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Weight (kg)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text('Dietary Preference',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: _dietaryPrefs.map((diet) {
            return ChoiceChip(
              label: Text(diet),
              selected: _selectedDiet == diet,
              selectedColor: MaaColors.deepPink.withOpacity(0.2),
              onSelected: (selected) => setState(() => _selectedDiet = diet),
            );
          }).toList(),
        ),
        // Dynamic Field Example
        if (_selectedProfileType == 'Pregnant Mother') ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: MaaColors.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: MaaColors.pink.withOpacity(0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pregnancy Details',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Current Trimester / Week',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3Lifestyle() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Lifestyle & Habits',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Daily Physical Activity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        DropdownButtonFormField<String>(
          items: ['Sedentary', 'Light', 'Moderate', 'Active', 'Athlete']
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (val) {},
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 20),
        const Text('Water Intake (Glasses)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Slider(
          value: 8,
          min: 1,
          max: 15,
          divisions: 14,
          label: '8 glasses',
          activeColor: MaaColors.deepPink,
          onChanged: (val) {},
        ),
      ],
    );
  }

  Widget _buildStep4Goals() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Special Nutrition Goals',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const Text('Select what you want to achieve',
            style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _goals.map((goal) {
            final isSelected = _selectedGoals.contains(goal);
            return FilterChip(
              label: Text(goal),
              selected: isSelected,
              selectedColor: MaaColors.deepPink.withOpacity(0.3),
              checkmarkColor: MaaColors.deepPink,
              onSelected: (selected) {
                setState(() {
                  selected
                      ? _selectedGoals.add(goal)
                      : _selectedGoals.remove(goal);
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStep5Customisation() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Plan Customisation',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Local Assamese/North-East Ingredients'),
          subtitle: const Text('Include bamboo shoot, local fish, etc.'),
          value: true,
          activeColor: MaaColors.deepPink,
          onChanged: (val) {},
        ),
        SwitchListTile(
          title: const Text('Auto Shopping List'),
          value: true,
          activeColor: MaaColors.deepPink,
          onChanged: (val) {},
        ),
        SwitchListTile(
          title: const Text('Meal Reminders'),
          value: false,
          activeColor: MaaColors.deepPink,
          onChanged: (val) {},
        ),
      ],
    );
  }

  Widget _buildStep6Consent() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Family & Sharing',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: MaaColors.cardDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: MaaColors.glassBorder),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                title: const Text('Make plan visible to family members'),
                value: true,
                onChanged: (val) {},
              ),
              CheckboxListTile(
                title: const Text('Share PDF with Doctor/Nutritionist'),
                value: false,
                onChanged: (val) {},
              ),
              const Divider(),
              CheckboxListTile(
                title: const Text(
                  'I agree data will be used to generate my personalized AI plan',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: true,
                checkColor: Colors.white,
                activeColor: MaaColors.deepPink,
                onChanged: (val) {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}
