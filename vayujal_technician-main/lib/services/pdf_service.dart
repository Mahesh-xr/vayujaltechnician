// services/pdf_service.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<File> generateServiceAcknowledgmentPdf(
    Map<String, dynamic> serviceRequestData,
    Map<String, dynamic> serviceHistoryData,
    Map<String, dynamic>? technicianData,
  ) async {
    final pdf = pw.Document();

    // Download images for PDF
    pw.ImageProvider? issueImage;
    pw.ImageProvider? resolutionImage;

    try {
      // Get issue image URL
      final issueImageUrls = serviceHistoryData['issueImageUrls'];
      if (issueImageUrls != null && issueImageUrls is List && issueImageUrls.isNotEmpty) {
        final issueResponse = await http.get(Uri.parse(issueImageUrls[0]));
        if (issueResponse.statusCode == 200) {
          issueImage = pw.MemoryImage(issueResponse.bodyBytes);
        }
      }
      
      // Get resolution image URL
      final resolutionImageUrls = serviceHistoryData['resolutionImageUrls'];
      if (resolutionImageUrls!= null && resolutionImageUrls is List && resolutionImageUrls.isNotEmpty) {
        final resolutionResponse = await http.get(Uri.parse(resolutionImageUrls[0]));
         // Check if the response is successful
         // If successful, convert the image bytes to MemoryImage
        if (resolutionResponse.statusCode == 200) {
          resolutionImage = pw.MemoryImage(resolutionResponse.bodyBytes);
        }
      }
    } catch (e) {
      print('Error downloading images: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return [
            // Header
            _buildHeader(serviceHistoryData['srNumber'] ?? 'N/A'),
            
            pw.SizedBox(height: 20),

            // Service Summary
            _buildSection('Service Summary', [
              _buildRow('SR Number', serviceHistoryData['srNumber'] ?? 'N/A'),
              _buildRow('Service Date', _formatTimestamp(serviceHistoryData['timestamp'])),
              _buildRow('Next Service Date', _formatTimestamp(serviceHistoryData['nextServiceDate'])),
              _buildRow('Status', serviceHistoryData['status'] ?? 'Completed'),
              _buildRow('Technician', _getTechnicianName(serviceHistoryData, technicianData)),
            ]),

            // AWG Details
            _buildSection('AWG Details', [
              _buildRow('Serial Number', serviceHistoryData['awgSerialNumber'] ?? 'N/A'),
              _buildRow('Model', serviceRequestData['equipmentDetails']?['model'] ?? 'N/A'),
            ]),

            // Customer Details
            _buildSection('Customer Details', [
              _buildRow('Name', serviceRequestData['customerDetails']?['name'] ?? 'N/A'),
              _buildRow('Phone Number', serviceRequestData['customerDetails']?['phone'] ?? 'N/A'),
              _buildRow('Company', serviceRequestData['customerDetails']?['company'] ?? 'N/A'),
              _buildRow('Address', _getFullAddress(serviceRequestData)),
            ]),

            // Service Details
            _buildSection('Service Details', [
              _buildRow('Customer Complaint', serviceHistoryData['customerComplaint'] ?? 'N/A'),
              _buildRow('Solution Provided', serviceHistoryData['solutionProvided'] ?? 'N/A'),
              _buildRow('Issue Identification', serviceHistoryData['issueIdentification'] ?? 'N/A'),
              _buildRow('Complaint Related To', serviceHistoryData['complaintRelatedTo'] ?? 'N/A'),
              _buildRow('Complaint Type', serviceRequestData['serviceDetails']?['requestType'] ?? 'N/A'),
              _buildRow('Parts Replaced', serviceHistoryData['partsReplaced'] ?? 'N/A'),
            ]),

            // Maintenance Suggestions
            _buildSection('Maintenance Suggestions', [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildCheckItem('Keep Air Filter Clean', 
                    serviceHistoryData['suggestions']?['keepAirFilterClean'] ?? false),
                  _buildCheckItem('Keep Away From Smells', 
                    serviceHistoryData['suggestions']?['keepAwayFromSmells'] ?? false),
                  _buildCheckItem('Protect From Sun And Rain', 
                    serviceHistoryData['suggestions']?['protectFromSunAndRain'] ?? false),
                  _buildCheckItem('Supply Stable Electricity', 
                    serviceHistoryData['suggestions']?['supplyStableElectricity'] ?? false),
                  
                  if (serviceHistoryData['customSuggestions'] != null && 
                      serviceHistoryData['customSuggestions'].toString().isNotEmpty)
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(top: 10),
                      child: pw.Text(
                        'Custom Suggestions: ${serviceHistoryData['customSuggestions']}',
                        style: pw.TextStyle(fontSize: 12),
                      ),
                    ),
                ],
              ),
            ]),

            // Service Timeline
            _buildSection('Service Timeline', [
              _buildRow('Request Created', _formatTimestamp(serviceRequestData['createdAt'])),
              _buildRow('Resolution Time', _formatTimestamp(serviceHistoryData['resolutionTimestamp'])),
              if (serviceHistoryData['acknowledgmentTimestamp'] != null)
                _buildRow('Acknowledgment Time', _formatTimestamp(serviceHistoryData['acknowledgmentTimestamp'])),
            ]),

            // Images Section
            if (issueImage != null || resolutionImage != null)
              pw.SizedBox(height: 20),
            
            if (issueImage != null)
              _buildSection('Issue Photo', [
                pw.Container(
                  height: 200,
                  width: double.infinity,
                  child: pw.Image(issueImage, fit: pw.BoxFit.contain),
                ),
              ]),

            if (resolutionImage != null)
              _buildSection('Resolution Photo', [
                pw.Container(
                  height: 200,
                  width: double.infinity,
                  child: pw.Image(resolutionImage, fit: pw.BoxFit.contain),
                ),
              ]),

            // Footer
            _buildFooter(),
          ];
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/service_acknowledgment_${serviceHistoryData['srNumber'] ?? 'unknown'}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static pw.Widget _buildHeader(String srNumber) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue300),
        borderRadius: pw.BorderRadius.circular(10),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Service Acknowledgment Report',
                style: pw.TextStyle(
                  fontSize: 24, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'VAYUJAL TECHNICIAN SERVICES',
                style: pw.TextStyle(
                  fontSize: 16, 
                  color: PdfColors.blue600,
                  fontWeight: pw.FontWeight.normal,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.blue300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'SR Number',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  srNumber,
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSection(String title, List<pw.Widget> children) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue100,
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16, 
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold, 
                fontSize: 12,
                color: PdfColors.black,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCheckItem(String text, bool isChecked) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        children: [
          pw.Container(
            width: 14,
            height: 14,
            decoration: pw.BoxDecoration(
              color: isChecked ? PdfColors.green : PdfColors.white,
              border: pw.Border.all(
                color: isChecked ? PdfColors.green : PdfColors.grey400,
                width: 1.5,
              ),
              borderRadius: pw.BorderRadius.circular(3),
            ),
            child: isChecked 
              ? pw.Center(
                  child: pw.Text(
                    '✓', 
                    style: pw.TextStyle(
                      fontSize: 10, 
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                )
              : null,
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            text, 
            style: pw.TextStyle(
              fontSize: 12,
              color: isChecked ? PdfColors.green700 : PdfColors.grey600,
              fontWeight: isChecked ? pw.FontWeight.normal : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        border: pw.Border.all(color: PdfColors.green300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Icon(
                pw.IconData(0xe876), // checkmark icon
                color: PdfColors.green600,
                size: 20,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Service Acknowledgment Completed',
                style: pw.TextStyle(
                  fontSize: 18, 
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.green800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'This document serves as official acknowledgment of the service provided by VAYUJAL technician. The customer has verified the completion of service and accepts the work performed.',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.green700,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Report generated on: ${_formatDate(DateTime.now())}',
                style: pw.TextStyle(
                  fontSize: 10, 
                  color: PdfColors.grey600,
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
              pw.Text(
                'VAYUJAL Services',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.blue600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods - Updated to match acknowledgment screen format
  static String _formatTimestamp(dynamic timestamp) {
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

  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _getTechnicianName(Map<String, dynamic> serviceHistoryData, Map<String, dynamic>? technicianData) {
    if (technicianData != null) {
      return technicianData['fullName'] ?? technicianData['name'] ?? 'N/A';
    }
    return serviceHistoryData['technician'] ?? 'N/A';
  }

  static String _getFullAddress(Map<String, dynamic> serviceRequestData) {
    final serviceDetails = serviceRequestData['customerDetails']?['address'];
    if (serviceDetails == null) return 'N/A';
    
    final List<String> addressParts = [];
    
    if (serviceDetails['fullAddress'] != null) addressParts.add(serviceDetails['fullAddress']);
    if (serviceDetails['city'] != null) addressParts.add(serviceDetails['city']);
    if (serviceDetails['state'] != null) addressParts.add(serviceDetails['state']);
    
    return addressParts.isNotEmpty ? addressParts.join(', ') : 'N/A';
  }

  static Future<void> shareAcknowledgmentPdf(File pdfFile) async {
    await Share.shareXFiles([XFile(pdfFile.path)]);
  }
}