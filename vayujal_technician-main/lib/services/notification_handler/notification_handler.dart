import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fcm_service.dart';
import 'in_app_notification_service.dart';
import 'service_request_notifier.dart';
import 'admin_access_notifier.dart';
import 'logout_helper.dart';

class NotificationHandler {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ===== SERVICE REQUEST NOTIFICATIONS =====

  /// Notify when technician accepts a service request
  static Future<void> notifyServiceAccepted({
    required String serviceRequestId,
    required String serviceRequestNumber,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final technicianName = await ServiceRequestNotifier.getTechnicianName(currentUser.uid);
        
        await ServiceRequestNotifier.notifyServiceAccepted(
          serviceRequestId: serviceRequestId,
          technicianName: technicianName,
          serviceRequestNumber: serviceRequestNumber,
        );
      }
    } catch (e) {
      print('Error in notifyServiceAccepted: $e');
    }
  }

  /// Notify when technician rejects a service request
  static Future<void> notifyServiceRejected({
    required String serviceRequestId,
    required String serviceRequestNumber,
    String? reason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final technicianName = await ServiceRequestNotifier.getTechnicianName(currentUser.uid);
        
        await ServiceRequestNotifier.notifyServiceRejected(
          serviceRequestId: serviceRequestId,
          technicianName: technicianName,
          serviceRequestNumber: serviceRequestNumber,
          reason: reason,
        );
      }
    } catch (e) {
      print('Error in notifyServiceRejected: $e');
    }
  }

  /// Notify when technician completes a service request
  static Future<void> notifyServiceCompleted({
    required String serviceRequestId,
    required String serviceRequestNumber,
    String? completionNotes,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final technicianName = await ServiceRequestNotifier.getTechnicianName(currentUser.uid);
        
        await ServiceRequestNotifier.notifyServiceCompleted(
          serviceRequestId: serviceRequestId,
          technicianName: technicianName,
          serviceRequestNumber: serviceRequestNumber,
          completionNotes: completionNotes,
        );
      }
    } catch (e) {
      print('Error in notifyServiceCompleted: $e');
    }
  }

  /// Notify when technician starts a service request
  
  // ===== ADMIN ACCESS NOTIFICATIONS =====

  /// Request admin access (called by technician)
  static Future<void> requestAdminAccess(Map<String, dynamic> technicianData, String technicianId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        
        await AdminAccessNotifier.notifyAdminAccessRequest(
          technicianId: technicianId,
          technicianName: technicianData['fullName'],
          uid:currentUser.uid
        );
      }
    } catch (e) {
      print('Error in requestAdminAccess: $e');
    }
  }

  /// Promote technician to admin (called by admin)
  static Future<bool> promoteTechnicianToAdmin({
    required String technicianUID,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final promotedByAdminName = await AdminAccessNotifier.getCurrentAdminName();
        final technicianName = await AdminAccessNotifier.getTechnicianName(technicianUID);
        
        return await AdminAccessNotifier.promoteTechnicianToAdmin(
          technicianUID: technicianUID,
          technicianName: technicianName,
          promotedByAdminName: promotedByAdminName,
        );
      }
      return false;
    } catch (e) {
      print('Error in promoteTechnicianToAdmin: $e');
      return false;
    }
  }

  /// Reject admin access request (called by admin)
  static Future<void> rejectAdminAccessRequest({
    required String technicianUID,
    String? reason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final rejectedByAdminName = await AdminAccessNotifier.getCurrentAdminName();
        final technicianName = await AdminAccessNotifier.getTechnicianName(technicianUID);
        
        await AdminAccessNotifier.rejectAdminAccessRequest(
          technicianUID: technicianUID,
          technicianName: technicianName,
          rejectedByAdminName: rejectedByAdminName,
          reason: reason,
        );
      }
    } catch (e) {
      print('Error in rejectAdminAccessRequest: $e');
    }
  }

  /// Respond to admin access request (called by admin)
  static Future<void> respondToAdminRequest({
    required String technicianUID,
    required String status, // 'approved' or 'rejected'
    String? reason,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final technicianName = await AdminAccessNotifier.getTechnicianName(technicianUID);
        
        await AdminAccessNotifier.respondToAdminRequest(
          technicianUID: technicianUID,
          technicianName: technicianName,
          status: status,
          reason: reason,
        );
      }
    } catch (e) {
      print('Error in respondToAdminRequest: $e');
    }
  }

  // ===== IN-APP NOTIFICATION HELPERS =====

  /// Get notifications stream for current user
  static Stream<QuerySnapshot> getNotificationsStream() {
    return InAppNotificationService.getNotificationsStream();
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async {
    await InAppNotificationService.markNotificationAsRead(notificationId);
  }

  /// Mark all notifications as read
  static Future<void> markAllNotificationsAsRead() async {
    await InAppNotificationService.markAllNotificationsAsRead();
  }

  /// Get unread notification count
  static Stream<int> getUnreadNotificationCount() {
    return InAppNotificationService.getUnreadNotificationCount();
  }

  /// Delete notification
  static Future<void> deleteNotification(String notificationId) async {
    await InAppNotificationService.deleteNotification(notificationId);
  }

  // ===== FCM TOKEN MANAGEMENT =====

  /// Update FCM token for current user
  static Future<void> updateFCMToken(String token) async {
    await FCMService.updateFCMToken(token);
  }

  /// Get current user's FCM token
  static Future<String?> getCurrentUserFCMToken() async {
    return await FCMService.getCurrentUserFCMToken();
  }

  // ===== SESSION MANAGEMENT =====

  /// Check if current user should be force logged out
  static Future<bool> shouldForceLogout() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return await LogoutHelper.shouldForceLogout(currentUser.uid);
      }
      return false;
    } catch (e) {
      print('Error checking force logout: $e');
      return false;
    }
  }

  /// Check if user session is valid
  static Future<bool> isUserSessionValid() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return await LogoutHelper.isUserSessionValid(currentUser.uid);
      }
      return false;
    } catch (e) {
      print('Error checking session validity: $e');
      return false;
    }
  }

  /// Logout current user
  static Future<void> logoutCurrentUser() async {
    await LogoutHelper.logoutCurrentUser();
  }

  // ===== UTILITY METHODS =====

  /// Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        return await AdminAccessNotifier.isUserAdmin(currentUser.uid);
      }
      return false;
    } catch (e) {
      print('Error checking if current user is admin: $e');
      return false;
    }
  }

  /// Get current user's name
  static Future<String> getCurrentUserName() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        final isAdmin = await AdminAccessNotifier.isUserAdmin(currentUser.uid);
        if (isAdmin) {
          return await AdminAccessNotifier.getCurrentAdminName();
        } else {
          return await ServiceRequestNotifier.getTechnicianName(currentUser.uid);
        }
      }
      return 'Unknown User';
    } catch (e) {
      print('Error getting current user name: $e');
      return 'Unknown User';
    }
  }
} 