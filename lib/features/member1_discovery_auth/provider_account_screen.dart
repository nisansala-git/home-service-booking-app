import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/provider_backend.dart';
import '../../services/app_state_service.dart';
import 'provider_registration_screen.dart';

class ProviderAccountScreen extends StatefulWidget {
  const ProviderAccountScreen({super.key});
  @override
  State<ProviderAccountScreen> createState() => _ProviderAccountScreenState();
}

class _ProviderAccountScreenState extends State<ProviderAccountScreen> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await ProviderBackend.instance.auth.signInWithEmailAndPassword(
          email: email.text.trim(), password: password.text);
      AppStateService().connectProviders();
    } on FirebaseAuthException catch (e) {
      message = e.message ?? 'Sign in failed.';
    } catch (_) {
      message = 'Firebase is unavailable. Please try again.';
    }
    if (mounted) setState(() => busy = false);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Provider account')),
        body: StreamBuilder<User?>(
          stream: ProviderBackend.instance.auth.authStateChanges(),
          builder: (context, snapshot) {
            final user = snapshot.data;
            return ListView(padding: const EdgeInsets.all(20), children: [
              if (message != null) Text(message!),
              if (user == null) ...[
                TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 16),
                TextField(
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password')),
                const SizedBox(height: 20),
                ElevatedButton(
                    onPressed: busy ? null : signIn,
                    child: Text(busy ? 'Signing in…' : 'Sign in')),
                TextButton(
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const ProviderRegistrationScreen())),
                    child: const Text('Create provider account')),
              ] else ...[
                Text('Signed in as ${user.email}'),
                StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: ProviderBackend.instance.db
                      .collection('providers')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, profile) {
                    if (profile.hasError)
                      return const Text(
                          'Could not load your profile. Check Firestore setup.');
                    if (!profile.hasData)
                      return const LinearProgressIndicator();
                    if (!profile.data!.exists)
                      return const Text(
                          'Your profile is not saved yet. Complete registration using the same email.');
                    return SwitchListTile(
                      title: const Text('Available today'),
                      value: profile.data!.data()?['isAvailableToday'] == true,
                      onChanged: busy
                          ? null
                          : (value) async {
                              setState(() => busy = true);
                              try {
                                await profile.data!.reference.update({
                                  'isAvailableToday': value
                                }).timeout(const Duration(seconds: 20));
                                message = 'Availability saved.';
                              } catch (_) {
                                message =
                                    'Could not confirm saving availability. Check your connection and retry.';
                              }
                              if (mounted) setState(() => busy = false);
                            },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                    'Your saved profile appears in Home and Search. Email verification is separate from identity verification.'),
                TextButton(
                    onPressed: () async {
                      await ProviderBackend.instance.auth.signOut();
                      AppStateService().setRole('homeowner');
                    },
                    child: const Text('Sign out')),
              ],
            ]);
          },
        ),
      );
}
