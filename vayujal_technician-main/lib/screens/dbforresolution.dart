import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

class ResolutionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Upload multiple resolution images to Firebase Storage
  Future<List<String>> uploadResolutionImages(String srNumber, List<File> imageFiles) async {
    try {
      List<String> downloadUrls = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        // Create reference to storage location with index
        final storageRef = _storage.ref().child('service_requests/$srNumber/resolution_image_${i + 1}.jpg');
        
        // Upload file
        final uploadTask = storageRef.putFile(imageFiles[i]);
        final snapshot = await uploadTask;
        
        // Get download URL
        final downloadUrl = await snapshot.ref.getDownloadURL();
        downloadUrls.add(downloadUrl);
      }
      
      return downloadUrls;
    } catch (e) {
      throw Exception('Failed to upload resolution images: $e');
    }
  }

  // Upload resolution video to Firebase Storage
  Future<String?> uploadResolutionVideo(String srNumber, File videoFile) async {
    try {
      // Create reference to storage location
      final storageRef = _storage.ref().child('service_requests/$srNumber/resolution_video.mp4');
      
      // Upload file
      final uploadTask = storageRef.putFile(videoFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload resolution video: $e');
    }
  }

  // Upload single resolution image (keeping for backward compatibility)
  Future<String> uploadResolutionImage(String srNumber, File imageFile) async {
    try {
      // Create reference to storage location
      final storageRef = _storage.ref().child('service_requests/$srNumber/${srNumber}_resolution.jpg');
      
      // Upload file
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask;
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload resolution image: $e');
    }
  }

  // Update serviceHistory document with resolution data
  Future<void> updateServiceHistoryWithResolution({
    required String srNumber,
    required String serialNumber,
    required String issueIdentification,
    required String issueType,
    required String solutionProvided,
    required String partsReplaced,
    required List<String> resolutionImageUrls,
    required String? resolutionVideoUrl,
    required DateTime nextServiceDate,
    required Map<String, bool> suggestions,
    required String customSuggestions,
    required String status,
    required String issueOthers,
    required String partsOthers,
  }) async {
    try {
      // Get current user (technician)
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the existing serviceHistory document
      final querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      if (querySnapshot.docs.isEmpty) {
        throw Exception('Service request not found');
      }

      final docId = querySnapshot.docs.first.id;

      // Prepare update data
      Map<String, dynamic> updateData = {
        'serialNumber': serialNumber,
        'issueIdentification': issueIdentification,
        'issueType': issueType,
        'solutionProvided': solutionProvided,
        'partsReplaced': partsReplaced,
        'resolutionImageUrls': resolutionImageUrls, // Multiple images
        'nextServiceDate': Timestamp.fromDate(nextServiceDate),
        'suggestions': suggestions,
        'customSuggestions': customSuggestions,
        'status': status,
        'resolutionTimestamp': FieldValue.serverTimestamp(),
        'resolvedBy': currentUser.uid,
        'issueOthers': issueOthers,
        'partsOthers': partsOthers,
      };

      // Add video URL if available
      if (resolutionVideoUrl != null && resolutionVideoUrl.isNotEmpty) {
        updateData['resolutionVideoUrl'] = resolutionVideoUrl;
      }

      // Update the serviceHistory document
      await _firestore.collection('serviceHistory').doc(docId).update(updateData);
      
      // Also update the serviceRequests document
      await _firestore.collection('serviceRequests').doc(srNumber).update({
        'status': status,
        'resolvedBy': currentUser.uid,
        'resolutionTimestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update service history: $e');
    }
  }

  // Complete resolution process (upload images/video + update database)
  Future<void> completeResolution({
    required String srNumber,
    required String serialNumber,
    required String issueIdentification,
    required String issueType,
    required String solutionProvided,
    required String partsReplaced,
    required DateTime nextServiceDate,
    required Map<String, bool> suggestions,
    required String customSuggestions,
    required String status,
    required List<File> resolutionImages,
    File? resolutionVideo,
    required String issueOthers,
    required String partsOthers,
  }) async {
    try {
      List<String> resolutionImageUrls = [];
      String? resolutionVideoUrl;
      
      // Upload resolution images if provided
      if (resolutionImages.isNotEmpty) {
        resolutionImageUrls = await uploadResolutionImages(srNumber, resolutionImages);
      }

      // Upload resolution video if provided
      if (resolutionVideo != null) {
        resolutionVideoUrl = await uploadResolutionVideo(srNumber, resolutionVideo);
      }

      // Update serviceHistory document
      await updateServiceHistoryWithResolution(
        srNumber: srNumber,
        serialNumber: serialNumber,
        issueIdentification: issueIdentification,
        issueType: issueType,
        solutionProvided: solutionProvided,
        partsReplaced: partsReplaced,
        resolutionImageUrls: resolutionImageUrls,
        resolutionVideoUrl: resolutionVideoUrl,
        nextServiceDate: nextServiceDate,
        suggestions: suggestions,
        customSuggestions: customSuggestions,
        status: status,
        issueOthers: issueOthers,
        partsOthers: partsOthers,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get image from camera or gallery
  Future<File?> pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Get existing service request data
  Future<Map<String, dynamic>?> getServiceRequestData(String srNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.first.data();
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get service request data: $e');
    }
  }
}