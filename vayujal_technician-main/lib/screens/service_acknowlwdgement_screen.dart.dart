import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/services/otp_services.dart';
import 'package:vayujal_technician/services/pdf_service.dart';
import 'package:intl/intl.dart';

class ServiceAcknowledgmentScreen extends StatefulWidget {
  final String srNumber;

  const ServiceAcknowledgmentScreen({super.key, required this.srNumber});

  @override
  State<ServiceAcknowledgmentScreen> createState() => _ServiceAcknowledgmentScreenState();
}

class _ServiceAcknowledgmentScreenState extends State<ServiceAcknowledgmentScreen> {
  Map<String, dynamic>? _serviceRequestData;
  Map<String, dynamic>? _serviceHistoryData;
  Map<String, dynamic>? _technicianData;
  bool _isLoading = true;
  bool _isGeneratingPdf = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadServiceData();
    print("Navigation to service acknowledgment successful");
  }

  Future<void> _loadServiceData() async {
    try {
      // Load service request data
      final serviceRequestQuery = await FirebaseFirestore.instance
          .collection('serviceRequests')
          .doc(widget.srNumber)
          .get();

      // Load service history data
      final serviceHistoryQuery = await FirebaseFirestore.instance
          .collection('serviceHistory')
          .doc(widget.srNumber)
          .get();

      if (serviceRequestQuery.exists && serviceHistoryQuery.exists) {
        _serviceRequestData = serviceRequestQuery.data();
        _serviceHistoryData = serviceHistoryQuery.data();

        // Load technician data
        final technicianId = _serviceHistoryData!['resolvedBy'] ?? _serviceHistoryData!['technician'];
        if (technicianId != null) {
          final technicianQuery = await FirebaseFirestore.instance
              .collection('technicians')
              .where('uid', isEqualTo: technicianId)
              .get();
          
          if (technicianQuery.docs.isNotEmpty) {
            _technicianData = technicianQuery.docs.first.data();
          }
        }

        setState(() {
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Service data not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading service data: $e';
        _isLoading = false;
      });
    }
  }

  // Show OTP verification dialog before PDF generation
  void _initiateOtpVerification() {
    final customerPhone = _serviceRequestData!['customerDetails']?['phone'];
    
    if (customerPhone == null || customerPhone.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Customer phone number not found. Cannot proceed with verification.'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => OtpVerificationDialog(
        customerPhone: customerPhone.toString(),
        onVerificationSuccess: _generateAndDownloadPdf,
      ),
    );
  }

  // Updated PDF generation method (called after OTP verification)
  Future<void> _generateAndDownloadPdf() async {
    if (_serviceRequestData == null || _serviceHistoryData == null) return;

    setState(() {
      _isGeneratingPdf = true;
      _errorMessage = null;
    });

    try {
      // Generate PDF using the updated method
      final pdfFile = await PdfService.generateServiceAcknowledgmentPdf(
        _serviceRequestData!,
        _serviceHistoryData!,
        _technicianData,
      );
      
      // Share/Download PDF
      await PdfService.shareAcknowledgmentPdf(pdfFile);
      
      // Update acknowledgment status in Firestore
      await FirebaseFirestore.instance
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: widget.srNumber)
          .get()
          .then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({
            'acknowledgmentStatus': 'downloaded',
            'acknowledgmentTimestamp': FieldValue.serverTimestamp(),
            'verifiedDownload': true, // New field to track verified downloads
          });
        }
      });

      // Send notification to admin about service acknowledgment completion
      await _sendServiceAcknowledgmentNotification();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Service acknowledgment PDF generated successfully!'),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
            },
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating PDF: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red[600],
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isGeneratingPdf = false;
         Navigator.pushNamed(context, '/history');

      });
    }
  }

  /// Send notification to admin about service acknowledgment completion
  Future<void> _sendServiceAcknowledgmentNotification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Get technician name
      final technicianDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(user.uid)
          .get();
      
      final technicianName = technicianDoc.exists 
          ? (technicianDoc.data()?['fullName'] ?? technicianDoc.data()?['name'] ?? 'Unknown Technician')
          : 'Unknown Technician';

      // Get customer details
      final customerName = _serviceRequestData!['customerDetails']?['name'] ?? 'Unknown Customer';
      final customerPhone = _serviceRequestData!['customerDetails']?['phone'] ?? 'N/A';
      final customerCompany = _serviceRequestData!['customerDetails']?['company'] ?? 'N/A';

      // Get service details
      final serviceDate = _formatTimestamp(_serviceHistoryData!['timestamp']);
      final nextServiceDate = _formatTimestamp(_serviceHistoryData!['nextServiceDate']);
      final solutionProvided = _serviceHistoryData!['solutionProvided'] ?? 'N/A';
      final partsReplaced = _serviceHistoryData!['partsReplaced'] ?? 'N/A';

      // Create comprehensive notification data
     

      // Create detailed notification message
      final notificationMessage = '''

SR Number: ${widget.srNumber}
Technician: $technicianName
Customer: $customerName ($customerPhone)
Company: $customerCompany
Service Date: $serviceDate
'''.trim();

      // Send notification to admin using Firestore directly
      await FirebaseFirestore.instance.collection('notifications').add({
        'type': 'service_acknowledgment_completed',
        'title': 'Service Acknowledgment Completed',
        'data': {
          'srId': widget.srNumber,
          },
        'message': notificationMessage,
        'recipientRole': 'admin',
        'senderId': user.uid,
        'senderName': technicianName,
        'isRead': false,
        'isActioned': false, // New field to track if action buttons are disabled
        'createdAt': FieldValue.serverTimestamp(),
        'category': 'service_completion', // Add category for filtering
      });

      print('Service acknowledgment notification sent to admin successfully');
      print('Notification details:');
      print('- SR: ${widget.srNumber}');
      print('- Technician: $technicianName');
      print('- Customer: $customerName ($customerPhone)');
      print('- Service Date: $serviceDate');
    } catch (e) {
      print('Error sending service acknowledgment notification: $e');
      // Don't throw error to avoid affecting the main flow
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Normalappbar(
        title: 'Service Acknowledgment'
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _serviceRequestData == null || _serviceHistoryData == null
              ? Center(child: Text(_errorMessage ?? 'Service data not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Service Summary Section
                      _buildSection(
                        'Service Summary',
                        [
                          _buildInfoRow('SR Number', widget.srNumber),
                          _buildInfoRow('Service Date', _formatTimestamp(_serviceHistoryData!['timestamp'])),
                          _buildInfoRow('Next Service Date', _formatTimestamp(_serviceHistoryData!['nextServiceDate'])),
                          _buildInfoRow('Status', _serviceHistoryData!['status'] ?? 'Completed'),
                          _buildInfoRow('Technician', _getTechnicianName()),
                        ],
                      ),

                      // AWG/Device Details Section
                      _buildSection(
                        'AWG Details',
                        [
                          _buildInfoRow('Serial Number', _serviceHistoryData!['awgSerialNumber'] ?? 'N/A'),
                          _buildInfoRow('Model', _serviceRequestData!['equipmentDetails']?['model'] ?? 'N/A'),
                        ],
                      ),

                      // Customer Details Section
                      _buildSection(
                        'Customer Details',
                        [
                          _buildInfoRow('Name', _serviceRequestData!['customerDetails']?['name'] ?? 'N/A'),
                          _buildInfoRow('Phone Number', _serviceRequestData!['customerDetails']?['phone'] ?? 'N/A'),
                          _buildInfoRow('Company', _serviceRequestData!['customerDetails']?['company'] ?? 'N/A'),
                          _buildInfoRow('Address', _getFullAddress()),
                        ],
                      ),

                      // Service Details Section
                      _buildSection(
                        'Service Details',
                        [
                          _buildInfoRow('Customer Complaint', _serviceHistoryData!['customerComplaint'] ?? 'N/A'),
                          _buildInfoRow('Complaint Type', _serviceRequestData!['serviceDetails']?['requestType'] ?? 'N/A'),                       
                          _buildInfoRow('Solution Provided', _serviceHistoryData!['solutionProvided'] ?? 'N/A'),
                          _buildInfoRow('Complaint Related To', _serviceHistoryData!['complaintRelatedTo'] ?? 'N/A'),
                          _buildInfoRow('Issue Type', _serviceHistoryData!['typeOfRaisedIssue'] ?? 'N/A'),
                          _buildInfoRow('Issue Identification', _serviceHistoryData!['issueIdentification'] ?? 'N/A'),
                          _buildInfoRow('Parts Replaced', _serviceHistoryData!['partsReplaced'] ?? 'N/A'),
                        ],
                      ),

                      // Maintenance Suggestions Section
                      _buildSection(
                        'Maintenance Suggestions',
                        [
                          _buildSuggestionItem('Keep Air Filter Clean', _serviceHistoryData!['suggestions']?['keepAirFilterClean'] ?? false),
                          _buildSuggestionItem('Keep Away From Smells', _serviceHistoryData!['suggestions']?['keepAwayFromSmells'] ?? false),
                          _buildSuggestionItem('Protect From Sun And Rain', _serviceHistoryData!['suggestions']?['protectFromSunAndRain'] ?? false),
                          _buildSuggestionItem('Supply Stable Electricity', _serviceHistoryData!['suggestions']?['supplyStableElectricity'] ?? false),
                          if (_serviceHistoryData!['customSuggestions'] != null && _serviceHistoryData!['customSuggestions'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('Custom Suggestions: ${_serviceHistoryData!['customSuggestions']}'),
                            ),
                        ],
                      ),

                      // Service Timeline Section
                      _buildSection(
                        'Service Timeline',
                        [
                          _buildInfoRow('Request Created', _formatTimestamp(_serviceRequestData!['createdAt'])),
                          _buildInfoRow('Resolution Time', _formatTimestamp(_serviceHistoryData!['resolutionTimestamp'])),
                          if (_serviceHistoryData!['acknowledgmentTimestamp'] != null)
                            _buildInfoRow('Acknowledgment Time', _formatTimestamp(_serviceHistoryData!['acknowledgmentTimestamp'])),
                        ],
                      ),

                      // Download PDF Section with OTP Verification
                      _buildDownloadSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSectionIcon(String title) {
    switch (title) {
      case 'Service Summary':
        return Icons.summarize;
      case 'AWG Details':
        return Icons.devices;
      case 'Customer Details':
        return Icons.person;
      case 'Service Details':
        return Icons.build;
      case 'Service Images':
        return Icons.photo_library;
      case 'Maintenance Suggestions':
        return Icons.lightbulb;
      case 'Service Timeline':
        return Icons.timeline;
      case 'Download Service Report':
        return Icons.download;
      default:
        return Icons.info;
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionItem(String text, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isSelected ? Icons.check_circle : Icons.circle_outlined,
            size: 20,
            color: isSelected ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: isSelected ? Colors.green[700] : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadSection() {
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
              color: Colors.green[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: Colors.green[600],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Download Service Report',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Security Notice
                
                
                const Text(
                  'Generate and download the service acknowledgment PDF report',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    // onPressed: _isGeneratingPdf ? null : _initiateOtpVerification,
                    onPressed: _generateAndDownloadPdf,
                    icon: _isGeneratingPdf
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.verified_user),
                    label: Text(_isGeneratingPdf ? 'Generating PDF...' : 'Verify & Download PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime? date;

    // Case 1: Firebase Timestamp
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } 
    // Case 2: ISO-8601 String
    else if (timestamp is String) {
      try {
        date = DateTime.parse(timestamp);
      } catch (e) {
        // Case 3: Try custom string like "July 22, 2025 at 11:06:43 AM UTC+5:30"
        try {
          // Normalize UTC+5:30 to UTC+0530 for parsing
          String cleaned = timestamp.replaceAll('UTC+5:30', 'UTC+0530');

          // Optional: remove any unusual unicode spaces (like non-breaking space)
          cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

          final customFormat = DateFormat("MMMM d, y 'at' hh:mm:ss a 'UTC'Z");
          date = customFormat.parse(cleaned);
        } catch (e) {
          return timestamp; // Still can't parse
        }
      }
    } else {
      return 'N/A';
    }

    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getTechnicianName() {
    if (_technicianData != null) {
      return _technicianData!['fullName'] ?? _technicianData!['name'] ?? 'N/A';
    }
    return _serviceHistoryData!['technician'] ?? 'N/A';
  }

  String _getFullAddress() {
    final serviceDetails = _serviceRequestData!['customerDetails']?['address'];
    if (serviceDetails == null) return 'N/A';
    
    final List<String> addressParts = [];
    
    if (serviceDetails['fullAddress'] != null) addressParts.add(serviceDetails['fullAddress']);
    if (serviceDetails['city'] != null) addressParts.add(serviceDetails['city']);
    if (serviceDetails['state'] != null) addressParts.add(serviceDetails['state']);
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
  }
}