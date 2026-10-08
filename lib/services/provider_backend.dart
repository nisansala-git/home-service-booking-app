import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      ServiceProvider provider, String phone, String email, String area) async {
    final user = auth.currentUser;
    if (user == null || user.uid != provider.id)
      throw StateError('Sign in to save your profile.');
    final batch = db.batch();
    batch.set(db.collection('providers').doc(user.uid), provider.toMap());
    batch.set(db.collection('provider_private').doc(user.uid), {
      'phone': phone,
      'email': email,
      'area': area,
    });
    // Wait for server acknowledgement; never report an offline queued write as saved.
    await batch.commit().timeout(const Duration(seconds: 20));
  }

  Stream<List<ServiceProvider>> watchProviders() =>
      db.collection('providers').snapshots().map((snapshot) => snapshot.docs
          .map((doc) => ServiceProvider.fromMap(doc.data(), doc.id))
          .toList());
}
