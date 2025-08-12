import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'package:vayujal_technician/screens/login_screen.dart';
import 'package:vayujal_technician/screens/profile_setup_screen.dart';
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
          // Save FCM token when user is logged in
         
          
          // Check if user profile is complete
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('technicians')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }
              
              if (profileSnapshot.hasData && profileSnapshot.data!.exists) {
                
                final data = profileSnapshot.data!.data() as Map<String, dynamic>?;
                final bool isProfileComplete = data?['isProfileComplete'] ?? false;
                
                if (isProfileComplete) {
                  return const DashboardScreen();
                } else {
                  return const ProfileSetupScreen();
                }
              } else {
                // Document doesn't exist, show profile setup
                return const ProfileSetupScreen();
              }
            },
          );
        }
        else{
          return const LoginScreen();
        }

        
      },
    );
  }
}
