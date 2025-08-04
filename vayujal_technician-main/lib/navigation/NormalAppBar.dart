import 'package:flutter/material.dart';

class Normalappbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const Normalappbar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5, // slight shadow to separate from scroll area
      shadowColor: Colors.transparent, // no harsh shadow

      title: Text(
        title,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Ensure logo blends with AppBar background
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            color: Colors.white, // force background match
            child: Image.asset(
              "assets/images/ayujal_logo.png",
              width: 80,
              height: 30,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
