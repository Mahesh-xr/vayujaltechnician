import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  // Collection references
  static CollectionReference get serviceHistory => _firestore.collection('serviceHistory');

  /// Upload image to Firebase Storage
  static Future<String?> uploadImage({
    required File imageFile,
    required String srNumber,
    required String imageName,
  }) async {
    try {
      String fileName = '${srNumber}_$imageName.jpg';
      Reference storageRef = _storage
          .ref()
          .child('service_requests')
          .child(srNumber)
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(imageFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Save service data to Firestore
  static Future<void> saveServiceData({
    required String srNumber,
    required String customerComplaint,
    required String complaintRelatedTo,
    required String typeOfRaisedIssue,
    String? leftViewImageUrl,
    String? rightViewImageUrl,
    String? issueImageUrl,
    String? complaintOthersText,
    String? issueOthersText,
  }) async {
    try {
      Map<String, dynamic> serviceData = {
        'srNumber': srNumber,
        'customerComplaint': customerComplaint,
        'complaintRelatedTo': complaintRelatedTo,
        'typeOfRaisedIssue': typeOfRaisedIssue,
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'in_progress',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Add image URLs if available
      if (leftViewImageUrl != null) {
        serviceData['leftViewImageUrl'] = leftViewImageUrl;
      }
      if (rightViewImageUrl != null) {
        serviceData['rightViewImageUrl'] = rightViewImageUrl;
      }
      if (issueImageUrl != null) {
        serviceData['issueImageUrl'] = issueImageUrl;
      }

      // Add others text if applicable
      if (complaintOthersText != null && complaintOthersText.isNotEmpty) {
        serviceData['complaintOthersText'] = complaintOthersText;
      }
      if (issueOthersText != null && issueOthersText.isNotEmpty) {
        serviceData['issueOthersText'] = issueOthersText;
      }

      // Save to Firestore using SR number as document ID
      await serviceHistory.doc(srNumber).set(serviceData, SetOptions(merge: true));
      
      print('Service data saved successfully for SR: $srNumber');
    } catch (e) {
      print('Error saving service data: $e');
      throw Exception('Failed to save service data: $e');
    }
  }

  /// Update resolution data
  static Future<void> updateResolution({
    required String srNumber,
    required String resolution,
    String? identifiedIssue,
    String? partsReplaced,
    String? identifiedIssueOthers,
    String? partsReplacedOthers,
  }) async {
    try {
      Map<String, dynamic> resolutionData = {
        'resolution': resolution,
        'status': 'completed',
        'completedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (identifiedIssue != null) {
        resolutionData['identifiedIssue'] = identifiedIssue;
      }
      if (partsReplaced != null) {
        resolutionData['partsReplaced'] = partsReplaced;
      }
      if (identifiedIssueOthers != null && identifiedIssueOthers.isNotEmpty) {
        resolutionData['identifiedIssueOthers'] = identifiedIssueOthers;
      }
      if (partsReplacedOthers != null && partsReplacedOthers.isNotEmpty) {
        resolutionData['partsReplacedOthers'] = partsReplacedOthers;
      }

      await serviceHistory.doc(srNumber).update(resolutionData);
      
      print('Resolution updated successfully for SR: $srNumber');
    } catch (e) {
      print('Error updating resolution: $e');
      throw Exception('Failed to update resolution: $e');
    }
  }

  /// Get service data by SR number
  static Future<Map<String, dynamic>?> getServiceData(String srNumber) async {
    try {
      DocumentSnapshot doc = await serviceHistory.doc(srNumber).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting service data: $e');
      throw Exception('Failed to get service data: $e');
    }
  }

  /// Get all service records (for admin/history view)
  static Stream<QuerySnapshot> getAllServiceRecords() {
    return serviceHistory
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Get service records by status
  static Stream<QuerySnapshot> getServiceRecordsByStatus(String status) {
    return serviceHistory
        .where('status', isEqualTo: status)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Delete image from Firebase Storage
  static Future<void> deleteImage(String imageUrl) async {
    try {
      Reference imageRef = _storage.refFromURL(imageUrl);
      await imageRef.delete();
      print('Image deleted successfully');
    } catch (e) {
      print('Error deleting image: $e');
      throw Exception('Failed to delete image: $e');
    }
  }

  /// Delete entire service record
  static Future<void> deleteServiceRecord(String srNumber) async {
    try {
      // Get service data first to get image URLs
      Map<String, dynamic>? serviceData = await getServiceData(srNumber);
      
      if (serviceData != null) {
        // Delete images from Storage
        List<String> imageKeys = [
          'leftViewImageUrl',
          'rightViewImageUrl',
          'issueImageUrl'
        ];
        
        for (String key in imageKeys) {
          if (serviceData[key] != null) {
            await deleteImage(serviceData[key]);
          }
        }
      }

      // Delete document from Firestore
      await serviceHistory.doc(srNumber).delete();
      
      print('Service record deleted successfully for SR: $srNumber');
    } catch (e) {
      print('Error deleting service record: $e');
      throw Exception('Failed to delete service record: $e');
    }
  }

  /// Update service status
  static Future<void> updateServiceStatus(String srNumber, String status) async {
    try {
      await serviceHistory.doc(srNumber).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      print('Service status updated successfully for SR: $srNumber');
    } catch (e) {
      print('Error updating service status: $e');
      throw Exception('Failed to update service status: $e');
    }
  }

  /// Batch upload multiple images
  static Future<Map<String, String>> uploadMultipleImages({
    required String srNumber,
    File? leftViewImage,
    File? rightViewImage,
    File? issueImage,
  }) async {
    Map<String, String> imageUrls = {};
    
    try {
      // Upload left view image
      if (leftViewImage != null) {
        String? url = await uploadImage(
          imageFile: leftViewImage,
          srNumber: srNumber,
          imageName: 'left_view',
        );
        if (url != null) imageUrls['leftViewImageUrl'] = url;
      }

      // Upload right view image
      if (rightViewImage != null) {
        String? url = await uploadImage(
          imageFile: rightViewImage,
          srNumber: srNumber,
          imageName: 'right_view',
        );
        if (url != null) imageUrls['rightViewImageUrl'] = url;
      }

      // Upload issue image
      if (issueImage != null) {
        String? url = await uploadImage(
          imageFile: issueImage,
          srNumber: srNumber,
          imageName: 'issue_photo',
        );
        if (url != null) imageUrls['issueImageUrl'] = url;
      }

      return imageUrls;
    } catch (e) {
      print('Error uploading multiple images: $e');
      throw Exception('Failed to upload images: $e');
    }
  }
}