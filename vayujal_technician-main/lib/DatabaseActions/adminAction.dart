// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAction {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============== EXISTING DEVICE MANAGEMENT METHODS ==============

  static Future<List<Map<String, dynamic>>> getAllTechnicians() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('technicians')
          .get();

      List<Map<String, dynamic>> technicians = snapshot.docs.map((doc) {
        return {
          'name': doc['fullName'] ?? '',
          'empId': doc['employeeId'] ?? '',
        };
      }).toList();

      return technicians;
    } catch (e) {
      print("🔥Error fetching technicians: $e");
      return [];
    }  
  }

  /// Adds a new device to Firestore
  static Future addNewDevice(Map<String, dynamic> deviceData) async {
    try {
      String serialNumber = deviceData['deviceInfo']['awgSerialNumber'];
      await _firestore.collection('devices').doc(serialNumber).set(deviceData);
      print("✅ Device added successfully: $serialNumber");
    } catch (e) {
      print("❌ Error adding device: $e");
    }
  }

  /// Updates an existing device in Firestore
  static Future editDevice(String serialNumber, Map<String, dynamic> updatedData) async {
    try {
      await _firestore.collection('devices').doc(serialNumber).update(updatedData);
      print("✅ Device updated successfully: $serialNumber");
    } catch (e) {
      print("❌ Error updating device: $e");
    }
  }

  /// Fetches all devices from Firestore
  static Future<List<Map<String, dynamic>>> getAllDevices() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('devices').get();
      List<Map<String, dynamic>> devices = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      print("✅ Fetched ${devices.length} devices.");
      return devices;
    } catch (e) {
      print("❌ Error fetching devices: $e");
      return [];
    }
  }

  /// Fetch a single device by its serial number
  static Future<Map<String, dynamic>?> getDeviceBySerial(String serialNumber) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('devices').doc(serialNumber).get();
      if (doc.exists) {
        print("✅ Device found: $serialNumber");
        return doc.data() as Map<String, dynamic>;
      } else {
        print("⚠️ No device found with serial: $serialNumber");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching device: $e");
      return null;
    }
  }

  /// Fetch unique cities from all devices
  static Future<List<String>> getUniqueCities() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('devices').get();
      Set<String> cities = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final locationDetails = data['locationDetails'] as Map<String, dynamic>?;
        final city = locationDetails?['city']?.toString().trim();
        
        if (city != null && city.isNotEmpty) {
          cities.add(city);
        }
      }
      
      List<String> sortedCities = cities.toList()..sort();
      print("✅ Fetched ${sortedCities.length} unique cities.");
      return sortedCities;
    } catch (e) {
      print("❌ Error fetching cities: $e");
      return [];
    }
  }

  /// Fetch unique states from all devices
  static Future<List<String>> getUniqueStates() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('devices').get();
      Set<String> states = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final locationDetails = data['locationDetails'] as Map<String, dynamic>?;
        final state = locationDetails?['state']?.toString().trim();
        
        if (state != null && state.isNotEmpty) {
          states.add(state);
        }
      }
      
      List<String> sortedStates = states.toList()..sort();
      print("✅ Fetched ${sortedStates.length} unique states.");
      return sortedStates;
    } catch (e) {
      print("❌ Error fetching states: $e");
      return [];
    }
  }

  /// Fetch unique models from all devices
  static Future<List<String>> getUniqueModels() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('devices').get();
      Set<String> models = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final deviceInfo = data['deviceInfo'] as Map<String, dynamic>?;
        final model = deviceInfo?['model']?.toString().trim();
        
        if (model != null && model.isNotEmpty) {
          models.add(model);
        }
      }
      
      List<String> sortedModels = models.toList()..sort();
      print("✅ Fetched ${sortedModels.length} unique models.");
      return sortedModels;
    } catch (e) {
      print("❌ Error fetching models: $e");
      return [];
    }
  }

  /// Fetch devices with multiple filters
  static Future<List<Map<String, dynamic>>> getFilteredDevices({
    List<String>? models,
    List<String>? cities,
    List<String>? states,
    String? searchTerm,
  }) async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('devices').get();
      List<Map<String, dynamic>> devices = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      // Apply filters
      List<Map<String, dynamic>> filteredDevices = devices.where((device) {
        final deviceInfo = device['deviceInfo'] as Map<String, dynamic>?;
        final locationDetails = device['locationDetails'] as Map<String, dynamic>?;
        final customerDetails = device['customerDetails'] as Map<String, dynamic>?;
        
        // Model filter
        if (models != null && models.isNotEmpty) {
          final deviceModel = deviceInfo?['model']?.toString();
          if (deviceModel == null || !models.contains(deviceModel)) {
            return false;
          }
        }
        
        // City filter
        if (cities != null && cities.isNotEmpty) {
          final deviceCity = locationDetails?['city']?.toString();
          if (deviceCity == null || !cities.contains(deviceCity)) {
            return false;
          }
        }
        
        // State filter
        if (states != null && states.isNotEmpty) {
          final deviceState = locationDetails?['state']?.toString();
          if (deviceState == null || !states.contains(deviceState)) {
            return false;
          }
        }
        
        // Search term filter
        if (searchTerm != null && searchTerm.isNotEmpty) {
          final searchLower = searchTerm.toLowerCase();
          final model = deviceInfo?['model']?.toString().toLowerCase() ?? '';
          final serialNumber = deviceInfo?['serialNumber']?.toString().toLowerCase() ?? '';
          final company = customerDetails?['company']?.toString().toLowerCase() ?? '';
          final city = locationDetails?['city']?.toString().toLowerCase() ?? '';
          
          if (!model.contains(searchLower) && 
              !serialNumber.contains(searchLower) && 
              !company.contains(searchLower) && 
              !city.contains(searchLower)) {
            return false;
          }
        }
        
        return true;
      }).toList();
      
      print("✅ Filtered ${filteredDevices.length} devices from ${devices.length} total devices.");
      return filteredDevices;
    } catch (e) {
      print("❌ Error fetching filtered devices: $e");
      return [];
    }
  }

  /// Get devices count by filter criteria
  static Future<Map<String, int>> getDevicesCountByFilters() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('devices').get();
      List<Map<String, dynamic>> devices = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      
      Map<String, int> modelCounts = {};
      Map<String, int> cityCounts = {};
      Map<String, int> stateCounts = {};
      
      for (var device in devices) {
        final deviceInfo = device['deviceInfo'] as Map<String, dynamic>?;
        final locationDetails = device['locationDetails'] as Map<String, dynamic>?;
        
        // Count models
        final model = deviceInfo?['model']?.toString();
        if (model != null && model.isNotEmpty) {
          modelCounts[model] = (modelCounts[model] ?? 0) + 1;
        }
        
        // Count cities
        final city = locationDetails?['city']?.toString();
        if (city != null && city.isNotEmpty) {
          cityCounts[city] = (cityCounts[city] ?? 0) + 1;
        }
        
        // Count states
        final state = locationDetails?['state']?.toString();
        if (state != null && state.isNotEmpty) {
          stateCounts[state] = (stateCounts[state] ?? 0) + 1;
        }
      }
      
      return {
        'models': modelCounts.length,
        'cities': cityCounts.length,
        'states': stateCounts.length,
        'totalDevices': devices.length,
      };
    } catch (e) {
      print("❌ Error getting devices count: $e");
      return {};
    }
  }

  /// Delete a device from Firestore
  static Future<bool> deleteDevice(String serialNumber) async {
    try {
      await _firestore.collection('devices').doc(serialNumber).delete();
      print("✅ Device deleted successfully: $serialNumber");
      return true;
    } catch (e) {
      print("❌ Error deleting device: $e");
      return false;
    }
  }

  /// Check if device exists before deletion
  static Future<bool> deviceExists(String serialNumber) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('devices').doc(serialNumber).get();
      return doc.exists;
    } catch (e) {
      print("❌ Error checking device existence: $e");
      return false;
    }
  }

  // ============== NEW SERVICE REQUEST MANAGEMENT METHODS ==============

 
 
static Future<List<Map<String, dynamic>>> getEmployeeServiceRequests(String employeeId) async {
  try {
    QuerySnapshot snapshot = await _firestore
        .collection('serviceRequests')
        .where('serviceDetails.assignedTo', isEqualTo: employeeId) // Filter by employee ID in serviceDetails
        .where('isAccepted', isEqualTo: true) // Only fetch accepted service requests
        .orderBy('createdAt', descending: true)
        .get();
        
    List<Map<String, dynamic>> serviceRequests = snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
        
    print("✅ Fetched ${serviceRequests.length} accepted service requests for employee: $employeeId");
    return serviceRequests;
  } catch (e) {
    print("❌ Error fetching service requests for employee: $e");
    return [];
  }
}

/// Get service requests by status for a specific employee
static Future<List<Map<String, dynamic>>> getEmployeeServiceRequestsByStatus(String employeeId, String status) async {
  try {
    List<Map<String, dynamic>> serviceRequests = [];
    
    // Get service requests from main collection with isAccepted == true
    QuerySnapshot snapshot = await _firestore
        .collection('serviceRequests')
        .where('serviceDetails.assignedTo', isEqualTo: employeeId) // Filter by employee ID in serviceDetails
        .where('isAccepted', isEqualTo: true) // Only fetch accepted service requests
        .where('status', isEqualTo: status) // Filter by status in serviceDetails
        .get();
        
    serviceRequests.addAll(snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList());
        
    print("✅ Fetched ${serviceRequests.length} accepted service requests for employee: $employeeId with status: $status");
    return serviceRequests;
  } catch (e) {
    print("❌ Error fetching service requests for employee by status: $e");
    return [];
  }
}

  /// Update service request status
  static Future<void> updateServiceRequestStatus({
    required String serviceRequestId,
    required String status,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      Map<String, dynamic> updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      if (additionalData != null) {
        updateData.addAll(additionalData);
      }
      
      await _firestore.collection('serviceRequests').doc(serviceRequestId).update(updateData);
      
      print("✅ Service request status updated: $serviceRequestId -> $status");
    } catch (e) {
      print("❌ Error updating service request status: $e");
      throw Exception('Failed to update service request status: $e');
    }
  }

   static Future<Map<String, dynamic>?> getServiceHistoryBySrId(String srId) async {
    try {
      // Query the serviceHistory collection using srId as document ID
      DocumentSnapshot doc = await _firestore
          .collection('serviceHistory')
          .doc(srId)
          .get();

      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Add document ID to the data for reference
        data['id'] = doc.id;
        
        return data;
      } else {
        // Document doesn't exist
        return null;
      }
    } catch (e) {
      print('Error fetching service history for SR ID $srId: $e');
      throw Exception('Failed to fetch service history: $e');
    }
  }


  /// Get service request by ID
  static Future<Map<String, dynamic>?> getServiceRequestById(String serviceRequestId) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('serviceRequests')
          .doc(serviceRequestId)
          .get();
      
      if (doc.exists) {
        print("✅ Service request found: $serviceRequestId");
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      } else {
        print("⚠️ No service request found with ID: $serviceRequestId");
        return null;
      }
    } catch (e) {
      print("❌ Error fetching service request: $e");
      return null;
    }
  }

  
  /// Get all tasks
 
 
  /// Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      // Get service requests count by status
      QuerySnapshot pendingSR = await _firestore
          .collection('serviceRequests')
          .where('status', isEqualTo: 'pending')
          .get();
      
      QuerySnapshot assignedSR = await _firestore
          .collection('serviceRequests')
          .where('status', isEqualTo: 'assigned')
          .get();
      
      QuerySnapshot completedSR = await _firestore
          .collection('serviceRequests')
          .where('status', isEqualTo: 'completed')
          .get();
      
      // Get tasks count by status
      QuerySnapshot pendingTasks = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'pending')
          .get();
      
      QuerySnapshot inProgressTasks = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'in_progress')
          .get();
      
      QuerySnapshot completedTasks = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'completed')
          .get();
      
      QuerySnapshot delayedTasks = await _firestore
          .collection('tasks')
          .where('status', isEqualTo: 'delayed')
          .get();
      
      // Get total devices and technicians
      QuerySnapshot devicesSnapshot = await _firestore.collection('devices').get();
      QuerySnapshot techniciansSnapshot = await _firestore.collection('technicians').get();
      
      Map<String, dynamic> stats = {
        'serviceRequests': {
          'pending': pendingSR.size,
          'assigned': assignedSR.size,
          'completed': completedSR.size,
          'total': pendingSR.size + assignedSR.size + completedSR.size,
        },
        'tasks': {
          'pending': pendingTasks.size,
          'inProgress': inProgressTasks.size,
          'completed': completedTasks.size,
          'delayed': delayedTasks.size,
          'total': pendingTasks.size + inProgressTasks.size + completedTasks.size + delayedTasks.size,
        },
        'devices': {
          'total': devicesSnapshot.size,
        },
        'technicians': {
          'total': techniciansSnapshot.size,
        }
      };
      
      print("✅ Dashboard statistics fetched successfully");
      return stats;
    } catch (e) {
      print("❌ Error fetching dashboard statistics: $e");
      return {};
    }
  }

  
}