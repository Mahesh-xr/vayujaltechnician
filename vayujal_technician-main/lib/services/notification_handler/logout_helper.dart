import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LogoutHelper {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Logout user after promotion to admin
  static Future<void> logoutUserAfterPromotion(String userUID) async {
    try {
      // Check if the current user is the one being promoted
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userUID) {
        // Sign out the user
        await _auth.signOut();
        print('User logged out after promotion to admin');
      }
    } catch (e) {
      print('Error logging out user after promotion: $e');
    }
  }

  // Force logout user by UID (for admin actions)
  static Future<void> forceLogoutUser(String userUID) async {
    try {
      // Update user's session status in Firestore
      await _firestore
          .collection('technicians')
          .doc(userUID)
          .update({
        'forceLogout': true,
        'forceLogoutTimestamp': FieldValue.serverTimestamp(),
      });

      // If it's the current user, sign them out
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.uid == userUID) {
        await _auth.signOut();
        print('User force logged out');
      }
    } catch (e) {
      print('Error force logging out user: $e');
    }
  }

  // Check if user should be force logged out
  static Future<bool> shouldForceLogout(String userUID) async {
    try {
      final doc = await _firestore
          .collection('technicians')
          .doc(userUID)
          .get();
      
      if (doc.exists) {
        final forceLogout = doc.data()?['forceLogout'] ?? false;
        if (forceLogout) {
          // Clear the force logout flag
          await _firestore
              .collection('technicians')
              .doc(userUID)
              .update({
            'forceLogout': false,
            'forceLogoutTimestamp': null,
          });
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking force logout status: $e');
      return false;
    }
  }

  // Clear force logout flag
  static Future<void> clearForceLogoutFlag(String userUID) async {
    try {
      await _firestore
          .collection('technicians')
          .doc(userUID)
          .update({
        'forceLogout': false,
        'forceLogoutTimestamp': null,
      });
    } catch (e) {
      print('Error clearing force logout flag: $e');
    }
  }

  // Logout current user
  static Future<void> logoutCurrentUser() async {
    try {
      await _auth.signOut();
      print('Current user logged out successfully');
    } catch (e) {
      print('Error logging out current user: $e');
    }
  }

  // Check if user session is valid
  static Future<bool> isUserSessionValid(String userUID) async {
    try {
      final doc = await _firestore
          .collection('technicians')
          .doc(userUID)
          .get();
      
      if (doc.exists) {
        final role = doc.data()?['role'];
        // If user is now admin, their session should be invalidated
        if (role == 'admin') {
          return false;
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking user session validity: $e');
      return false;
    }
  }
} 