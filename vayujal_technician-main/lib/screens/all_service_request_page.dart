import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/DatabaseActions/adminAction.dart';
import 'package:vayujal_technician/models/technicaian_profile.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/navigation/bottom_navigation.dart';
import 'package:vayujal_technician/pages/service_details_page.dart';
import 'package:vayujal_technician/services/notification_service.dart';

class AllServiceRequestsPage extends StatefulWidget {
  // Add optional parameter for initial filter
  final String? initialFilter;
  
  const AllServiceRequestsPage({super.key, this.initialFilter});

  @override
  State<AllServiceRequestsPage> createState() => _AllServiceRequestsPageState();
}

class _AllServiceRequestsPageState extends State<AllServiceRequestsPage> {
  List<Map<String, dynamic>> _allServiceRequests = [];
  List<Map<String, dynamic>> _filteredServiceRequests = [];
  bool _isLoading = true;
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  
  // Add this to store current technician's employee ID
  String? _currentEmployeeId;

  // Updated filter options to include all statuses
  final List<String> _filterOptions = ['All', 'Pending', 'In Progress', 'Delayed', 'Completed'];

  @override
  void initState() {
    super.initState();
    // Set initial filter if provided
    if (widget.initialFilter != null) {
      _selectedFilter = widget.initialFilter!;
    }
    _loadTechnicianAndServiceRequests();
  }

  // New method to load technician profile and then service requests
  Future<void> _loadTechnicianAndServiceRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user from Firebase Auth
      User? currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user is currently logged in');
      }

      // Fetch technician profile from Firestore
      DocumentSnapshot technicianDoc = await FirebaseFirestore.instance
          .collection('technicians')
          .doc(currentUser.uid)
          .get();

      if (technicianDoc.exists) {
        TechnicianProfile technicianProfile = TechnicianProfile.fromFirestore(technicianDoc);
        _currentEmployeeId = technicianProfile.employeeId;
        
        // Load service requests with initial filter
        await _loadServiceRequestsWithFilter();
      } else {
        throw Exception('Technician profile not found');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading technician profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // New method to load service requests with the current filter
  Future<void> _loadServiceRequestsWithFilter() async {
    if (_currentEmployeeId == null) return;

    try {
      List<Map<String, dynamic>> serviceRequests;
      
      if (_selectedFilter == 'All') {
        serviceRequests = await AdminAction.getEmployeeServiceRequests(_currentEmployeeId!);
      } else {
        String statusFilter = _getStatusFromFilter(_selectedFilter);
        serviceRequests = await AdminAction.getEmployeeServiceRequestsByStatus(_currentEmployeeId!, statusFilter);
      }
      
      setState(() {
        _allServiceRequests = serviceRequests;
        _filteredServiceRequests = serviceRequests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading service requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

 
  // void _filterServiceRequests(String filter) async {
  //   if (_currentEmployeeId == null) return;

  //   setState(() {
  //     _selectedFilter = filter;
  //     _isLoading = true;
  //   });

  //   try {
  //     List<Map<String, dynamic>> serviceRequests;
      
  //     if (filter == 'All') {
  //       serviceRequests = await AdminAction.getEmployeeServiceRequests(_currentEmployeeId!);
  //     } else {
  //       String statusFilter = _getStatusFromFilter(filter);
  //       print('Filtering by status: $statusFilter'); // Debug print
  //       serviceRequests = await AdminAction.getEmployeeServiceRequestsByStatus(_currentEmployeeId!, statusFilter);
  //       print('Found ${serviceRequests.length} requests with status: $statusFilter'); // Debug print
  //     }
      
  //     setState(() {
  //       _allServiceRequests = serviceRequests;
  //       _filteredServiceRequests = serviceRequests;
  //       _isLoading = false;
  //     });
      
  //     // Apply search filter if there's a search query
  //     if (_searchController.text.isNotEmpty) {
  //       _searchServiceRequests(_searchController.text);
  //     }
  //   } catch (e) {
  //     print('Error in _filterServiceRequests: $e'); // Debug print
  //     setState(() {
  //       _isLoading = false;
  //     });
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Error filtering service requests: $e'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   }
  // }

  // Updated status mapping to match database values
  String _getStatusFromFilter(String filter) {
    switch (filter) {
      case 'Pending':
        return 'pending'; // Shows accepted requests with pending status
      case 'In Progress':
        return 'in_progress'; // Shows accepted requests with in_progress status
      case 'Delayed':
        return 'delayed'; // Shows accepted requests with delayed status
      case 'Completed':
        return 'completed'; // Shows accepted requests with completed status
      default:
        return 'pending';
    }
  }

  void _searchServiceRequests(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredServiceRequests = _allServiceRequests;
      } else {
        _filteredServiceRequests = _allServiceRequests.where((sr) {
          String srId = sr['serviceDetails']?['srId'] ?? sr['srId'] ?? '';
          String customerName = sr['customerDetails']?['name'] ?? '';
          String model = sr['equipmentDetails']?['model'] ?? '';
          
          return srId.toLowerCase().contains(query.toLowerCase()) ||
                 customerName.toLowerCase().contains(query.toLowerCase()) ||
                 model.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  // Fixed status color logic to handle both formats
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'delayed':
        return Colors.red;
      case 'accepted':
        return Colors.orange; // Same color as pending
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Helper method to get status color based on service request data
  Color _getStatusColorFromData(Map<String, dynamic> serviceRequest) {
    String status = serviceRequest['status'] ?? 'pending';
    return _getStatusColor(status);
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else {
        return 'N/A';
      }
      
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Method to manually check expired requests
  Future<void> _checkExpiredRequests() async {
    if (_currentEmployeeId == null) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Checking expired requests..."),
            ],
          ),
        );
      },
    );

    try {
      // Check and update delayed service requests
      await NotificationService.checkAndUpdateDelayedServiceRequests(_currentEmployeeId!);
      
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Refresh the current view
      await _loadServiceRequestsWithFilter();
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Expired requests checked successfully, check your delayed service requests  list.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
    } catch (e) {
      // Close loading dialog
      Navigator.of(context).pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking expired requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to show confirmation dialog before checking expired requests
  Future<void> _showCheckExpiredDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Check Expired Requests'),
          content: const Text(
            'This will check all your pending service requests for expired deadlines and update their status to "Delayed" if overdue. Admin will be notified about delayed requests.\n\nDo you want to continue?'
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check Now'),
              onPressed: () {
                Navigator.of(context).pop();
                _checkExpiredRequests();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: Normalappbar(
        title: 'My Service Requests',
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _filterOptions.length,
              itemBuilder: (context, index) {
                String option = _filterOptions[index];
                bool isSelected = _selectedFilter == option;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(option),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = option;
                      });
                      _loadServiceRequestsWithFilter();
                    },
                    selectedColor: Colors.blue.withOpacity(0.2),
                    checkmarkColor: Colors.blue,
                  ),
                );
              },
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search service requests...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                _searchServiceRequests(value);
              },
            ),
          ),
          
          // Service Requests List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredServiceRequests.isEmpty
                    ? const Center(
                        child: Text(
                              'No service requests found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredServiceRequests.length,
                          itemBuilder: (context, index) {
                          final serviceRequest = _filteredServiceRequests[index];
                          final srNumber = serviceRequest['srId'] ?? 'N/A';
                          final customerName = serviceRequest['customerDetails']['name'] ?? 'N/A';
                          final model = serviceRequest['equipmentDetails']['model'] ?? 'N/A';
                          final requestType = serviceRequest['serviceDetails']['requestType'] ?? 'N/A';
                          final status = serviceRequest['status'] ?? 'N/A';
                          final assignedDate = _formatDate(serviceRequest['serviceDetails']['createdDate']);
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ServiceDetailsPage(
                                      serviceRequestId: serviceRequest['id'],
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                    // SR Number and Status
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                            'SR: $srNumber',
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColorFromData(serviceRequest).withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: _getStatusColorFromData(serviceRequest),
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              status,
                                              style: TextStyle(
                                                color: _getStatusColorFromData(serviceRequest),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Customer and Model
                                      Text(
                                        '$customerName - $model',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 4),
                                      
                                      // Request Type
                                      Text(
                                        requestType.replaceAll('_', ' ').toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 8),
                                      
                                      // Assigned Date
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.schedule,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Assigned: $assignedDate',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                      ),
          ),
        ],
      ),
      // Add Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCheckExpiredDialog,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.access_time),
        label: const Text('Check Expired'),
      ),
      bottomNavigationBar: BottomNavigation(
        currentIndex: widget.initialFilter == 'Completed' ? 2 : 1,
        onTap:(currentIndex) => BottomNavigation.navigateTo(currentIndex, context) ,
      ),
    );
  }
}