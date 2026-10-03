import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import '../member3_payment_reviews/secure_payment_receipt_screen.dart';

/// Member 2 (IT23707122): Digital Contract & Deposit Screen (Variant B)
/// Requirements: FR006 (Digital contract + deposit before job starts to protect both parties)
class DigitalContractDepositScreen extends StatefulWidget {
  final Booking booking;

  const DigitalContractDepositScreen({super.key, required this.booking});

  @override
  State<DigitalContractDepositScreen> createState() => _DigitalContractDepositScreenState();
}

class _DigitalContractDepositScreenState extends State<DigitalContractDepositScreen> {
  bool _agreedToTerms = false;
  bool _hasSigned = false;

  void _proceedToPayment() {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the confirmation box to agree to the key terms.')),
      );
      return;
    }
    if (!_hasSigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your digital signature on the pad.')),
      );
      return;
    }

    // Update state with signed contract
    AppStateService().signContractAndPayDeposit(widget.booking.id, 'signed_signature_data');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecurePaymentReceiptScreen(booking: widget.booking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deposit = widget.booking.depositAmount;
    final remaining = widget.booking.remainingAmount;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Digital Contract & Escrow'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm Scope & Deposit',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            const Text(
              'Formalizing terms prevents unexpected scope changes and secures your booking.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),

            const SizedBox(height: 20),

            // Condensed "Key terms" bullets (Variant B)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Key Agreement Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTermItem('1. Scope of Work', 'Agreed for ${widget.booking.serviceItem} at designated address.'),
                  _buildTermItem('2. Upfront Pricing Lock', 'Rs. ${widget.booking.totalPrice.toInt()} fixed rate. Any modifications require mutual in-app signoff.'),
                  _buildTermItem('3. 100% Refundable Deposit', 'Deposit is 100% refundable if cancelled up to 4 hours before slot.'),
                  _buildTermItem('4. Escrow Protection', 'Deposit held securely. Final balance released only after customer inspection.'),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Deposit / Remaining Split Bar (Variant B)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Deposit Due Now', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            'Rs. ${deposit.toInt()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                          const Text('Refundable (Policy active)', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(width: 1, height: 40, color: AppColors.cardBorder),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining After Job', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          Text(
                            'Rs. ${remaining.toInt()}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                          ),
                          const Text('Payable on completion', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Digital Signature Pad (Interactive Canvas simulation)
            const Text(
              'Digital Signature',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _hasSigned ? AppColors.primary : AppColors.cardBorder),
              ),
              child: Stack(
                children: [
                  if (!_hasSigned)
                    Center(
                      child: TextButton.icon(
                        onPressed: () => setState(() => _hasSigned = true),
                        icon: const Icon(Icons.draw, color: AppColors.primary),
                        label: const Text('Tap here to draw signature', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Poornima M. (Signed digitally)', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.primary)),
                              SizedBox(height: 4),
                              Text('Timestamped & encrypted via SHA-256', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 20, color: AppColors.textSecondary),
                            onPressed: () => setState(() => _hasSigned = false),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Agreement Checkbox
            CheckboxListTile(
              value: _agreedToTerms,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              activeColor: AppColors.primary,
              title: const Text(
                'I confirm the service scope and agree to deposit payment terms.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _proceedToPayment,
              child: Text('Accept & Pay Rs. ${deposit.toInt()} Deposit'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTermItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
