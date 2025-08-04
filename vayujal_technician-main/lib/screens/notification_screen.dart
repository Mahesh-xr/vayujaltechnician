import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/navigation/bottom_navigation.dart';
import 'package:vayujal_technician/pages/service_details_page.dart';
import 'package:vayujal_technician/services/notification_actions_service.dart';
import 'package:vayujal_technician/services/notification_handler/admin_access_notifier.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  
  // Track which notifications have been acted upon
  final Set<String> _actedNotifications = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Notifications',
        style: TextStyle(
          color: Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),),
        
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
         
          FutureBuilder<bool>(
            future: _checkIfUserIsAdmin(),
            builder: (context, adminSnapshot) {
              if (adminSnapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox.shrink();
              }

              
              return StreamBuilder<QuerySnapshot>(
                stream: _getUnreadNotificationStream(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    unreadCount = snapshot.data!.docs.length;
                  }

                  return unreadCount > 0
                      ? TextButton.icon(
                          onPressed: _markAllAsRead,
                          icon: const Icon(Icons.done_all, color: Colors.blue),
                          label: Text(
                            'Mark All Read',
                            style: TextStyle(color: Colors.blue),
                          ),
                        )
                      : const SizedBox.shrink();
                },
              );
            },
          ),
        
        
        ],
      ),
      body: _buildNotificationList(),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 3, // Notification tab index
        onTap: (currentIndex) => BottomNavigation.navigateTo(currentIndex, context),
      ),
    );
  }

  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getNotificationStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final notifications = snapshot.data?.docs ?? [];

        if (notifications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none,
                  size: 64,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'No notifications yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 20),
                
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index].data() as Map<String, dynamic>;
            final notificationId = notifications[index].id;
            final isRead = notification['isRead'] ?? false;
            final type = notification['type'] ?? '';
            final title = notification['title'] ?? '';
            final message = notification['message'] ?? '';
            final createdAt = notification['createdAt'] as Timestamp?;
            final isActioned = notification['isActioned'] ?? false;

            // Debug print to see notification structure
            print('DEBUG: Notification type: $type, title: $title, data: ${notification['data']}');

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isRead ? Colors.grey.shade300 : Colors.blue.shade300,
                    width: isRead ? 1 : 2,
                  ),
                ),
                child: InkWell(
                  onTap: () => _markNotificationAsRead(notificationId),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isRead ? Colors.grey[600] : Colors.black87,
                                ),
                              ),
                            ),
                            if (!isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          message,
                          style: TextStyle(
                            fontSize: 14,
                            color: isRead ? Colors.grey[600] : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(createdAt ?? Timestamp.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            if (!isRead)
                              TextButton(
                                onPressed: () => _markNotificationAsRead(notificationId),
                                child: const Text(
                                  'Mark as Read',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        
                        // Action buttons for different notification types
                        if (type == 'service_assignment' && !isActioned)
                          _buildServiceRequestActions(notificationId, notification['serviceRequestId'] ?? '', notification, isRead: isRead),
                        
                        // Action buttons for admin access request
                        if (type == 'admin_access_request')
                          _buildAdminAccessActions(notificationId, notification),
                        
                        // Action buttons for admin role acceptance
                        if (type == 'admin_role_acceptance')
                          _buildAdminRoleAcceptanceActions(notificationId, notification),
                        
                        // Action buttons for admin request response
                        if (type == 'admin_request_response')
                          _buildAdminRequestResponseActions(notificationId, notification, isRead: isRead),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Get appropriate notification stream based on user role
  Stream<QuerySnapshot> _getNotificationStream() {
    final currentUserUID = _auth.currentUser?.uid;
    
    // For technician users, get notifications with userId OR recipientId
    print('DEBUG: Querying technician notifications with userId: $currentUserUID');
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: currentUserUID)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get appropriate unread notification stream based on user role
  Stream<QuerySnapshot> _getUnreadNotificationStream() {
  
    // For technician users, get unread notifications with userId
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: _auth.currentUser?.uid)
        .where('isRead', isEqualTo: false)
        .snapshots();
  }

  // Check if current user is admin
  Future<bool> _checkIfUserIsAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('admins')
          .doc(user.uid)
          .get();
      
      return doc.exists;
    } catch (e) {
      print('Error checking if user is admin: $e');
      return false;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll see notifications here when you receive\nservice requests or updates',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification, String notificationId) {
    final type = notification['type'] ?? '';
    final title = notification['title'] ?? 'Notification';
    final message = notification['message'] ?? '';
    final isRead = notification['isRead'] ?? false;
    final createdAt = notification['createdAt'] as Timestamp?;
    final srId = notification['serviceRequestId'];
   


    return GestureDetector(
      onTap: () => _handleNotificationTap(notificationId, srId, type),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isRead ? 1 : 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isRead ? Colors.grey[300]! : Colors.blue[200]!,
            width: isRead ? 1 : 2,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: isRead ? Colors.white : Colors.blue[50],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon and timestamp
                Row(
                  children: [
                    _getNotificationIcon(type),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w600,
                              color: isRead ? Colors.grey[700] : Colors.black87,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              _formatTimestamp(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!isRead)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Message
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                
                // Action buttons for service requests
                if (type == 'service_assignment' )
                  _buildServiceRequestActions(notificationId, srId, notification, isRead: isRead),
                
                // Action buttons for admin access request
                if (type == 'admin_access_request')
                  _buildAdminAccessActions(notificationId, notification),
                
                // Action buttons for admin role acceptance
                if (type == 'admin_role_acceptance')
                  _buildAdminRoleAcceptanceActions(notificationId, notification),
                
                // Action buttons for admin request response
                if (type == 'admin_request_response')
                  _buildAdminRequestResponseActions(notificationId, notification, isRead: isRead),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'service_assignment':
        iconData = Icons.assignment;
        iconColor = Colors.blue;
        break;
      case 'service_accepted':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case 'service_delayed':
        iconData = Icons.schedule;
        iconColor = Colors.orange;
        break;
      case 'admin_access_request':
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.purple;
        break;
      case 'admin_request_response':
        iconData = Icons.admin_panel_settings;
        iconColor = Colors.green;
        break;
      case 'delayed_reminder':
        iconData = Icons.warning;
        iconColor = Colors.red;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  Widget _buildServiceRequestActions(String notificationId, String srId, Map<String, dynamic> notification, {required bool isRead}) {
  // Check if buttons should be disabled based on action taken, not read status
  final isActioned = notification['isActioned'] ?? false;
  
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isActioned ? null : () => _acceptServiceRequest(srId, notificationId),
                icon: const Icon(Icons.check, size: 16),
                label: const Text('Accept'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActioned ? Colors.grey : Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isActioned ? null : () => _rejectServiceRequest(srId, notificationId),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Reject'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isActioned ? Colors.grey : Colors.red,
                  side: BorderSide(color: isActioned ? Colors.grey : Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (isActioned)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Action completed',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    ),
  );
}


  Widget _buildAdminAccessActions(String notificationId, Map<String, dynamic> notification) {
    final isOwnRequest = notification['senderId'] == _auth.currentUser?.uid;
    final isActioned = notification['isActioned'] ?? false;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isOwnRequest)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.purple.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.purple[700], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your admin access request is pending review by administrators.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.purple[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            // Admin action buttons for admin access requests
            FutureBuilder<bool>(
              future: _checkIfUserIsAdmin(),
              builder: (context, adminSnapshot) {
                if (adminSnapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }

                final isAdmin = adminSnapshot.data ?? false;
                
                if (isAdmin && !isActioned) {
                  final data = notification['data'] as Map<String, dynamic>?;
                  final technicianUID = data?['technicianUID'] ?? '';
                  final technicianName = data?['technicianName'] ?? 'Unknown Technician';
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Admin Access Request',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.purple[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _approveAdminAccess(notificationId, technicianUID, technicianName),
                              icon: const Icon(Icons.check, size: 16),
                              label: const Text('Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _rejectAdminAccess(notificationId, technicianUID, technicianName),
                              icon: const Icon(Icons.close, size: 16),
                              label: const Text('Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: const BorderSide(color: Colors.red),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                } else if (isAdmin && isActioned) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.grey[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Action completed',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Non-admin users see the request access button
                  return Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _requestAdminAccess(notificationId),
                          icon: const Icon(Icons.admin_panel_settings, size: 16),
                          label: const Text('Request Access'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.purple,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAdminRoleAcceptanceActions(String notificationId, Map<String, dynamic> notification) {
    final isActioned = notification['isActioned'] ?? false;
    final action = notification['data']?['action'] ?? '';
    
    // Debug prints
    print('DEBUG: _buildAdminRoleAcceptanceActions called');
    print('DEBUG: isActioned: $isActioned, action: $action');
    
    // Only show buttons if it's a role offer (not already accepted/rejected)
    if (action != 'role_offered' || isActioned) {
      print('DEBUG: Not showing buttons - action: $action, isActioned: $isActioned');
      return const SizedBox.shrink();
    }

    print('DEBUG: Showing admin role acceptance buttons');
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Role Offer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.purple[700],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _acceptAdminRoleOffer(notificationId, notification),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Accept Role'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _declineAdminRoleOffer(notificationId, notification),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Decline'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _acceptAdminRoleOffer(String notificationId, Map<String, dynamic> notification) async {
    if (!mounted) return;

    try {
      final data = notification['data'] as Map<String, dynamic>;
      final technicianUID = data['technicianUID'] as String;
      final technicianName = data['technicianName'] as String;
      final approvedByAdmin = data['approvedBy'] as String;

      // Mark notification as actioned
      await _markNotificationAsActioned(notificationId);
      setState(() {
        _actedNotifications.add(notificationId);
      });

      // Accept the admin role
      await AdminAccessNotifier.acceptAdminRole(
        technicianUID: technicianUID,
        technicianName: technicianName,
        approvedByAdmin: approvedByAdmin,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin role accepted! You will be logged out and can no longer use this technician app.'),
            backgroundColor: Colors.green,
          ),
        );

        // Logout after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            FirebaseAuth.instance.signOut();
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting admin role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineAdminRoleOffer(String notificationId, Map<String, dynamic> notification) async {
    if (!mounted) return;

    try {
      final data = notification['data'] as Map<String, dynamic>;
      final technicianUID = data['technicianUID'] as String;
      final technicianName = data['technicianName'] as String;
      final approvedByAdmin = data['approvedBy'] as String;

      // Mark notification as actioned
      await _markNotificationAsActioned(notificationId);
      setState(() {
        _actedNotifications.add(notificationId);
      });

      // Decline the admin role
      await AdminAccessNotifier.rejectAdminRole(
        technicianUID: technicianUID,
        technicianName: technicianName,
        approvedByAdmin: approvedByAdmin,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Admin role declined. You will remain as a technician.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error declining admin role: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _approveAdminAccess(String notificationId, String technicianUID, String technicianName) async {
    if (!mounted) return;

    try {
      // Mark notification as actioned
      await _markNotificationAsActioned(notificationId);
      setState(() {
        _actedNotifications.add(notificationId);
      });

      // Show approval dialog and create notification
      await NotificationActionsService.respondToAdminAccessRequest(
        context: context,
        technicianUID: technicianUID,
        status: 'approved',
      );

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error approving admin access: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectAdminAccess(String notificationId, String technicianUID, String technicianName) async {
    if (!mounted) return;

    try {
      // Show rejection dialog
      final reason = await showDialog<String>(
        context: context,
        builder: (BuildContext context) {
          String? rejectionReason;
          return AlertDialog(
            title: const Text('Reject Admin Access'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Are you sure you want to reject admin access for:'),
                const SizedBox(height: 8),
                Text(
                  technicianName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Reason for rejection (optional)',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    rejectionReason = value;
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(rejectionReason),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Reject'),
              ),
            ],
          );
        },
      );

      if (reason != null) {
        // Mark notification as actioned
        await _markNotificationAsActioned(notificationId);
        setState(() {
          _actedNotifications.add(notificationId);
        });

        // Send rejection notification
        await NotificationActionsService.respondToAdminAccessRequest(
          context: context,
          technicianUID: technicianUID,
          status: 'rejected',
          reason: reason.isEmpty ? null : reason,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Admin access rejected for $technicianName'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting admin access: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _acceptServiceRequest(String srId, String notificationId) async {
    if (!mounted) return;

    try {
      final success = await NotificationActionsService.acceptServiceRequest(srId);
      
      if (success) {
        // Mark notification as actioned (buttons will be disabled)
        await _markNotificationAsActioned(notificationId);
        setState(() {
          _actedNotifications.add(notificationId); // Mark as acted upon
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service request $srId added to the service pending request'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to accept service request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting service request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectServiceRequest(String srId, String notificationId) async {
    if (!mounted) return;

    try {
      final success = await NotificationActionsService.rejectServiceRequest(srId);
      
      if (success) {
        // Mark notification as actioned (buttons will be disabled)
        await _markNotificationAsActioned(notificationId);
        setState(() {
          _actedNotifications.add(notificationId); // Mark as acted upon
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Service request $srId rejected.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to reject service request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error rejecting service request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _requestAdminAccess(String notificationId) async {
    if (!mounted) return;

    try {
      final success = await NotificationActionsService.requestAdminAccess();
      
      if (success) {
        // Mark notification as actioned (buttons will be disabled)
        await _markNotificationAsActioned(notificationId);
        setState(() {
          _actedNotifications.add(notificationId); // Mark as acted upon
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Admin access request sent successfully!'),
              backgroundColor: Colors.purple,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to send admin access request. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending admin access request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleNotificationTap(String notificationId, String? srId, String type) async {
    // Mark notification as read
    await _markNotificationAsRead(notificationId);
    
    if (srId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ServiceDetailsPage(serviceRequestId: srId),
        ),
      );
    } else if (type == 'admin_access_request') {
      // For admin access request, you might navigate to a different screen or show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin access request notification tapped.'),
          backgroundColor: Colors.purple,
        ),
      );
    } else if (type == 'admin_request_response') {
      // For admin request response, show a message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin request response notification tapped.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }


  String _formatTimestamp(Timestamp timestamp) {
    final now = DateTime.now();
    final date = timestamp.toDate();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  Future<void> _markNotificationAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isRead': true,
      });
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  Future<void> _markNotificationAsActioned(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'isActioned': true,
        'actionedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error marking notification as actioned: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final batch = _firestore.batch();
      final unreadNotifications = await _firestore
          .collection('notifications')
          .where('recipientId', isEqualTo: _auth.currentUser?.uid)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in unreadNotifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error marking notifications as read: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

Widget _buildAdminRequestResponseActions(String notificationId, Map<String, dynamic> notification, {required bool isRead}) {
  // Fix: Check both 'action' and 'status' in the data field
  final data = notification['data'] as Map<String, dynamic>?;
  final action = data?['action'] ?? data?['status'] ?? '';
  final isActioned = notification['isActioned'] ?? false;
  
  print('DEBUG: _buildAdminRequestResponseActions - action/status: $action, isActioned: $isActioned');
  
  return Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (action == 'approved' && !isActioned)
          // Show acceptance/rejection buttons for approved admin access
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Access Approved',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You have been approved for admin access. Do you want to accept the admin role?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptAdminRoleFromApproval(notificationId, notification),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept Admin Role'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _declineAdminRoleFromApproval(notificationId, notification),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )
        else if (action == 'approved' && isActioned)
          // Show that action has been completed
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Admin role decision completed.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        else if (action == 'rejected')
          // Show rejection message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.cancel, color: Colors.red[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your admin access request has been rejected.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

// Add these new methods to handle the admin role acceptance from approval notification
Future<void> _acceptAdminRoleFromApproval(String notificationId, Map<String, dynamic> notification) async {
  if (!mounted) return;

  try {
    final data = notification['data'] as Map<String, dynamic>;
    final technicianId = data['technicianId'] as String;
    final technicianName = data['technicianName'] as String;

    // Mark notification as actioned
    await _markNotificationAsActioned(notificationId);
    setState(() {
      _actedNotifications.add(notificationId);
    });

    // Update technician role to tech-admin in Firestore
    await _firestore.collection('technicians').doc(technicianId).update({
      'role': 'tech-admin',
      'promotedAt': FieldValue.serverTimestamp(),
      'promotedBy': data['processedBy'],
    });

    

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin role accepted! You will be logged out and can now use the admin app.'),
          backgroundColor: Colors.green,
        ),
      );

      // Logout after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          FirebaseAuth.instance.signOut();
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      });
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error accepting admin role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

Future<void> _declineAdminRoleFromApproval(String notificationId, Map<String, dynamic> notification) async {
  if (!mounted) return;

  try {
    final data = notification['data'] as Map<String, dynamic>;
    final technicianId = data['technicianId'] as String;
    final technicianName = data['technicianName'] as String;

    // Mark notification as actioned
    await _markNotificationAsActioned(notificationId);
    setState(() {
      _actedNotifications.add(notificationId);
    });

    // Send notification to admin about role decline
    await _firestore.collection('notifications').add({
      'type': 'admin_role_declined',
      'title': 'Admin Role Declined',
      'message': 'Technician $technicianName has declined the admin role promotion.',
      'recipientRole': 'admin',
      'senderId': technicianId,
      'senderName': technicianName,
      'senderRole': 'technician',
      'isRead': false,
      'isActioned': false,
      'createdAt': FieldValue.serverTimestamp(),
      'data': {
        'technicianId': technicianId,
        'technicianName': technicianName,
        'originalRequestId': data['requestId'],
      },
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin role declined. You will remain as a technician.'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error declining admin role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
 
} 