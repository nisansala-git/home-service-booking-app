import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import '../member3_payment_reviews/provider_dashboard_screen.dart';

/// Member 1 (IT23684980): Provider Registration & Verification (Variant B)
/// Solves Theme 3Usability Issue (FR002, NFR001, NFR003): Resend timer, clear error states, website fallback
class ProviderVerificationScreen extends StatefulWidget {
  final String name;
  final String phone;
  final String category;
  final String email;
  final String area;
  final double startingPrice;

  const ProviderVerificationScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.category,
    required this.email,
    required this.area,
    required this.startingPrice,
  });

  @override
  State<ProviderVerificationScreen> createState() => _ProviderVerificationScreenState();
}

class _ProviderVerificationScreenState extends State<ProviderVerificationScreen> {
  final List<TextEditingController> _codeControllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  int _secondsRemaining = 45;
  Timer? _timer;
  bool _hasError = false;
  String _errorMessage = '';
  int _attemptsRemaining = 3;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _secondsRemaining = 45;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _codeControllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _verifyOtp() {
    final code = _codeControllers.map((c) => c.text).join();
    if (code.length < 6) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter all 6 digits of your SMS code.';
      });
      return;
    }

    // For evaluation/demo, any 6-digit code or '123456' succeeds
    if (code == '000000') {
      setState(() {
        _hasError = true;
        _attemptsRemaining--;
        _errorMessage = 'Incorrect verification code. $_attemptsRemaining attempts left.';
      });
      return;
    }

    // Success: Register provider in AppStateService (CRUD: Create)
    final newProv = ServiceProvider(
      id: 'prov_${DateTime.now().millisecondsSinceEpoch}',
      name: widget.name,
      category: widget.category,
      rating: 5.0,
      reviewCount: 0,
      jobsCompleted: 0,
      onTimePercentage: 100,
      experienceYears: 2,
      startingPrice: widget.startingPrice,
      distanceKm: 0.5,
      imageUrl: 'https://images.unsplash.com/photo-1540569014015-19a7be504e3a?w=400',
      about: 'Verified ${widget.category} professional serving ${widget.area}.',
      pastWorkImages: [],
      pricingTable: [
        {'item': 'Standard Service', 'price': widget.startingPrice, 'unit': 'inspection/base'},
      ],
    );

    AppStateService().registerProvider(newProv);
    AppStateService().setRole('provider');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success),
            SizedBox(width: 8),
            Text('Account Verified!'),
          ],
        ),
        content: Text('Welcome, ${widget.name}! Your service profile is now live on FixIt Home.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const ProviderDashboardScreen()),
                (route) => route.isFirst,
              );
            },
            child: const Text('Go to Provider Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Verify Phone Number'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Step Indicator (Variant B: Info -> Verify -> Details)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStepDot(1, 'Info', true),
                _buildStepLine(true),
                _buildStepDot(2, 'Verify', true),
                _buildStepLine(false),
                _buildStepDot(3, 'Live', false),
              ],
            ),
            const SizedBox(height: 32),

            const Icon(Icons.mark_email_read_outlined, size: 60, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Enter Verification Code',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            Text(
              'We sent a 6-digit SMS verification code to\n${widget.phone}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),

            // 6-digit Code Input Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 48,
                  height: 56,
                  child: TextField(
                    controller: _codeControllers[index],
                    focusNode: _focusNodes[index],
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: _hasError ? AppColors.error : AppColors.cardBorder,
                          width: 1.5,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _hasError = false);
                      if (value.isNotEmpty && index < 5) {
                        _focusNodes[index + 1].requestFocus();
                      } else if (value.isEmpty && index > 0) {
                        _focusNodes[index - 1].requestFocus();
                      }
                    },
                  ),
                );
              }),
            ),

            if (_hasError) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(_errorMessage, style: const TextStyle(color: AppColors.error, fontSize: 12)),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Resend Timer (FR002, NFR003)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Didn't receive the code? ", style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                _secondsRemaining > 0
                    ? Text('Resend in ${_secondsRemaining}s', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary))
                    : TextButton(
                        onPressed: _startTimer,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Resend SMS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
              ],
            ),

            const SizedBox(height: 20),

            // Observed User Research Solution: Website Fallback Link (FR002 / NFR001)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help_outline, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Having trouble receiving SMS on mobile? You can also complete instant verification on our web portal.',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Verify Button
            ElevatedButton(
              onPressed: _verifyOtp,
              child: const Text('Verify & Complete Registration'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepDot(int num, String label, bool active) {
    return Column(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: active ? AppColors.primary : AppColors.surfaceMuted,
          child: Text(
            num.toString(),
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(bool active) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: active ? AppColors.primary : AppColors.cardBorder,
    );
  }
}
