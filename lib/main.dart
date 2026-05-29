import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'timecard_notifier.dart';
import 'screens/onboarding_screen.dart';
import 'screens/timecard_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Style the status bar to match the app's dark-blue header.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF0D47A1),
    statusBarIconBrightness: Brightness.light,
  ));

  final prefs = await SharedPreferences.getInstance();
  final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

  runApp(MyApp(showOnboarding: !onboardingDone));
}

class MyApp extends StatelessWidget {
  final bool showOnboarding;
  const MyApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TimecardNotifier(),
      child: MaterialApp(
        title: 'Timecard Utility',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: showOnboarding
            ? const OnboardingScreen()
            : const TimecardScreen(),
      ),
    );
  }
}
