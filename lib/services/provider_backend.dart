import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';
import '../models/models.dart';

class ProviderBackend {
  static final instance = ProviderBackend();
  FirebaseAuth get auth => FirebaseAuth.instance;
  FirebaseFirestore get db => FirebaseFirestore.instance;

  Future<void> createAccount(String email, String password, String name) async {
    final result = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    await result.user!.updateDisplayName(name);
    await result.user!.sendEmailVerification();
  }

  Future<void> saveProfile(
      ServiceProvider provider, String phone, String email, String area,
      {Uint8List? documentBytes, String? documentName}) async {
    final user = auth.currentUser;
    if (user == null || user.uid != provider.id)
      throw StateError('Sign in to save your profile.');
    final batch = db.batch();
    String? documentPath;
    if (documentBytes != null && documentName != null) {
      final extension = documentName.split('.').last.toLowerCase();
      final types = {
        'pdf': 'application/pdf',
        'jpg': 'image/jpeg',
        'jpeg': 'image/jpeg',
        'png': 'image/png'
      };
      if (!types.containsKey(extension) ||
          documentBytes.isEmpty ||
          documentBytes.length > 5 * 1024 * 1024) {
        throw ArgumentError('Choose a PDF, JPG or PNG smaller than 5 MB.');
      }
      documentPath = 'provider_documents/${user.uid}/identity.$extension';
      final task = FirebaseStorage.instance.ref(documentPath).putData(
          documentBytes, SettableMetadata(contentType: types[extension]));
      try {
        await task.timeout(const Duration(seconds: 60));
      } catch (_) {
        await task.cancel();
        rethrow;
      }
    }
    batch.set(db.collection('providers').doc(user.uid), provider.toMap());
    batch.set(db.collection('provider_private').doc(user.uid), {
      'phone': phone,
      'email': email,
      'area': area,
      if (documentPath != null) 'documentPath': documentPath,
      if (documentName != null) 'documentName': documentName,
    });
    // Wait for server acknowledgement; never report an offline queued write as saved.
    await batch.commit().timeout(const Duration(seconds: 20));
  }

  Stream<List<ServiceProvider>> watchProviders() =>
      db.collection('providers').snapshots().map((snapshot) => snapshot.docs
          .map((doc) => ServiceProvider.fromMap(doc.data(), doc.id))
          .toList());
}
