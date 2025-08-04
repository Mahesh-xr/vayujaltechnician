import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/screens/admin_profile.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  
  const CustomAppBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, 
      backgroundColor: Colors.white,
      elevation: 0,
     
      title: Row(
        children: [
          
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminProfileSetupPage(),
                ),
              );
            },
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('technicians')
                  .doc(FirebaseAuth.instance.currentUser?.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                String profileImageUrl = '';
                String adminName = 'Admin';
                
                if (snapshot.hasData && snapshot.data!.exists) {
                  final data = snapshot.data!.data() as Map<String, dynamic>?;
                  profileImageUrl = data?['profileImageUrl'] ?? '';
                  adminName = data?['name'] ?? 'Admin';
                }
                
                return Container(
                  margin: EdgeInsets.only(right: 13),
                  child: Tooltip(
                    message: 'Click to edit profile',
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminProfileSetupPage(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey[300],
                        backgroundImage: profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        child: profileImageUrl.isEmpty
                            ? Icon(Icons.admin_panel_settings, 
                                   color: Colors.grey[600], size: 20)
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Image.asset(
            "assets/images/ayujal_logo.png",
            width: 80,
            height: 30,
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}