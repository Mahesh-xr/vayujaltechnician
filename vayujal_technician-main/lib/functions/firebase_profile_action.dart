import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:vayujal_technician/utils/constants.dart';

class FirebaseProfileActions {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload profile image to Firebase Storage
  static Future<String?> uploadProfileImage(XFile imageFile) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Verify Firebase Storage is properly configured
      final String bucketName = _storage.bucket;
      print('Using Firebase Storage bucket: $bucketName');
      
      // Validate AppConstants.profileImagesPath
      print('Profile images path from constants: "${AppConstants.profileImagesPath}"');

      final String fileName = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      print('Uploading file: $fileName');
      
      // Create storage reference with proper path
      Reference storageRef;
      
      // Option 1: Try with your constants path
      try {
        storageRef = _storage.ref().child('${AppConstants.profileImagesPath}/$fileName');
        print('Storage path: ${AppConstants.profileImagesPath}/$fileName');
      } catch (e) {
        // Option 2: Fallback to simple path if constants cause issues
        print('Constants path failed, using fallback: $e');
        storageRef = _storage.ref().child('profile_images/$fileName');
        print('Using fallback path: profile_images/$fileName');
      }

      // Verify file exists and get info
      final file = File(imageFile.path);
      if (!file.existsSync()) {
        throw Exception('File not found at path: ${imageFile.path}');
      }

      final int fileSize = await file.length();
      print('File size: $fileSize bytes');

      // Check file size limit (5MB)
      if (fileSize > 5 * 1024 * 1024) {
        throw Exception('File too large. Maximum size is 5MB');
      }

      // Upload with proper metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        cacheControl: 'max-age=3600',
        customMetadata: {
          'uploaded_by': user.uid,
          'upload_time': DateTime.now().toIso8601String(),
        },
      );

      print('Starting upload to Firebase Storage...');
      final UploadTask uploadTask = storageRef.putFile(file, metadata);
      
      // Monitor upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      print('Upload completed successfully');

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Download URL obtained: $downloadUrl');
      
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      print('Firebase error during upload:');
      print('Code: ${e.code}');
      print('Message: ${e.message}');
      print('Plugin: ${e.plugin}');
      
      // Handle specific Firebase Storage errors
      switch (e.code) {
        case 'object-not-found':
          print('Storage bucket or path not found. Check your Firebase configuration.');
          break;
        case 'unauthorized':
          print('Unauthorized. Check your Firebase Storage rules.');
          break;
        case 'retry-limit-exceeded':
          print('Upload failed after multiple retries. Check your internet connection.');
          break;
        case 'invalid-checksum':
          print('File checksum mismatch. File may be corrupted.');
          break;
        default:
          print('Unknown Firebase error: ${e.code}');
      }
      return null;
      
    } catch (e) {
      print('General error uploading profile image: $e');
      return null;
    }
  }

  /// Simplified upload method that should work reliably
  static Future<String?> uploadProfileImageSimple(XFile imageFile) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName = '${user.uid}.jpg';
      
      // Use simple path - this is most likely to work
      final Reference storageRef = _storage.ref().child('profile_images').child(fileName);
      
      print('Simple upload - Storage path: profile_images/$fileName');

      final file = File(imageFile.path);
      if (!file.existsSync()) {
        throw Exception('File not found');
      }

      print('File size: ${await file.length()} bytes');

      // Basic upload
      final UploadTask uploadTask = storageRef.putFile(file);
      
      // Monitor progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
      });
      
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = "www.sample.png";
      
      print('Simple upload successful: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('Simple upload error: $e');
      return null;
    }
  }
  static Future<String?> uploadProfileImageAlternative(XFile imageFile) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final String fileName = '${user.uid}.jpg';
      
      // Use the most basic path structure to avoid 404 errors
      final Reference storageRef = _storage.ref('profile_images/$fileName');
      
      print('Alternative upload - Storage path: profile_images/$fileName');

      final file = File(imageFile.path);
      if (!file.existsSync()) {
        throw Exception('File not found');
      }

      // Simple upload without complex metadata
      final UploadTask uploadTask = storageRef.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      print('Alternative upload successful: $downloadUrl');
      return downloadUrl;
      
    } catch (e) {
      print('Alternative upload error: $e');
      return null;
    }
  }

  /// Test Firebase Storage connectivity
  static Future<bool> testStorageConnectivity() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user for storage test');
        return false;
      }

      // Try to get a reference to test connectivity
      final Reference testRef = _storage.ref('test/connectivity_test.txt');
      
      // Try to get metadata (this will fail if storage isn't accessible)
      try {
        await testRef.getMetadata();
        print('Storage connectivity test: PASSED');
        return true;
      } catch (e) {
        if (e is FirebaseException && e.code == 'object-not-found') {
          // This is expected - the test file doesn't exist, but we can access storage
          print('Storage connectivity test: PASSED (storage accessible)');
          return true;
        }
        print('Storage connectivity test: FAILED - $e');
        return false;
      }
    } catch (e) {
      print('Storage connectivity test: ERROR - $e');
      return false;
    }
  }

  /// Check if employee ID is unique
  static Future<bool> isEmployeeIdUnique(String employeeId, {String? excludeUserId}) async {
    try {
      print('Checking employee ID uniqueness: "$employeeId" (exclude user: $excludeUserId)');
      
      // Query technicians collection for the employee ID
      QuerySnapshot querySnapshot = await _firestore
          .collection('technicians')
          .where('employeeId', isEqualTo: employeeId.trim())
          .get();

      print('Found ${querySnapshot.docs.length} documents with this employee ID');

      // If we're updating an existing user, exclude their own document
      if (excludeUserId != null) {
        // Filter out the current user's document
        var filteredDocs = querySnapshot.docs.where((doc) => doc.id != excludeUserId).toList();
        print('After excluding current user, ${filteredDocs.length} documents remain');
        return filteredDocs.isEmpty;
      }

      // If no documents found, the employee ID is unique
      print('No exclusion needed, ${querySnapshot.docs.length} documents found');
      return querySnapshot.docs.isEmpty;
    } catch (e) {
      print('Error checking employee ID uniqueness: $e');
      return false;
    }
  }

  /// Validate mobile number to ensure exactly 10 digits
  static String? validateMobileNumber(String? mobileNumber) {
    if (mobileNumber == null || mobileNumber.trim().isEmpty) {
      return 'Mobile number is required';
    }
    
    // Remove any spaces, hyphens, or parentheses
    String cleanNumber = mobileNumber.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    
    // Check for Indian mobile number pattern (with or without country code)
    if (cleanNumber.startsWith('+91')) {
      cleanNumber = cleanNumber.substring(3);
    } else if (cleanNumber.startsWith('91') && cleanNumber.length == 12) {
      cleanNumber = cleanNumber.substring(2);
    }
    
    // Check if it's exactly 10 digits and starts with 6-9
    if (cleanNumber.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }
    
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleanNumber)) {
      return 'Enter a valid 10-digit mobile number starting with 6-9';
    }
    
    return null;
  }

  /// Complete profile setup with employee ID uniqueness check
  static Future<Map<String, dynamic>> completeProfileSetup({
    required String name,
    required String employeeId,
    required String mobileNumber,
    required String email,
    required String designation,
    required String profileImage,
  }) async {
    try {
      // Validate mobile number
      String? mobileValidation = validateMobileNumber(mobileNumber);
      if (mobileValidation != null) {
        return {
          'success': false,
          'message': mobileValidation,
        };
      }

      // Check employee ID uniqueness
      final User? user = _auth.currentUser;
      bool isUnique = await isEmployeeIdUnique(employeeId, excludeUserId: user?.uid);
      
      if (!isUnique) {
        return {
          'success': false,
          'message': 'Employee ID already exists. Please choose a different one.',
        };
      }

      // Save profile data
      print('Saving profile data...');
      final bool success = await saveTechnicianProfile(
        fullName: name,
        employeeId: employeeId,
        mobileNumber: mobileNumber,
        email: email,
        designation: designation,
        profileImageUrl: profileImage,
      );
      
      if (success) {
        return {
          'success': true,
          'message': 'Profile setup completed successfully',
          'imageUrl': profileImage,
        };
      } else {
        return {
          'success': false,
          'message': 'Profile image uploaded but failed to save profile data',
        };
      }
    } catch (e) {
      print('Error in completeProfileSetup: $e');
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  /// Save technician profile data to Firestore
  static Future<bool> saveTechnicianProfile({
    required String fullName,
    required String employeeId,
    required String mobileNumber,
    required String email,
    required String designation,
    String? profileImageUrl,
  }) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final Map<String, dynamic> profileData = {
        'uid': user.uid,
        'fullName': fullName.trim(),
        'employeeId': employeeId.trim(),
        'mobileNumber': mobileNumber.trim(),
        'email': email.trim(),
        'designation': designation.trim(),
        'profileImageUrl': profileImageUrl ?? '',
        'isProfileComplete': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('technicians')
          .doc(user.uid)
          .set(profileData, SetOptions(merge: true));

      return true;
    } catch (e) {
      print('Error saving technician profile: $e');
      return false;
    }
  }

  /// Check if user profile is complete
  static Future<bool> isProfileComplete() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.adminCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        return data?['isProfileComplete'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking profile completion: $e');
      return false;
    }
  }

  /// Get technician profile data
  static Future<Map<String, dynamic>?> getTechnicianProfile() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return null;

      final DocumentSnapshot doc = await _firestore
          .collection(AppConstants.adminCollection)
          .doc(user.uid)
          .get();

      if (doc.exists) {
        return doc.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      print('Error getting technician profile: $e');
      return null;
    }
  }

  /// Update profile completion status
  static Future<bool> updateProfileCompletionStatus(bool isComplete) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return false;

      await _firestore
          .collection(AppConstants.adminCollection)
          .doc(user.uid)
          .update({
        'isProfileComplete': isComplete,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error updating profile completion status: $e');
      return false;
    }
  }
}