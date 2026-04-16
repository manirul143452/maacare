// ============================================================
//  main.dart – MaaCare Entry Point
//  Multilingual + Dynamic Theme (dark/light/pink)
// ============================================================

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding/welcome_screen.dart';
import 'app_theme.dart';
import 'constants.dart';
import 'providers/user_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/community_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'l10n/app_localizations.dart';
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
import 'screens/guide/child_care_guide_screen.dart';
import 'screens/guide/contraception_guide_screen.dart';
import 'screens/guide/family_planning_guide_screen.dart';
import 'screens/notifications/notification_center_screen.dart';
import 'screens/notifications/notification_settings_screen.dart';
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  debugPrint('MAACARE_DEBUG: main() started');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('MAACARE_DEBUG: WidgetsFlutterBinding initialized');

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('MAACARE_DEBUG: FlutterError: ${details.exception}');
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('MAACARE_DEBUG: PlatformDispatcher Error: $error');
    return true;
  };

  // Initialize Push Notification Service (OneSignal)
  debugPrint('MAACARE_DEBUG: Initializing PushNotificationService...');
  await PushNotificationService.instance.initialize();

  // Initialize Local Notification Service
  debugPrint('MAACARE_DEBUG: Initializing NotificationService...');
  await NotificationService.instance.initialize();

  runApp(const MaaCareApp());
  debugPrint('MAACARE_DEBUG: runApp called');
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
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, LocaleProvider>(
        builder: (context, themeProvider, localeProvider, _) {
          ThemeData activeTheme;
          ThemeMode flutterThemeMode;
          switch (themeProvider.themeMode) {
            case MaaThemeMode.light:
              activeTheme = MaaTheme.lightTheme;
              flutterThemeMode = ThemeMode.light;
              break;
            case MaaThemeMode.pink:
              activeTheme = MaaTheme.pinkTheme;
              flutterThemeMode = ThemeMode.dark;
              break;
            case MaaThemeMode.dark:
              activeTheme = MaaTheme.darkTheme;
              flutterThemeMode = ThemeMode.dark;
              break;
          }

          return MaterialApp(
            title: AppConstants.appName,
            debugShowCheckedModeBanner: false,
            // ── Theme ──
            theme: activeTheme,
            darkTheme: MaaTheme.darkTheme,
            themeMode: flutterThemeMode,
            // ── Localization ──
            locale: localeProvider.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            // ── Routes ──
            initialRoute: '/auth',
            onGenerateRoute: _generateRoute,
          );
        },
      ),
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    Widget getScreen() {
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
        case '/family':
          return const FamilyPlanningScreen();
        case '/self-care':
        case '/selfcare':
          return const SelfCareScreen();
        case '/nutrition_form':
          return const UniversalNutritionFormScreen();
        case '/vaccinations':
          return const VaccinationTrackerScreen();
        case '/nutrition':
          return const NutritionGuideScreen();
        case '/settings':
          return const SettingsScreen();
        case '/help':
          return const HelpCenterScreen();
        case '/privacy':
          return const PrivacyPolicyScreen();
        case '/terms':
          return const TermsConditionsScreen();
        case '/guide':
        case '/childcare':
          return const ChildCareGuideScreen();
        case '/contraception':
          return const ContraceptionGuideScreen();
        case '/planning':
        case '/familyplanning-guide':
          return const FamilyPlanningGuideScreen();
        case '/notifications':
          return const NotificationCenterScreen();
        case '/notification-settings':
          return const NotificationSettingsScreen();
        default:
          return const AuthScreen(); // Default to auth screen
      }
    }

    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => getScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
