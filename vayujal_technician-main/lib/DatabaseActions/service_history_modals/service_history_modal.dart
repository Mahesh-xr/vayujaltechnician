import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceHistoryItem {
  final String srNumber;
  final String serviceType;
  final String technician;
  final String empId;
  final DateTime serviceDate;
  final String? issues;
  final String? resolution;
  final List<String>? partsReplaced;
  final Map<String, dynamic>? amcChecklist;
  final List<String>? technicianSuggestions;
  final DateTime? nextServiceDate;

  ServiceHistoryItem({
    required this.empId,
    required this.srNumber,
    required this.serviceType,
    required this.technician,
    required this.serviceDate,
    this.issues,
    this.resolution,
    this.partsReplaced,
    this.amcChecklist,
    this.technicianSuggestions,
    this.nextServiceDate,
  });

  factory ServiceHistoryItem.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ServiceHistoryItem(
      srNumber: data['srNumber'] ?? '',
      serviceType: data['serviceType'] ?? 'General Service',
      technician: data['technician'] ?? 'Name',
      serviceDate: (data['serviceDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      issues: data['issues'],
      empId: data['empId'] ?? 'Unknown Employee ID',
      // resolution: data['resolutions'],
      // partsReplaced: data['partsReplaced'] != null 
      //     ? List<String>.from(data['partsReplaced']) 
      //     : null,
      // amcChecklist: data['amcChecklist'],
      // technicianSuggestions: data['technicianSuggestions'] != null 
      //     ? List<String>.from(data['technicianSuggestions']) 
      //     : null,
      nextServiceDate: (data['nextServiceDate'] as Timestamp?)?.toDate(),
    );
  }

}

class AWGDetails {
  final String srNumber;
  final String type; // Premium, Standard
  final DateTime? startDate;
  final DateTime? endDate;

  AWGDetails({
    required this.srNumber,
    required this.type,
    this.startDate,
    this.endDate,
  });

   // Static method to get AMC details - returns map or null
static Future<Map<String, dynamic>?> getAMCDetails(String deviceId) async {
  try {
    print('Fetching AMC details for deviceId: $deviceId');
    
    DocumentSnapshot doc = await FirebaseFirestore.instance
        .collection('devices')
        .doc(deviceId)
        .get();

    print('Document exists: ${doc.exists}');
    
    // Check if document exists before accessing data
    if (!doc.exists) {
      print('Device document does not exist');
      return null; // Return null if device doesn't exist
    }

    Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
    
    // Check if data is null
    if (data == null) {
      print('Document data is null');
      return null;
    }
    
    print('Document data: $data');
    
    // Check if maintenanceContract exists
    if (!data.containsKey('maintenanceContract')) {
      print('No maintenanceContract field found');
      return null; // Return null if no maintenanceContract field
    }
    
    Map<String, dynamic>? maintenanceContract = data['maintenanceContract'];
    if (maintenanceContract == null || maintenanceContract.isEmpty) {
      print('maintenanceContract is null or empty');
      return null; // Return null if maintenanceContract is null/empty
    }

    print('maintenanceContract data: $maintenanceContract');
    
    // Check if annualContract field exists and is true
    bool hasAnnualContract = maintenanceContract['annualContract'] == true;
    print('annualContract value: ${maintenanceContract['annualContract']}');
    print('hasAnnualContract: $hasAnnualContract');
    
    if (!hasAnnualContract) {
      print('Device has no AMC - annualContract is false or not set');
      return null; // Return null if no annual contract
    }
    
    // Parse dates
    DateTime? startDate = _parseDate(maintenanceContract['amcStartDate']);
    DateTime? endDate = _parseDate(maintenanceContract['amcEndDate']);
    
    // Check if expired
    bool isExpired = false;
    if (endDate != null) {
      isExpired = DateTime.now().isAfter(endDate);
    }
    
    // Create and return map with AMC details
    Map<String, dynamic> amcDetails = {
      'regNo': data['deviceId']?.toString() ?? '',
      'type': maintenanceContract['amcType'] ?? 'Standard',
      'startDate': startDate,
      'endDate': endDate,
      'isActive': !isExpired,
      'isExpired': isExpired,
      'status': isExpired ? 'Expired' : 'Active',
      'dateRange': _getDateRange(startDate, endDate),
    };
    
    print('Created AMC details map: $amcDetails');
    
    return amcDetails;
    
  } catch (e) {
    print('Error fetching AMC details: $e');
    print('Stack trace: ${StackTrace.current}');
    return null; // Return null on error
  }
}

// Helper method to get formatted date range
static String _getDateRange(DateTime? startDate, DateTime? endDate) {
  if (startDate == null || endDate == null) return 'No dates available';
  return '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
      ' to ${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}';
}

// Helper method to parse date strings (keep existing implementation)
static DateTime? _parseDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) return null;
  
  try {
    // Parse date in format "5/6/2025" or "26/6/2025"
    List<String> parts = dateString.split('/');
    if (parts.length == 3) {
      int day = int.parse(parts[0]);
      int month = int.parse(parts[1]);
      int year = int.parse(parts[2]);
      return DateTime(year, month, day);
    }
  } catch (e) {
    print('Error parsing date: $dateString, error: $e');
  }
  
  return null;
}
  // Static method to get AMC details - returns single object or null
  
}
