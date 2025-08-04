import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/DatabaseActions/service_history_modals/service_history_modal.dart';

class ServiceHistoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all service history for a specific serial number
  Future<List<ServiceHistoryItem>> getServiceHistory(String serialNumber) async {
    print(serialNumber);
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('awgSerialNumber', isEqualTo: serialNumber)
          // .orderBy('serviceDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => ServiceHistoryItem.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching service history: $e');
      return [];
    }
  }

}