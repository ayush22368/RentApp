import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/property_constants.dart';

class PropertyModel {
  final String id;
  final String title;
  final String propertyType;
  final List<String> photos;
  final num monthlyRent;
  final num securityDeposit;
  final String city;
  final String locality;
  final String completeAddress;
  final String description;
  final List<String> facilities;
  final String ownerName;
  final String contactPhone;
  final String availabilityStatus;
  final int? totalBeds;
  final int? availableBeds;
  final String ownerUid;
  final String ownerEmail;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PropertyModel({
    required this.id,
    required this.title,
    required this.propertyType,
    this.photos = const [],
    required this.monthlyRent,
    required this.securityDeposit,
    required this.city,
    required this.locality,
    required this.completeAddress,
    required this.description,
    this.facilities = const [],
    required this.ownerName,
    required this.contactPhone,
    this.availabilityStatus = PropertyConstants.statusAvailable,
    this.totalBeds,
    this.availableBeds,
    required this.ownerUid,
    required this.ownerEmail,
    this.createdAt,
    this.updatedAt,
  });

  bool get isBedBased =>
      propertyType == 'PG Accommodation' || propertyType == 'Hostels';

  String get bedAvailabilityText {
    if (isBedBased && availableBeds != null && totalBeds != null) {
      return '$availableBeds of $totalBeds beds available';
    }
    return '';
  }

  bool get isAvailableForPublic =>
      availabilityStatus == PropertyConstants.statusAvailable ||
      availabilityStatus == PropertyConstants.statusLimited;

  factory PropertyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PropertyModel(
      id: doc.id,
      title: data['title'] as String? ?? 'Untitled Property',
      propertyType: data['propertyType'] as String? ?? 'Flats / Apartments',
      photos: List<String>.from(data['photos'] ?? []),
      monthlyRent: (data['monthlyRent'] as num?) ?? 0,
      securityDeposit: (data['securityDeposit'] as num?) ?? 0,
      city: data['city'] as String? ?? '',
      locality: data['locality'] as String? ?? '',
      completeAddress: data['completeAddress'] as String? ?? '',
      description: data['description'] as String? ?? '',
      facilities: List<String>.from(data['facilities'] ?? []),
      ownerName: data['ownerName'] as String? ?? '',
      contactPhone: data['contactPhone'] as String? ?? '',
      availabilityStatus: data['availabilityStatus'] as String? ??
          PropertyConstants.statusAvailable,
      totalBeds: data['totalBeds'] as int?,
      availableBeds: data['availableBeds'] as int?,
      ownerUid: data['ownerUid'] as String? ?? '',
      ownerEmail: data['ownerEmail'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'propertyType': propertyType,
      'photos': photos,
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'city': city,
      'locality': locality,
      'completeAddress': completeAddress,
      'description': description,
      'facilities': facilities,
      'ownerName': ownerName,
      'contactPhone': contactPhone,
      'availabilityStatus': availabilityStatus,
      'totalBeds': totalBeds,
      'availableBeds': availableBeds,
      'ownerUid': ownerUid,
      'ownerEmail': ownerEmail,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  PropertyModel copyWith({
    String? id,
    String? title,
    String? propertyType,
    List<String>? photos,
    num? monthlyRent,
    num? securityDeposit,
    String? city,
    String? locality,
    String? completeAddress,
    String? description,
    List<String>? facilities,
    String? ownerName,
    String? contactPhone,
    String? availabilityStatus,
    int? totalBeds,
    int? availableBeds,
    String? ownerUid,
    String? ownerEmail,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      propertyType: propertyType ?? this.propertyType,
      photos: photos ?? this.photos,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      city: city ?? this.city,
      locality: locality ?? this.locality,
      completeAddress: completeAddress ?? this.completeAddress,
      description: description ?? this.description,
      facilities: facilities ?? this.facilities,
      ownerName: ownerName ?? this.ownerName,
      contactPhone: contactPhone ?? this.contactPhone,
      availabilityStatus: availabilityStatus ?? this.availabilityStatus,
      totalBeds: totalBeds ?? this.totalBeds,
      availableBeds: availableBeds ?? this.availableBeds,
      ownerUid: ownerUid ?? this.ownerUid,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
