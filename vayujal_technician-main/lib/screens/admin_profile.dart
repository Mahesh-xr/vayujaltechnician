import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/services/notification_actions_service.dart';
import 'package:vayujal_technician/utils/validation_utils.dart';
import 'package:vayujal_technician/functions/firebase_profile_action.dart';

class AdminProfileSetupPage extends StatefulWidget {
  const AdminProfileSetupPage({super.key});

  @override
  _AdminProfileSetupPageState createState() => _AdminProfileSetupPageState();
}

class _AdminProfileSetupPageState extends State<AdminProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _organizationController = TextEditingController();
  
  bool _isLoading = false;
  bool _isLoadingProfile = true;
  bool _isEditingMode = false;
  bool _isUploadingImage = false;
  String _profileImageUrl = '';
  String _selectedDesignation = 'Technician';
  File? _selectedImage;
  
  // Designation options
  final List<String> _designations = [
    'Technician',
    'Senior Technician',
    'Lead Technician',
    'Supervisor',
    'Manager',
    'Engineer',
    'Senior Engineer',
    'Field Engineer',
    'Technical Lead',
    'Team Leader',
    'Project Manager',
    'Operations Manager',
  ];
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadAdminProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  // Load existing admin profile data
  Future<void> _loadAdminProfile() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('technicians').doc(user.uid).get();
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = data['fullName'] ?? '';
            _emailController.text = data['email'] ?? user.email ?? '';
            _phoneController.text = data['mobileNumber'] ?? '';
            _organizationController.text = data['employeeId'] ?? '';
            _selectedDesignation = data['designation'] ?? 'Technician';
            _profileImageUrl = data['profileImageUrl'] ?? '';
          });
        } else {
          // Set default email from Firebase Auth
          _emailController.text = user.email ?? '';
          // If no profile exists, start in editing mode
          setState(() {
            _isEditingMode = true;
          });
        }
      }
    } catch (e) {
      _showSnackBar('Error loading profile: $e', Colors.red);
    } finally {
      setState(() {
        _isLoadingProfile = false;
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
          _selectedImage = File(image.path);
        });
        await _uploadImageToFirebase();
      }
    } catch (e) {
      _showSnackBar('Error picking image from camera: $e', Colors.red);
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
          _selectedImage = File(image.path);
        });
        await _uploadImageToFirebase();
      }
    } catch (e) {
      _showSnackBar('Error picking image from gallery: $e', Colors.red);
    }
  }

  // Upload image to Firebase Storage
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
        final UploadTask uploadTask = storageRef.putFile(_selectedImage!);
        
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

  // Remove profile image
  Future<void> _removeProfileImage() async {
    if (_profileImageUrl.isEmpty) return;

    try {
      // Delete from Firebase Storage
      await _storage.refFromURL(_profileImageUrl).delete();
      
      setState(() {
        _profileImageUrl = '';
      });
      
      _showSnackBar('Profile picture removed successfully!', Colors.orange);
    } catch (e) {
      _showSnackBar('Error removing image: $e', Colors.red);
    }
  }

  // Toggle edit mode
  void _toggleEditMode() {
    setState(() {
      _isEditingMode = !_isEditingMode;
    });
  }

  // Save admin profile
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for mobile number
    String? mobileValidation = ValidationUtils.validateMobile(_phoneController.text);
    if (mobileValidation != null) {
      _showSnackBar(mobileValidation, Colors.red);
      return;
    }

    // Check employee ID uniqueness
    try {
      bool isUnique = await FirebaseProfileActions.isEmployeeIdUnique(
        _organizationController.text.trim(),
        excludeUserId: _auth.currentUser?.uid,
      );
      
      if (!isUnique) {
        _showSnackBar('Employee ID already exists. Please choose a different one.', Colors.red);
        return;
      }
    } catch (e) {
      _showSnackBar('Error checking employee ID. Please try again.', Colors.red);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('technicians').doc(user.uid).set({
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'mobileNumber': _phoneController.text.trim(),
          'employeeId': _organizationController.text.trim(),
          'designation': _selectedDesignation,
          'profileImageUrl': _profileImageUrl,
          'uid': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        _showSnackBar('Profile updated successfully!', Colors.green);
        
        // Switch back to view mode after saving
        setState(() {
          _isEditingMode = false;
        });
      }
    } catch (e) {
      _showSnackBar('Error saving profile: $e', Colors.red);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Logout function
  Future<void> _logout() async {
    try {
      await _auth.signOut();
      // Navigate to login page - adjust route as needed
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login', // Replace with your login route
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      _showSnackBar('Error logging out: $e', Colors.red);
    }
  }

  // Request admin access
  Future<void> _requestAdminAccess() async {
    try {
      final success = await NotificationActionsService.requestAdminAccess();
      
      if (success) {
        _showSnackBar('Admin access request sent successfully!', Colors.purple);
      } else {
        _showSnackBar('Failed to send admin access request. Please try again.', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error sending admin access request: $e', Colors.red);
    }
  }

  // Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 10),
              Text('Logout'),
            ],
          ),
          content: Text('Are you sure you want to logout from your admin account?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _logout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  // Show image picker options
  void _showImagePickerOptions() {
    if (!_isEditingMode) return; // Only allow image picking in edit mode
    
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
                  if (_profileImageUrl.isNotEmpty)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: Normalappbar(
        title: 'Technician Profile'
      ),
      body: _isLoadingProfile
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image Section
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
                                  backgroundImage: _selectedImage != null 
                                      ? FileImage(_selectedImage!) 
                                      : (_profileImageUrl.isNotEmpty
                                          ? NetworkImage(_profileImageUrl) 
                                          : null) as ImageProvider?,
                                  child: (_selectedImage == null && _profileImageUrl.isEmpty)
                                      ? Icon(
                                          Icons.admin_panel_settings,
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
                          if (_isEditingMode && !_isUploadingImage)
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
                    
                    SizedBox(height: 30),
                    
                    // Form Fields - Toggle between TextField and Text display
                    _buildProfileField(
                      controller: _nameController,
                      label: 'Full Name',
                      icon: Icons.person,
                      validator: ValidationUtils.validateName,
                    ),
                    
                    SizedBox(height: 16),
                    
                    _buildProfileField(
                      controller: _emailController,
                      label: 'Email',
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: ValidationUtils.validateEmail,
                    ),
                    
                    SizedBox(height: 16),
                    
                    _buildProfileField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: ValidationUtils.validateMobile,
                    ),
                    
                    SizedBox(height: 16),
                    
                    _buildProfileField(
                      controller: _organizationController,
                      label: 'Employee ID',
                      icon: Icons.business,
                      validator: ValidationUtils.validateEmployeeId,
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Designation Dropdown Field
                    _buildDesignationField(),
                    
                    SizedBox(height: 30),
                    
                    // Edit/Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: (_isLoading || _isUploadingImage) ? null : (_isEditingMode ? _saveProfile : _toggleEditMode),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isEditingMode ? Colors.green : Colors.blue,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 2,
                        ),
                        child: (_isLoading || _isUploadingImage)
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    _isUploadingImage ? 'Uploading...' : 'Saving...',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _isEditingMode ? Icons.save : Icons.edit,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    _isEditingMode ? 'Save Changes' : 'Edit Profile',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Cancel button (only shown in edit mode)
                    if (_isEditingMode)
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isEditingMode = false;
                              _selectedImage = null;
                            });
                            // Reload profile data to revert changes
                            _loadAdminProfile();
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 20),
                    
                    // Request Admin Access Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _requestAdminAccess,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.purple, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings, color: Colors.purple),
                            SizedBox(width: 8),
                            Text(
                              'Request Admin Access',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.purple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 20),
                    
                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _showLogoutDialog,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red, width: 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    if (_isEditingMode) {
      // Show TextField in edit mode
      return TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: validator,
      );
    } else {
      // Show text display in view mode
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade600),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    controller.text.isEmpty ? 'Not set' : controller.text,
                    style: TextStyle(
                      fontSize: 16,
                      color: controller.text.isEmpty ? Colors.grey[400] : Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDesignationField() {
    if (_isEditingMode) {
      // Show Dropdown in edit mode
      return DropdownButtonFormField<String>(
        value: _selectedDesignation,
        decoration: InputDecoration(
          labelText: 'Designation',
          prefixIcon: Icon(Icons.work, color: Colors.grey.shade500),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.red),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
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
      );
    } else {
      // Show text display in view mode
      return Container(
        width: double.infinity,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(Icons.work, color: Colors.grey.shade600),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Designation',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _selectedDesignation.isEmpty ? 'Not set' : _selectedDesignation,
                    style: TextStyle(
                      fontSize: 16,
                      color: _selectedDesignation.isEmpty ? Colors.grey[400] : Colors.black87,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }


}
