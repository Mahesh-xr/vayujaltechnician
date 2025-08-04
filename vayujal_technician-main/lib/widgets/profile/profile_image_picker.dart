import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vayujal_technician/utils/constants.dart';
// ignore: depend_on_referenced_packages
import 'package:image_picker/image_picker.dart';


class ProfileImagePicker extends StatefulWidget {
  final Function(XFile?) onImageSelected;
  final XFile? initialImage;

  const ProfileImagePicker({
    super.key,
    required this.onImageSelected,
    this.initialImage,
  });

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker> {
  XFile? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImage;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        widget.onImageSelected(image);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: AppConstants.errorColor,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
    widget.onImageSelected(null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: AppConstants.profileImageSize,
          height: AppConstants.profileImageSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey[200],
            border: Border.all(
              color: const Color.fromARGB(255, 94, 93, 93),
              width: 3,
            ),
          ),
          child: Stack(
            children: [
              // Profile Image or Placeholder
              ClipOval(
                child: _selectedImage != null
                    ? Image.file(
                        File(_selectedImage!.path),
                        width: AppConstants.profileImageSize,
                        height: AppConstants.profileImageSize,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: AppConstants.profileImageSize,
                        height: AppConstants.profileImageSize,
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.person,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
              // Add/Edit Button
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color.fromARGB(255, 100, 99, 99),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: _showImageSourceDialog,
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Action Buttons
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: _showImageSourceDialog,
              icon: const Icon(Icons.add_a_photo),
              label: Text(_selectedImage != null ? 'Change Photo' : 'Add Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 0, 0, 0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: AppConstants.buttonBorderRadius,
                ),
              ),
            ),
            if (_selectedImage != null) ...[
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: _removeImage,
                icon: const Icon(Icons.delete_outline),
                label: const Text('Remove'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.errorColor,
                  side: const BorderSide(color: AppConstants.errorColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: AppConstants.buttonBorderRadius,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Tap the camera icon or button to select a profile photo',
          style: AppConstants.captionStyle,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}