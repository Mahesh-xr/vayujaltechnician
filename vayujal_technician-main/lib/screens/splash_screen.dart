import 'package:flutter/material.dart';
import 'package:vayujal_technician/screens/login_screen.dart';
import 'dart:async';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(Duration(milliseconds: 1600), () {
      if (mounted) {
        try {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
        } catch (e) {
          print('Error navigating from splash screen: $e');
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Center(
        child: Image.asset(
          "assets/images/ayujal_logo.png",
          fit: BoxFit.contain,
          width: 200, // Adjust size as needed
          height: 200,
        ),
      ),
    );
  }
}
