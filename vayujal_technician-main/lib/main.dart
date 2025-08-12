import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vayujal_technician/firebase_options.dart';
import 'package:vayujal_technician/screens/all_service_request_page.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'package:vayujal_technician/screens/login_screen.dart';
import 'package:vayujal_technician/screens/notification_screen.dart';
import 'package:vayujal_technician/services/auth.dart';
import 'package:vayujal_technician/utils/constants.dart';
import 'package:vayujal_technician/screens/splash_screen.dart';
import 'package:vayujal_technician/utils/dropdown_uploader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // ONE-TIME UPLOAD: Uncomment the line below to upload initial dropdowns
  // Then comment it out again after running once
  // await DropdownUploader.uploadInitialDropdowns();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Technician App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppConstants.primaryColor,
        scaffoldBackgroundColor: AppConstants.backgroundColor,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: AppConstants.textPrimaryColor,
          elevation: 0,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: AppConstants.buttonBorderRadius,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppConstants.primaryColor, width: 2),
          ),
        ),
      ),
      home: const AuthWrapper(),
      //  home: ServiceAcknowledgmentScreen(srNumber: 'SR_01797_194'),
       routes: {
        '/dashboard': (context) => const DashboardScreen(),
        '/service': (context) => const AllServiceRequestsPage(
              initialFilter: 'In Progress',
            ),
        '/history': (context) => const AllServiceRequestsPage(
              initialFilter: 'Completed',
            ),
        '/notifications': (context) => const NotificationScreen(),
        '/login':(context) => const LoginScreen()
      },
    );
  }
}
