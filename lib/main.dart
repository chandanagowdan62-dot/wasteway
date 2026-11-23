import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_constants.dart';
import 'core/config/ai_config.dart';
import 'core/services/firebase/firebase_service_manager.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/providers/home_provider.dart';
import 'features/scanner/presentation/providers/scanner_provider.dart';
import 'features/passport/presentation/providers/passport_provider.dart';
import 'features/facilities/presentation/providers/facility_provider.dart';
import 'features/education/presentation/providers/education_provider.dart';
import 'features/civic_reports/presentation/providers/civic_report_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize modular Firebase services (backed by local mock storage fallback)
  await FirebaseServiceManager().initialize();

  // Initialize modular AI configuration (Gemini Vision with offline mock fallback)
  await AIConfig.init();

  runApp(const WasteWayApp());
}

class WasteWayApp extends StatelessWidget {
  const WasteWayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<FirebaseServiceManager>.value(
          value: FirebaseServiceManager(),
        ),
        ChangeNotifierProvider(create: (_) => HomeProvider()),
        ChangeNotifierProvider(create: (_) => ScannerProvider()),
        ChangeNotifierProvider(create: (_) => PassportProvider()),
        ChangeNotifierProvider(create: (_) => FacilityProvider()),
        ChangeNotifierProvider(create: (_) => EducationProvider()),
        ChangeNotifierProvider(create: (_) => CivicReportProvider()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
