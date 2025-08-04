import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_service.dart';
import 'in_app_notification_service.dart';

class ServiceRequestNotifier {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notify when technician accepts a service request
  static Future<void> notifyServiceAccepted({
    required String serviceRequestId,
    required String technicianName,
    required String serviceRequestNumber,
  }) async {
    try {
      // Get all admin FCM tokens
      final adminFCMTokens = await FCMService.getAllAdminFCMTokens();
      final adminUIDs = await InAppNotificationService.getAllAdminUIDs();

      // Send push notification to all admins
      if (adminFCMTokens.isNotEmpty) {
        await FCMService.sendNotificationToMultipleUsers(
          fcmTokens: adminFCMTokens,
          title: 'Service Request Accepted',
          body: '$technicianName has accepted service request #$serviceRequestNumber',
          data: {
            'type': 'service_update',
            'action': 'accepted',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
          },
        );
      }

      // Save in-app notification for all admins
      if (adminUIDs.isNotEmpty) {
        await InAppNotificationService.saveNotificationToMultipleUsers(
          receiverUids: adminUIDs,
          title: 'Service Request Accepted',
          body: '$technicianName has accepted service request #$serviceRequestNumber',
          type: 'service_update',
          additionalData: {
            'action': 'accepted',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
            'serviceRequestNumber': serviceRequestNumber,
          },
        );
      }

      print('Service acceptance notification sent successfully');
    } catch (e) {
      print('Error sending service acceptance notification: $e');
    }
  }

  // Notify when technician rejects a service request
  static Future<void> notifyServiceRejected({
    required String serviceRequestId,
    required String technicianName,
    required String serviceRequestNumber,
    String? reason,
  }) async {
    try {
      // Get all admin FCM tokens
      final adminFCMTokens = await FCMService.getAllAdminFCMTokens();
      final adminUIDs = await InAppNotificationService.getAllAdminUIDs();

      final reasonText = reason != null ? ' Reason: $reason' : '';

      // Send push notification to all admins
      if (adminFCMTokens.isNotEmpty) {
        await FCMService.sendNotificationToMultipleUsers(
          fcmTokens: adminFCMTokens,
          title: 'Service Request Rejected',
          body: '$technicianName has rejected service request #$serviceRequestNumber$reasonText',
          data: {
            'type': 'service_update',
            'action': 'rejected',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
            'reason': reason,
          },
        );
      }

      // Save in-app notification for all admins
      if (adminUIDs.isNotEmpty) {
        await InAppNotificationService.saveNotificationToMultipleUsers(
          receiverUids: adminUIDs,
          title: 'Service Request Rejected',
          body: '$technicianName has rejected service request #$serviceRequestNumber$reasonText',
          type: 'service_update',
          additionalData: {
            'action': 'rejected',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
            'serviceRequestNumber': serviceRequestNumber,
            'reason': reason,
          },
        );
      }

      print('Service rejection notification sent successfully');
    } catch (e) {
      print('Error sending service rejection notification: $e');
    }
  }

  // Notify when technician completes a service request
  static Future<void> notifyServiceCompleted({
    required String serviceRequestId,
    required String technicianName,
    required String serviceRequestNumber,
    String? completionNotes,
  }) async {
    try {
      // Get all admin FCM tokens
      final adminFCMTokens = await FCMService.getAllAdminFCMTokens();
      final adminUIDs = await InAppNotificationService.getAllAdminUIDs();

      final notesText = completionNotes != null ? ' Notes: $completionNotes' : '';

      // Send push notification to all admins
      if (adminFCMTokens.isNotEmpty) {
        await FCMService.sendNotificationToMultipleUsers(
          fcmTokens: adminFCMTokens,
          title: 'Service Request Completed',
          body: '$technicianName has completed service request #$serviceRequestNumber$notesText',
          data: {
            'type': 'service_update',
            'action': 'completed',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
            'completionNotes': completionNotes,
          },
        );
      }

      // Save in-app notification for all admins
      if (adminUIDs.isNotEmpty) {
        await InAppNotificationService.saveNotificationToMultipleUsers(
          receiverUids: adminUIDs,
          title: 'Service Request Completed',
          body: '$technicianName has completed service request #$serviceRequestNumber$notesText',
          type: 'service_update',
          additionalData: {
            'action': 'completed',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
            'serviceRequestNumber': serviceRequestNumber,
            'completionNotes': completionNotes,
          },
        );
      }

      print('Service completion notification sent successfully');
    } catch (e) {
      print('Error sending service completion notification: $e');
    }
  }

  // Notify when technician starts a service request
  static Future<void> notifyServiceStarted({
    required String serviceRequestId,
    required String technicianName,
    required String serviceRequestNumber,
  }) async {
    try {
      // Get all admin FCM tokens
      final adminFCMTokens = await FCMService.getAllAdminFCMTokens();
      final adminUIDs = await InAppNotificationService.getAllAdminUIDs();

      // Send push notification to all admins
      if (adminFCMTokens.isNotEmpty) {
        await FCMService.sendNotificationToMultipleUsers(
          fcmTokens: adminFCMTokens,
          title: 'Service Request Started',
          body: '$technicianName has started service request #$serviceRequestNumber',
          data: {
            'type': 'service_update',
            'action': 'started',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
          },
        );
      }

      // Save in-app notification for all admins
      if (adminUIDs.isNotEmpty) {
        await InAppNotificationService.saveNotificationToMultipleUsers(
          receiverUids: adminUIDs,
          title: 'Service Request Started',
          body: '$technicianName has started service request #$serviceRequestNumber',
          type: 'service_update',
          additionalData: {
            'action': 'started',
            'serviceRequestId': serviceRequestId,
            'technicianName': technicianName,
            'serviceRequestNumber': serviceRequestNumber,
          },
        );
      }

      print('Service start notification sent successfully');
    } catch (e) {
      print('Error sending service start notification: $e');
    }
  }

  // Get technician name by UID
  static Future<String> getTechnicianName(String technicianUID) async {
    try {
      final doc = await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .get();
      
      if (doc.exists) {
        return doc.data()?['fullName'] ?? 'Unknown Technician';
      }
      return 'Unknown Technician';
    } catch (e) {
      print('Error getting technician name: $e');
      return 'Unknown Technician';
    }
  }
} 