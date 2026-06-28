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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'providers/theme_provider.dart';
import 'screens/onboarding/auth_screen.dart';
import 'screens/onboarding/role_selection_screen.dart';
import 'screens/onboarding/permission_gate_screen.dart';
import 'screens/auth/doctor_onboarding.dart';
import 'screens/auth/menstrual_cycle_config_screen.dart';
import 'screens/auth/maternal_timeline_config_screen.dart';
import 'screens/consult_expert/join_consultation_screen.dart';
import 'models/booking_model.dart';

// Screens
import 'screens/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_conditions_screen.dart';
import 'screens/family_planning/family_planning_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/period_dashboard_screen.dart';
import 'screens/ai_companion/ai_chat_screen.dart';
import 'screens/pregnancy_tracker/pregnancy_tracker_screen.dart';
import 'screens/community/parents_park_screen.dart';
import 'screens/symptom_checker/symptom_checker_screen.dart';
import 'screens/symptom_checker/gyne_care_screen.dart';
import 'screens/consult_expert/consult_expert_screen.dart';
import 'screens/consult_expert/doctor_registration_screen.dart';
import 'screens/consult_expert/doctor_dashboard_screen.dart';
import 'screens/subscription/subscription_screen.dart';
import 'screens/self_care/self_care_screen.dart';
import 'screens/self_care/contraception_tracker_screen.dart';
import 'screens/self_care/cycle_nutrition_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/vaccinations/vaccination_tracker_screen.dart';
import 'screens/nutrition/nutrition_guide_screen.dart';
import 'screens/nutrition/universal_nutrition_form_screen.dart';
import 'screens/nutrition/menstrual_selection_flow.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/help_center/help_center_screen.dart';
import 'screens/guide/child_care_guide_screen.dart';
import 'screens/guide/contraception_guide_screen.dart';
import 'screens/guide/family_planning_guide_screen.dart';
import 'screens/notifications/notification_center_screen.dart';
import 'screens/notifications/notification_settings_screen.dart';
import 'screens/notifications/notification_permission_screen.dart';
import 'screens/child_growth/child_growth_screen.dart';
import 'screens/health_insights/health_insights_screen.dart';
import 'providers/menstrual_provider.dart';
import 'screens/consult_expert/gynecare_consultation_screen.dart';
import 'screens/consult_expert/doctor_slots_screen.dart';
import 'screens/ai_companion/sakhi_ai_screen.dart';
import 'services/push_notification_service.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'providers/nutrition_provider.dart';

Future<void> main() async {
  debugPrint('MAACARE_DEBUG: main() started');
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('MAACARE_DEBUG: WidgetsFlutterBinding initialized');

  // ── Global image cache limits (prevents OOM in Release APK) ──────────────
  PaintingBinding.instance.imageCache.maximumSize = 150; // max 150 images
  PaintingBinding.instance.imageCache.maximumSizeBytes = 80 << 20; // 80 MB cap

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('MAACARE_DEBUG: FlutterError: ${details.exception}');
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('MAACARE_DEBUG: PlatformDispatcher Error: $error');
    return true;
  };

  // Initialize Services Safely Without Blocking UI
  debugPrint('MAACARE_DEBUG: Initializing Notification Services...');

  Future.microtask(() async {
    try {
      await PushNotificationService.instance.initialize();
      await NotificationService.instance.initialize();
    } catch (e, stack) {
      debugPrint('MAACARE_DEBUG: Notification Init Error: $e\n$stack');
    }
  });

  runApp(const MaaCareApp());
  debugPrint('MAACARE_DEBUG: runApp called');
}

class MaaCareApp extends StatefulWidget {
  const MaaCareApp({super.key});

  @override
  State<MaaCareApp> createState() => _MaaCareAppState();
}

class _MaaCareAppState extends State<MaaCareApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initDeepLinks();
    }
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    _appLinks.uriLinkStream.listen((uri) async {
      debugPrint('AUTH_DEBUG: Deep link received: $uri');
      if (uri.scheme == 'maacare' && uri.host == 'auth') {
        final code = uri.queryParameters['insforge_code'] ?? uri.queryParameters['code'];
        if (code != null) {
          debugPrint('AUTH_DEBUG: Exchanging OAuth code from deep link...');
          final result = await AuthService.instance.exchangeOAuthCodeWeb(code);
          if (result.success) {
            debugPrint('AUTH_DEBUG: Deep link OAuth success! Loading user profile...');
            final userProvider = _navigatorKey.currentContext?.read<UserProvider>();
            if (userProvider != null) {
              await userProvider.loadUser();
              final role = userProvider.user?.userRole;
              // No public.users profile row → Google OAuth new user → role selection
              if (userProvider.user == null) {
                debugPrint('AUTH_DEBUG: No profile, routing to role selection...');
                _navigatorKey.currentState?.pushNamedAndRemoveUntil('/role-selection', (route) => false);
              } else if (role == null || role.isEmpty || role == 'unset') {
                debugPrint('AUTH_DEBUG: No role found, routing to role selection...');
                _navigatorKey.currentState?.pushNamedAndRemoveUntil('/role-selection', (route) => false);
              } else if (role == 'doctor') {
                _navigatorKey.currentState?.pushNamedAndRemoveUntil('/doctor_dashboard', (route) => false);
              } else if (role == 'unmarried_girl') {
                _navigatorKey.currentState?.pushNamedAndRemoveUntil('/period_dashboard', (route) => false);
              } else {
                _navigatorKey.currentState?.pushNamedAndRemoveUntil('/mother_dashboard', (route) => false);
              }
            } else {
              // Could not load user provider – go to role selection as safe fallback
              _navigatorKey.currentState?.pushNamedAndRemoveUntil('/role-selection', (route) => false);
            }
          } else {
            debugPrint('AUTH_DEBUG: Deep link OAuth failed: ${result.error}');
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => CommunityProvider()),
        ChangeNotifierProvider(create: (_) => MenstrualProvider()),
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NutritionProvider()),
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
            navigatorKey: _navigatorKey,
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
            initialRoute: '/splash',
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
        case '/mother_dashboard':
          return const HomeScreen();
        case '/period_dashboard':
          return const PeriodDashboardScreen();
        case '/doctor_dashboard':
          return const DoctorDashboardScreen();
        case '/chat':
          return const AiChatScreen();
        case '/tracker':
          return const PregnancyTrackerScreen();
        case '/profile':
          return const ProfileScreen();
        case '/edit_profile':
          return const EditProfileScreen();
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
        case '/gynecare':
          return const GyneCareScreen();
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
        case '/contraception_tracker':
          return const ContraceptionTrackerScreen();
        case '/planning':
        case '/familyplanning-guide':
          return const FamilyPlanningGuideScreen();
        case '/notifications':
          return const NotificationCenterScreen();
        case '/notification-settings':
          return const NotificationSettingsScreen();
        case '/notification-permission':
          return const NotificationPermissionScreen();
        // ── Auth role-selection (post Google OAuth) ──
        case '/role-selection':
          return const RoleSelectionScreen();
        case '/doctor-onboarding':
          return const DoctorOnboardingScreen();
        case '/menstrual-config':
          return const MenstrualCycleConfigScreen();
        case '/maternal-config':
          return const MaternalTimelineConfigScreen();
        case '/permission_gate':
          return const PermissionGateScreen();
        case '/join-consultation':
          final args = settings.arguments as Map<String, dynamic>? ?? {};
          final BookingModel appointment;
          if (args['appointment'] is BookingModel) {
            appointment = args['appointment'] as BookingModel;
          } else {
            appointment = BookingModel(
              id: args['appointment_id']?.toString() ?? args['session_id']?.toString() ?? '',
              userId: '',
              doctorId: '',
              patientName: args['patient_name']?.toString() ?? 'Mama',
              symptoms: '',
              appointmentDate: DateTime.now(),
              status: 'scheduled',
              paymentStatus: 'paid',
              meetingLink: '',
              amount: '',
              createdAt: DateTime.now(),
            );
          }
          final roomCode = args['room_code']?.toString() ?? '96if48kf-ap-southeast';
          final userName = args['user_name']?.toString() ?? 'Mama';
          return JoinConsultationScreen(
            appointment: appointment,
            roomCode: roomCode,
            userName: userName,
          );
        // ── New feature deep-link routes ──
        case '/child-growth':
          return const ChildGrowthScreen();
        case '/health-insights':
          return const HealthInsightsScreen();
        case '/expert':
        case '/gynecare_consultation':
          return const GyneCareConsultationScreen();
        case '/doctor_slots':
          return const DoctorSlotsScreen();
        case '/sakhi_ai':
          return const SakhiAiScreen();
        case '/cycle_nutrition':
          return const CycleNutritionScreen();
        case '/menstrual_nutrition':
          return const MenstrualSelectionFlow();
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
