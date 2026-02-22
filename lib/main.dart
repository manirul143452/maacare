// ============================================================
//  main.dart – MaaCare Entry Point
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/insforge_service.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/community_provider.dart';
import 'services/notification_service.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_conditions_screen.dart';
import 'screens/family_planning/family_planning_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/ai_companion/ai_chat_screen.dart';
import 'screens/pregnancy_tracker/pregnancy_tracker_screen.dart';
import 'screens/community/parents_park_screen.dart';
import 'screens/symptom_checker/symptom_checker_screen.dart';
import 'screens/consult_expert/consult_expert_screen.dart';
import 'screens/self_care/self_care_screen.dart';
import 'screens/vaccinations/vaccination_tracker_screen.dart';
import 'screens/nutrition/nutrition_guide_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/help_center/help_center_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load InsForge session
  await InsForgeService.instance.loadSession();

  // Initialize notifications
  await NotificationService.instance.initialize();

  runApp(const MaaCareApp());
}

class MaaCareApp extends StatelessWidget {
  const MaaCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: MaaTheme.lightTheme,
        initialRoute: '/splash',
        routes: {
          '/splash': (_) => const SplashScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/privacy': (_) => const PrivacyPolicyScreen(),
          '/terms': (_) => const TermsConditionsScreen(),
          '/family': (_) => const FamilyPlanningScreen(),
          '/home': (_) => const HomeScreen(),
          '/chat': (_) => const AiChatScreen(),
          '/tracker': (_) => const PregnancyTrackerScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/settings': (_) => const SettingsScreen(),
          '/subscription': (_) => const SubscriptionScreen(),
          '/help': (_) => const HelpCenterScreen(),
          '/community': (_) => const ParentsParkScreen(),
          '/symptoms': (_) => const SymptomCheckerScreen(),
          '/consult': (_) => const ConsultExpertScreen(),
          '/selfcare': (_) => const SelfCareScreen(),
          '/vaccinations': (_) => const VaccinationTrackerScreen(),
          '/nutrition': (_) => const NutritionGuideScreen(),
          '/family': (_) => const FamilyPlanningScreen(),
          '/profile': (_) => const ProfileScreen(),
        },
      ),
    );
  }
}
