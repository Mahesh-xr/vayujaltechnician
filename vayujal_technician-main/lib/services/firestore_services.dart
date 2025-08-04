// services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vayujal_technician/models/service_acknowledgement_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<ServiceAcknowledgmentModel?> getServiceAcknowledgmentData(String srNumber) async {
    try {
      // Get service request data
      final serviceRequestQuery = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.srId', isEqualTo: srNumber)
          .get();

      // Get service history data
      final serviceHistoryQuery = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      if (serviceRequestQuery.docs.isEmpty || serviceHistoryQuery.docs.isEmpty) {
        return null;
      }

      final serviceRequestData = serviceRequestQuery.docs.first.data();
      final serviceHistoryData = serviceHistoryQuery.docs.first.data();

      return ServiceAcknowledgmentModel.fromFirestore(
        serviceRequestData,
        serviceHistoryData,
      );
    } catch (e) {
      print('Error fetching service acknowledgment data: $e');
      return null;
    }
  }

  Future<void> updateAcknowledgmentStatus(String srNumber, {
    required bool isVerified,
    DateTime? acknowledgedAt,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      for (var doc in querySnapshot.docs) {
        await doc.reference.update({
          'acknowledgmentStatus': isVerified ? 'verified' : 'pending',
          'acknowledgmentTimestamp': acknowledgedAt ?? FieldValue.serverTimestamp(),
          'customerVerified': isVerified,
        });
      }
    } catch (e) {
      print('Error updating acknowledgment status: $e');
      rethrow;
    }
  }

  Future<bool> isServiceAcknowledged(String srNumber) async {
    try {
      final querySnapshot = await _firestore
          .collection('serviceHistory')
          .where('srNumber', isEqualTo: srNumber)
          .get();

      if (querySnapshot.docs.isEmpty) return false;

      final data = querySnapshot.docs.first.data();
      return data['acknowledgmentStatus'] == 'verified' || 
             data['customerVerified'] == true;
    } catch (e) {
      print('Error checking acknowledgment status: $e');
      return false;
    }
  }

  // Stream for real-time updates
  Stream<ServiceAcknowledgmentModel?> getServiceAcknowledgmentStream(String srNumber) {
    return _firestore
        .collection('serviceHistory')
        .where('srNumber', isEqualTo: srNumber)
        .snapshots()
        .asyncMap((historySnapshot) async {
      if (historySnapshot.docs.isEmpty) return null;

      final serviceRequestQuery = await _firestore
          .collection('serviceRequests')
          .where('serviceDetails.srId', isEqualTo: srNumber)
          .get();

      if (serviceRequestQuery.docs.isEmpty) return null;

      return ServiceAcknowledgmentModel.fromFirestore(
        serviceRequestQuery.docs.first.data(),
        historySnapshot.docs.first.data(),
      );
    });
  }
}