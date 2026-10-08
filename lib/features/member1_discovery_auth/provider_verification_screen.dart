import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/models.dart';
import '../../services/provider_backend.dart';
import '../../services/app_state_service.dart';

class ProviderVerificationScreen extends StatefulWidget {
  final String name, phone, category, email, area, password;
  final double startingPrice;
  const ProviderVerificationScreen(
      {super.key,
      required this.name,
      required this.phone,
      required this.category,
      required this.email,
      required this.area,
      required this.password,
      required this.startingPrice});
  @override
  State<ProviderVerificationScreen> createState() =>
      _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState
    extends State<ProviderVerificationScreen> {
  bool busy = false, accountCreated = false, saved = false;
  String message = 'Create your account to receive an email verification link.';
  Future<void> perform(Future<void> Function() action) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await action();
    } on FirebaseAuthException catch (e) {
      message = e.message ?? e.code;
    } catch (e) {
      message =
          'Could not complete this step. Check Firebase setup and your connection, then retry. $e';
    }
    if (mounted) setState(() => busy = false);
  }

  Future<void> create() => perform(() async {
        final backend = ProviderBackend.instance;
        if (backend.auth.currentUser?.email != widget.email) {
          await backend.createAccount(
              widget.email, widget.password, widget.name);
        } else {
          await backend.auth.currentUser!.sendEmailVerification();
        }
        accountCreated = true;
        message =
            'Check ${widget.email} for the verification link, then return here.';
      });
  Future<void> complete() => perform(() async {
        final backend = ProviderBackend.instance;
        await backend.auth.currentUser!.reload();
        final user = backend.auth.currentUser!;
        if (!user.emailVerified) {
          message = 'Open the verification link in your email and try again.';
          return;
        }
        await user.getIdToken(true);
        final provider = ServiceProvider(
          id: user.uid,
          name: widget.name,
          category: widget.category,
          rating: 0,
          reviewCount: 0,
          jobsCompleted: 0,
          onTimePercentage: 0,
          experienceYears: 0,
          startingPrice: widget.startingPrice,
          distanceKm: 0,
          isVerified: false,
          isBackgroundChecked: false,
          isInsured: false,
          imageUrl: '',
          about: '${widget.category} services in ${widget.area}.',
          pastWorkImages: [],
          pricingTable: [
            {
              'item': 'Standard service',
              'price': widget.startingPrice,
              'unit': 'base'
            },
          ],
        );
        await backend.saveProfile(
            provider, widget.phone, widget.email, widget.area);
        AppStateService().connectProviders();
        saved = true;
        message =
            'Profile saved to Firebase. Find it on Home and Search. Identity checks are pending.';
      });
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Verify and save account')),
        body: ListView(padding: const EdgeInsets.all(24), children: [
          const Icon(Icons.mark_email_read_outlined, size: 64),
          const SizedBox(height: 20),
          Text(message),
          const SizedBox(height: 24),
          if (busy) const Center(child: CircularProgressIndicator()),
          if (!saved) ...[
            ElevatedButton(
                onPressed: busy ? null : create,
                child: Text(accountCreated
                    ? 'Resend verification email'
                    : 'Create account and send verification')),
            const SizedBox(height: 12),
            if (accountCreated)
              ElevatedButton(
                  onPressed: busy ? null : complete,
                  child: const Text('I verified my email — save profile')),
            const SizedBox(height: 16),
            const Text(
                'Verification uses email, not SMS. Phone and email are stored privately; your service profile is public.'),
          ] else
            ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                child: const Text('Return to Home')),
        ]),
      );
}
