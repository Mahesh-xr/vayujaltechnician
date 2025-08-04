
import 'package:flutter/material.dart';
import 'package:vayujal_technician/navigation/bottom_navigation.dart';
import 'package:vayujal_technician/navigation/custom_app_bar.dart';
import 'package:vayujal_technician/widgets/dashbord/quick_actions_section.dart';
import 'package:vayujal_technician/widgets/dashbord/status_cards_grid.dart';
import 'package:vayujal_technician/services/notification_service.dart';
import 'package:vayujal_technician/screens/service_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  void _initializeNotifications() async {
    // Initialize notification service
    await NotificationService.initialize(context);
    
    // Set navigation callback for notification taps
    NotificationService.setNavigationCallback((String srId) {
      _navigateToServiceDetails(srId);
    });
  }

  void _navigateToServiceDetails(String srId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(srId: srId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[80],
      appBar: const CustomAppBar(title: 'Dashboard'),
      body: _buildMainContent(),
      bottomNavigationBar: BottomNavigation(
        currentIndex: 0, // 'Devices' tab index
        onTap: (currentIndex) => BottomNavigation.navigateTo(currentIndex, context),
      ),
    );
  }

  Widget _buildMainContent() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatusCardsGrid(),
          SizedBox(height: 32),
          QuickActionsSection(),
        ],
      ),
    );
  }
}