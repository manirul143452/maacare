import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../widgets/maa_button.dart';
import '../../services/maacare_backend_service.dart';
import '../../services/auth_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final ConfettiController _confetti = ConfettiController(
    duration: const Duration(seconds: 3),
  );

  // Form data
  String _selectedRole = 'mother'; // 'mother', 'unmarried_girl', 'doctor'
  final _nameController = TextEditingController();
  final _babyNameController = TextEditingController(); // Curiosity hook
  DateTime? _dueDate;
  String? _lonelinessAnswer;

  // Doctor credentials
  final _regNoController = TextEditingController();
  final _specializationController = TextEditingController();
  final _hospitalController = TextEditingController();

  int _currentPage = 0;
  bool _isSubmitting = false;

  int get _totalPages {
    if (_selectedRole == 'unmarried_girl') return 2;
    if (_selectedRole == 'doctor') return 3;
    return 5; // mother
  }

  @override
  void dispose() {
    _pageController.dispose();
    _confetti.dispose();
    _nameController.dispose();
    _babyNameController.dispose();
    _regNoController.dispose();
    _specializationController.dispose();
    _hospitalController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validation based on the current page for each role
    if (_currentPage == 1 && _nameController.text.trim().isEmpty) {
      _showSnack('Please tell us your name 🌸');
      return;
    }

    if (_selectedRole == 'mother') {
      if (_currentPage == 3 && _dueDate == null) {
        _showSnack('Please pick your due date 💕');
        return;
      }
    } else if (_selectedRole == 'doctor') {
      if (_currentPage == 2) {
        if (_regNoController.text.trim().isEmpty) {
          _showSnack('Please enter your Medical Registration Number 🌸');
          return;
        }
        if (_specializationController.text.trim().isEmpty) {
          _showSnack('Please enter your Specialization 🌸');
          return;
        }
        if (_hospitalController.text.trim().isEmpty) {
          _showSnack('Please enter your Hospital Affiliation 🌸');
          return;
        }
      }
    }

    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutBack,
      );
    } else {
      _complete();
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 280)),
      helpText: 'When is your baby due? 👶',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
                primary: MaaColors.deepPink,
              ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _complete() async {
    if (_selectedRole == 'mother' && _lonelinessAnswer == null) {
      _showSnack('Please share how you feel 💕');
      return;
    }
    setState(() => _isSubmitting = true);

    try {
      final String? userId = AuthService.instance.getCurrentUserId();

      if (userId == null) {
        final tokenStatus = MaaCareBackendService.instance.isLoggedIn
            ? '(Token Length: ${MaaCareBackendService.instance.debugTokenLength()})'
            : 'Token is NULL';
        throw Exception('User not authenticated! $tokenStatus');
      }

      final user = UserModel(
        id: userId,
        name: _nameController.text.trim(),
        dueDate: _selectedRole == 'mother' ? _dueDate : null,
        userRole: _selectedRole,
        createdAt: DateTime.now(),
      );

      if (!mounted) return;
      await context.read<UserProvider>().createOrUpdateUser(user);

      // Initialize based on selected role
      if (_selectedRole == 'doctor') {
        await MaaCareBackendService.instance.upsertDoctorProfile(
          userId: userId,
          medicalRegistrationNo: _regNoController.text.trim(),
          specialization: _specializationController.text.trim(),
          hospitalAffiliation: _hospitalController.text.trim(),
        );
      } else {
        // Initialize empty symptoms checks for mothers and unmarried girls
        await MaaCareBackendService.instance.saveSymptomCheck(
          userId: userId,
          symptoms: [],
          riskLevel: 'low',
        );
      }

      _confetti.play();
      await Future.delayed(const Duration(milliseconds: 2000));

      if (!mounted) return;
      if (_selectedRole == 'doctor') {
        Navigator.pushReplacementNamed(context, '/doctor-dashboard');
      } else if (_selectedRole == 'unmarried_girl') {
        Navigator.pushReplacementNamed(context, '/gynecare');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      debugPrint('ONBOARDING EXCEPTION: $e');
      if (mounted) _showSnack('Error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: MaaColors.pink.withAlpha(30),
                shape: BoxShape.circle,
              ),
            ),
          )
              .animate()
              .scale(duration: 2.seconds, curve: Curves.easeInOut)
              .fadeIn(),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confetti,
              blastDirectionality: BlastDirectionality.explosive,
              colors: const [
                MaaColors.pink,
                MaaColors.peach,
                MaaColors.gold,
                MaaColors.deepPink,
              ],
              numberOfParticles: 40,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),
                // Progress dots
                SmoothPageIndicator(
                  controller: _pageController,
                  count: _totalPages,
                  effect: ExpandingDotsEffect(
                    activeDotColor: MaaColors.deepPink,
                    dotColor: MaaColors.pink.withAlpha(100),
                    dotHeight: 8,
                    dotWidth: 8,
                    expansionFactor: 4,
                  ),
                ).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 8),
                Text(
                  'Step ${_currentPage + 1} of $_totalPages',
                  style: Theme.of(context).textTheme.bodyMedium,
                ).animate().fadeIn(delay: 300.ms),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _RoleSelectionStep(
                        selectedRole: _selectedRole,
                        onSelect: (role) {
                          setState(() {
                            _selectedRole = role;
                          });
                        },
                      ),
                      _NameStep(controller: _nameController),
                      if (_selectedRole == 'mother') ...[
                        _BabyNameHeroStep(controller: _babyNameController),
                        _DueDateStep(
                          dueDate: _dueDate,
                          onPick: _pickDueDate,
                        ),
                        _LonelinessStep(
                          selected: _lonelinessAnswer,
                          onSelect: (v) => setState(() => _lonelinessAnswer = v),
                        ),
                      ] else if (_selectedRole == 'doctor') ...[
                        _DoctorDetailsStep(
                          regNoController: _regNoController,
                          specializationController: _specializationController,
                          hospitalController: _hospitalController,
                        ),
                      ],
                    ],
                  ),
                ),

                // Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: MaaButton(
                    label: _currentPage == _totalPages - 1 ? 'Let\'s Begin 🌸' : 'Next 💕',
                    isLoading: _isSubmitting,
                    onPressed: _nextPage,
                  ).animate(target: _currentPage == _totalPages - 1 ? 1 : 0).scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      curve: Curves.elasticOut),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────── Step 0: Role Selection ───────
class _RoleSelectionStep extends StatelessWidget {
  final String selectedRole;
  final ValueChanged<String> onSelect;

  const _RoleSelectionStep({
    required this.selectedRole,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.png',
                width: 76,
                height: 76,
                fit: BoxFit.contain,
              ),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shake(hz: 2, duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            'Who are you? 💕',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text(
            'Please select your role to set up your sacred space',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MaaColors.textGrey,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          _buildRoleRowCard(
            context: context,
            role: 'mother',
            title: 'Pregnant Mother',
            subtitle: 'Track pregnancy week by week & baby growth 👶',
            icon: Icons.pregnant_woman_rounded,
          ),
          const SizedBox(height: 12),
          _buildRoleRowCard(
            context: context,
            role: 'unmarried_girl',
            title: 'GyneCare & Period Support',
            subtitle: 'Menstrual health, comfort advice & cramps help 🌸',
            icon: Icons.spa_rounded,
          ),
          const SizedBox(height: 12),
          _buildRoleRowCard(
            context: context,
            role: 'doctor',
            title: 'Doctor / Specialist',
            subtitle: 'Consult patients & provide expert pregnancy care 👩‍⚕️',
            icon: Icons.local_hospital_rounded,
          ),
        ],
      ),
    );
  }

  Widget _buildRoleRowCard({
    required BuildContext context,
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = selectedRole == role;
    return GestureDetector(
      onTap: () => onSelect(role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? MaaColors.pink.withAlpha(30)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? MaaColors.deepPink : MaaColors.pink.withAlpha(80),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MaaColors.deepPink.withAlpha(30),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? MaaColors.deepPink.withAlpha(25)
                    : MaaColors.pink.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? MaaColors.deepPink : MaaColors.textDark,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? MaaColors.deepPink : MaaColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? MaaColors.deepPink.withAlpha(204)
                          : MaaColors.textGrey,
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

// ─────── Step 1: Name ───────
class _NameStep extends StatelessWidget {
  final TextEditingController controller;
  const _NameStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌸', style: TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat())
              .shake(hz: 2, duration: 2.seconds),
          const SizedBox(height: 24),
          Text(
            'Welcome!',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text(
            'We\'re so happy you\'re here. What should we call you?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MaaColors.textGrey,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Your name or nickname 💕',
              prefixIcon:
                  Icon(Icons.person_outline_rounded, color: MaaColors.deepPink),
            ),
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
        ],
      ),
    );
  }
}

// ─────── Step 2: Baby Name Hero (Curiosity Hook) ───────
class _BabyNameHeroStep extends StatelessWidget {
  final TextEditingController controller;
  const _BabyNameHeroStep({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👶', style: TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat())
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                  duration: 1.seconds,
                  curve: Curves.easeInOut),
          const SizedBox(height: 24),
          Text(
            'Thinking of names?',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text(
            'Is there a cute name you have in mind for your little one? ✨',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MaaColors.textGrey,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Maybe some cute ideas? 🌸',
              prefixIcon:
                  Icon(Icons.favorite_outline_rounded, color: MaaColors.pink),
            ),
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(fontSize: 16),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
        ],
      ),
    );
  }
}

// ─────── Step 3: Due Date ───────
class _DueDateStep extends StatelessWidget {
  final DateTime? dueDate;
  final VoidCallback onPick;
  const _DueDateStep({this.dueDate, required this.onPick});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🗓️', style: TextStyle(fontSize: 80)).animate().rotate(
              begin: -0.1,
              end: 0.1,
              duration: 1.seconds,
              curve: Curves.easeInOut),
          const SizedBox(height: 24),
          Text(
            'When is baby arriving?',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text(
            'Personalizing your journey week by week! 🌸',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MaaColors.textGrey,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: onPick,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: MaaColors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dueDate != null
                      ? MaaColors.deepPink
                      : MaaColors.pink.withAlpha(100),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month_rounded,
                      color: MaaColors.deepPink),
                  const SizedBox(width: 12),
                  Text(
                    dueDate != null
                        ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                        : 'Tap to pick your due date',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          dueDate != null ? FontWeight.w600 : FontWeight.w400,
                      color: dueDate != null
                          ? MaaColors.textDark
                          : MaaColors.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
          if (dueDate != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: MaaColors.cardGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '🍼 That\'s in about '
                '${dueDate!.difference(DateTime.now()).inDays} days!\n'
                'You\'re doing amazing! 💕',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: MaaColors.textDark),
              ),
            ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          ],
        ],
      ),
    );
  }
}

// ─────── Step 4: Loneliness ───────
class _LonelinessStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onSelect;
  const _LonelinessStep({this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'emoji': '😊', 'text': 'No, I have great support!'},
      {'emoji': '🤷', 'text': 'Sometimes I do'},
      {'emoji': '😔', 'text': 'Yes, I feel alone often'},
    ];

    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💜', style: TextStyle(fontSize: 80))
              .animate(onPlay: (c) => c.repeat())
              .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(0.9, 0.9),
                  duration: 1.seconds,
                  curve: Curves.easeInOut),
          const SizedBox(height: 24),
          Text(
            'How are you feeling?',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn().scale(curve: Curves.easeOutBack),
          const SizedBox(height: 12),
          Text(
            'MaaCare is here to walk every step with you 💕',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: MaaColors.textGrey,
                ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 32),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final isSelected = selected == opt['text'];
            return GestureDetector(
              onTap: () => onSelect(opt['text']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MaaColors.pink.withAlpha(50)
                      : MaaColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? MaaColors.deepPink
                        : MaaColors.pink.withAlpha(80),
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: MaaColors.deepPink.withAlpha(40),
                              blurRadius: 10,
                              spreadRadius: 2)
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Text(opt['emoji']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 16),
                    Text(
                      opt['text']!,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w400,
                        color: isSelected
                            ? MaaColors.deepPink
                            : MaaColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            )
                .animate()
                .fadeIn(delay: (400 + idx * 100).ms)
                .moveX(begin: -20, end: 0);
          }),
        ],
      ),
    );
  }
}

// ─────── Step 3: Doctor Details ───────
class _DoctorDetailsStep extends StatelessWidget {
  final TextEditingController regNoController;
  final TextEditingController specializationController;
  final TextEditingController hospitalController;

  const _DoctorDetailsStep({
    required this.regNoController,
    required this.specializationController,
    required this.hospitalController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('👩‍⚕️', style: TextStyle(fontSize: 80))
                .animate(onPlay: (c) => c.repeat())
                .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.1, 1.1),
                    duration: 1.2.seconds,
                    curve: Curves.easeInOut),
            const SizedBox(height: 24),
            Text(
              'Doctor Details',
              style: Theme.of(context).textTheme.displayMedium,
              textAlign: TextAlign.center,
            ).animate().fadeIn().scale(curve: Curves.easeOutBack),
            const SizedBox(height: 8),
            Text(
              'We verify all registration numbers for maternal safety',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: MaaColors.textGrey,
                  ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            TextField(
              controller: regNoController,
              decoration: const InputDecoration(
                hintText: 'Medical Registration Number 🌸',
                prefixIcon: Icon(Icons.assignment_ind_outlined, color: MaaColors.deepPink),
              ),
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(fontSize: 15),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 15, end: 0),
            const SizedBox(height: 16),
            TextField(
              controller: specializationController,
              decoration: const InputDecoration(
                hintText: 'Specialization (e.g. Gynecologist) 💕',
                prefixIcon: Icon(Icons.star_outline_rounded, color: MaaColors.deepPink),
              ),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 15),
            ).animate().fadeIn(delay: 400.ms).moveY(begin: 15, end: 0),
            const SizedBox(height: 16),
            TextField(
              controller: hospitalController,
              decoration: const InputDecoration(
                hintText: 'Hospital / Clinic Affiliation 🏥',
                prefixIcon: Icon(Icons.business_outlined, color: MaaColors.deepPink),
              ),
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(fontSize: 15),
            ).animate().fadeIn(delay: 500.ms).moveY(begin: 15, end: 0),
          ],
        ),
      ),
    );
  }
}
