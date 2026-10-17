import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../constants/property_constants.dart';
import '../models/user_role.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _auth.authStateChanges().listen(_handleAuthStateChange);
  }

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // GoogleSignIn with serverClientId (Web Client ID from google-services.json)
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '472143225007-nj0lc4l5eqvgv7el45eefij9qe3d6kst.apps.googleusercontent.com',
  );

  UserRole _currentRole = UserRole.normal;
  StreamSubscription<DocumentSnapshot>? _ownerDocSubscription;

  User? get currentUser => _auth.currentUser;
  UserRole get currentRole => _currentRole;
  bool get isAuthenticated => _auth.currentUser != null;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  void _handleAuthStateChange(User? user) {
    _ownerDocSubscription?.cancel();
    if (user == null) {
      _currentRole = UserRole.normal;
      notifyListeners();
      return;
    }

    final email = user.email?.toLowerCase().trim() ?? '';

    // 1. Super Admin Check
    if (email == PropertyConstants.superAdminEmail.toLowerCase().trim()) {
      _currentRole = UserRole.superAdmin;
      _saveUserProfile(user, 'super_admin');
      notifyListeners();
      return;
    }

    // 2. Real-time Authorized Owner Check
    _ownerDocSubscription = _firestore
        .collection('authorized_owners')
        .doc(email)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        final isActive = data?['isActive'] as bool? ?? false;

        if (isActive) {
          _currentRole = UserRole.owner;
          // Mark owner as active and record UID and last login
          _firestore.collection('authorized_owners').doc(email).set({
            'status': 'active',
            'uid': user.uid,
            'lastLoginAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

          _saveUserProfile(user, 'owner');
        } else {
          // Deactivated owner -> falls back to normal user!
          _currentRole = UserRole.normal;
          _saveUserProfile(user, 'normal');
        }
      } else {
        // Not in authorized_owners -> normal user!
        _currentRole = UserRole.normal;
        _saveUserProfile(user, 'normal');
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error listening to authorized_owner: $e');
      _currentRole = UserRole.normal;
      notifyListeners();
    });
  }

  Future<void> _saveUserProfile(User user, String role) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email?.toLowerCase().trim(),
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'role': role,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving user profile: $e');
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in flow
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential;
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ownerDocSubscription?.cancel();
      await _googleSignIn.signOut();
      await _auth.signOut();
      _currentRole = UserRole.normal;
      notifyListeners();
    } catch (e) {
      debugPrint('Sign-Out Error: $e');
      rethrow;
    }
  }
}
