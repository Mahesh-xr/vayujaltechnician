import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Callback for navigation
  static Function(String)? onNotificationTapped;

  /// Initialize notification service
  static Future<void> initialize(BuildContext context) async {
    await _requestPermission();
    await _initializeLocalNotifications();
    await _registerBackgroundHandler();
    _setupForegroundListener();
    _setupBackgroundListener();
    
    // Only save FCM token if technician document exists (don't create automatically)
    await saveTokenToFirestore();
  }

  /// Explicitly save FCM token (call this after profile setup is complete)
  static Future<void> saveTokenAfterProfileSetup() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('FCM: No user logged in, cannot save token');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM: Could not get FCM token');
        return;
      }

      // Get existing technician data
      final technicianDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (!technicianDoc.exists) {
        debugPrint('FCM: Technician document does not exist, cannot save token');
        return;
      }

      Map<String, dynamic> technicianData = technicianDoc.data() as Map<String, dynamic>;
      
      // Ensure the role and designation are correct for notifications
      technicianData['role'] = 'tech';
      technicianData['designation'] = 'Technician';

      // Add/update FCM token and device info
      final deviceInfo = {
        ...technicianData,
        'fcmToken': token,
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to technicians collection only
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .set(deviceInfo, SetOptions(merge: true));

      debugPrint('FCM: Token saved after profile setup for user: ${user.uid}');
      
      // Listen for token refresh and update automatically
      _messaging.onTokenRefresh.listen((newToken) async {
        await _updateTokenInFirestore(newToken);
      });
      
    } catch (e) {
      debugPrint('FCM: Error saving token after profile setup: $e');
    }
  }

  /// Request notification permissions
  static Future<void> _requestPermission() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('FCM: Notification permission denied');
      } else {
        debugPrint('FCM: Notification permission granted');
      }
    } catch (e) {
      debugPrint('FCM: Error requesting permission: $e');
    }
  }

  /// Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle action buttons and deep linking
        if (response.actionId == 'accept') {
          // Handle accept action
          print('Notification: Accept action tapped for SR: ${response.payload}');
          _handleServiceRequestAction('accept', response.payload);
        } else if (response.actionId == 'delay') {
          // Handle delay action
          print('Notification: Delay action tapped for SR: ${response.payload}');
          _handleServiceRequestAction('delay', response.payload);
        } else if (response.actionId == 'view_details') {
          _handleNotificationTap(response.payload);
        } else if (response.actionId == 'mark_complete') {
          // Handle mark complete action for service acknowledgment
          print('Notification: Mark complete action tapped for SR: ${response.payload}');
          _handleServiceAcknowledgmentAction('mark_complete', response.payload);
        } else {
          _handleNotificationTap(response.payload);
        }
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Create Android notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'service_requests', // id
      'Service Requests', // title
      description: 'Notifications for service request assignments and updates', // description
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Save the FCM token to Firestore under the technician's document
  static Future<void> saveTokenToFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('FCM: No user logged in, cannot save token');
        return;
      }

      final token = await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM: Could not get FCM token');
        return;
      }

      // First, try to get existing technician data
      final technicianDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();

      // Only proceed if technician document exists
      if (!technicianDoc.exists) {
        debugPrint('FCM: Technician document does not exist, skipping token save');
        return;
      }

      // Use existing technician data
      Map<String, dynamic> technicianData = technicianDoc.data() as Map<String, dynamic>;
      debugPrint('FCM: Found existing technician data');

      // Ensure the role and designation are correct for notifications
      technicianData['role'] = 'tech';
      technicianData['designation'] = 'Technician'; // This is what Cloud Function looks for

      // Add/update FCM token and device info
      final deviceInfo = {
        ...technicianData, // Keep existing technician data
        'fcmToken': token,
        'platform': Platform.operatingSystem,
        'osVersion': Platform.operatingSystemVersion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Save to technicians collection only
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .set(deviceInfo, SetOptions(merge: true));

      debugPrint('FCM: Token and technician data saved to Firestore for user: ${user.uid}');
      debugPrint('FCM: Data saved: ${deviceInfo.keys.toList()}');
      debugPrint('FCM: Role: ${deviceInfo['role']}, Designation: ${deviceInfo['designation']}');
      
      // Listen for token refresh and update automatically
      _messaging.onTokenRefresh.listen((newToken) async {
        await _updateTokenInFirestore(newToken);
      });
      
    } catch (e) {
      debugPrint('FCM: Error saving token to Firestore: $e');
    }
  }

  /// Update token in Firestore when it refreshes
  static Future<void> _updateTokenInFirestore(String newToken) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Check if technician document exists before updating
      final technicianDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (!technicianDoc.exists) {
        debugPrint('FCM: Technician document does not exist, skipping token update');
        return;
      }

      // Update in technicians collection only
      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .update({
        'fcmToken': newToken,
        'role': 'tech',
        'designation': 'Technician',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('FCM: Token refreshed and updated in technicians collection');
    } catch (e) {
      debugPrint('FCM: Error updating token in Firestore: $e');
    }
  }

  /// Register background handler
  static Future<void> _registerBackgroundHandler() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Setup foreground listener
  static void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM: Foreground message received');
      _showLocalNotification(message);
    });
  }

  /// Setup background/terminated listener
  static void _setupBackgroundListener() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM: Background message opened');
      _handleNotificationTap(message.data['srId']);
    });
  }

  /// Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    try {
      final data = message.data;
      final srId = data['srId'] ?? 'Unknown';
      final comments = data['comments'] ?? message.notification?.body ?? '';
      final title = message.notification?.title ?? 'New Service Request';
      final type = data['type'] ?? 'service_assignment';

      // Create notification actions based on type
      List<AndroidNotificationAction> actions = [];
      
      if (type == 'service_assignment') {
        actions = [
          const AndroidNotificationAction('accept', 'Accept'),
          const AndroidNotificationAction('delay', 'Delay'),
          const AndroidNotificationAction('view_details', 'View Details'),
        ];
      } else if (type == 'service_acknowledgment_completed') {
        actions = [
          const AndroidNotificationAction('view_details', 'View Details'),
          const AndroidNotificationAction('mark_complete', 'Mark Complete'),
        ];
      } else {
        actions = [
          const AndroidNotificationAction('view_details', 'View Details'),
        ];
      }

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'service_requests',
        'Service Requests',
        channelDescription: 'Notifications for service requests',
        importance: Importance.max,
        priority: Priority.high,
        actions: actions,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      await _localNotifications.show(
        srId.hashCode, // Use hash as notification ID
        title,
        'Request ID: $srId\n$comments',
        NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        ),
        payload: srId,
      );

      debugPrint('FCM: Local notification shown for SR: $srId');
    } catch (e) {
      debugPrint('FCM: Error showing local notification: $e');
    }
  }

  /// Handle notification tap
  static void _handleNotificationTap(String? srId) {
    if (srId == null || srId.isEmpty) return;
    
    debugPrint('FCM: Notification tapped for SR: $srId');
    
    // Call the navigation callback
    if (onNotificationTapped != null) {
      onNotificationTapped!(srId);
    }
  }

  /// Handle service request actions from notification
  static void _handleServiceRequestAction(String action, String? srId) {
    if (srId == null || srId.isEmpty) return;
    
    debugPrint('FCM: Service request action $action for SR: $srId');
    
    // For now, just navigate to service details
    // In a real app, you might want to show a confirmation dialog
    if (onNotificationTapped != null) {
      onNotificationTapped!(srId);
    }
  }

  /// Set navigation callback
  static void setNavigationCallback(Function(String) callback) {
    onNotificationTapped = callback;
  }

  /// Clear all notifications
  static Future<void> clearAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get FCM token
  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  /// Checks and updates service requests that have passed their deadline
  /// Updates status from 'pending' or 'in_progress' to 'delayed'
/// Enhanced method to check and update delayed service requests with better error handling
static Future<void> checkAndUpdateDelayedServiceRequests(String employeeId) async {
  try {
    debugPrint('FCM: Starting delayed service request check for employeeId: $employeeId');
    
    final DateTime now = DateTime.now();
    debugPrint('FCM: Current time: $now');
    
    // Get all service requests for the employee that are not completed and are accepted
    QuerySnapshot serviceRequestsSnapshot = await FirebaseFirestore.instance
        .collection('serviceRequests')
        .where('serviceDetails.assignedTo', isEqualTo: employeeId)
        .where('isAccepted', isEqualTo: true)
        .where('status', whereIn: ['pending', 'in_progress'])
        .get();

    debugPrint('FCM: Found ${serviceRequestsSnapshot.docs.length} service requests to check');

    List<String> delayedRequestIds = [];
    List<WriteBatch> batches = [];
    WriteBatch currentBatch = FirebaseFirestore.instance.batch();
    int batchCount = 0;
    
    for (QueryDocumentSnapshot doc in serviceRequestsSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final serviceDetails = data['serviceDetails'] as Map<String, dynamic>?;
      
      debugPrint('FCM: Checking service request: ${doc.id}');
      
      if (serviceDetails != null) {
        final deadlineTimestamp = serviceDetails['addressByDate'];
        
        if (deadlineTimestamp != null) {
          DateTime deadline;
          
          // Handle different timestamp formats
          try {
            if (deadlineTimestamp is Timestamp) {
              deadline = deadlineTimestamp.toDate();
            } else if (deadlineTimestamp is String) {
              deadline = DateTime.parse(deadlineTimestamp);
            } else {
              debugPrint('FCM: Unknown deadline format for ${doc.id}: ${deadlineTimestamp.runtimeType}');
              continue;
            }
            
            debugPrint('FCM: Service request ${doc.id} deadline: $deadline');
            
            // Check if deadline has passed
            if (now.isAfter(deadline)) {
              debugPrint('FCM: Service request ${doc.id} is delayed');
              delayedRequestIds.add(doc.id);
              
              // Update the service request status to 'delayed'
              currentBatch.update(doc.reference, {
                'status': 'delayed',
                'serviceDetails.delayedAt': FieldValue.serverTimestamp(),
                'serviceDetails.lastStatusUpdate': FieldValue.serverTimestamp(),
              });
              
              batchCount++;
              
              // Firestore batch limit is 500 operations
              if (batchCount >= 500) {
                batches.add(currentBatch);
                currentBatch = FirebaseFirestore.instance.batch();
                batchCount = 0;
              }
            } else {
              debugPrint('FCM: Service request ${doc.id} is still within deadline');
            }
          } catch (e) {
            debugPrint('FCM: Error parsing deadline for ${doc.id}: $e');
            continue;
          }
        } else {
          debugPrint('FCM: No deadline found for service request: ${doc.id}');
        }
      } else {
        debugPrint('FCM: No serviceDetails found for service request: ${doc.id}');
      }
    }

    // Add the last batch if it has operations
    if (batchCount > 0) {
      batches.add(currentBatch);
    }

    debugPrint('FCM: Found ${delayedRequestIds.length} delayed requests');

    // Execute all batches
    for (int i = 0; i < batches.length; i++) {
      try {
        await batches[i].commit();
        debugPrint('FCM: Batch ${i + 1} committed successfully');
      } catch (e) {
        debugPrint('FCM: Error committing batch ${i + 1}: $e');
      }
    }

    // Create notifications for delayed requests
    if (delayedRequestIds.isNotEmpty) {
      debugPrint('FCM: Creating notifications for ${delayedRequestIds.length} delayed requests');
      await _createDelayedNotifications(employeeId, delayedRequestIds);
    } else {
      debugPrint('FCM: No delayed requests found, skipping notification creation');
    }

    debugPrint('FCM: Successfully processed delayed service requests check');
    
  } catch (e) {
    debugPrint('FCM: Error in checkAndUpdateDelayedServiceRequests: $e');
    debugPrint('FCM: Stack trace: ${StackTrace.current}');
    rethrow;
  }
}/// Creates notifications for delayed service requests - FIXED VERSION
/// Creates notifications for delayed service requests - FIXED VERSION
static Future<void> _createDelayedNotifications(String employeeId, List<String> delayedRequestIds) async {
  try {
    debugPrint('FCM: Creating delayed notifications for employeeId: $employeeId');
    debugPrint('FCM: Delayed request IDs: $delayedRequestIds');
    
    // First, find the technician document using employeeId field, not document ID
    QuerySnapshot technicianQuery = await FirebaseFirestore.instance
        .collection('technicians')
        .where('employeeId', isEqualTo: employeeId)
        .limit(1)
        .get();
    
    if (technicianQuery.docs.isEmpty) {
      debugPrint('FCM: No technician found with employeeId: $employeeId');
      return;
    }
    
    DocumentSnapshot technicianDoc = technicianQuery.docs.first;

    final technicianData = technicianDoc.data() as Map<String, dynamic>;
    final technicianName = technicianData['fullName'] ?? 'Unknown Technician';
    final technicianUID = technicianDoc.id; // Use document ID as UID

    debugPrint('FCM: Technician details - Name: $technicianName, UID: $technicianUID');

    // Create separate notification for admin for each delayed service request
    List<String> createdNotificationIds = [];
    
    for (String srId in delayedRequestIds) {
      try {
        DocumentReference adminNotificationRef = await FirebaseFirestore.instance.collection('notifications').add({
          'type': 'delayed_service_request',
          'title': 'Service Request Overdue - $srId',
          'message': 'SR Request with SR ID - $srId assigned to $technicianName has been delayed. Reassign that immediately.',
          'recipientRole': 'admin',
          'senderId': technicianUID,
          'senderName': technicianName,
          'senderRole': 'technician',
          'data': {
            'employeeId': employeeId,
            'technicianUID': technicianUID,
            'technicianName': technicianName,
            'delayedSrId': srId,
            'action': 'reassign',
          },
          'isRead': false,
          'isActioned': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        createdNotificationIds.add(adminNotificationRef.id);
        debugPrint('FCM: Admin notification created for SR $srId with ID: ${adminNotificationRef.id}');
        
      } catch (e) {
        debugPrint('FCM: Error creating admin notification for SR $srId: $e');
        // Continue with other SRs even if one fails
      }
    }
    
    debugPrint('FCM: Created ${createdNotificationIds.length} admin notifications for delayed SRs');

    // Create notification for the technician
    DocumentReference techNotificationRef = await FirebaseFirestore.instance.collection('notifications').add({
      'type': 'delayed_reminder',
      'title': 'Service Requests Overdue',
      'message': 'You have ${delayedRequestIds.length} service request(s) that have passed their deadline. Please update the status or contact admin for assistance.',
      'recipientId': technicianUID,
      'recipientRole': 'technician',
      'senderId': 'system',
      'senderName': 'System',
      'senderRole': 'system',
      'data': {
        'employeeId': employeeId,
        'technicianUID': technicianUID,
        'delayedRequestIds': delayedRequestIds,
        'delayedCount': delayedRequestIds.length,
      },
      'isRead': false,
      'isActioned': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
    
    debugPrint('FCM: Technician notification created with ID: ${techNotificationRef.id}');
    debugPrint('FCM: Successfully created ${delayedRequestIds.length} delayed notifications');

  } catch (e) {
    debugPrint('FCM: Error creating delayed notifications: $e');
    debugPrint('FCM: Stack trace: ${StackTrace.current}');
    // Don't rethrow here as notification failure shouldn't break the main process
  }
}
  static void _handleServiceAcknowledgmentAction(String action, String? srId) {
    if (srId == null || srId.isEmpty) return;
    
    debugPrint('FCM: Service acknowledgment action $action for SR: $srId');
    
    // Handle different acknowledgment actions
    switch (action) {
      case 'mark_complete':
        // Mark the service acknowledgment as complete in Firestore
        _markServiceAcknowledgmentComplete(srId);
        break;
      case 'view_details':
        // Navigate to service details
        if (onNotificationTapped != null) {
          onNotificationTapped!(srId);
        }
        break;
      default:
        // Default to viewing details
        if (onNotificationTapped != null) {
          onNotificationTapped!(srId);
        }
    }
  }

  /// Mark service acknowledgment as complete
  static Future<void> _markServiceAcknowledgmentComplete(String srId) async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srId)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({
            'adminMarkedComplete': true,
            'adminMarkedCompleteTimestamp': FieldValue.serverTimestamp(),
            'status': 'completed',
          });
        }
      });
      
      debugPrint('FCM: Service acknowledgment marked as complete for SR: $srId');
    } catch (e) {
      debugPrint('FCM: Error marking service acknowledgment complete: $e');
    }
  }
}

// Top-level background handler (required for iOS)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM: Background message received: ${message.messageId}');
  // Minimal processing in background
}

// Top-level background tap handler
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  debugPrint('FCM: Background notification tapped: ${response.payload}');
  // Handle background tap if needed
} 