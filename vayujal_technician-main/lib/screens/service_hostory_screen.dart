import 'package:flutter/material.dart';
import 'package:vayujal_technician/DatabaseActions/service_history_modals/service_history_modal.dart';
import 'package:vayujal_technician/navigation/NormalAppBar.dart';
import 'package:vayujal_technician/screens/service_details_screen.dart';
import 'package:vayujal_technician/services/service_history_services.dart';
import 'package:vayujal_technician/widgets/history/amc_history_card.dart';
import 'package:vayujal_technician/widgets/history/service_history_card.dart';


class ServiceHistoryScreen extends StatefulWidget {
  final String serialNumber;

  const ServiceHistoryScreen({super.key, required this.serialNumber});

  @override
  // ignore: library_private_types_in_public_api
  _ServiceHistoryScreenState createState() => _ServiceHistoryScreenState();
}

class _ServiceHistoryScreenState extends State<ServiceHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ServiceHistoryService _service = ServiceHistoryService();
  
  List<ServiceHistoryItem> serviceHistory = [];
  bool isLoading = true;
  Map<String, dynamic>? awgDetails; // Made nullable

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final serviceData = await _service.getServiceHistory(widget.serialNumber);
      final awgData = await AWGDetails.getAMCDetails(widget.serialNumber);
      
      setState(() {
        serviceHistory = serviceData;
        awgDetails = awgData; // Removed the force cast (!)
        print("Data");
        print(serviceHistory);
        print(awgDetails);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: $e')), // Fixed typo
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
        appBar: Normalappbar(
        title: 'History'
        
        
      ),      body: Column(
        children: [
          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Service History'),
                Tab(text: 'AMC History'),
              ],
              
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.blue,
            ),
          ),
          // Tab Views
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildServiceHistoryTab(),
                      _buildAMCHistoryTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceHistoryTab() {
    // Check if service history is empty
    if (serviceHistory.isEmpty) {
      return _buildEmptyState(
        icon: Icons.build_outlined,
        title: 'No Service History',
        message: 'This device has no recorded service history yet.\nService records will appear here once maintenance is performed.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: serviceHistory.length,
        itemBuilder: (context, index) {
          final service = serviceHistory[index];
          return ServiceHistoryCard(
            service: service,
            onTap: () => _showServiceDetails(service.srNumber),
          );
        },
      ),
    );
  }

  Widget _buildAMCHistoryTab() {
    // Check if AMC details exist and are not empty
    if (awgDetails == null || awgDetails!.isEmpty) {
      return _buildEmptyState(
        icon: Icons.assignment_outlined,
        title: 'No AMC Records',
        message: 'No Annual Maintenance Contract records found for this device.\nAMC details will be displayed here once a contract is active.',
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: AMCHistoryCard(amcData: awgDetails!), // Safe to use ! here after null check
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 50,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showServiceDetails(String srNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(srId: srNumber),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}