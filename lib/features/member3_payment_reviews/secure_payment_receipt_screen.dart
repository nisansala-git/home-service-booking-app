import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import 'completed_job_review_screen.dart';

/// Member 3 (IT23710610): Secure Payment & Receipt Screen (Variant B)
/// Requirements: FR009 (Secure in-app payment with digital receipt), NFR004 (Payment encryption)
class SecurePaymentReceiptScreen extends StatefulWidget {
  final Booking booking;

  const SecurePaymentReceiptScreen({super.key, required this.booking});

  @override
  State<SecurePaymentReceiptScreen> createState() => _SecurePaymentReceiptScreenState();
}

class _SecurePaymentReceiptScreenState extends State<SecurePaymentReceiptScreen> {
  String _selectedMethod = 'card'; // card | wallet | bank
  bool _isPaymentDone = false;
  bool _isProcessing = false;

  void _processPayment() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 1200));
    if (mounted) {
      setState(() {
        _isProcessing = false;
        _isPaymentDone = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _isPaymentDone ? 'Payment Receipt' : 'Secure Checkout',
        showBack: !_isPaymentDone,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: _isPaymentDone ? _buildReceiptView() : _buildPaymentForm(),
      ),
    );
  }

  Widget _buildPaymentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encryption Security Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock, size: 16, color: AppColors.success),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '256-bit TLS Encrypted & PCI-DSS Compliant Gateway',
                  style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        const Text('Select Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),

        // Payment Method Icon-based Picker (Variant B)
        Row(
          children: [
            _buildMethodCard('card', Icons.credit_card, 'Card'),
            const SizedBox(width: 10),
            _buildMethodCard('wallet', Icons.account_balance_wallet, 'e-Wallet'),
            const SizedBox(width: 10),
            _buildMethodCard('bank', Icons.account_balance, 'Bank Transfer'),
          ],
        ),

        const SizedBox(height: 20),

        // Saved Card Row (Variant B)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary, width: 1.5),
          ),
          child: Row(
            children: [
              const Icon(Icons.credit_card, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Visa ending in •••• 4821', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Expires 08/28', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Amount Due Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Deposit Amount (Held in Escrow)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  Text('Rs. ${widget.booking.depositAmount.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaction Fee (SLIPS/LankaPay)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  const Text('Rs. 0 (Waived)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success)),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Payable Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    'Rs. ${widget.booking.depositAmount.toInt()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Pay Securely Button
        ElevatedButton(
          onPressed: _isProcessing ? null : _processPayment,
          child: _isProcessing
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Pay Securely Rs. ${widget.booking.depositAmount.toInt()}'),
        ),
      ],
    );
  }

  Widget _buildReceiptView() {
    return Column(
      children: [
        // Digital Receipt Card (Variant B)
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 50, color: AppColors.success),
              const SizedBox(height: 10),
              const Text('Payment Successful!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Transaction ID: TXN-893427192', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              const Divider(height: 28),

              _buildReceiptRow('Service', widget.booking.serviceItem),
              _buildReceiptRow('Provider', widget.booking.providerName),
              _buildReceiptRow('Date & Slot', widget.booking.timeSlot),
              _buildReceiptRow('Payment Method', 'Visa (•••• 4821)'),
              _buildReceiptRow('Deposit Amount Paid', 'Rs. ${widget.booking.depositAmount.toInt()}'),
              _buildReceiptRow('Remaining on Completion', 'Rs. ${widget.booking.remainingAmount.toInt()}'),

              const Divider(height: 28),

              // Share / Download Receipt Action Icons (Milestone 02 Variant B)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildReceiptAction(Icons.email_outlined, 'Email', () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt emailed to customer.')));
                  }),
                  const SizedBox(width: 24),
                  _buildReceiptAction(Icons.download_outlined, 'Download PDF', () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt downloaded to device.')));
                  }),
                  const SizedBox(width: 24),
                  _buildReceiptAction(Icons.share_outlined, 'Share', () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receipt link copied.')));
                  }),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 28),

        // Complete Job & Review Trigger (Allows user testing full lifecycle)
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CompletedJobReviewScreen(booking: widget.booking),
              ),
            );
          },
          child: const Text('Simulate Service Completion & Rate'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Return to Home', style: TextStyle(color: AppColors.textSecondary)),
        ),
      ],
    );
  }

  Widget _buildMethodCard(String key, IconData icon, String label) {
    final isSelected = _selectedMethod == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = key),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary.withOpacity(0.08) : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildReceiptAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.surfaceMuted,
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
