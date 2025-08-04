import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FCMService {
  static const String _serverKey = 'YOUR_FCM_SERVER_KEY'; // Replace with your FCM server key
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  // Send push notification to a single user
  static Future<bool> sendNotificationToUser({
    required String fcmToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode({
          'to': fcmToken,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('Push notification sent successfully');
        return true;
      } else {
        print('Failed to send push notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  // Send push notification to multiple users
  static Future<bool> sendNotificationToMultipleUsers({
    required List<String> fcmTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: json.encode({
          'registration_ids': fcmTokens,
          'notification': {
            'title': title,
            'body': body,
            'sound': 'default',
          },
          'data': data ?? {},
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        print('Push notification sent to multiple users successfully');
        return true;
      } else {
        print('Failed to send push notification: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Error sending push notification: $e');
      return false;
    }
  }

  // Get FCM token for current user
  static Future<String?> getCurrentUserFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance
            .collection('technicians')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          return doc.data()?['fcmToken'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  // Get all admin FCM tokens
  static Future<List<String>> getAllAdminFCMTokens() async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('admins')
          .get();
      
      List<String> tokens = [];
      for (var doc in querySnapshot.docs) {
        final fcmToken = doc.data()['fcmToken'];
        if (fcmToken != null && fcmToken.isNotEmpty) {
          tokens.add(fcmToken);
        }
      }
      return tokens;
    } catch (e) {
      print('Error getting admin FCM tokens: $e');
      return [];
    }
  }

  // Update FCM token for current user
  static Future<void> updateFCMToken(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('technicians')
            .doc(user.uid)
            .update({'fcmToken': token});
      }
    } catch (e) {
      print('Error updating FCM token: $e');
    }
  }
} 