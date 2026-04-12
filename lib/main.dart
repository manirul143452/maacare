// ============================================================
//  main.dart – MaaCare Entry Point
//  Premium dark theme with smooth transitions
// ============================================================

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/community_provider.dart';
import 'screens/onboarding/auth_screen.dart';

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
import 'screens/consult_expert/doctor_registration_screen.dart';
import 'screens/consult_expert/doctor_dashboard_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/self_care/self_care_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/vaccinations/vaccination_tracker_screen.dart';
import 'screens/nutrition/nutrition_guide_screen.dart';
import 'screens/nutrition/universal_nutrition_form_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/help_center/help_center_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        theme: MaaTheme.darkTheme,
        darkTheme: MaaTheme.darkTheme,
        themeMode: ThemeMode.dark,
        initialRoute: '/splash',
        home: const SplashScreen(),
        routes: {
          '/welcome': (_) => const WelcomeScreen(),
          '/auth': (_) => const AuthScreen(),
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
          '/doctor-registration': (_) => const DoctorRegistrationScreen(),
          '/doctor-dashboard': (_) => const DoctorDashboardScreen(),
          '/selfcare': (_) => const SelfCareScreen(),
          '/vaccinations': (_) => const VaccinationTrackerScreen(),
          '/nutrition': (_) => const NutritionGuideScreen(),
          '/nutrition_form': (_) => const UniversalNutritionFormScreen(),
        },
        onGenerateRoute: _generateRoute,
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    // Default fade transition for all routes
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        // Return the appropriate screen based on route name
        switch (settings.name) {
          case '/welcome':
            return const WelcomeScreen();
          case '/auth':
            return const AuthScreen();
          case '/splash':
            return const SplashScreen();
          case '/onboarding':
            return const OnboardingScreen();
          case '/home':
            return const HomeScreen();
          case '/chat':
            return const AiChatScreen();
          case '/tracker':
            return const PregnancyTrackerScreen();
          case '/profile':
            return const ProfileScreen();
          case '/community':
            return const ParentsParkScreen();
          case '/doctor-registration':
            return const DoctorRegistrationScreen();
          case '/doctor-dashboard':
            return const DoctorDashboardScreen();
          case '/consult':
            return const ConsultExpertScreen();
          case '/subscription':
            return const SubscriptionScreen();
          case '/symptoms':
            return const SymptomCheckerScreen();
          case '/family-planning':
            return const FamilyPlanningScreen();
          case '/self-care':
            return const SelfCareScreen();
          case '/nutrition_form':
            return const UniversalNutritionFormScreen();
          case '/privacy':
            return const PrivacyPolicyScreen();
          case '/terms':
            return const TermsConditionsScreen();
          default:
            return const AuthScreen();
        }
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Smooth fade transition with subtle slide
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }
}
