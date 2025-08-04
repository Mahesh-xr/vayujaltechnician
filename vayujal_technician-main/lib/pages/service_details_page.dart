import 'package:flutter/material.dart';
import 'package:vayujal_technician/DatabaseActions/adminAction.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/pages/videoPlayerHelper.dart';
import 'package:vayujal_technician/screens/service_hostory_screen.dart';
import 'package:vayujal_technician/screens/startservice.dart';
import 'package:vayujal_technician/utils/submit_button.dart';

class ServiceDetailsPage extends StatefulWidget {
  final String serviceRequestId;
  
  const ServiceDetailsPage({
    super.key,
    required this.serviceRequestId,
  });

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  Map<String, dynamic>? _serviceRequest;
  Map<String, dynamic>? _serviceHistory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServiceRequestDetails();
  }

  Future<void> _loadServiceRequestDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      Map<String, dynamic>? serviceRequest = await AdminAction.getServiceRequestById(widget.serviceRequestId);
      Map<String, dynamic>? serviceHistory = await AdminAction.getServiceHistoryBySrId(widget.serviceRequestId);
      
      setState(() {
        _serviceRequest = serviceRequest;
        _serviceHistory = serviceHistory;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading service request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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

  Widget _buildDetailCard(String title, Widget content) {
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
                  _getSectionIcon(title),
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

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Service Request Information':
        return Icons.assignment;
      case 'VJ AWG Details':
        return Icons.devices;
      case 'Equipment Details':
        return Icons.devices;
      case 'Owner Details':
        return Icons.person;
      case 'Customer Details':
        return Icons.person;
      case 'Service History':
        return Icons.history;
      case 'Complaint Details':
        return Icons.report_problem;
      case 'Service Execution Details':
        return Icons.build;
      case 'Technician Details':
        return Icons.engineering;
      case 'Service Images':
        return Icons.photo_library;
      case 'Resolution Details':
        return Icons.check_circle;
      case 'Solution Provided':
        return Icons.check_circle;
      case 'Custom Suggestions':
        return Icons.lightbulb;
      case 'Maintenance Suggestions':
        return Icons.lightbulb;
      case 'Service Action':
        return Icons.build;
      default:
        return Icons.info;
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

  Widget _buildEquipmentDetails() {
    Map<String, dynamic> equipmentDetails = _serviceRequest?['equipmentDetails'] ?? {};
    
    return _buildDetailCard(
      'VJ AWG Details',
      Column(
        children: [
          _buildDetailRow('Model', equipmentDetails['model'] ?? ''),
          _buildDetailRow('Serial Number', equipmentDetails['awgSerialNumber'] ?? ''),
          _buildDetailRow('City', equipmentDetails['city'] ?? ''),
          _buildDetailRow('State', equipmentDetails['state'] ?? ''),
          _buildDetailRow('Owner', equipmentDetails['owner'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildOwnerDetails() {
    Map<String, dynamic> customerDetails = _serviceRequest?['customerDetails'] ?? {};
    
    return _buildDetailCard(
      'Owner Details',
      Column(
        children: [
          _buildDetailRow('Name', customerDetails['name'] ?? ''),
          _buildDetailRow('Company', customerDetails['company'] ?? ''),
          _buildDetailRow('Mobile', customerDetails['phone'] ?? ''),
          _buildDetailRow('Email', customerDetails['email'] ?? ''),
          _buildDetailRow('Address', customerDetails['address']['fullAddress'] ?? ''),
        ],
      ),
    );
  }

  Widget _buildServiceHistory() {
    Map<String, dynamic> serviceDetails = _serviceRequest?['equipmentDetails']['amcDetails'] ?? {};
    
    return _buildDetailCard(
      'Service History',
      Column(
        children: [
          _buildDetailRow('AMC Start', (serviceDetails['amcStartDate'] ?? '')),
          _buildDetailRow('AMC End', (serviceDetails['amcEndDate'] ?? '')),
          _buildDetailRow('AMC Type', (serviceDetails['amcType'] ?? '')),
          _buildDetailRow("Annual Contact", (serviceDetails['annualContract'] ? 'yes':'no')),
          SubmitButton(
            text: "View Full History",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ServiceHistoryScreen(
                    serialNumber: _serviceRequest?['deviceId'],
                  ),
                ),
              );
            }
          )
        ],
      ),
    );
  }

  Widget _buildComplaintDetails() {
    Map<String, dynamic> serviceDetails = _serviceRequest?['serviceDetails'] ?? {};
    String requestType = serviceDetails['requestType'] ?? '';
    String description = serviceDetails['description'] ?? '';
    String comments = serviceDetails['comments'] ?? '';
    
    if (requestType.toLowerCase().contains('complaint') || 
        description.isNotEmpty || 
        comments.isNotEmpty) {
      
      return _buildDetailCard(
        'Complaint Details',
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (comments.isNotEmpty && comments != description) ...[
              const Text(
                'Details',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                comments,
                style: const TextStyle(
                  color: Colors.black87,
                ),
              ),
            ],
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
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

  Widget _buildServiceExecutionDetails() {
    if (_serviceHistory == null) {
      return const SizedBox.shrink();
    }

    return _buildDetailCard(
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
    );
  }

  Widget _buildTechnicianDetails() {
    if (_serviceHistory == null) {
      return const SizedBox.shrink();
    }

    return _buildDetailCard(
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
    );
  }

  Widget _buildMaintenanceSuggestions() {
    if (_serviceHistory == null || _serviceHistory!['suggestions'] == null) {
      return const SizedBox.shrink();
    }

    Map<String, dynamic> suggestions = _serviceHistory!['suggestions'];
    List<Widget> suggestionWidgets = [];

    suggestions.forEach((key, value) {
      if (value == true) {
        String readableKey = key.replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        ).toLowerCase();
        readableKey = readableKey[0].toUpperCase() + readableKey.substring(1);
        
        suggestionWidgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    readableKey,
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    });

    if (suggestionWidgets.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildDetailCard(
      'Maintenance Suggestions',
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: suggestionWidgets,
      ),
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

  // Enhanced image gallery replacement
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
        _buildPhotoCarousel(
          frontViewImages, 
          'Front View Images',
          accentColor: Colors.blue,
        ),
        
        // Left View Images
        _buildPhotoCarousel(
          leftViewImages, 
          'Left View Images',
          accentColor: Colors.green,
        ),
        
        // Right View Images
        _buildPhotoCarousel(
          rightViewImages, 
          'Right View Images',
          accentColor: Colors.orange,
        ),
        
        // Issue Images
        _buildPhotoCarousel(
          issueImages, 
          'Issue Images',
          accentColor: Colors.red,
        ),
        
        // Resolution Images
        _buildPhotoCarousel(
          resolutionImages, 
          'Resolution Images',
          accentColor: Colors.teal,
        ),
        
        // Issue Video
        _buildVideoSection(
          issueVideoUrl,
          'Issue Video',
          accentColor: Colors.red,
        ),
        
        // Resolution Video
        _buildVideoSection(
          resolutionVideoUrl,
          'Resolution Video',
          accentColor:  Colors.teal,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: Normalappbar(
        title: 'Service Details',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceRequest == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Service request not found',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Go Back',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadServiceRequestDetails,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
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
                                  _serviceRequest?['serviceDetails']?['srId'] ?? 
                                  _serviceRequest?['srId'] ?? 
                                  'Service Request',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Status: ${(_serviceRequest?['serviceDetails']?['status'] ?? _serviceRequest?['status'] ?? 'pending').toString().replaceAll('_', ' ').toUpperCase()}',
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
                        _buildEquipmentDetails(),

                        // Owner Details
                        _buildOwnerDetails(),

                        // Service History
                        _buildServiceHistory(),

                        // Complaint Details (conditional)
                        _buildComplaintDetails(),


                        _buildStartServiceButton(),

                        // Service Execution Details (only if service history exists)
                        _buildServiceExecutionDetails(),

                        // Technician Details (only if service history exists)
                        _buildTechnicianDetails(),
                        
                        // Solution Provided
                        if (_serviceHistory != null && _serviceHistory!['solutionProvided'] != null)
                          _buildDetailCard(
                            'Solution Provided', 
                            buildLabeledContent(content: _serviceHistory!['solutionProvided'] ?? '')
                          ),
                              if (_serviceHistory != null && _serviceHistory!['customSuggestions'] != null)
                          _buildDetailCard(
                            'Custom Suggestions', 
                            buildLabeledContent(content: _serviceHistory!['customSuggestions'] ?? '')
                          ),

                        // Maintenance Suggestions
                        _buildMaintenanceSuggestions(),

                        // Enhanced Image Gallery
                        _buildEnhancedImageGallery(),

                       
                      

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
    );
  }


    // Add this method to your ServiceDetailsPage class
  Widget _buildStartServiceButton() {
    // Extract the complaint/description for the service
    Map<String, dynamic> serviceDetails = _serviceRequest?['serviceDetails'] ?? {};
    String customerComplaint = serviceDetails['description'] ?? 
                              serviceDetails['comments'] ?? 
                              'Service request';
    
    String srNumber = _serviceRequest?['serviceDetails']?['srId'] ?? 
                     _serviceRequest?['srId'] ?? 
                     widget.serviceRequestId;
    
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
                  Icons.build,
                  color: Colors.blue[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Service Action',
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
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StartServiceScreen(
                        awgSerialNumber: _serviceRequest?['deviceId'] ?? '',
                        srNumber: srNumber,
                        customerComplaint: customerComplaint,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.build, color: Colors.white),
                label: const Text(
                  'Start Service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}


                          