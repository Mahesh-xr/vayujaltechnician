import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';

import 'package:vayujal_technician/screens/resolution.dart';

class StartServiceScreen extends StatefulWidget {
  final String srNumber;
  final String customerComplaint;
  final String awgSerialNumber;

  const StartServiceScreen({
    super.key,
    required this.srNumber,
    required this.customerComplaint,
    required this.awgSerialNumber,
  });

  @override
  State<StartServiceScreen> createState() => _StartServiceScreenState();
}

class _StartServiceScreenState extends State<StartServiceScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _complaintOthersController = TextEditingController();
  final TextEditingController _issueOthersController = TextEditingController();
  
  // Multiple image files
  final List<File> _leftViewImages = [];
  final List<File> _rightViewImages = [];
  final List<File> _frontViewImages = [];
  final List<File> _issueImages = [];
  
  // Video file
  File? _issueVideo;
  VideoPlayerController? _videoController;
  
  // Dropdown values
  List<String> _selectedComplaintTypes = [];
  List<String> _selectedIssueTypes = [];
  
  // Loading states
  bool _isUploading = false;
  final bool _leftViewUploading = false;
  final bool _rightViewUploading = false;
  final bool _issuePhotoUploading = false;
  final bool _frontViewUploading = false;
  bool _videoUploading = false;

  // Maximum images per view
  static const int maxImagesPerView = 5;

  // Dropdown options
  static final List<String> _complaintTypes = [
    'Electrical','Refrigeration', 'Filtration', 'Mechanical', 'General Service', 'Others'
  ];

  static final List<String> _issueTypes = [
    'Machine start', 'Machine trip', 'LP trip', 'HP trip', 'PP error', 'Tank full error', 'Power button', 'Pump button', 'Water leakage', 'Water taste', 'Mechanical structure', 
    'Automatic Water dispense', 'Noise', 'None', 'Others' 
  ];

  @override
  void dispose() {
    _complaintOthersController.dispose();
    _issueOthersController.dispose();
    _videoController?.dispose();
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: Normalappbar(title: 'Start Service'),
      body: SafeArea(
        child: Column( // Changed from SingleChildScrollView to Column
          children: [
            Expanded( // Now Expanded is properly inside Column
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SR Number (Read-only)
                    _buildReadOnlyField('SR Number', widget.srNumber),
                    const SizedBox(height: 16),
                    
                    // Customer Complaint (Read-only)
                    _buildReadOnlyField('Customer Complaint', widget.customerComplaint),
                    const SizedBox(height: 24),

                    // Front View Photo Section
                    _buildMultiplePhotoSection(
                      'Front View',
                      _frontViewImages,
                      _frontViewUploading,
                      () => _showImageSourceDialog('front'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Left View Photo Section
                    _buildMultiplePhotoSection(
                      'Left View',
                      _leftViewImages,
                      _leftViewUploading,
                      () => _showImageSourceDialog('left'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Right View Photo Section
                    _buildMultiplePhotoSection(
                      'Right View',
                      _rightViewImages,
                      _rightViewUploading,
                      () => _showImageSourceDialog('right'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Complaint Details Section
                    _buildSectionTitle('Complaint Details'),
                    const Text(
                      'Select related components',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    
                    // Complaint Related to Multi-Select
                    Text('Complaint Related to', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showComplaintSelectionDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedComplaintTypes.isEmpty
                                  ? 'Tap to select complaints'
                                  : 'Selected (${_selectedComplaintTypes.length}):',
                              style: TextStyle(
                                color: _selectedComplaintTypes.isEmpty ? Colors.grey : Colors.blue[800],
                                fontWeight: _selectedComplaintTypes.isEmpty ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            if (_selectedComplaintTypes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(_selectedComplaintTypes.join(', '), style: const TextStyle(color: Colors.black87)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_selectedComplaintTypes.contains('Others'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildTextField('Mention if Others', _complaintOthersController),
                      ),
                    const SizedBox(height: 16),
                    
                    // Type of Raised Issue Multi-Select
                    Text('Type of Raised Issue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _showIssueSelectionDialog,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedIssueTypes.isEmpty
                                  ? 'Tap to select issues'
                                  : 'Selected (${_selectedIssueTypes.length}):',
                              style: TextStyle(
                                color: _selectedIssueTypes.isEmpty ? Colors.grey : Colors.blue[800],
                                fontWeight: _selectedIssueTypes.isEmpty ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                            if (_selectedIssueTypes.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(_selectedIssueTypes.join(', '), style: const TextStyle(color: Colors.black87)),
                            ],
                          ],
                        ),
                      ),
                    ),
                    if (_selectedIssueTypes.contains('Others'))
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildTextField('Mention if Others', _issueOthersController),
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Issue Photos Section
                    _buildSectionTitle('Upload Issue Photos'),
                    _buildMultiplePhotoSection(
                      '',
                      _issueImages,
                      _issuePhotoUploading,
                      () => _showImageSourceDialog('issue'),
                    ),
                    const SizedBox(height: 24),
                    
                    // Issue Video Section
                    _buildSectionTitle('Upload Issue Video (10 seconds)'),
                    _buildVideoSection(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Continue to Resolution Button - Fixed positioning
            Container(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _saveServiceData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUploading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Continue to Resolution',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiplePhotoSection(String title, List<File> images, bool isUploading, VoidCallback onTap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        if (title.isNotEmpty) const SizedBox(height: 8),
        
        // Images preview
        if (images.isNotEmpty)
          SizedBox( // Changed from Container to SizedBox
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          images[index],
                          fit: BoxFit.cover,
                          width: 120,
                          height: 120,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              images.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 8),
        
        // Add photo button
        Container(
          width: double.infinity,
          height: 120,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 24,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.photo_library_outlined,
                    size: 24,
                    color: Colors.grey[400],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                images.isEmpty 
                    ? 'No Photos uploaded' 
                    : '${images.length}/$maxImagesPerView photos',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: (isUploading || images.length >= maxImagesPerView) ? null : onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        images.length >= maxImagesPerView 
                            ? 'Max Photos Reached' 
                            : 'Add Photos',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildVideoSection() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       // Video preview
  //       if (_issueVideo != null && _videoController != null)
  //         Container(
  //           height: 200,
  //           width: double.infinity,
  //           decoration: BoxDecoration(
  //             borderRadius: BorderRadius.circular(8),
  //             border: Border.all(color: Colors.grey[300]!),
  //           ),
  //           child: ClipRRect(
  //             borderRadius: BorderRadius.circular(8),
  //             child: Stack(
  //               children: [
  //                 VideoPlayer(_videoController!),
  //                 Positioned(
  //                   top: 8,
  //                   right: 8,
  //                   child: Row(
  //                     children: [
  //                       GestureDetector(
  //                         onTap: () {
  //                           setState(() {
  //                             if (_videoController!.value.isPlaying) {
  //                               _videoController!.pause();
  //                             } else {
  //                               _videoController!.play();
  //                             }
  //                           });
  //                         },
  //                         child: Container(
  //                           padding: const EdgeInsets.all(8),
  //                           decoration: const BoxDecoration(
  //                             color: Colors.black54,
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: Icon(
  //                             _videoController!.value.isPlaying 
  //                                 ? Icons.pause 
  //                                 : Icons.play_arrow,
  //                             color: Colors.white,
  //                             size: 20,
  //                           ),
  //                         ),
  //                       ),
  //                       const SizedBox(width: 8),
  //                       GestureDetector(
  //                         onTap: () {
  //                           setState(() {
  //                             _videoController?.dispose();
  //                             _videoController = null;
  //                             _issueVideo = null;
  //                           });
  //                         },
  //                         child: Container(
  //                           padding: const EdgeInsets.all(8),
  //                           decoration: const BoxDecoration(
  //                             color: Colors.red,
  //                             shape: BoxShape.circle,
  //                           ),
  //                           child: const Icon(
  //                             Icons.close,
  //                             color: Colors.white,
  //                             size: 20,
  //                           ),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
        
  //       if (_issueVideo != null) const SizedBox(height: 8),
        
  //       // Add video button
  //       Container(
  //         width: double.infinity,
  //         height: 120,
  //         decoration: BoxDecoration(
  //           color: Colors.grey[50],
  //           borderRadius: BorderRadius.circular(8),
  //           border: Border.all(color: Colors.grey[300]!),
  //         ),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.center,
  //               children: [
  //                 Icon(
  //                   Icons.videocam_outlined,
  //                   size: 24,
  //                   color: Colors.grey[400],
  //                 ),
  //                 const SizedBox(width: 8),
  //                 Icon(
  //                   Icons.video_library_outlined,
  //                   size: 24,
  //                   color: Colors.grey[400],
  //                 ),
  //               ],
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               _issueVideo == null 
  //                   ? 'No Video uploaded' 
  //                   : 'Video ready',
  //               style: TextStyle(
  //                 color: Colors.grey[600],
  //                 fontSize: 12,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             ElevatedButton(
  //               onPressed: (_videoUploading || _issueVideo != null) ? null : () => _showVideoSourceDialog(),
  //               style: ElevatedButton.styleFrom(
  //                 backgroundColor: Colors.black,
  //                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
  //                 shape: RoundedRectangleBorder(
  //                   borderRadius: BorderRadius.circular(4),
  //                 ),
  //               ),
  //               child: _videoUploading
  //                   ? const SizedBox(
  //                       height: 16,
  //                       width: 16,
  //                       child: CircularProgressIndicator(
  //                         color: Colors.white,
  //                         strokeWidth: 2,
  //                       ),
  //                     )
  //                   : Text(
  //                       _issueVideo != null 
  //                           ? 'Video Added' 
  //                           : 'Add Video',
  //                       style: const TextStyle(
  //                         color: Colors.white,
  //                         fontSize: 12,
  //                         fontWeight: FontWeight.w600,
  //                       ),
  //                     ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildDropdownField(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: const Text('Select'),
              isExpanded: true,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue),
            ),
          ),
        ),
      ],
    );
  }

  // UPDATED: Multiple image source dialog with enhanced options
  Future<void> _showImageSourceDialog(String type) async {
    return showDialog(
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
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery (Single)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(type, ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Gallery (Multiple)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultipleImagesFromGallery(type);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // UPDATED: Video source dialog with enhanced options
  Future<void> _showVideoSourceDialog() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Video Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.videocam),
                title: const Text('Record Video (10 sec max)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.video_library),
                title: const Text('Gallery (10 sec max)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickVideo(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // UPDATED: Single image picker
  Future<void> _pickImage(String type, ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        File imageFile = File(image.path);
        
        setState(() {
          List<File> targetList = _getImageListByType(type);
          if (targetList.length < maxImagesPerView) {
            targetList.add(imageFile);
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking image: $e');
    }
  }

  // NEW: Multiple image picker from gallery
  Future<void> _pickMultipleImagesFromGallery(String type) async {
    try {
      List<File> targetList = _getImageListByType(type);
      
      // Pick images one by one until limit is reached
      while (targetList.length < maxImagesPerView) {
        final XFile? image = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1024,
          maxHeight: 1024,
          imageQuality: 85,
        );
        
        if (image != null) {
          setState(() {
            targetList.add(File(image.path));
          });
          
          // Ask user if they want to add more images
          if (targetList.length < maxImagesPerView) {
            bool? addMore = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Add More Images'),
                content: Text('You have added ${targetList.length} image(s). Do you want to add more? (Max: $maxImagesPerView)'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Yes'),
                  ),
                ],
              ),
            );
            
            if (addMore != true) break;
          }
        } else {
          break; // User cancelled
        }
      }
    } catch (e) {
      _showErrorDialog('Error picking images: $e');
    }
  }

  // Helper method to get the correct image list by type
  List<File> _getImageListByType(String type) {
    switch (type) {
      case 'left':
        return _leftViewImages;
      case 'right':
        return _rightViewImages;
      case 'issue':
        return _issueImages;
      case 'front':
        return _frontViewImages;
      default:
        return [];
    }
  }

  // UPDATED: Video picker with better error handling
  // Future<void> _pickVideo(ImageSource source) async {
  //   try {
  //     setState(() => _videoUploading = true);
      
  //     final XFile? video = await _picker.pickVideo(
  //       source: source,
  //       maxDuration: const Duration(seconds: 10),
  //     );
      
  //     if (video != null) {
  //       File videoFile = File(video.path);
        
  //       // Initialize video controller
  //       _videoController = VideoPlayerController.file(videoFile);
  //       await _videoController!.initialize();
        
  //       setState(() {
  //         _issueVideo = videoFile;
  //       });
  //     }
  //   } catch (e) {
  //     _showErrorDialog('Error picking video: $e');
  //   } finally {
  //     setState(() => _videoUploading = false);
  //   }
  // }

  Future<List<String>> _uploadMultipleImages(List<File> images, String prefix) async {
    List<String> urls = [];
    
    for (int i = 0; i < images.length; i++) {
      String fileName = '${widget.srNumber}_${prefix}_${i + 1}.jpg';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('service_requests')
          .child(widget.srNumber)
          .child(fileName);

      try {
        UploadTask uploadTask = storageRef.putFile(images[i]);
        TaskSnapshot snapshot = await uploadTask;
        String downloadUrl = await snapshot.ref.getDownloadURL();
        urls.add(downloadUrl);
      } catch (e) {
        print('Error uploading image $i: $e');
      }
    }
    
    return urls;
  }

  Future<String?> _uploadVideoToFirebase(File videoFile) async {
    try {
      String fileName = '${widget.srNumber}_issue_video.mp4';
      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('service_requests')
          .child(widget.srNumber)
          .child(fileName);

      UploadTask uploadTask = storageRef.putFile(videoFile);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      print('Error uploading video: $e');
      return null;
    }
  }

  Future<void> _saveServiceData() async {
    // Validate required fields
    if (_selectedComplaintTypes.isEmpty || _selectedIssueTypes.isEmpty) {
      _showErrorDialog('Please fill in all required fields');
      return;
    }

    if (_selectedComplaintTypes.contains('Others') && _complaintOthersController.text.trim().isEmpty) {
      _showErrorDialog('Please specify the complaint type');
      return;
    }

    if (_selectedIssueTypes.contains('Others') && _issueOthersController.text.trim().isEmpty) {
      _showErrorDialog('Please specify the issue type');
      return;
    }

    setState(() => _isUploading = true);

    try {
      // Upload multiple images
      List<String> leftViewUrls = [];
      List<String> rightViewUrls = [];
      List<String> issueImageUrls = [];
      List<String> frontViewUrls = [];

      if (_leftViewImages.isNotEmpty) {
        leftViewUrls = await _uploadMultipleImages(_leftViewImages, 'left_view');
      }

      if (_rightViewImages.isNotEmpty) {
        rightViewUrls = await _uploadMultipleImages(_rightViewImages, 'right_view');
      }

      if (_issueImages.isNotEmpty) {
        issueImageUrls = await _uploadMultipleImages(_issueImages, 'issue_photo');
      }

      if (_frontViewImages.isNotEmpty) {
        frontViewUrls = await _uploadMultipleImages(_frontViewImages, 'front_view');
      }

      // Upload video
      String? videoUrl;
      if (_issueVideo != null) {
        videoUrl = await _uploadVideoToFirebase(_issueVideo!);
      }

      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final FirebaseAuth auth = FirebaseAuth.instance;
      final user = auth.currentUser;
    
      final doc = await firestore.collection('technicians').doc(user?.uid).get();
      final data = doc.data() as Map<String, dynamic>;
      String technician = data['name'] ?? 'Unknown Technician';
      String empId = data['employeeId'] ?? 'Unknown Employee ID';
      
      // Prepare data for Firestore
      Map<String, dynamic> serviceData = {
        'technician': technician,
        'empId': empId,
        'srNumber': widget.srNumber,
        'customerComplaint': widget.customerComplaint,
        'complaintRelatedTo': _selectedComplaintTypes.join(', '),
        'typeOfRaisedIssue': _selectedIssueTypes.join(', '),
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'in_progress',
        'awgSerialNumber': widget.awgSerialNumber,
      };

      // Add image URLs arrays if available
      if (leftViewUrls.isNotEmpty) serviceData['leftViewImageUrls'] = leftViewUrls;
      if (rightViewUrls.isNotEmpty) serviceData['rightViewImageUrls'] = rightViewUrls;
      if (issueImageUrls.isNotEmpty) serviceData['issueImageUrls'] = issueImageUrls;
      if (frontViewUrls.isNotEmpty) serviceData['frontViewImageUrls'] = frontViewUrls;

      // Add video URL if available
      if (videoUrl != null) serviceData['issueVideoUrl'] = videoUrl;

      // Add others text if applicable
      if (_selectedComplaintTypes.contains('Others')) {
        serviceData['complaintOthersText'] = _complaintOthersController.text.trim();
      }
      if (_selectedIssueTypes.contains('Others')) {
        serviceData['issueOthersText'] = _issueOthersController.text.trim();
      }

      // Handle "Others" text for complaint types
      if (_selectedComplaintTypes.contains('Others')) {
        serviceData['complaintRelatedTo'] = _selectedComplaintTypes
            .map((type) => type == 'Others' ? _complaintOthersController.text.trim() : type)
            .join(', ');
      }
      
      // Handle "Others" text for issue types
      if (_selectedIssueTypes.contains('Others')) {
        serviceData['typeOfRaisedIssue'] = _selectedIssueTypes
            .map((type) => type == 'Others' ? _issueOthersController.text.trim() : type)
            .join(', ');
      }

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('serviceHistory')
          .doc(widget.srNumber)
          .set(serviceData, SetOptions(merge: true));

      // Navigate to resolution screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ResolutionPage(
            srNumber: widget.srNumber,
          ),
        ),
      );

    } catch (e) {
      _showErrorDialog('Error saving data: $e');
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  // UPDATED: Video picker with proper setState and thumbnail display
// Future<void> _pickVideo(ImageSource source) async {
//   try {
//     setState(() => _videoUploading = true);
    
//     final XFile? video = await _picker.pickVideo(
//       source: source,
//       maxDuration: const Duration(seconds: 10),
//     );
    
//     if (video != null) {
//       File videoFile = File(video.path);
      
//       // Dispose previous controller if exists
//       _videoController?.dispose();
      
//       // Initialize video controller
//       _videoController = VideoPlayerController.file(videoFile);
      
//       // Wait for initialization and then update UI
//       await _videoController!.initialize();
      
//       setState(() {
//         _issueVideo = videoFile;
//         _videoUploading = false; // Move this inside setState
//       });
//     } else {
//       setState(() => _videoUploading = false);
//     }
//   } catch (e) {
//     _showErrorDialog('Error picking video: $e');
//     setState(() => _videoUploading = false);
//   }
// }

// // Also update your video section widget to handle the loading state better
// Widget _buildVideoSection() {
//   return Column(
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       // Video preview
//       if (_issueVideo != null && _videoController != null && _videoController!.value.isInitialized)
//         Container(
//           height: 200,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey[300]!),
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(8),
//             child: Stack(
//               children: [
//                 // Add AspectRatio widget to maintain proper video dimensions
//                 AspectRatio(
//                   aspectRatio: _videoController!.value.aspectRatio,
//                   child: VideoPlayer(_videoController!),
//                 ),
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             if (_videoController!.value.isPlaying) {
//                               _videoController!.pause();
//                             } else {
//                               _videoController!.play();
//                             }
//                           });
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: const BoxDecoration(
//                             color: Colors.black54,
//                             shape: BoxShape.circle,
//                           ),
//                           child: Icon(
//                             _videoController!.value.isPlaying 
//                                 ? Icons.pause 
//                                 : Icons.play_arrow,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 8),
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _videoController?.dispose();
//                             _videoController = null;
//                             _issueVideo = null;
//                           });
//                         },
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: const BoxDecoration(
//                             color: Colors.red,
//                             shape: BoxShape.circle,
//                           ),
//                           child: const Icon(
//                             Icons.close,
//                             color: Colors.white,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
      
//       // Show loading indicator while video is being processed
//       if (_issueVideo != null && (_videoController == null || !_videoController!.value.isInitialized))
//         Container(
//           height: 200,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: Colors.grey[300]!),
//             color: Colors.grey[100],
//           ),
//           child: const Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text(
//                   'Loading video...',
//                   style: TextStyle(color: Colors.grey),
//                 ),
//               ],
//             ),
//           ),
//         ),
      
//       if (_issueVideo != null) const SizedBox(height: 8),
      
//       // Add video button (rest of your existing code...)
//       Container(
//         width: double.infinity,
//         height: 120,
//         decoration: BoxDecoration(
//           color: Colors.grey[50],
//           borderRadius: BorderRadius.circular(8),
//           border: Border.all(color: Colors.grey[300]!),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(
//                   Icons.videocam_outlined,
//                   size: 24,
//                   color: Colors.grey[400],
//                 ),
//                 const SizedBox(width: 8),
//                 Icon(
//                   Icons.video_library_outlined,
//                   size: 24,
//                   color: Colors.grey[400],
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _issueVideo == null 
//                   ? 'No Video uploaded' 
//                   : 'Video ready',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 12,
//               ),
//             ),
//             const SizedBox(height: 8),
//             ElevatedButton(
//               onPressed: (_videoUploading || _issueVideo != null) ? null : () => _showVideoSourceDialog(),
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.black,
//                 padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(4),
//                 ),
//               ),
//               child: _videoUploading
//                   ? const SizedBox(
//                       height: 16,
//                       width: 16,
//                       child: CircularProgressIndicator(
//                         color: Colors.white,
//                         strokeWidth: 2,
//                       ),
//                     )
//                   : Text(
//                       _issueVideo != null 
//                           ? 'Video Added' 
//                           : 'Add Video',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 12,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     ],
//   );
// }


// Add this boolean to your state variables at the top of the class
bool _videoInitializing = false;

// Replace your existing _buildVideoSection method with this improved version
Widget _buildVideoSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Video preview
      if (_issueVideo != null)
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // Show loading indicator while initializing
                if (_videoInitializing || _videoController == null)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                else if (_videoController!.value.isInitialized)
                  // Show video player when ready
                  SizedBox.expand(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: VideoPlayer(_videoController!),
                      ),
                    ),
                  )
                else
                  // Show error state
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.white, size: 48),
                        SizedBox(height: 8),
                        Text(
                          'Failed to load video',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),

                // Control buttons (only show when video is ready)
                if (_videoController != null && 
                    _videoController!.value.isInitialized && 
                    !_videoInitializing)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _videoController!.value.isPlaying 
                                  ? Icons.pause 
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _videoController?.dispose();
                              _videoController = null;
                              _issueVideo = null;
                              _videoInitializing = false;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Video duration indicator (bottom left)
                if (_videoController != null && 
                    _videoController!.value.isInitialized && 
                    !_videoInitializing)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(_videoController!.value.duration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      
      if (_issueVideo != null) const SizedBox(height: 8),
      
      // Add video button (same as before)
      Container(
        width: double.infinity,
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 24,
                  color: Colors.grey[400],
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.video_library_outlined,
                  size: 24,
                  color: Colors.grey[400],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _issueVideo == null 
                  ? 'No Video uploaded' 
                  : 'Video ready',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: (_videoUploading || _videoInitializing || _issueVideo != null) 
                  ? null 
                  : () => _showVideoSourceDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: (_videoUploading || _videoInitializing)
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      _issueVideo != null 
                          ? 'Video Added' 
                          : 'Add Video',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    ],
  );
}

// Replace your existing _pickVideo method with this improved version
Future<void> _pickVideo(ImageSource source) async {
  try {
    setState(() => _videoUploading = true);
    
    final XFile? video = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 10),
    );
    
    if (video != null) {
      File videoFile = File(video.path);
      
      // Set initializing state
      setState(() {
        _videoInitializing = true;
        _videoUploading = false;
        _issueVideo = videoFile;
      });
      
      try {
        // Dispose previous controller if exists
        await _videoController?.dispose();
        
        // Initialize new video controller
        _videoController = VideoPlayerController.file(videoFile);
        await _videoController!.initialize();
        
        // Listen to video controller changes for play/pause updates
        _videoController!.addListener(() {
          if (mounted) setState(() {});
        });
        
        setState(() {
          _videoInitializing = false;
        });
        
      } catch (e) {
        print('Error initializing video: $e');
        setState(() {
          _videoInitializing = false;
          _issueVideo = null;
          _videoController = null;
        });
        _showErrorDialog('Error loading video: $e');
      }
    }
  } catch (e) {
    setState(() {
      _videoUploading = false;
      _videoInitializing = false;
    });
    _showErrorDialog('Error picking video: $e');
  } finally {
    if (mounted) {
      setState(() => _videoUploading = false);
    }
  }
}

// Add this helper method for formatting video duration
String _formatDuration(Duration duration) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  return "$twoDigitMinutes:$twoDigitSeconds";
}

// Also update your dispose method to handle the new state

void _showComplaintSelectionDialog() {
  List<String> tempSelected = List.from(_selectedComplaintTypes);
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Select Complaint Related to (Multiple Selection)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: _complaintTypes.map((item) => CheckboxListTile(
              title: Text(item),
              value: tempSelected.contains(item),
              onChanged: (value) {
                setDialogState(() {
                  if (value == true) {
                    tempSelected.add(item);
                  } else {
                    tempSelected.remove(item);
                  }
                });
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedComplaintTypes = tempSelected;
              });
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}
void _showIssueSelectionDialog() {
  List<String> tempSelected = List.from(_selectedIssueTypes);
  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Select Type of Raised Issue (Multiple Selection)'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView(
            children: _issueTypes.map((item) => CheckboxListTile(
              title: Text(item),
              value: tempSelected.contains(item),
              onChanged: (value) {
                setDialogState(() {
                  if (value == true) {
                    tempSelected.add(item);
                  } else {
                    tempSelected.remove(item);
                  }
                });
              },
            )).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedIssueTypes = tempSelected;
              });
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    ),
  );
}



}

