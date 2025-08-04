import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_service.dart';
import 'in_app_notification_service.dart';
import 'logout_helper.dart';
import 'package:flutter/material.dart'; // Added for BuildContext

class AdminAccessNotifier {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Notify when technician requests admin access
  static Future<void> notifyAdminAccessRequest({
    required String technicianId,
    required String technicianName,
    required String uid,
  }) async {
    try {
      // Create notification for all admins
      await _firestore.collection('notifications').add({
        'type': 'admin_access_request',
        'title': 'Admin Access Request',
        'message': '$technicianName is requesting admin access',
        'recipientRole': 'admin', // All admins can see this
        'senderId': uid,
        'senderName': technicianName,
        'data': {
          'action': 'request',
          'technicianUID': uid, // Use actual Firebase UID
          'technicianId': technicianId, // Keep employee ID for reference
          'technicianName': technicianName,
        },
        'isRead': false,
        'isActioned': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

        

      // Get all admin FCM tokens for push notifications
      final adminFCMTokens = await FCMService.getAllAdminFCMTokens();

      // Send push notification to all admins
      if (adminFCMTokens.isNotEmpty) {
        await FCMService.sendNotificationToMultipleUsers(
          fcmTokens: adminFCMTokens,
          title: 'Admin Access Request',
          body: '$technicianName is requesting admin access',
          data: {
            'type': 'admin_access_request',
            'action': 'request',
            'technicianUID': uid, // Use actual Firebase UID
            'technicianId': technicianId, // Keep employee ID for reference
            'technicianName': technicianName,
          },
        );
      }

      // Send push notification to the technician
      final technicianFCMToken = await FCMService.getCurrentUserFCMToken();
      if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
        await FCMService.sendNotificationToUser(
          fcmToken: technicianFCMToken,
          title: 'Admin Access Request Sent',
          body: 'Your admin access request has been sent to administrators for review.',
          data: {
            'type': 'admin_access_request',
            'action': 'request_sent',
            'technicianUID': uid,
            'technicianId': technicianId,
            'technicianName': technicianName,
          },
        );
      }

      print('Admin access request notification sent successfully');
    } catch (e) {
      print('Error sending admin access request notification: $e');
    }
  }

  // Promote technician to admin
  static Future<bool> promoteTechnicianToAdmin({
    required String technicianUID,
    required String technicianName,
    required String promotedByAdminName,
  }) async {
    try {
      // Get technician data
      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .get();

      if (!technicianDoc.exists) {
        print('Technician not found');
        return false;
      }

      final technicianData = technicianDoc.data()!;

      // Add technician to admin collection
      await _firestore.collection('admins').doc(technicianUID).set({
        'uid': technicianUID,
        'email': technicianData['email'],
        'fullName': technicianData['fullName'],
        'role': 'admin',
        'fcmToken': technicianData['fcmToken'],
        'promotedBy': promotedByAdminName,
        'promotedAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update technician role
      await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .update({
        'role': 'admin',
        'promotedBy': promotedByAdminName,
        'promotedAt': FieldValue.serverTimestamp(),
      });

      // // Send notification to promoted technician
      // final technicianFCMToken = technicianData['fcmToken'];
      // if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
      //   await FCMService.sendNotificationToUser(
      //     fcmToken: technicianFCMToken,
      //     title: 'Promotion Successful!',
      //     body: 'You have been promoted to Admin by $promotedByAdminName!',
      //     data: {
      //       'type': 'admin_request_response',
      //       'action': 'promoted',
      //       'promotedBy': promotedByAdminName,
      //     },
      //   );
      // }

      // // Create notification in the main notifications collection for promoted technician
      // await _firestore.collection('notifications').add({
      //   'type': 'admin_request_response',
      //   'title': 'Promotion Successful!',
      //   'message': 'You have been promoted to Admin by $promotedByAdminName!',
      //   'userId': technicianUID, // Use userId for the notification screen
      //   'recipientRole': 'technician',
      //   'senderId': promotedByAdminName,
      //   'senderName': promotedByAdminName,
      //   'data': {
      //     'action': 'promoted',
      //     'promotedBy': promotedByAdminName,
      //   },
      //   'isRead': false,
      //   'createdAt': FieldValue.serverTimestamp(),
      // });

      // Logout the technician from current session
      await LogoutHelper.logoutUserAfterPromotion(technicianUID);

      print('Technician promoted to admin successfully');
      return true;
    } catch (e) {
      print('Error promoting technician to admin: $e');
      return false;
    }
  }

  // Reject admin access request
  static Future<void> rejectAdminAccessRequest({
    required String technicianUID,
    required String technicianName,
    required String rejectedByAdminName,
    String? reason,
  }) async {
    try {
      // Get technician FCM token
      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .get();

      if (technicianDoc.exists) {
        final technicianFCMToken = technicianDoc.data()?['fcmToken'];
        final reasonText = reason != null ? ' Reason: $reason' : '';

        // Create notification in the main notifications collection for technician
        await _firestore.collection('notifications').add({
          'type': 'admin_request_response',
          'title': 'Admin Access Denied',
          'message': 'Your admin access request has been denied by $rejectedByAdminName$reasonText',
          'recipientId': technicianUID, // Use recipientId instead of userId
          'recipientRole': 'technician',
          'senderId': rejectedByAdminName,
          'senderName': rejectedByAdminName,
          'data': {
            'action': 'rejected',
            'rejectedBy': rejectedByAdminName,
            'reason': reason,
          },
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Send push notification to technician
        if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
          await FCMService.sendNotificationToUser(
            fcmToken: technicianFCMToken,
            title: 'Admin Access Denied',
            body: 'Your admin access request has been denied by $rejectedByAdminName$reasonText',
            data: {
              'type': 'admin_request_response',
              'action': 'rejected',
              'rejectedBy': rejectedByAdminName,
              'reason': reason,
            },
          );
        }
      }

      print('Admin access request rejected successfully');
    } catch (e) {
      print('Error rejecting admin access request: $e');
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

  // Check if user is admin
  static Future<bool> isUserAdmin(String userUID) async {
    try {
      final doc = await _firestore
          .collection('admins')
          .doc(userUID)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking if user is admin: $e');
      return false;
    }
  }

  // Get current user's admin name
  static Future<String> getCurrentAdminName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await _firestore
            .collection('admins')
            .doc(user.uid)
            .get();
        
        if (doc.exists) {
          return doc.data()?['fullName'] ?? 'Unknown Admin';
        }
      }
      return 'Unknown Admin';
    } catch (e) {
      print('Error getting current admin name: $e');
      return 'Unknown Admin';
    }
  }

  // Show approval dialog and handle admin role offer
  static Future<void> showApprovalDialogAndCreateNotification({
    required BuildContext context,
    required String technicianUID,
    required String technicianName,
  }) async {
    try {
      final currentAdminName = await getCurrentAdminName();
      
      // Show confirmation dialog
      final shouldProceed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Approve Admin Access'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to approve admin access for:'),
                const SizedBox(height: 8),
                Text(
                  technicianName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'This will send a notification to the technician asking them to accept the admin role.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Approve'),
              ),
            ],
          );
        },
      );

      if (shouldProceed == true) {
        // Get technician FCM token
        final technicianDoc = await _firestore
            .collection('technicians')
            .doc(technicianUID)
            .get();

        if (technicianDoc.exists) {
          final technicianFCMToken = technicianDoc.data()?['fcmToken'];

          // Create notification asking technician to accept admin role
          await _firestore.collection('notifications').add({
            'type': 'admin_role_acceptance',
            'title': 'Admin Role Offered',
            'message': 'Your admin access request has been approved by $currentAdminName. Would you like to accept the admin role?',
            'recipientId': technicianUID, // Use recipientId instead of userId
            'recipientRole': 'technician',
            'senderId': currentAdminName,
            'senderName': currentAdminName,
            'data': {
              'action': 'role_offered',
              'approvedBy': currentAdminName,
              'status': 'pending_acceptance',
              'technicianUID': technicianUID,
              'technicianName': technicianName,
            },
            'isRead': false,
            'isActioned': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send push notification to technician
          if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
            await FCMService.sendNotificationToUser(
              fcmToken: technicianFCMToken,
              title: 'Admin Role Offered',
              body: 'Your admin access request has been approved. Please check your notifications to accept the role.',
              data: {
                'type': 'admin_role_acceptance',
                'action': 'role_offered',
                'approvedBy': currentAdminName,
              },
            );
          }

          // Show success message
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Admin access approved for $technicianName'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error showing approval dialog: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving admin access: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle admin request response (called by admin)
  static Future<void> respondToAdminRequest({
    required String technicianUID,
    required String technicianName,
    required String status, // 'approved' or 'rejected'
    String? reason,
  }) async {
    try {
      print('DEBUG: respondToAdminRequest called with technicianUID: $technicianUID');
      
      // Get technician FCM token
      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .get();

      print('DEBUG: Technician document exists: ${technicianDoc.exists}');
      
      if (technicianDoc.exists) {
        final technicianFCMToken = technicianDoc.data()?['fcmToken'];
        final currentAdminName = await getCurrentAdminName();
        
        print('DEBUG: Creating notification with userId: $technicianUID');

        if (status == 'approved') {
          // Create notification asking technician to accept admin role
          await _firestore.collection('notifications').add({
            'type': 'admin_role_acceptance',
            'title': 'Admin Role Offered',
            'message': 'Your admin access request has been approved by $currentAdminName. Would you like to accept the admin role?',
            'recipientId': technicianUID, // Use recipientId instead of userId
            'recipientRole': 'technician',
            'senderId': currentAdminName,
            'senderName': currentAdminName,
            'data': {
              'action': 'role_offered',
              'approvedBy': currentAdminName,
              'status': 'pending_acceptance',
              'technicianUID': technicianUID,
              'technicianName': technicianName,
            },
            'isRead': false,
            'isActioned': false,
            'createdAt': FieldValue.serverTimestamp(),
          });

          // Send push notification to technician
          if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
            await FCMService.sendNotificationToUser(
              fcmToken: technicianFCMToken,
              title: 'Admin Role Offered',
              body: 'Your admin access request has been approved. Please check your notifications to accept the role.',
              data: {
                'type': 'admin_role_acceptance',
                'action': 'role_offered',
                'approvedBy': currentAdminName,
              },
            );
          }
        } else {
          // Send rejection notification to technician
          final reasonText = reason != null ? ' Reason: $reason' : '';
          
          if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
            await FCMService.sendNotificationToUser(
              fcmToken: technicianFCMToken,
              title: 'Admin Access Request Rejected',
              body: 'Your admin access request has been rejected by $currentAdminName$reasonText',
              data: {
                'type': 'admin_request_response',
                'action': 'rejected',
                'rejectedBy': currentAdminName,
                'reason': reason,
              },
            );
          }

          // Create notification in the main notifications collection for technician
          await _firestore.collection('notifications').add({
            'type': 'admin_request_response',
            'title': 'Admin Access Request Rejected',
            'message': 'Your admin access request has been rejected by $currentAdminName$reasonText',
            'recipientId': technicianUID, // Use recipientId instead of userId
            'recipientRole': 'technician',
            'senderId': currentAdminName,
            'senderName': currentAdminName,
            'data': {
              'action': 'rejected',
              'rejectedBy': currentAdminName,
              'reason': reason,
              'status': 'rejected',
            },
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      } else {
        print('DEBUG: Technician document not found for UID: $technicianUID');
      }

      print('Admin request response sent successfully');
    } catch (e) {
      print('Error sending admin request response: $e');
    }
  }

  // Handle technician accepting admin role
  static Future<void> acceptAdminRole({
    required String technicianUID,
    required String technicianName,
    required String approvedByAdmin,
  }) async {
    try {
      // Get technician data
      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .get();

      if (!technicianDoc.exists) {
        print('Technician not found');
        return;
      }

      final technicianData = technicianDoc.data()!;

      // Update technician role to admin-tech (prevents using this app)
      await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .update({
        'role': 'admin-tech',
        'promotedBy': approvedByAdmin,
        'promotedAt': FieldValue.serverTimestamp(),
      });

      // Create notification confirming role acceptance
      await _firestore.collection('notifications').add({
        'type': 'admin_role_acceptance',
        'title': 'Admin Role Accepted',
        'message': 'You have successfully accepted the admin role. You will be logged out and can no longer use this technician app.',
        'recipientId': technicianUID,
        'recipientRole': 'technician',
        'senderId': technicianUID,
        'senderName': technicianName,
        'data': {
          'action': 'role_accepted',
          'approvedBy': approvedByAdmin,
          'status': 'accepted',
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification
      final technicianFCMToken = technicianData['fcmToken'];
      if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
        await FCMService.sendNotificationToUser(
          fcmToken: technicianFCMToken,
          title: 'Admin Role Accepted',
          body: 'You have successfully accepted the admin role. You will be logged out and can no longer use this technician app.',
          data: {
            'type': 'admin_role_acceptance',
            'action': 'role_accepted',
            'approvedBy': approvedByAdmin,
          },
        );
      }

      print('Admin role accepted successfully');
    } catch (e) {
      print('Error accepting admin role: $e');
    }
  }

  // Handle technician rejecting admin role
  static Future<void> rejectAdminRole({
    required String technicianUID,
    required String technicianName,
    required String approvedByAdmin,
  }) async {
    try {
      // Delete technician from admins collection if they exist there
      await _firestore
          .collection('admins')
          .doc(technicianUID)
          .delete();

      // Create notification confirming role rejection
      await _firestore.collection('notifications').add({
        'type': 'admin_role_acceptance',
        'title': 'Admin Role Declined',
        'message': 'You have declined the admin role offer. You will remain as a technician.',
        'recipientId': technicianUID,
        'recipientRole': 'technician',
        'senderId': technicianUID,
        'senderName': technicianName,
        'data': {
          'action': 'role_rejected',
          'approvedBy': approvedByAdmin,
          'status': 'rejected',
        },
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Send push notification
      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(technicianUID)
          .get();

      if (technicianDoc.exists) {
        final technicianFCMToken = technicianDoc.data()?['fcmToken'];
        if (technicianFCMToken != null && technicianFCMToken.isNotEmpty) {
          await FCMService.sendNotificationToUser(
            fcmToken: technicianFCMToken,
            title: 'Admin Role Declined',
            body: 'You have declined the admin role offer. You will remain as a technician.',
            data: {
              'type': 'admin_role_acceptance',
              'action': 'role_rejected',
              'approvedBy': approvedByAdmin,
            },
          );
        }
      }

      print('Admin role rejected successfully');
    } catch (e) {
      print('Error rejecting admin role: $e');
    }
  }
} 