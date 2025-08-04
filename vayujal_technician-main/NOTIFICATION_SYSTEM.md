# 🔔 Notification System Documentation

## Overview

This document describes the comprehensive notification system implemented for the Vayujal Technician App, supporting real-time notifications between Technicians and Admins using Firebase Cloud Messaging (FCM) and Firestore.

## 🏗️ Architecture

### Components
1. **Flutter App** - Client-side notification handling
2. **Firebase Cloud Messaging (FCM)** - Push notifications
3. **Firestore** - Notification storage and real-time updates
4. **Firebase Cloud Functions** - Server-side notification triggers

## 📱 Features Implemented

### 1. Service Request Notifications
- **Technician receives notification** when assigned a new service request
- **Action buttons**: Accept, Delay, View Details
- **Real-time updates** via FCM and in-app notifications

### 2. Admin Notifications
- **Admin receives notification** when technician accepts/delays service request
- **Admin access request notifications**
- **Real-time FCM delivery** to all admin users

### 3. In-App Notification Center
- **Dedicated notification screen** with action buttons
- **Unread notification indicators**
- **Real-time notification updates**

### 4. Admin Access Requests
- **"Request Admin Access" button** in technician profile
- **Admin notification** when technician requests access

## 🔧 Technical Implementation

### Firestore Collections

#### 1. Notifications Collection
```json
{
  "type": "service_assignment|service_accepted|service_delayed|admin_access_request",
  "title": "Notification Title",
  "message": "Notification message",
  "recipientId": "user_uid",
  "recipientRole": "technician|admin",
  "senderId": "sender_uid",
  "senderName": "Sender Name",
  "data": {
    "srId": "service_request_id",
    "technicianId": "technician_uid",
    "technicianName": "Technician Name"
  },
  "isRead": false,
  "createdAt": "timestamp"
}
```

#### 2. Technicians Collection (Enhanced)
```json
{
  "uid": "user_uid",
  "fullName": "Technician Name",
  "email": "technician@email.com",
  "employeeId": "EMP001",
  "designation": "Technician",
  "mobileNumber": "1234567890",
  "profileImageUrl": "https://...",
  "isProfileComplete": true,
  "role": "tech",
  "platform": "android",
  "osVersion": "Android 12",
  "fcmToken": "fcm_token_here",
  "createdAt": "timestamp",
  "updatedAt": "timestamp"
}
```

#### 3. Accepted Requests Subcollection
```
/technicians/{technicianId}/acceptedRequests/{srId}
{
  "srId": "service_request_id",
  "acceptedAt": "timestamp",
  "status": "accepted"
}
```

### Firebase Cloud Functions

#### 1. `notifyTechnicianOnAssignment`
- **Trigger**: Service request document changes
- **Action**: Sends FCM notification to assigned technician
- **Features**: Handles new assignments and reassignments

#### 2. `notifyAdminOnTechnicianResponse`
- **Trigger**: Notification document creation
- **Action**: Sends FCM notification to all admin users
- **Features**: Processes service acceptance/delay and admin access requests

#### 3. `createInAppNotification`
- **Trigger**: Service request document changes
- **Action**: Creates in-app notification in Firestore
- **Features**: Real-time notification center updates

### Flutter Services

#### 1. `NotificationService` (Enhanced)
- **FCM token management**
- **Local notification handling**
- **Background/foreground message processing**
- **Action button support**

#### 2. `NotificationActionsService` (New)
- **Service request acceptance/delay**
- **Admin access requests**
- **Notification management**
- **Accepted requests tracking**

## 🎯 User Flows

### Service Request Assignment Flow
1. **Admin assigns** service request to technician
2. **Cloud Function triggers** FCM notification to technician
3. **Technician receives** push notification with Accept/Delay buttons
4. **Technician responds** via notification or in-app
5. **Admin receives** notification of technician's response
6. **Service request status** updates in Firestore

### Admin Access Request Flow
1. **Technician clicks** "Request Admin Access" in profile
2. **System creates** notification for admin
3. **Admin receives** FCM notification
4. **Admin can review** and respond to request

## 📋 Testing Scenarios

| Action | Sender | Receiver | Notification Type | Expected Result |
|--------|--------|----------|-------------------|-----------------|
| Assign service request | Admin | Technician | `service_assignment` | Technician receives FCM + in-app notification |
| Accept service request | Technician | Admin | `service_accepted` | Admin receives FCM notification |
| Delay service request | Technician | Admin | `service_delayed` | Admin receives FCM notification |
| Request admin access | Technician | Admin | `admin_access_request` | Admin receives FCM notification |

## 🚀 Setup Instructions

### 1. Firebase Configuration
```bash
# Deploy Cloud Functions
cd functions
npm install
firebase deploy --only functions
```

### 2. Flutter App Setup
```dart
// Initialize notification service in main.dart
await NotificationService.initialize(context);

// Set navigation callback
NotificationService.setNavigationCallback((String srId) {
  // Navigate to service details
});
```

### 3. FCM Token Management
- Tokens are automatically saved on app initialization
- Token refresh is handled automatically
- Tokens are stored in both `admins` and `technicians` collections

## 🔒 Security Rules

### Firestore Rules
```javascript
// Notifications collection
match /notifications/{notificationId} {
  allow read: if request.auth != null && 
    (resource.data.recipientId == request.auth.uid || 
     resource.data.recipientRole == 'admin');
  allow create: if request.auth != null;
  allow update: if request.auth != null && 
    resource.data.recipientId == request.auth.uid;
}

// Technicians collection
match /technicians/{technicianId} {
  allow read, write: if request.auth != null && 
    request.auth.uid == technicianId;
}
```

## 📊 Monitoring & Analytics

### Cloud Function Logs
- All notification events are logged
- Error handling with detailed error messages
- Success/failure tracking

### FCM Delivery Tracking
- Message delivery status
- Token validity checks
- Retry mechanisms for failed deliveries

## 🛠️ Troubleshooting

### Common Issues

1. **FCM Token Not Saved**
   - Check Firebase Auth state
   - Verify Firestore permissions
   - Check network connectivity

2. **Notifications Not Received**
   - Verify FCM token is valid
   - Check notification permissions
   - Review Cloud Function logs

3. **Action Buttons Not Working**
   - Verify notification channel setup
   - Check action button configuration
   - Review notification tap handling

### Debug Commands
```bash
# Check Cloud Function logs
firebase functions:log

# Test FCM token
firebase functions:shell
```

## 🔄 Future Enhancements

1. **Notification Preferences**
   - User-configurable notification settings
   - Quiet hours support
   - Notification categories

2. **Rich Notifications**
   - Image attachments
   - Custom notification sounds
   - Advanced action buttons

3. **Analytics Integration**
   - Notification engagement tracking
   - Response time analytics
   - User behavior insights

4. **Multi-language Support**
   - Localized notification messages
   - Language-specific templates

## 📞 Support

For technical support or questions about the notification system:
- Check Cloud Function logs for errors
- Verify FCM configuration
- Review Firestore security rules
- Test with sample data

---

**Last Updated**: December 2024
**Version**: 1.0.0 