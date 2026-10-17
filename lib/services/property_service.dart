import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/property_constants.dart';
import '../models/property_model.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _propertiesRef =>
      _firestore.collection('properties');

  // Stream of public available properties for Discover screen
  Stream<List<PropertyModel>> getPublicAvailablePropertiesStream({
    String? categoryFilter,
  }) {
    Query<Map<String, dynamic>> query = _propertiesRef.where(
      'availabilityStatus',
      whereIn: [
        PropertyConstants.statusAvailable,
        PropertyConstants.statusLimited,
      ],
    );

    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter != 'All') {
      query = query.where('propertyType', isEqualTo: categoryFilter);
    }

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList();
      // Sort newest first
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // Stream of properties belonging to a specific owner
  Stream<List<PropertyModel>> getOwnerPropertiesStream(String ownerUid) {
    return _propertiesRef
        .where('ownerUid', isEqualTo: ownerUid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // Stream of ALL properties (for Super Admin)
  Stream<List<PropertyModel>> getAllPropertiesStream({String? categoryFilter}) {
    Query<Map<String, dynamic>> query = _propertiesRef;
    if (categoryFilter != null &&
        categoryFilter.isNotEmpty &&
        categoryFilter != 'All') {
      query = query.where('propertyType', isEqualTo: categoryFilter);
    }
    return query.snapshots().map((snapshot) {
      final list = snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList();
      list.sort((a, b) {
        final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // Get single property stream
  Stream<PropertyModel?> getPropertyStream(String propertyId) {
    return _propertiesRef.doc(propertyId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PropertyModel.fromFirestore(doc);
    });
  }

  // Add new property
  Future<String> addProperty(PropertyModel property) async {
    final docRef = await _propertiesRef.add(property.toMap());
    return docRef.id;
  }

  // Update existing property
  Future<void> updateProperty(PropertyModel property) async {
    await _propertiesRef.doc(property.id).update(property.toMap());
  }

  // Quick update availability status & bed count
  Future<void> updateAvailability({
    required String propertyId,
    required String status,
    int? availableBeds,
    int? totalBeds,
  }) async {
    final Map<String, dynamic> updateData = {
      'availabilityStatus': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (availableBeds != null) updateData['availableBeds'] = availableBeds;
    if (totalBeds != null) updateData['totalBeds'] = totalBeds;

    await _propertiesRef.doc(propertyId).update(updateData);
  }

  // Delete property
  Future<void> deleteProperty(String propertyId) async {
    await _propertiesRef.doc(propertyId).delete();
  }

  // --- Favorites Management ---

  // Stream of favorite property IDs for a user
  Stream<Set<String>> getFavoritePropertyIdsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toSet());
  }

  // Toggle favorite for user
  Future<bool> toggleFavorite(String uid, String propertyId) async {
    final favDoc = _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .doc(propertyId);

    final snapshot = await favDoc.get();
    if (snapshot.exists) {
      await favDoc.delete();
      return false; // Removed
    } else {
      await favDoc.set({
        'propertyId': propertyId,
        'addedAt': FieldValue.serverTimestamp(),
      });
      return true; // Added
    }
  }

  // Stream of actual favorite property models
  Stream<List<PropertyModel>> getFavoritePropertiesStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('favorites')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return <PropertyModel>[];
      final propertyIds = snapshot.docs.map((d) => d.id).toList();

      final List<PropertyModel> properties = [];
      for (final id in propertyIds) {
        try {
          final doc = await _propertiesRef.doc(id).get();
          if (doc.exists) {
            properties.add(PropertyModel.fromFirestore(doc));
          }
        } catch (e) {
          debugPrint('Error fetching favorite property $id: $e');
        }
      }
      return properties;
    });
  }

  // Direct calling handler
  static Future<bool> callPhoneNumber(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.isEmpty) return false;
    final Uri uri = Uri(scheme: 'tel', path: cleaned);
    if (await canLaunchUrl(uri)) {
      return await launchUrl(uri);
    }
    return false;
  }
}
