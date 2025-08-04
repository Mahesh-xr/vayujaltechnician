import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/pages/videoPlayerHelper.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String srId;

  const ServiceDetailsScreen({super.key, required this.srId});

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  Map<String, dynamic>? _serviceRequest;
  Map<String, dynamic>? _serviceHistory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceRequest();
  }

  Future<void> _loadServiceRequest() async {
    try {
      // Load service request data
      final serviceRequestDoc = await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(widget.srId)
          .get();

      // Load service history data
      final serviceHistoryDoc = await FirebaseFirestore.instance
          .collection('serviceHistory')
          .doc(widget.srId)
          .get();

      if (serviceRequestDoc.exists) {
        setState(() {
          _serviceRequest = serviceRequestDoc.data();
          _serviceHistory = serviceHistoryDoc.exists ? serviceHistoryDoc.data() : null;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Service request not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error loading service request: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        date = timestamp.toDate();
      }
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDateTime(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else {
        date = timestamp.toDate();
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} at ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : 'N/A',
              style: const TextStyle(
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLabeledContent({
    required String content,
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color? textColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 4),
        Text(
          content,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: fontWeight,
            color: textColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Normalappbar(title: 'Service Details'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceRequest == null
              ? const Center(child: Text('Service request not found'))
              : _buildServiceDetails(),
    );
  }

  Widget _buildServiceDetails() {
    final serviceDetails = _serviceRequest!['serviceDetails'] ?? {};
    final equipmentDetails = _serviceRequest!['equipmentDetails'] ?? {};
    final customerDetails = _serviceRequest!['customerDetails'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Service Request Header
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.srId,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Status: ${(_serviceRequest!['status'] ?? 'pending').toString().replaceAll('_', ' ').toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Equipment Details
          _buildInfoCard(
            'Equipment Details',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Model', equipmentDetails['model'] ?? 'Unknown'),
                _buildDetailRow('Serial Number', equipmentDetails['awgSerialNumber'] ?? 'Unknown'),
                _buildDetailRow('City', equipmentDetails['city'] ?? 'Unknown'),
                _buildDetailRow('State', equipmentDetails['state'] ?? 'Unknown'),
              ],
            ),
            Icons.devices,
          ),
          const SizedBox(height: 16),

          // Customer Details
          _buildInfoCard(
            'Customer Details',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Name', customerDetails['name'] ?? 'Unknown'),
                _buildDetailRow('Company', customerDetails['company'] ?? 'Unknown'),
                _buildDetailRow('Phone', customerDetails['phone'] ?? 'Unknown'),
                _buildDetailRow('Email', customerDetails['email'] ?? 'Unknown'),
              ],
            ),
            Icons.person,
          ),
          const SizedBox(height: 16),

          // Complaint Details (conditional)
          _buildComplaintDetails(),

          // Service Execution Details (if service history exists)
          _buildServiceExecutionDetails(),

          // Technician Details (if service history exists)
          _buildTechnicianDetails(),

          // Solution Provided (if available)
          _buildSolutionProvided(),

          // Custom Suggestions (if available)
          _buildCustomSuggestions(),

          // Maintenance Suggestions
          _buildMaintenanceSuggestions(),

          // Enhanced Image Gallery
          _buildEnhancedImageGallery(),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, Widget content, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: content,
          ),
        ],
      ),
    );
  }

  void _acknowledgeServiceRequest() async {
    try {
      await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(widget.srId)
          .update({
        'status': 'acknowledged',
        'acknowledgedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service request acknowledged successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Refresh the data
      _loadServiceRequest();
    } catch (e) {
      _showErrorSnackBar('Error acknowledging service request: $e');
    }
  }

  // Complaint Details (conditional)
  Widget _buildComplaintDetails() {
    final serviceDetails = _serviceRequest!['serviceDetails'] ?? {};
    String requestType = serviceDetails['requestType'] ?? '';
    String description = serviceDetails['description'] ?? '';
    String comments = serviceDetails['comments'] ?? '';
    
    if (requestType.toLowerCase().contains('complaint') || 
        description.isNotEmpty || 
        comments.isNotEmpty) {
      
      return _buildInfoCard(
        'Complaint Details',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Request Type', requestType),
            _buildDetailRow('Description', description),
            if (comments.isNotEmpty && comments != description) 
              _buildDetailRow('Comments', comments),
          ],
        ),
        Icons.report_problem,
      );
    }
    
    return const SizedBox.shrink();
  }



  // Service Execution Details
  Widget _buildServiceExecutionDetails() {
    if (_serviceHistory == null) {
      return const SizedBox.shrink();
    }

    return _buildInfoCard(
      'Service Execution Details',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Status', (_serviceHistory!['status'] ?? '').toString().replaceAll('_', ' ').toUpperCase()),
          _buildDetailRow('Complaint \nRelated To', _serviceHistory!['complaintRelatedTo'] ?? ''),
          _buildDetailRow('Type of Issue Raised', _serviceHistory!['typeOfRaisedIssue'] ?? ''),
          _buildDetailRow('Issue Type', _serviceHistory!['issueType'] ?? ''),
          const SizedBox(height: 8),
          _buildChipList('Issue Identification', _serviceHistory!['issueIdentification']),
          _buildChipList('Parts Replaced', _serviceHistory!['partsReplaced']),
        ],
      ),
      Icons.build,
    );
  }

  // Technician Details
  Widget _buildTechnicianDetails() {
    if (_serviceHistory == null) {
      return const SizedBox.shrink();
    }

    return _buildInfoCard(
      'Technician Details',
      Column(
        children: [
          _buildDetailRow('Technician Name', _serviceHistory!['technician'] ?? ''),
          _buildDetailRow('Employee ID', _serviceHistory!['empId'] ?? ''),
          _buildDetailRow('Resolved By ID', _serviceHistory!['resolvedBy'] ?? ''),
          _buildDetailRow('Service Date', _formatDateTime(_serviceHistory!['timestamp'])),
          _buildDetailRow('Resolution Date', _formatDateTime(_serviceHistory!['resolutionTimestamp'])),
          _buildDetailRow('Next Service Date', _formatDate(_serviceHistory!['nextServiceDate'])),
        ],
      ),
      Icons.engineering,
    );
  }

  // Solution Provided
  Widget _buildSolutionProvided() {
    if (_serviceHistory == null || _serviceHistory!['solutionProvided'] == null) {
      return const SizedBox.shrink();
    }

    return _buildInfoCard(
      'Solution Provided', 
      buildLabeledContent(content: _serviceHistory!['solutionProvided'] ?? ''),
      Icons.check_circle,
    );
  }

  // Custom Suggestions
  Widget _buildCustomSuggestions() {
    if (_serviceHistory == null || _serviceHistory!['customSuggestions'] == null) {
      return const SizedBox.shrink();
    }

    return _buildInfoCard(
      'Custom Suggestions', 
      buildLabeledContent(content: _serviceHistory!['customSuggestions'] ?? ''),
      Icons.lightbulb,
    );
  }

  // Maintenance Suggestions
  Widget _buildMaintenanceSuggestions() {
    if (_serviceHistory == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic> suggestions = _serviceHistory!['suggestions'] ?? {};
    List<Widget> suggestionWidgets = [];

    suggestions.forEach((key, value) {
      if (value == true) {
        String displayText = key.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim();
        suggestionWidgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (suggestionWidgets.isEmpty) {
      suggestionWidgets.add(
        const Text(
          'No maintenance suggestions provided',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return _buildInfoCard(
      'Maintenance Suggestions',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestionWidgets,
      ),
      Icons.lightbulb,
    );
  }

  // Enhanced Image Gallery
  Widget _buildEnhancedImageGallery() {
    if (_serviceHistory == null) {
      return const SizedBox.shrink();
    }

    // Extract different types of images safely
    final List<String> frontViewImages = _extractUrls(_serviceHistory!['frontViewImageUrls']);
    final List<String> leftViewImages = _extractUrls(_serviceHistory!['leftViewImageUrls']);
    final List<String> rightViewImages = _extractUrls(_serviceHistory!['rightViewImageUrls']);
    final List<String> issueImages = _extractUrls(_serviceHistory!['issueImageUrls']);
    final List<String> resolutionImages = _extractUrls(_serviceHistory!['resolutionImageUrls']);

    // Extract video URLs safely
    final String? issueVideoUrl = _serviceHistory!['issueVideoUrl']?.toString();
    final String? resolutionVideoUrl = _serviceHistory!['resolutionVideoUrl']?.toString();

    return Column(
      children: [
        // Front View Images
        if (frontViewImages.isNotEmpty)
          _buildPhotoCarousel(
            frontViewImages, 
            'Front View Images',
            accentColor: Colors.blue,
          ),
        
        // Left View Images
        if (leftViewImages.isNotEmpty)
          _buildPhotoCarousel(
            leftViewImages, 
            'Left View Images',
            accentColor: Colors.green,
          ),
        
        // Right View Images
        if (rightViewImages.isNotEmpty)
          _buildPhotoCarousel(
            rightViewImages, 
            'Right View Images',
            accentColor: Colors.orange,
          ),
        
        // Issue Images
        if (issueImages.isNotEmpty)
          _buildPhotoCarousel(
            issueImages, 
            'Issue Images',
            accentColor: Colors.red,
          ),
        
        // Resolution Images
        if (resolutionImages.isNotEmpty)
          _buildPhotoCarousel(
            resolutionImages, 
            'Resolution Images',
            accentColor: Colors.teal,
          ),
        
        // Issue Video
        if (issueVideoUrl != null && issueVideoUrl.isNotEmpty)
          _buildVideoSection(
            issueVideoUrl,
            'Issue Video',
            accentColor: Colors.red,
          ),
        
        // Resolution Video
        if (resolutionVideoUrl != null && resolutionVideoUrl.isNotEmpty)
          _buildVideoSection(
            resolutionVideoUrl,
            'Resolution Video',
            accentColor: Colors.teal,
          ),
      ],
    );
  }

  // Helper method to safely extract URLs from different data types
  List<String> _extractUrls(dynamic urlData) {
    if (urlData == null) return [];
    
    if (urlData is List) {
      return urlData
          .where((url) => url != null && url.toString().isNotEmpty)
          .map((url) => url.toString())
          .toList();
    } else if (urlData is String && urlData.isNotEmpty) {
      return [urlData];
    }
    return [];
  }

  // Build photo carousel for specific image type
  Widget _buildPhotoCarousel(List<String> photos, String title, {Color? accentColor}) {
    if (photos.isEmpty) return const SizedBox.shrink();
    
    final PageController pageController = PageController();
    final Color cardColor = accentColor ?? Colors.blue;
    
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconForTitle(title),
                  color: cardColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${photos.length} photo${photos.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PageView.builder(
                controller: pageController,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () => _showFullScreenImage(photos[index], title),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(photos[index]),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (photos.length > 1) ...[
              const SizedBox(height: 12),
              _buildPhotoIndicators(photos.length, pageController, cardColor),
            ],
          ],
        ),
      ),
    );
  }

  // Build video section
  Widget _buildVideoSection(String? videoUrl, String title, {Color? accentColor}) {
    if (videoUrl == null || videoUrl.isEmpty) return const SizedBox.shrink();
    
    final Color cardColor = accentColor ?? Colors.purple;
    
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.videocam_outlined,
                  color: cardColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: cardColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardColor),
              ),
              child: InkWell(
                onTap: () => _playVideo(videoUrl, title),
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap to Play Video',
                      style: TextStyle(
                        color: cardColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build image widget with error handling
  Widget _buildImageWidget(String imageUrl) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          color: Colors.grey.shade100,
          child: Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                  : null,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.grey.shade200,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                color: Colors.grey.shade400,
                size: 48,
              ),
              const SizedBox(height: 8),
              Text(
                'Image not available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show full screen image
  void _showFullScreenImage(String imageUrl, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            title: Text(title, style: const TextStyle(color: Colors.white)),
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Failed to load image',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Play video
  void _playVideo(String videoUrl, String title) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenVideoPlayer(
          videoUrl: videoUrl,
          title: title,
        ),
      ),
    );
  }

  // Build chip list for arrays
  Widget _buildChipList(String label, dynamic items) {
    List<dynamic> itemList = [];

    if (items == null) {
      return _buildDetailRow(label, 'None');
    } else if (items is List) {
      itemList = items;
    } else if (items is String) {
      if (items.isNotEmpty) {
        itemList = [items];
      }
    } else {
      itemList = [items.toString()];
    }

    if (itemList.isEmpty) {
      return _buildDetailRow(label, 'None');
    }

    String itemText = itemList.join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            itemText,
            style: TextStyle(
              fontSize: 13,
              color: Colors.blue.shade700,
            ),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  // Build photo indicators
  Widget _buildPhotoIndicators(int count, PageController controller, Color accentColor) {
    return StreamBuilder<int>(
      stream: Stream.periodic(const Duration(milliseconds: 100)).map((_) {
        return controller.hasClients ? (controller.page?.round() ?? 0) : 0;
      }),
      builder: (context, snapshot) {
        final currentPage = snapshot.data ?? 0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(count, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: currentPage == index ? accentColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        );
      },
    );
  }

  // Get appropriate icon for title
  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'front view images':
        return Icons.camera_front_outlined;
      case 'left view images':
        return Icons.rotate_left_outlined;
      case 'right view images':
        return Icons.rotate_right_outlined;
      case 'issue images':
        return Icons.report_problem_outlined;
      case 'resolution images':
        return Icons.check_circle_outline;
      default:
        return Icons.photo_library_outlined;
    }
  }
}