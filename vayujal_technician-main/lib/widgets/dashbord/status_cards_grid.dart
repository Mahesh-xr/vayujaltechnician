import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/widgets/dashbord/status_card.dart';

class StatusCardsGrid extends StatefulWidget {
  const StatusCardsGrid({super.key});

  @override
  State<StatusCardsGrid> createState() => _StatusCardsGridState();
}

class _StatusCardsGridState extends State<StatusCardsGrid> {
  final FirestoreService _firestoreService = FirestoreService();
  
  int totalRequests = 0;
  int pendingRequests = 0;
  int inProgressRequests = 0;
  int completedRequests = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatusCounts();
  }

  @override
  void dispose() {
    // Clean up any resources if needed
    super.dispose();
  }

  Future<void> _loadStatusCounts() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
    });

    try {
      Map<String, int> statusCounts = await _firestoreService.getCurrentUserServiceRequestCounts();
      
      if (mounted) {
        setState(() {
          totalRequests = statusCounts['total'] ?? 0;
          pendingRequests = statusCounts['pending'] ?? 0;
          inProgressRequests = statusCounts['in_progress'] ?? 0;
          completedRequests = statusCounts['completed'] ?? 0;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading status counts: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        StatusCard(
          title: 'Total Requests',
          count: totalRequests.toString(),
          accentColor: Colors.blue,
        ),
        StatusCard(
          title: 'Pending',
          count: pendingRequests.toString(),
          accentColor: Colors.orange,
        ),
        StatusCard(
          title: 'In Progress',
          count: inProgressRequests.toString(),
          accentColor: Colors.green,
        ),
        StatusCard(
          title: 'Completed',
          count: completedRequests.toString(),
          accentColor: Colors.purple,
        ),
      ],
    );
  }
}

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get service request counts for currently logged-in user
  /// Uses current user's UID to get employeeId from technicians collection
  /// Then fetches service requests where serviceDetails.assignedTo equals that employeeId
  /// AND isAccepted is true (updated login system)
  Future<Map<String, int>> getCurrentUserServiceRequestCounts() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user is currently logged in');
      }

      // Get employee ID from technicians collection using current user's UID
      final technicianDoc = await _firestore
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (!technicianDoc.exists) {
        throw Exception('Technician document not found for user: ${user.uid}');
      }

      final technicianData = technicianDoc.data() as Map<String, dynamic>;
      final employeeId = technicianData['employeeId']?.toString();

      if (employeeId == null || employeeId.isEmpty) {
        throw Exception('Employee ID not found in technician document');
      }

      // Get service requests where serviceDetails.assignedTo equals employeeId AND isAccepted is true
      final QuerySnapshot querySnapshot = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.assignedTo', isEqualTo: employeeId)
          .where('isAccepted', isEqualTo: true) // Only fetch accepted service requests
          .get();

      // Initialize counters
      Map<String, int> statusCounts = {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
      };

      // Count requests by status
      for (QueryDocumentSnapshot doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final status = data['status']?.toString().toLowerCase() ?? 'unknown';

        statusCounts['total'] = statusCounts['total']! + 1;

        if (statusCounts.containsKey(status)) {
          statusCounts[status] = statusCounts[status]! + 1;
        }
      }

      return statusCounts;
    } catch (e) {
      print('Error getting current user service request counts: $e');
      return {
        'total': 0,
        'pending': 0,
        'in_progress': 0,
        'completed': 0,
      };
    }
  }

  /// Get employee ID from technician document using current user's UID
  Future<String?> getCurrentUserEmployeeId() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final doc = await _firestore
          .collection('technicians')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['employeeId']?.toString();
      }

      return null;
    } catch (e) {
      print('Error getting current user employee ID: $e');
      return null;
    }
  }

  /// Get service requests for current user by status
  Future<List<QueryDocumentSnapshot>> getCurrentUserServiceRequestsByStatus(String status) async {
    try {
      final employeeId = await getCurrentUserEmployeeId();
      if (employeeId == null) {
        return [];
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.assignedTo', isEqualTo: employeeId)
          .where('isAccepted', isEqualTo: true) // Only fetch accepted service requests
          .where('status', isEqualTo: status)
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error getting service requests by status: $e');
      return [];
    }
  }

  /// Get all service requests for current user
  Future<List<QueryDocumentSnapshot>> getCurrentUserServiceRequests() async {
    try {
      final employeeId = await getCurrentUserEmployeeId();
      if (employeeId == null) {
        return [];
      }

      final QuerySnapshot querySnapshot = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.assignedTo', isEqualTo: employeeId)
          .where('isAccepted', isEqualTo: true) // Only fetch accepted service requests
          .get();

      return querySnapshot.docs;
    } catch (e) {
      print('Error getting all service requests: $e');
      return [];
    }
  }
}