import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianProfile {
  final String uid;
  final String name;
  final String employeeId;
  final String mobileNumber;
  final String email;
  final String designation;
  final String profileImageUrl;
  final bool isProfileComplete;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TechnicianProfile({
    required this.uid,
    required this.name,
    required this.employeeId,
    required this.mobileNumber,
    required this.email,
    required this.designation,
    this.profileImageUrl = '',
    this.isProfileComplete = false,
    this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore document
  factory TechnicianProfile.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TechnicianProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      employeeId: data['employeeId'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      email: data['email'] ?? '',
      designation: data['designation'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert from Map
  factory TechnicianProfile.fromMap(Map<String, dynamic> data) {
    return TechnicianProfile(
      uid: data['uid'] ?? '',
      name: data['name'] ?? '',
      employeeId: data['employeeId'] ?? '',
      mobileNumber: data['mobileNumber'] ?? '',
      email: data['email'] ?? '',
      designation: data['designation'] ?? '',
      profileImageUrl: data['profileImageUrl'] ?? '',
      isProfileComplete: data['isProfileComplete'] ?? false,
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : null,
      updatedAt: data['updatedAt'] != null 
          ? (data['updatedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'employeeId': employeeId,
      'mobileNumber': mobileNumber,
      'email': email,
      'designation': designation,
      'profileImageUrl': profileImageUrl,
      'isProfileComplete': isProfileComplete,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Copy with method for easy updates
  TechnicianProfile copyWith({
    String? uid,
    String? name,
    String? employeeId,
    String? mobileNumber,
    String? email,
    String? designation,
    String? profileImageUrl,
    bool? isProfileComplete,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TechnicianProfile(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      employeeId: employeeId ?? this.employeeId,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      designation: designation ?? this.designation,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'TechnicianProfile(uid: $uid, name: $name, employeeId: $employeeId, email: $email, designation: $designation, isProfileComplete: $isProfileComplete)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TechnicianProfile &&
        other.uid == uid &&
        other.name == name &&
        other.employeeId == employeeId &&
        other.mobileNumber == mobileNumber &&
        other.email == email &&
        other.designation == designation &&
        other.profileImageUrl == profileImageUrl &&
        other.isProfileComplete == isProfileComplete;
  }

  @override
  int get hashCode {
    return uid.hashCode ^
        name.hashCode ^
        employeeId.hashCode ^
        mobileNumber.hashCode ^
        email.hashCode ^
        designation.hashCode ^
        profileImageUrl.hashCode ^
        isProfileComplete.hashCode;
  }
}