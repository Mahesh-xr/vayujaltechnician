
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:vayujal_technician/functions/firebase_profile_action.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/screens/dashboard_screen.dart';
import 'package:vayujal_technician/utils/validation_utils.dart';
import 'package:vayujal_technician/services/notification_service.dart';
import 'dart:io';

import 'package:vayujal_technician/utils/constants.dart';

class ProfileSetupScreen extends StatefulWidget {
  final VoidCallback? onProfileComplete;

  const ProfileSetupScreen({
    super.key,
    this.onProfileComplete,
  });

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _emailController = TextEditingController();
  
  String _selectedDesignation = 'Technician';
  XFile? _selectedImage;
  File? _selectedImageFile;
  bool _isLoading = false;
  bool _isUploadingImage = false;
  String _profileImageUrl = '';

  final List<String> _designations = [
    'Technician',
    'Senior Technician',
    'Lead Technician',
    'Supervisor',
    'Manager',
    'Engineer',
    'Senior Engineer',
  ];

  final ImagePicker _picker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _initializeUserData();
  }

  void _initializeUserData() {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      _emailController.text = user.email!;
      
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _employeeIdController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }


  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Create a unique filename
        final fileName = 'profile_${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Upload to Firebase Storage
        final Reference storageRef = _storage.ref().child('profile_images').child(fileName);
        final UploadTask uploadTask = storageRef.putFile(_selectedImageFile!);
        
        // Show upload progress
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          print('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        });

        // Wait for upload to complete
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Delete old image if exists
        if (_profileImageUrl.isNotEmpty) {
          try {
            await _storage.refFromURL(_profileImageUrl).delete();
          } catch (e) {
            print('Error deleting old image: $e');
          }
        }
        
        setState(() {
          _profileImageUrl = downloadUrl;
        });
        
        _showSnackBar('Profile picture uploaded successfully!', Colors.green);
      }
    } catch (e) {
      _showSnackBar('Error uploading image: $e', Colors.red);
    } finally {
      setState(() {
        _isUploadingImage = false;
        _selectedImage = null;
      });
    }
  }


  // Pick image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _selectedImageFile = File(image.path);
        });
        await _uploadImageToFirebase();
      }
    } catch (e) {
      _showSnackBar('Error picking image from camera: $e', AppConstants.errorColor);
    }
  }

  // Pick image from gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImage = image;
          _selectedImageFile = File(image.path);
        });
        await _uploadImageToFirebase();
      }
    } catch (e) {
      _showSnackBar('Error picking image from gallery: $e', AppConstants.errorColor);
    }
  }

  // Remove profile image
  void _removeProfileImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageFile = null;
      _profileImageUrl = '';
    });
  }

  // Show image picker options
  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Profile Picture',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.camera_alt, size: 30, color: Colors.blue),
                        ),
                        SizedBox(height: 8),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromGallery();
                    },
                    child: Column(
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.photo_library, size: 30, color: Colors.green),
                        ),
                        SizedBox(height: 8),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                  if (_selectedImage != null)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _removeProfileImage();
                      },
                      child: Column(
                        children: [
                          Container(
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.delete, size: 30, color: Colors.red),
                          ),
                          SizedBox(height: 8),
                          Text('Remove'),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showSnackBar(String message, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateMobile(String? value) {
    return ValidationUtils.validateMobile(value);
  }

  String? _validateEmployeeId(String? value) {
    return ValidationUtils.validateEmployeeId(value);
  }

  // Check employee ID uniqueness
  Future<String?> _checkEmployeeIdUniqueness(String employeeId) async {
    if (employeeId.trim().isEmpty) return null;
    
    try {
      bool isUnique = await FirebaseProfileActions.isEmployeeIdUnique(employeeId);
      if (!isUnique) {
        return 'Employee ID already exists. Please choose a different one.';
      }
      return null;
    } catch (e) {
      return 'Error checking employee ID. Please try again.';
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('=== PROFILE SAVE START ===');
      print('Name: ${_nameController.text}');
      print('Employee ID: ${_employeeIdController.text}');
      print('Mobile: ${_mobileController.text}');
      print('Email: ${_emailController.text}');
      print('Designation: $_selectedDesignation');
      print('Selected image: ${_selectedImage != null}');
      
      final result = await FirebaseProfileActions.completeProfileSetup(
        name: _nameController.text.trim(),
        employeeId: _employeeIdController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        email: _emailController.text.trim(),
        designation: _selectedDesignation,
        profileImage: _profileImageUrl,
      );

      print('Profile setup result: $result');

      if (result['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppConstants.successColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        // Save FCM token after successful profile setup
        await NotificationService.saveTokenAfterProfileSetup();
        
        // Wait for the snackbar to show
         Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(),
          ),
        );
        
        // Call the callback to notify parent that profile is complete
        if (widget.onProfileComplete != null) {
          print('Calling onProfileComplete callback');
          widget.onProfileComplete!();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: AppConstants.errorColor,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      print('Error in _saveProfile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('An error occurred: ${e.toString()}'),
            backgroundColor: AppConstants.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      appBar: Normalappbar(
        title: "Profile Set Up",
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: AppConstants.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // Profile Image Picker - Fixed Implementation
              Center(
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                          width: 3,
                        ),
                      ),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[300],
                            backgroundImage: _selectedImageFile != null 
                                ? FileImage(_selectedImageFile!) 
                                : (_profileImageUrl.isNotEmpty
                                    ? NetworkImage(_profileImageUrl) 
                                    : null) as ImageProvider?,
                            child: (_selectedImageFile == null && _profileImageUrl.isEmpty)
                                ? Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.grey[600],
                                  )
                                : null,
                          ),
                          if (_isUploadingImage)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_isUploadingImage)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: IconButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            onPressed: _showImagePickerOptions,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: AppConstants.getInputDecoration(
                  'Name',
                  hint: 'Enter your full name',
                ),
                validator: _validateName,
                textCapitalization: TextCapitalization.words,
              ),
              
              const SizedBox(height: 16),
              
              // Employee ID Field
              TextFormField(
                controller: _employeeIdController,
                decoration: AppConstants.getInputDecoration(
                  'Employee ID',
                  hint: 'Enter your employee ID',
                ),
                validator: _validateEmployeeId,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) {
                  // Clear any previous uniqueness error when user types
                  if (value.trim().isNotEmpty) {
                    setState(() {
                      // Trigger form validation
                    });
                  }
                },
              ),
              
              const SizedBox(height: 16),
              
              // Mobile Number Field
              TextFormField(
                controller: _mobileController,
                decoration: AppConstants.getInputDecoration(
                  'Mobile Number',
                  hint: 'Enter your mobile number',
                ),
                keyboardType: TextInputType.phone,
                validator: _validateMobile,
              ),
              
              const SizedBox(height: 16),
              
              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: AppConstants.getInputDecoration(
                  'Email',
                  hint: 'Enter your email address',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: _validateEmail,
              ),
              
              const SizedBox(height: 16),
              
              // Designation Dropdown
              DropdownButtonFormField<String>(
                value: _selectedDesignation,
                decoration: AppConstants.getInputDecoration('Designation'),
                items: _designations.map((String designation) {
                  return DropdownMenuItem<String>(
                    value: designation,
                    child: Text(designation),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDesignation = newValue;
                    });
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a designation';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: AppConstants.buttonHeight,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppConstants.buttonBorderRadius,
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Required fields note
              const Text(
                '* Required fields',
                style: AppConstants.captionStyle,
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
