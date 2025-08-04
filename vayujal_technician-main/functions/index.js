/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");
const admin = require('firebase-admin');

// Initialize Firebase Admin
admin.initializeApp();

/**
 * Cloud Function to notify technician when a service request is assigned
 * Triggers on serviceRequests/{docId} document changes
 */
exports.notifyTechnicianOnAssignment = onDocumentWritten('serviceRequests/{docId}', async (event) => {
  const change = event.data;
  const context = event.context;
    try {
      const after = change.after.exists ? change.after.data() : null;
      const before = change.before.exists ? change.before.data() : null;

      // If document was deleted, do nothing
      if (!after) {
        console.log('Document deleted, no notification needed');
        return null;
      }

      const afterAssignedTo = after.serviceDetails && after.serviceDetails.assignedTo;
      const beforeAssignedTo = before && before.serviceDetails && before.serviceDetails.assignedTo;

      // Check if this is a new assignment or reassignment
      const isFirstAssignment = !before && afterAssignedTo;
      const isReassignment = before && afterAssignedTo && (afterAssignedTo !== beforeAssignedTo);

      if (!isFirstAssignment && !isReassignment) {
        console.log('No relevant assignment change detected');
        return null;
      }

      console.log(`Service request assignment detected: ${isFirstAssignment ? 'New' : 'Reassignment'}`);
      console.log(`Assigned to employee ID: ${afterAssignedTo}`);

      // Find technician's FCM token - try multiple approaches
      let fcmToken = null;
      let technicianDoc = null;

      // Approach 1: Search in admins collection by employeeId
      console.log('Searching in admins collection...');
      const adminsRef = admin.firestore().collection('admins');
      const adminQuery = await adminsRef
        .where('employeeId', '==', afterAssignedTo)
        .limit(1)
        .get();

      if (!adminQuery.empty) {
        technicianDoc = adminQuery.docs[0];
        fcmToken = technicianDoc.get('fcmToken');
        console.log(`Found technician in admins collection: ${technicianDoc.id}`);
        console.log('Technician data:', technicianDoc.data());
      }

      // Approach 2: If not found, search in technicians collection
      if (!fcmToken) {
        console.log('Searching in technicians collection...');
        const techniciansRef = admin.firestore().collection('technicians');
        const techQuery = await techniciansRef
          .where('employeeId', '==', afterAssignedTo)
          .limit(1)
          .get();

        if (!techQuery.empty) {
          technicianDoc = techQuery.docs[0];
          fcmToken = technicianDoc.get('fcmToken');
          console.log(`Found technician in technicians collection: ${technicianDoc.id}`);
          console.log('Technician data:', technicianDoc.data());
        }
      }

      // Approach 3: If still not found, try searching by UID (if assignedTo is a UID)
      if (!fcmToken) {
        console.log('Trying to find by UID...');
        try {
          const uidDoc = await adminsRef.doc(afterAssignedTo).get();
          if (uidDoc.exists) {
            technicianDoc = uidDoc;
            fcmToken = uidDoc.get('fcmToken');
            console.log(`Found technician by UID: ${afterAssignedTo}`);
            console.log('Technician data:', uidDoc.data());
          }
        } catch (e) {
          console.log('No technician found by UID');
        }
      }

      // Approach 4: Try technicians collection by UID
      if (!fcmToken) {
        console.log('Trying technicians collection by UID...');
        try {
          const techUidDoc = await admin.firestore().collection('technicians').doc(afterAssignedTo).get();
          if (techUidDoc.exists) {
            technicianDoc = techUidDoc;
            fcmToken = techUidDoc.get('fcmToken');
            console.log(`Found technician by UID in technicians: ${afterAssignedTo}`);
            console.log('Technician data:', techUidDoc.data());
          }
        } catch (e) {
          console.log('No technician found by UID in technicians collection');
        }
      }

      if (!fcmToken) {
        console.error(`❌ No FCM token found for technician with employeeId: ${afterAssignedTo}`);
        if (technicianDoc) {
          console.log('Available fields in technician document:', Object.keys(technicianDoc.data()));
        }
        return null;
      }

      // Prepare notification data
      const srId = (after.serviceDetails && after.serviceDetails.srId) || context.params.docId;
      const comments = (after.serviceDetails && after.serviceDetails.comments) || '';
      const commentsPreview = comments.length > 50 ? comments.substring(0, 50) + '...' : comments;
      const assignedBy = (after.serviceDetails && after.serviceDetails.assignedBy) || 'Admin';

      // Create FCM message
      const message = {
        token: fcmToken,
        notification: {
          title: 'New Service Request Assigned',
          body: `SR ID: ${srId}\nAssigned by: ${assignedBy}\n${commentsPreview}`,
        },
        data: {
          srId: srId,
          comments: comments,
          assignedBy: assignedBy,
          type: 'service_assignment',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'service_requests',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the notification
      const response = await admin.messaging().send(message);
      console.log(`✅ Notification sent successfully to technician (employeeId: ${afterAssignedTo})`);
      console.log(`Message ID: ${response}`);
      console.log(`SR ID: ${srId}`);

      return null;
    } catch (error) {
      console.error('❌ Error in notifyTechnicianOnAssignment:', error);
      return null;
    }
  });

/**
 * Cloud Function to notify technician when service request status changes
 */
exports.notifyTechnicianOnStatusChange = onDocumentWritten('serviceRequests/{docId}', async (event) => {
  const change = event.data;
  const context = event.context;
    try {
      const before = change.before.data();
      const after = change.after.data();

      const beforeStatus = before.status;
      const afterStatus = after.status;
      const assignedTo = after.serviceDetails && after.serviceDetails.assignedTo;

      // Only notify if status changed and there's an assigned technician
      if (beforeStatus === afterStatus || !assignedTo) {
        return null;
      }

      console.log(`Service request status changed from ${beforeStatus} to ${afterStatus}`);

      // Find technician's FCM token
      let fcmToken = null;

      // Try admins collection first
      const adminsRef = admin.firestore().collection('admins');
      const techQuery = await adminsRef
        .where('employeeId', '==', assignedTo)
        .where('designation', '==', 'Technician')
        .limit(1)
        .get();

      if (!techQuery.empty) {
        fcmToken = techQuery.docs[0].get('fcmToken');
      } else {
        // Try technicians collection
        const techniciansRef = admin.firestore().collection('technicians');
        const techQuery2 = await techniciansRef
          .where('employeeId', '==', assignedTo)
          .limit(1)
          .get();

        if (!techQuery2.empty) {
          fcmToken = techQuery2.docs[0].get('fcmToken');
        }
      }

      if (!fcmToken) {
        console.error(`No FCM token found for technician with employeeId: ${assignedTo}`);
        return null;
      }

      const srId = (after.serviceDetails && after.serviceDetails.srId) || context.params.docId;

      // Create status update notification
      const message = {
        token: fcmToken,
        notification: {
          title: 'Service Request Status Updated',
          body: `SR ID: ${srId} is now ${afterStatus}`,
        },
        data: {
          srId: srId,
          status: afterStatus,
          type: 'status_update',
        },
        android: {
          priority: 'normal',
          notification: {
            channelId: 'service_requests',
            priority: 'normal',
          },
        },
      };

      const response = await admin.messaging().send(message);
      console.log(`✅ Status update notification sent for SR: ${srId}`);

      return null;
    } catch (error) {
      console.error('❌ Error in notifyTechnicianOnStatusChange:', error);
      return null;
    }
  });

/**
 * Cloud Function to notify admin when technician responds to service request
 */
exports.notifyAdminOnTechnicianResponse = onDocumentWritten('notifications/{notificationId}', async (event) => {
  const snap = event.data.after;
  const context = event.context;
    try {
      const notificationData = snap.data();
      const type = notificationData.type;
      const recipientRole = notificationData.recipientRole;

      // Only process notifications for admin
      if (recipientRole !== 'admin') {
        return null;
      }

      // Only process specific notification types
      if (!['service_accepted', 'service_delayed', 'admin_access_request', 'service_acknowledgment_completed'].includes(type)) {
        return null;
      }

      console.log(`Processing admin notification: ${type}`);

      // Get all admin FCM tokens
      const adminsRef = admin.firestore().collection('admins');
      const adminQuery = await adminsRef
        .where('role', '==', 'admin')
        .get();

      if (adminQuery.empty) {
        console.log('No admin users found');
        return null;
      }

      const adminTokens = [];
      adminQuery.docs.forEach(doc => {
        const fcmToken = doc.get('fcmToken');
        if (fcmToken) {
          adminTokens.push(fcmToken);
        }
      });

      if (adminTokens.length === 0) {
        console.log('No admin FCM tokens found');
        return null;
      }

      // Prepare notification message
      const title = notificationData.title || 'New Notification';
      const message = notificationData.message || '';
      const data = notificationData.data || {};

      const fcmMessage = {
        notification: {
          title: title,
          body: message,
        },
        data: {
          ...data,
          type: type,
          notificationId: context.params.notificationId,
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'admin_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send to all admin users
      const sendPromises = adminTokens.map(token => {
        const messageWithToken = { ...fcmMessage, token };
        return admin.messaging().send(messageWithToken);
      });

      const responses = await Promise.all(sendPromises);
      console.log(`✅ Admin notification sent to ${adminTokens.length} admin(s)`);
      console.log(`Type: ${type}, Message: ${message}`);

      return null;
    } catch (error) {
      console.error('❌ Error in notifyAdminOnTechnicianResponse:', error);
      return null;
    }
  });

/**
 * Cloud Function to create in-app notifications when service requests are assigned
 */
exports.createInAppNotification = onDocumentWritten('serviceRequests/{docId}', async (event) => {
  const change = event.data;
  const context = event.context;
    try {
      const after = change.after.exists ? change.after.data() : null;
      const before = change.before.exists ? change.before.data() : null;

      // If document was deleted, do nothing
      if (!after) {
        return null;
      }

      const afterAssignedTo = after.serviceDetails && after.serviceDetails.assignedTo;
      const beforeAssignedTo = before && before.serviceDetails && before.serviceDetails.assignedTo;

      // Check if this is a new assignment or reassignment
      const isFirstAssignment = !before && afterAssignedTo;
      const isReassignment = before && afterAssignedTo && (afterAssignedTo !== beforeAssignedTo);

      if (!isFirstAssignment && !isReassignment) {
        return null;
      }

      console.log(`Creating in-app notification for service request assignment`);

      // Find technician document to get UID
      let technicianUid = null;
      let technicianName = 'Unknown Technician';

      // Try to find technician by employeeId
      const adminsRef = admin.firestore().collection('admins');
      const techQuery = await adminsRef
        .where('employeeId', '==', afterAssignedTo)
        .limit(1)
        .get();

      if (!techQuery.empty) {
        const techDoc = techQuery.docs[0];
        technicianUid = techDoc.id;
        technicianName = techDoc.get('name') || techDoc.get('fullName') || 'Unknown Technician';
      } else {
        // Try technicians collection
        const techniciansRef = admin.firestore().collection('technicians');
        const techQuery2 = await techniciansRef
          .where('employeeId', '==', afterAssignedTo)
          .limit(1)
          .get();

        if (!techQuery2.empty) {
          const techDoc = techQuery2.docs[0];
          technicianUid = techDoc.id;
          technicianName = techDoc.get('name') || techDoc.get('fullName') || 'Unknown Technician';
        }
      }

      if (!technicianUid) {
        console.error(`No technician found for employeeId: ${afterAssignedTo}`);
        return null;
      }

      const srId = (after.serviceDetails && after.serviceDetails.srId) || context.params.docId;
      const comments = (after.serviceDetails && after.serviceDetails.comments) || '';
      const assignedBy = (after.serviceDetails && after.serviceDetails.assignedBy) || 'Admin';

      // Create in-app notification
      await admin.firestore().collection('notifications').add({
        type: 'service_assignment',
        title: 'New Service Request Assigned',
        message: `You have been assigned service request ${srId}. Assigned by: ${assignedBy}`,
        recipientId: technicianUid,
        recipientRole: 'technician',
        senderId: 'system',
        senderName: assignedBy,
        data: {
          srId: srId,
          comments: comments,
          assignedBy: assignedBy,
          employeeId: afterAssignedTo,
        },
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ In-app notification created for technician: ${technicianName}`);

      return null;
    } catch (error) {
      console.error('❌ Error in createInAppNotification:', error);
      return null;
    }
  });

/**
 * Cloud Function to handle service acknowledgment completion notifications
 * Triggers on notifications/{notificationId} document creation with type 'service_acknowledgment_completed'
 */
exports.handleServiceAcknowledgmentCompletion = onDocumentWritten('notifications/{notificationId}', async (event) => {
  const snap = event.data.after;
  const context = event.context;
    try {
      const notificationData = snap.data();
      const type = notificationData.type;

      // Only process service acknowledgment completion notifications
      if (type !== 'service_acknowledgment_completed') {
        return null;
      }

      console.log(`Processing service acknowledgment completion notification: ${context.params.notificationId}`);

      // Get all admin FCM tokens
      const adminsRef = admin.firestore().collection('admins');
      const adminQuery = await adminsRef
        .where('role', '==', 'admin')
        .get();

      if (adminQuery.empty) {
        console.log('No admin users found for service acknowledgment notification');
        return null;
      }

      const adminTokens = [];
      adminQuery.docs.forEach(doc => {
        const fcmToken = doc.get('fcmToken');
        if (fcmToken) {
          adminTokens.push(fcmToken);
        }
      });

      if (adminTokens.length === 0) {
        console.log('No admin FCM tokens found for service acknowledgment notification');
        return null;
      }

      // Prepare enhanced notification message
      const title = notificationData.title || 'Service Acknowledgment Completed';
      const message = notificationData.message || '';
      const data = notificationData.data || {};
      const srId = data.srId || 'Unknown';
      const technicianName = data.technicianName || 'Unknown Technician';
      const customerName = data.customerName || 'Unknown Customer';

      // Create enhanced FCM message with action buttons
      const fcmMessage = {
        notification: {
          title: title,
          body: `SR: ${srId} - ${customerName} - ${technicianName}`,
        },
        data: {
          ...data,
          type: type,
          notificationId: context.params.notificationId,
          srId: srId,
          technicianName: technicianName,
          customerName: customerName,
          action: 'view_service_details',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'admin_notifications',
            priority: 'high',
            defaultSound: true,
            defaultVibrateTimings: true,
            icon: '@mipmap/ic_launcher',
            color: '#4CAF50', // Green color for completion
            actions: [
              {
                title: 'View Details',
                action: 'view_details',
              },
              {
                title: 'Mark Complete',
                action: 'mark_complete',
              },
            ],
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
              category: 'SERVICE_ACKNOWLEDGMENT',
            },
          },
        },
      };

      // Send to all admin users
      const sendPromises = adminTokens.map(token => {
        const messageWithToken = { ...fcmMessage, token };
        return admin.messaging().send(messageWithToken);
      });

      const responses = await Promise.all(sendPromises);
      console.log(`✅ Service acknowledgment notification sent to ${adminTokens.length} admin(s)`);
      console.log(`SR: ${srId}, Technician: ${technicianName}, Customer: ${customerName}`);

      // Update service history with acknowledgment completion timestamp
      if (srId && srId !== 'Unknown') {
        try {
          const serviceHistoryRef = admin.firestore().collection('serviceHistory');
          const historyQuery = await serviceHistoryRef
            .where('srNumber', '==', srId)
            .limit(1)
            .get();

          if (!historyQuery.empty) {
            await historyQuery.docs[0].ref.update({
              'adminNotificationSent': true,
              'adminNotificationTimestamp': admin.firestore.FieldValue.serverTimestamp(),
              'adminNotificationId': context.params.notificationId,
            });
            console.log(`✅ Service history updated with admin notification details for SR: ${srId}`);
          }
        } catch (error) {
          console.error(`❌ Error updating service history for SR ${srId}:`, error);
        }
      }

      return null;
    } catch (error) {
      console.error('❌ Error in handleServiceAcknowledgmentCompletion:', error);
      return null;
    }
  });
