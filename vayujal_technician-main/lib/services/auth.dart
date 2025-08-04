import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'package:vayujal_technician/screens/login_screen.dart';
import 'package:vayujal_technician/screens/splash_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
       
        // Show loading screen while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // If user is not logged in, show login screen
        if (snapshot.hasData) {
          return const DashboardScreen();
        }
        else{
          return const LoginScreen();
        }

        
      },
    );
  }
}
