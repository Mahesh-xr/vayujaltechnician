import 'package:flutter/material.dart';

class AMCHistoryCard extends StatelessWidget {
  final Map<String, dynamic> amcData;

  const AMCHistoryCard({super.key, required this.amcData});

  @override
  Widget build(BuildContext context) {
    return Card(
      
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'AMC Details',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: amcData['isActive'] == true ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    amcData['status'],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Registration Number
            _buildDetailRow('Registration No.', amcData['regNo']),
            const SizedBox(height: 12),
            
            // AMC Type
            _buildDetailRow('AMC Type', amcData['type'] ?? 'Standard'),
            const SizedBox(height: 12),
            
            // Date Range
            _buildDetailRow('Contract Period', amcData['dateRange'] ?? 'No dates available'),
            const SizedBox(height: 12),
            
            // Start Date
            if (amcData['startDate'] != null)
              _buildDetailRow('Start Date', _formatDate(amcData['startDate'])),
            if (amcData['startDate'] != null) const SizedBox(height: 12),
            
            // End Date
            if (amcData['endDate'] != null)
              _buildDetailRow('End Date', _formatDate(amcData['endDate'])),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 14)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}