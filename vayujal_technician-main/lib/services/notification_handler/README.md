# Complete Notification System for Flutter + Firebase

This notification system provides a comprehensive solution for handling both push notifications (FCM) and in-app notifications for a Flutter + Firebase project with Admin and Technician roles.

## 📁 Folder Structure

```
lib/services/notification_handler/
├── fcm_service.dart                    # Firebase Cloud Messaging service
├── in_app_notification_service.dart    # In-app notification management
├── service_request_notifier.dart       # Service request notifications
├── admin_access_notifier.dart          # Admin access & promotion notifications
├── logout_helper.dart                  # Session management & logout
├── notification_handler.dart           # Main unified interface
├── example_usage.dart                  # Usage examples
└── README.md                          # This documentation
```

## 🚀 Quick Start

### 1. Setup FCM Server Key

In `fcm_service.dart`, replace `YOUR_FCM_SERVER_KEY` with your actual FCM server key:

```dart
static const String _serverKey = 'YOUR_ACTUAL_FCM_SERVER_KEY';
```

### 2. Update FCM Token on Login

```dart
// In your login success handler
await NotificationHandler.updateFCMToken(fcmToken);
```

### 3. Check Session Validity on App Start

```dart
// In your main.dart or splash screen
await NotificationExampleUsage.checkSessionValidity(context);
```

## 📋 Features

### ✅ Service Request Notifications

When a technician performs actions on service requests:

- **Accept Service Request**
- **Reject Service Request** 
- **Complete Service Request**
- **Start Service Request**

**Result:** Push notifications + in-app notifications sent to all admins.

### ✅ Admin Access & Promotion

- **Request Admin Access** (Technician → Admin notification)
- **Promote Technician** (Admin action with automatic logout)
- **Reject Admin Access** (Admin action with notification to technician)

### ✅ In-App Notifications

- Real-time notification streams
- Mark as read functionality
- Unread count badges
- Notification management (delete, mark all read)

### ✅ Session Management

- Automatic logout after promotion
- Force logout capabilities
- Session validity checks

## 🔧 Usage Examples

### Service Request Notifications

```dart
// When technician accepts a service request
await NotificationHandler.notifyServiceAccepted(
  serviceRequestId: 'SR123',
  serviceRequestNumber: '123',
);

// When technician rejects a service request
await NotificationHandler.notifyServiceRejected(
  serviceRequestId: 'SR123',
  serviceRequestNumber: '123',
  reason: 'Equipment not available',
);

// When technician completes a service request
await NotificationHandler.notifyServiceCompleted(
  serviceRequestId: 'SR123',
  serviceRequestNumber: '123',
  completionNotes: 'All issues resolved',
);
```

### Admin Access Management

```dart
// Technician requests admin access
await NotificationHandler.requestAdminAccess();

// Admin promotes technician
final success = await NotificationHandler.promoteTechnicianToAdmin(
  technicianUID: 'user123',
);

// Admin rejects technician's request
await NotificationHandler.rejectAdminAccessRequest(
  technicianUID: 'user123',
  reason: 'Insufficient experience',
);
```

### In-App Notifications

```dart
// Get notifications stream
Stream<QuerySnapshot> notificationsStream = 
  NotificationHandler.getNotificationsStream();

// Mark notification as read
await NotificationHandler.markNotificationAsRead('notificationId');

// Get unread count
Stream<int> unreadCount = 
  NotificationHandler.getUnreadNotificationCount();
```

## 🗄️ Firestore Collections

### Technicians Collection
```json
{
  "uid": "user123",
  "email": "tech@example.com",
  "fullName": "John Doe",
  "role": "tech",
  "fcmToken": "FCM_TOKEN_HERE",
  "createdAt": "timestamp",
  "isProfileComplete": true
}
```

### Admin Collection
```json
{
  "uid": "admin123",
  "email": "admin@example.com",
  "fullName": "Admin User",
  "role": "admin",
  "fcmToken": "FCM_TOKEN_HERE",
  "createdAt": "timestamp",
  "promotedBy": "otherAdmin",
  "promotedAt": "timestamp"
}
```

### Notifications Collection
```json
/notifications/{receiverUid}/messages/{notificationId}:
{
  "title": "Service Request Accepted",
  "body": "John Doe has accepted service request #123",
  "type": "service_update",
  "timestamp": "timestamp",
  "isRead": false,
  "additionalData": {
    "action": "accepted",
    "serviceRequestId": "SR123",
    "technicianName": "John Doe"
  }
}
```

## 🔐 Security Rules (Recommended)

### Technicians Collection
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /technicians/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        exists(/databases/$(database)/documents/admin/$(request.auth.uid));
    }
  }
}
```

### Admin Collection
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /admin/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      allow read: if request.auth != null && 
        exists(/databases/$(database)/documents/admin/$(request.auth.uid));
    }
  }
}
```

### Notifications Collection
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /notifications/{userId}/messages/{messageId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## 🎯 Integration Points

### 1. App Startup
```dart
// In main.dart or splash screen
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Check session validity
  await NotificationExampleUsage.checkSessionValidity(context);
  
  runApp(MyApp());
}
```

### 2. Login Success
```dart
// After successful login
await NotificationHandler.updateFCMToken(fcmToken);
```

### 3. Service Request Actions
```dart
// In your service request screens
await NotificationHandler.notifyServiceAccepted(
  serviceRequestId: serviceRequest.id,
  serviceRequestNumber: serviceRequest.number,
);
```

### 4. Admin Access Requests
```dart
// In technician profile or settings
await NotificationHandler.requestAdminAccess();
```

### 5. Admin Promotion Actions
```dart
// In admin dashboard
final success = await NotificationHandler.promoteTechnicianToAdmin(
  technicianUID: selectedTechnician.uid,
);
```

## 🔄 Notification Flow

### Service Request Flow
1. Technician performs action (accept/reject/complete)
2. `NotificationHandler` sends push notification to all admins
3. In-app notification saved to Firestore for all admins
4. Admins receive real-time updates

### Admin Access Flow
1. Technician requests admin access
2. All admins receive push + in-app notifications
3. Admin approves/rejects request
4. Technician receives notification of decision
5. If approved, technician is automatically logged out

## 🛠️ Customization

### Custom Notification Types
Add new notification types in `in_app_notification_service.dart`:

```dart
// Add to the type field
'custom_type': 'your_custom_type'
```

### Custom FCM Data
Modify the `data` parameter in FCM calls to include custom fields:

```dart
await FCMService.sendNotificationToUser(
  fcmToken: token,
  title: 'Custom Title',
  body: 'Custom Body',
  data: {
    'custom_field': 'custom_value',
    'action': 'custom_action',
  },
);
```

## 🐛 Troubleshooting

### Common Issues

1. **FCM Token Not Updating**
   - Ensure `updateFCMToken()` is called after login
   - Check Firebase configuration

2. **Notifications Not Sending**
   - Verify FCM server key is correct
   - Check network connectivity
   - Ensure user has valid FCM token

3. **In-App Notifications Not Showing**
   - Check Firestore security rules
   - Verify collection structure
   - Check stream subscription

4. **Automatic Logout Not Working**
   - Ensure `shouldForceLogout()` is called regularly
   - Check session validity checks

### Debug Logs
All services include comprehensive logging. Check console for:
- FCM send status
- Firestore operation results
- Error messages with context

## 📱 UI Integration

See `example_usage.dart` for complete UI examples including:
- Notification list widgets
- Badge counters
- Session management
- Error handling

## 🔄 Updates & Maintenance

### Adding New Notification Types
1. Add new method to `NotificationHandler`
2. Update `service_request_notifier.dart` or `admin_access_notifier.dart`
3. Add corresponding UI components
4. Update Firestore security rules if needed

### Performance Optimization
- Use batch operations for multiple notifications
- Implement notification pagination for large lists
- Cache frequently accessed data
- Use offline persistence for critical notifications

---

**Ready to use!** This system provides a complete, modular notification solution for your Flutter + Firebase project. 