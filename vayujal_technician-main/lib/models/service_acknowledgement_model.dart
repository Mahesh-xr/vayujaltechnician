// models/service_acknowledgment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceAcknowledgmentModel {
  final String srNumber;
  final DateTime serviceDate;
  final DateTime nextServiceDate;
  final AwgDetails awgDetails;
  final CustomerDetails customerDetails;
  final String partsReplaced;
  final String issueType;
  final String complaintRelatedTo;
  final ServiceSuggestions suggestions;
  final String customSuggestions;
  final ServiceImages images;
  final String solutionProvided;
  final String resolvedBy;

  ServiceAcknowledgmentModel({
    required this.srNumber,
    required this.serviceDate,
    required this.nextServiceDate,
    required this.awgDetails,
    required this.customerDetails,
    required this.partsReplaced,
    required this.issueType,
    required this.complaintRelatedTo,
    required this.suggestions,
    required this.customSuggestions,
    required this.images,
    required this.solutionProvided,
    required this.resolvedBy,
  });

  factory ServiceAcknowledgmentModel.fromFirestore(
    Map<String, dynamic> serviceRequest,
    Map<String, dynamic> serviceHistory,
  ) {
    return ServiceAcknowledgmentModel(
      srNumber: serviceHistory['srNumber'] ?? '',
      serviceDate: (serviceHistory['resolutionTimestamp'] as Timestamp).toDate(),
      nextServiceDate: (serviceHistory['nextServiceDate'] as Timestamp).toDate(),
      awgDetails: AwgDetails.fromMap(serviceRequest['equipmentDetails']),
      customerDetails: CustomerDetails.fromMap(serviceRequest['customerDetails']),
      partsReplaced: serviceHistory['partsReplaced'] ?? '',
      issueType: serviceHistory['typeOfRaisedIssue'] ?? '',
      complaintRelatedTo: serviceHistory['complaintRelatedTo'] ?? '',
      suggestions: ServiceSuggestions.fromMap(serviceHistory['suggestions']),
      customSuggestions: serviceHistory['customSuggestions'] ?? '',
      images: ServiceImages.fromMap(serviceHistory),
      solutionProvided: serviceHistory['solutionProvided'] ?? '',
      resolvedBy: serviceHistory['resolvedBy'] ?? '',
    );
  }
}

class AwgDetails {
  final String model;
  final String serialNumber;

  AwgDetails({required this.model, required this.serialNumber});

  factory AwgDetails.fromMap(Map<String, dynamic> map) {
    return AwgDetails(
      model: map['model'] ?? '',
      serialNumber: map['awgSerialNumber'] ?? '',
    );
  }
}

class CustomerDetails {
  final String name;
  final String phone;
  final String company;
  final String email;
  final String fullAddress;
  final String city;
  final String state;

  CustomerDetails({
    required this.name,
    required this.phone,
    required this.company,
    required this.email,
    required this.fullAddress,
    required this.city,
    required this.state,
  });

  factory CustomerDetails.fromMap(Map<String, dynamic> map) {
    return CustomerDetails(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      company: map['company'] ?? '',
      email: map['email'] ?? '',
      fullAddress: map['address']['fullAddress'] ?? '',
      city: map['address']['city'] ?? '',
      state: map['address']['state'] ?? '',
    );
  }
}

class ServiceSuggestions {
  final bool keepAirFilterClean;
  final bool keepAwayFromSmells;
  final bool protectFromSunAndRain;
  final bool supplyStableElectricity;

  ServiceSuggestions({
    required this.keepAirFilterClean,
    required this.keepAwayFromSmells,
    required this.protectFromSunAndRain,
    required this.supplyStableElectricity,
  });

  factory ServiceSuggestions.fromMap(Map<String, dynamic> map) {
    return ServiceSuggestions(
      keepAirFilterClean: map['keepAirFilterClean'] ?? false,
      keepAwayFromSmells: map['keepAwayFromSmells'] ?? false,
      protectFromSunAndRain: map['protectFromSunAndRain'] ?? false,
      supplyStableElectricity: map['supplyStableElectricity'] ?? false,
    );
  }
}

class ServiceImages {
  final String? frontViewImageUrl;
  final String? leftViewImageUrl;
  final String? rightViewImageUrl;
  final String? issueImageUrl;
  final String? resolutionImageUrl;

  ServiceImages({
    this.frontViewImageUrl,
    this.leftViewImageUrl,
    this.rightViewImageUrl,
    this.issueImageUrl,
    this.resolutionImageUrl,
  });

  factory ServiceImages.fromMap(Map<String, dynamic> map) {
    return ServiceImages(
      frontViewImageUrl: map['frontViewImageUrl'],
      leftViewImageUrl: map['leftViewImageUrl'],
      rightViewImageUrl: map['rightViewImageUrl'],
      issueImageUrl: map['issueImageUrl'],
      resolutionImageUrl: map['resolutionImageUrl'],
    );
  }
}