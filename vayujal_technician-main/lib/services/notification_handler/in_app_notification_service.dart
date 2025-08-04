import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InAppNotificationService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save notification to Firestore
  static Future<void> saveNotification({
    required String receiverUid,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final notificationData = {
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'additionalData': additionalData ?? {},
      };

      await _firestore
          .collection('notifications')
          .doc(receiverUid)
          .collection('messages')
          .add(notificationData);

      print('In-app notification saved successfully');
    } catch (e) {
      print('Error saving in-app notification: $e');
    }
  }

  // Save notification to multiple users
  static Future<void> saveNotificationToMultipleUsers({
    required List<String> receiverUids,
    required String title,
    required String body,
    required String type,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final batch = _firestore.batch();
      final notificationData = {
        'title': title,
        'body': body,
        'type': type,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'additionalData': additionalData ?? {},
      };

      for (String uid in receiverUids) {
        final docRef = _firestore
            .collection('notifications')
            .doc(uid)
            .collection('messages')
            .doc();
        
        batch.set(docRef, notificationData);
      }

      await batch.commit();
      print('In-app notifications saved to multiple users successfully');
    } catch (e) {
      print('Error saving in-app notifications to multiple users: $e');
    }
  }

  // Get notifications for current user
  static Stream<QuerySnapshot> getNotificationsStream() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return _firestore
            .collection('notifications')
            .doc(user.uid)
            .collection('messages')
            .orderBy('timestamp', descending: true)
            .snapshots();
      }
      return Stream.empty();
    } catch (e) {
      print('Error getting notifications stream: $e');
      return Stream.empty();
    }
  }

  // Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('notifications')
            .doc(user.uid)
            .collection('messages')
            .doc(notificationId)
            .update({'isRead': true});
      }
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  // Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final querySnapshot = await _firestore
            .collection('notifications')
            .doc(user.uid)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .get();

        final batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {'isRead': true});
        }
        await batch.commit();
      }
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  // Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore
            .collection('notifications')
            .doc(user.uid)
            .collection('messages')
            .doc(notificationId)
            .delete();
      }
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  // Get unread notification count
  static Stream<int> getUnreadNotificationCount() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        return _firestore
            .collection('notifications')
            .doc(user.uid)
            .collection('messages')
            .where('isRead', isEqualTo: false)
            .snapshots()
            .map((snapshot) => snapshot.docs.length);
      }
      return Stream.value(0);
    } catch (e) {
      print('Error getting unread notification count: $e');
      return Stream.value(0);
    }
  }

  // Get all admin UIDs
  static Future<List<String>> getAllAdminUIDs() async {
    try {
      final querySnapshot = await _firestore
          .collection('admins')
          .get();
      
      return querySnapshot.docs.map((doc) => doc.id).toList();
    } catch (e) {
      print('Error getting admin UIDs: $e');
      return [];
    }
  }
} 