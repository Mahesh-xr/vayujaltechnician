import 'package:flutter/material.dart';
import 'package:vayujal_technician/DatabaseActions/service_history_modals/service_history_modal.dart';


class ServiceHistoryCard extends StatelessWidget {
  final ServiceHistoryItem service;
  final VoidCallback onTap;

  const ServiceHistoryCard({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Service Request Number: ${service.srNumber}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(service.serviceType),
                    Text('Technician: ${service.technician} - ${service.empId}'),
                  ],
                ),
              ),
              const Icon(Icons.keyboard_arrow_down),
            ],
          ),
        ),
      ),
    );
  }
}