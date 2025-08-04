import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/services/notification_handler/notification_handler.dart';
import 'package:flutter/widgets.dart'; // Added for BuildContext
import 'package:vayujal_technician/services/notification_handler/admin_access_notifier.dart'; // Added for AdminAccessNotifier

class NotificationActionsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Accept a service request
  static Future<bool> acceptServiceRequest(String srId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get technician name
      final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
      final technicianName = technicianDoc.exists 
          ? (technicianDoc.data()?['name'] ?? technicianDoc.data()?['fullName'] ?? 'Unknown Technician')
          : 'Unknown Technician';

      // Get service request details
      final serviceRequestDoc = await _firestore.collection('serviceRequests').doc(srId).get();
      if (!serviceRequestDoc.exists) {
        print('Service request $srId not found');
        return false;
      }

      // Update service request status and isAccepted field
      await _firestore.collection('serviceRequests').doc(srId).update({
        
        'isAccepted': true,
        'serviceDetails.acceptedAt': FieldValue.serverTimestamp(),
        'serviceDetails.acceptedBy': technicianName,
        'serviceDetails.acceptedById': user.uid,
      });

      // Send notification to admin
      await _sendAdminNotification(
        'Service Request Accepted',
        'Technician $technicianName has accepted service request $srId.',
        'service_accepted',
        {'srId': srId, 'technicianId': user.uid, 'technicianName': technicianName},
      );

      return true;
    } catch (e) {
      print('Error accepting service request: $e');
      return false;
    }
  }

  /// Reject a service request (notify admin to assign to someone else)
  static Future<bool> rejectServiceRequest(String srId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get technician name
      final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
      final technicianName = technicianDoc.exists 
          ? (technicianDoc.data()?['name'] ?? technicianDoc.data()?['fullName'] ?? 'Unknown Technician')
          : 'Unknown Technician';

      // Update service request status to rejected and set isAccepted to false
      await _firestore.collection('serviceRequests').doc(srId).update({
        'isAccepted': false,
        'serviceDetails.rejectedAt': FieldValue.serverTimestamp(),
        'serviceDetails.rejectedBy': technicianName,
        'serviceDetails.rejectedById': user.uid,
      });

      // Send notification to admin to assign to someone else
      await _sendAdminNotification(
        'Service Request Rejected',
        'Technician $technicianName has rejected service request $srId. Please assign to another technician.',
        'service_rejected',
        {'srId': srId, 'technicianId': user.uid, 'technicianName': technicianName},
      );

      return true;
    } catch (e) {
      print('Error rejecting service request: $e');
      return false;
    }
  }

  /// Delay a service request (just mark notification as read, no additional actions)
  static Future<bool> delayServiceRequest(String srId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get technician name
      final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
      final technicianName = technicianDoc.exists 
          ? (technicianDoc.data()?['name'] ?? technicianDoc.data()?['fullName'] ?? 'Unknown Technician')
          : 'Unknown Technician';

      // Update service request status to delayed
      await _firestore.collection('serviceRequests').doc(srId).update({
        'status': 'delayed',
        'serviceDetails.delayedAt': FieldValue.serverTimestamp(),
        'serviceDetails.delayedBy': technicianName,
        'serviceDetails.delayedById': user.uid,
      });

      // Send notification to admin
      await _sendAdminNotification(
        'Service Request Delayed',
        'Technician $technicianName has delayed service request $srId.',
        'service_delayed',
        {'srId': srId, 'technicianId': user.uid, 'technicianName': technicianName},
      );

      return true;
    } catch (e) {
      print('Error delaying service request: $e');
      return false;
    }
  }

  /// Request admin access
  static Future<bool> requestAdminAccess() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Get technician name
      final technicianDoc = await _firestore.collection('technicians').doc(user.uid).get();
      final technicianData = technicianDoc.data() as Map<String, dynamic>;
      final technicianId = technicianData['employeeId'];
      
      // Send notification to admin using the new notification handler
      await NotificationHandler.requestAdminAccess(technicianData, technicianId);

      return true;
    } catch (e) {
      print('Error requesting admin access: $e');
      return false;
    }
  }

  /// Respond to admin access request (called by admin)
  static Future<bool> respondToAdminAccessRequest({
    required BuildContext context,
    required String technicianUID,
    required String status, // 'approved' or 'rejected'
    String? reason,
  }) async {
    try {
      if (status == 'approved') {
        // Get technician name for the dialog
        final technicianDoc = await _firestore
            .collection('technicians')
            .doc(technicianUID)
            .get();
        
        final technicianName = technicianDoc.exists 
            ? (technicianDoc.data()?['fullName'] ?? technicianDoc.data()?['name'] ?? 'Unknown Technician')
            : 'Unknown Technician';

        // Show approval dialog and create notification
        await AdminAccessNotifier.showApprovalDialogAndCreateNotification(
          context: context,
          technicianUID: technicianUID,
          technicianName: technicianName,
        );
      } else {
        // For rejections, use the original method
        await NotificationHandler.respondToAdminRequest(
          technicianUID: technicianUID,
          status: status,
          reason: reason,
        );
      }

      return true;
    } catch (e) {
      print('Error responding to admin access request: $e');
      return false;
    }
  }

  /// Send notification to admin
  static Future<void> _sendAdminNotification(
    String title,
    String message,
    String type,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('notifications').add({
      'type': type,
      'title': title,
      'message': message,
      'recipientRole': 'admin',
      'senderId': _auth.currentUser?.uid,
      'senderName': _getCurrentUserName(),
      'data': data,
      'isRead': false,
      'isActioned': false, // New field to track if action buttons are disabled
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get current user name
  static String _getCurrentUserName() {
    final user = _auth.currentUser;
    return user?.displayName ?? user?.email?.split('@')[0] ?? 'Unknown';
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
    });
  }

  /// Get unread notification count
  static Stream<int> getUnreadNotificationCount() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Get technician's accepted requests
  static Future<List<Map<String, dynamic>>> getAcceptedRequests() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final snapshot = await _firestore
          .collection('technicians')
          .doc(user.uid)
          .collection('acceptedRequests')
          .orderBy('acceptedAt', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting accepted requests: $e');
      return [];
    }
  }

  /// Get service request details
  static Future<Map<String, dynamic>?> getServiceRequestDetails(String srId) async {
    try {
      final doc = await _firestore.collection('serviceRequests').doc(srId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting service request details: $e');
      return null;
    }
  }
} 