import 'package:flutter/material.dart';
import 'package:vayujal_technician/screens/all_service_request_page.dart';
import 'action_button.dart';

class QuickActionsSection extends StatelessWidget {
  const QuickActionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        _buildActionButtons(context),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // View All Tasks Button
        ActionButton(
          title: 'View Tasks',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AllServiceRequestsPage(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        
        // Pending Services Button - Navigate to In Progress filter
        ActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AllServiceRequestsPage(
                  initialFilter: 'Pending', // Set initial filter to In Progress
                ),
              ),
            );
          },
          title: 'Pending Services',
        ),
      ],
    );
  }
}