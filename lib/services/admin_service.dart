import 'package:cloud_firestore/cloud_firestore.dart';
import '../constants/property_constants.dart';
import '../models/authorized_owner_model.dart';
import '../models/property_model.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _ownersRef =>
      _firestore.collection('authorized_owners');

  CollectionReference<Map<String, dynamic>> get _propertiesRef =>
      _firestore.collection('properties');

  // Stream of Super Admin Dashboard metrics
  Stream<Map<String, int>> getDashboardStatsStream() {
    return _propertiesRef.snapshots().asyncMap((propSnapshot) async {
      final totalProperties = propSnapshot.docs.length;
      int available = 0;
      int unavailable = 0;

      for (var doc in propSnapshot.docs) {
        final status = doc.data()['availabilityStatus'] as String? ?? '';
        if (status == PropertyConstants.statusAvailable ||
            status == PropertyConstants.statusLimited) {
          available++;
        } else {
          unavailable++;
        }
      }

      final ownersSnapshot = await _ownersRef.get();
      final totalOwners = ownersSnapshot.docs.length;

      return {
        'totalProperties': totalProperties,
        'available': available,
        'unavailable': unavailable,
        'totalOwners': totalOwners,
      };
    });
  }

  // Stream of all authorized owners & agents
  Stream<List<AuthorizedOwnerModel>> getAuthorizedOwnersStream() {
    return _ownersRef.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => AuthorizedOwnerModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) {
        final aDate = a.authorizedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.authorizedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  // Authorize a new owner by Google email address
  Future<void> authorizeOwner({
    required String email,
    String? name,
    required String authorizedBy,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    if (cleanEmail.isEmpty || !cleanEmail.contains('@')) {
      throw Exception('Please enter a valid Google email address.');
    }

    final docRef = _ownersRef.doc(cleanEmail);
    final existing = await docRef.get();
    if (existing.exists) {
      // If already exists, reactivate if deactivated
      await docRef.update({
        'isActive': true,
        if (name != null && name.isNotEmpty) 'name': name,
        'authorizedBy': authorizedBy,
      });
    } else {
      final newOwner = AuthorizedOwnerModel(
        email: cleanEmail,
        name: name,
        status: 'pending', // Pending until first Google login
        isActive: true,
        authorizedAt: DateTime.now(),
        authorizedBy: authorizedBy,
      );
      await docRef.set(newOwner.toMap());
    }
  }

  // Toggle active / deactivated state for an owner
  Future<void> setOwnerActiveStatus({
    required String email,
    required bool isActive,
  }) async {
    final cleanEmail = email.toLowerCase().trim();
    await _ownersRef.doc(cleanEmail).update({
      'isActive': isActive,
    });
  }

  // Delete / Remove owner authorization completely
  Future<void> removeOwnerAuthorization(String email) async {
    final cleanEmail = email.toLowerCase().trim();
    await _ownersRef.doc(cleanEmail).delete();
  }

  // Stream properties belonging to an owner (by email or UID)
  Stream<List<PropertyModel>> getOwnerProperties(String ownerEmail) {
    return _propertiesRef
        .where('ownerEmail', isEqualTo: ownerEmail.toLowerCase().trim())
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PropertyModel.fromFirestore(doc)).toList());
  }

  // Super Admin delete inappropriate property
  Future<void> removeProperty(String propertyId) async {
    await _propertiesRef.doc(propertyId).delete();
  }
}
