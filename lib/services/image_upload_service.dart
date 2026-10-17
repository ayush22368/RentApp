import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  // Pick single photo from Camera
  Future<File?> pickFromCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 75,
      );
      if (picked != null) {
        return File(picked.path);
      }
    } catch (e) {
      debugPrint('Error picking from camera: $e');
    }
    return null;
  }

  // Pick one or multiple photos from Gallery
  Future<List<File>> pickFromGallery({bool allowMultiple = true}) async {
    try {
      if (allowMultiple) {
        final List<XFile> pickedList = await _picker.pickMultiImage(
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
        );
        return pickedList.map((x) => File(x.path)).toList();
      } else {
        final XFile? picked = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 75,
        );
        if (picked != null) {
          return [File(picked.path)];
        }
      }
    } catch (e) {
      debugPrint('Error picking from gallery: $e');
    }
    return [];
  }

  // Upload a photo and return its URL (Firebase Storage with base64 fallback)
  Future<String> uploadPhoto(File file, {required String ownerUid}) async {
    try {
      // 1. Try Firebase Storage
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('properties')
          .child(ownerUid)
          .child(fileName);

      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage upload failed or not enabled ($e). Falling back to compressed base64.');
      // 2. Resilient fallback to compressed Base64 data URI
      final bytes = await file.readAsBytes();
      final base64String = base64Encode(bytes);
      return 'data:image/jpeg;base64,$base64String';
    }
  }
}
