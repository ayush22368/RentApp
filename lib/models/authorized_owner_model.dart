import 'package:cloud_firestore/cloud_firestore.dart';

class AuthorizedOwnerModel {
  final String email;
  final String? name;
  final String status; // 'pending' | 'active'
  final bool isActive; // Super admin can toggle active/deactive
  final DateTime? authorizedAt;
  final String? authorizedBy;
  final String? uid;
  final DateTime? lastLoginAt;

  AuthorizedOwnerModel({
    required this.email,
    this.name,
    this.status = 'pending',
    this.isActive = true,
    this.authorizedAt,
    this.authorizedBy,
    this.uid,
    this.lastLoginAt,
  });

  factory AuthorizedOwnerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AuthorizedOwnerModel(
      email: data['email'] ?? doc.id,
      name: data['name'] as String?,
      status: data['status'] as String? ?? 'pending',
      isActive: data['isActive'] as bool? ?? true,
      authorizedAt: (data['authorizedAt'] as Timestamp?)?.toDate(),
      authorizedBy: data['authorizedBy'] as String?,
      uid: data['uid'] as String?,
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email.toLowerCase().trim(),
      'name': name,
      'status': status,
      'isActive': isActive,
      'authorizedAt': authorizedAt != null
          ? Timestamp.fromDate(authorizedAt!)
          : FieldValue.serverTimestamp(),
      'authorizedBy': authorizedBy,
      'uid': uid,
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  AuthorizedOwnerModel copyWith({
    String? email,
    String? name,
    String? status,
    bool? isActive,
    DateTime? authorizedAt,
    String? authorizedBy,
    String? uid,
    DateTime? lastLoginAt,
  }) {
    return AuthorizedOwnerModel(
      email: email ?? this.email,
      name: name ?? this.name,
      status: status ?? this.status,
      isActive: isActive ?? this.isActive,
      authorizedAt: authorizedAt ?? this.authorizedAt,
      authorizedBy: authorizedBy ?? this.authorizedBy,
      uid: uid ?? this.uid,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }
}
