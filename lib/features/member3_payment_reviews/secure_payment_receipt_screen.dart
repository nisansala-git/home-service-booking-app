import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'completed_job_review_screen.dart';

/// Member 3 (IT23710610 - Karunathilaka T G C N): Secure Payment & Receipt Screen
/// Requirements & Usability:
/// - FR009: Secure in-app payment with digital receipt
/// - NFR004: Payment data encrypted in transit & at rest (256-bit TLS)
/// - Milestone 02 Variant B: Dynamic payment selector (Card / Wallet / Bank)
/// - Digital ticket receipt with dashed cutouts, TXN verification, and sharing/printing
class SecurePaymentReceiptScreen extends StatefulWidget {
  final Booking booking;

  const SecurePaymentReceiptScreen({super.key, required this.booking});

  @override
  State<SecurePaymentReceiptScreen> createState() =>
      _SecurePaymentReceiptScreenState();
}

class _SecurePaymentReceiptScreenState
    extends State<SecurePaymentReceiptScreen> {
  // Selected Payment Method: 'card' | 'wallet' | 'bank'
  String _selectedMethod = 'card';

  // Sub-method descriptions that update when method or 'Change' is clicked
  String _cardOption = 'Visa • • • • 4417';
  String _cardExpiry = 'Expires 08/28';

  String _walletOption = 'FriMi / Genie • • • • 9102';
  String _walletSubtitle = 'Linked & Verified';

  String _bankOption = 'Commercial Bank • • • • 7741';
  String _bankSubtitle = 'LankaPay / SLIPS Instant';

  bool _isProcessing = false;
  bool _isPaymentDone = false;
  String _transactionId = 'TXN-88213';
  late DateTime _paymentTimestamp;

  @override
  void initState() {
    super.initState();
    _paymentTimestamp = DateTime.now();
  }

  void _processPayment() async {
    setState(() => _isProcessing = true);

    // Simulate 256-bit secure gateway network authorization
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    // Generate unique transaction ID
    final txn =
        'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Update state via AppStateService (CRUD operation: update booking & trigger notification)
    AppStateService().updateBookingStatus(widget.booking.id, 'deposit_paid');
    AppStateService().createNotification(
      recipientId: widget.booking.providerId,
      title: 'Deposit Received (${AppColors.primaryDark != Colors.black ? "Rs. " : ""}${widget.booking.depositAmount.toInt()})',
      message:
          'Homeowner ${widget.booking.customerName} completed escrow deposit via ${_getMethodDisplayName()}. Ref: $txn',
      type: 'deposit_received',
      bookingId: widget.booking.id,
    );

    setState(() {
      _isProcessing = false;
      _isPaymentDone = true;
      _transactionId = txn;
      _paymentTimestamp = DateTime.now();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Payment successful! Receipt $txn generated.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMethodDisplayName() {
    switch (_selectedMethod) {
      case 'wallet':
        return _walletOption;
      case 'bank':
        return _bankOption;
      case 'card':
      default:
        return _cardOption;
    }
  }

  void _showChangeMethodModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select ${_selectedMethod.toUpperCase()} Account',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_selectedMethod == 'card') ...[
                _buildOptionTile(
                  title: 'Visa • • • • 4417',
                  subtitle: 'Expires 08/28 (Default)',
                  isSelected: _cardOption == 'Visa • • • • 4417',
                  onTap: () {
                    setState(() {
                      _cardOption = 'Visa • • • • 4417';
                      _cardExpiry = 'Expires 08/28';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                _buildOptionTile(
                  title: 'Mastercard • • • • 8821',
                  subtitle: 'Expires 11/27',
                  isSelected: _cardOption == 'Mastercard • • • • 8821',
                  onTap: () {
                    setState(() {
                      _cardOption = 'Mastercard • • • • 8821';
                      _cardExpiry = 'Expires 11/27';
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ] else if (_selectedMethod == 'wallet') ...[
                _buildOptionTile(
                  title: 'FriMi / Genie • • • • 9102',
                  subtitle: 'Nations Trust Bank Linked',
                  isSelected: _walletOption == 'FriMi / Genie • • • • 9102',
                  onTap: () {
                    setState(() {
                      _walletOption = 'FriMi / Genie • • • • 9102';
                      _walletSubtitle = 'Linked & Verified';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                _buildOptionTile(
                  title: 'eZ Cash • • • • 3450',
                  subtitle: 'Dialog Axiata Verified',
                  isSelected: _walletOption == 'eZ Cash • • • • 3450',
                  onTap: () {
                    setState(() {
                      _walletOption = 'eZ Cash • • • • 3450';
                      _walletSubtitle = 'Linked & Verified';
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ] else ...[
                _buildOptionTile(
                  title: 'Commercial Bank • • • • 7741',
                  subtitle: 'Savings Account (Instant)',
                  isSelected: _bankOption == 'Commercial Bank • • • • 7741',
                  onTap: () {
                    setState(() {
                      _bankOption = 'Commercial Bank • • • • 7741';
                      _bankSubtitle = 'LankaPay / SLIPS Instant';
                    });
                    Navigator.pop(ctx);
                  },
                ),
                _buildOptionTile(
                  title: 'Hatton National Bank • • • • 1209',
                  subtitle: 'Direct Debit Verified',
                  isSelected:
                      _bankOption == 'Hatton National Bank • • • • 1209',
                  onTap: () {
                    setState(() {
                      _bankOption = 'Hatton National Bank • • • • 1209';
                      _bankSubtitle = 'LankaPay / SLIPS Instant';
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      trailing: isSelected
          ? const Icon(Icons.check_circle, color: Color(0xFF182C25))
          : const Icon(Icons.circle_outlined, color: AppColors.cardBorder),
      onTap: onTap,
    );
  }

  // Action 1: SMS Receipt Summary Dialog
  void _sendReceiptViaSms() {
    final deposit = widget.booking.depositAmount.toInt();
    final smsBody =
        'FixIt Home Receipt: ${widget.booking.serviceItem} (Ref: ${widget.booking.id}). Deposit of Rs. $deposit paid via ${_getMethodDisplayName()}. Transaction ID: $_transactionId on ${DateFormat('MMM dd, yyyy h:mm a').format(_paymentTimestamp)}. Keep for your records.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.sms_outlined, color: Color(0xFF182C25)),
            SizedBox(width: 8),
            Text('SMS Receipt Summary', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A copy of this digital receipt will be sent to ${widget.booking.customerPhone.isNotEmpty ? widget.booking.customerPhone : "077 123 4567"}:',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                smsBody,
                style: const TextStyle(fontSize: 11, height: 1.4, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF182C25),
              foregroundColor: Colors.white,
              minimumSize: const Size(110, 38),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SMS receipt dispatched successfully to your phone.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            child: const Text('Send SMS'),
          ),
        ],
      ),
    );
  }

  // Action 2: Phone / Provider Contact Dialog
  void _callProviderWithReceipt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk, color: Color(0xFF182C25)),
            SizedBox(width: 8),
            Text('Contact Provider', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Call ${widget.booking.providerName} regarding appointment ${widget.booking.timeSlot}?',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            const Text(
              'Phone: 077 345 6789\nDeposit status: Verified Escrow (Rs. 300 / Paid)',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF182C25),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 38),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Calling ${widget.booking.providerName} (077 345 6789)...'),
                ),
              );
            },
            icon: const Icon(Icons.call, size: 16),
            label: const Text('Call Now'),
          ),
        ],
      ),
    );
  }

  // Action 3: Print Digital Receipt Dialog
  void _printReceipt() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.print_outlined, color: Color(0xFF182C25)),
            SizedBox(width: 8),
            Text('Print Receipt', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Preparing official printable receipt preview for your records:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('FIXIT HOME OFFICIAL E-RECEIPT',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  const Divider(height: 14),
                  Text('Ref: $_transactionId', style: const TextStyle(fontSize: 10)),
                  Text('Service: ${widget.booking.serviceItem}', style: const TextStyle(fontSize: 10)),
                  Text('Provider: ${widget.booking.providerName}', style: const TextStyle(fontSize: 10)),
                  Text('Deposit Amount: Rs. ${widget.booking.depositAmount.toInt()}',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('Date: ${DateFormat('yyyy-MM-dd HH:mm').format(_paymentTimestamp)}',
                      style: const TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF182C25),
              foregroundColor: Colors.white,
              minimumSize: const Size(120, 38),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Receipt sent to system print spooler.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final depositAmount = widget.booking.depositAmount.toInt();

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F6),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Payment',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_horiz, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top 256-bit TLS Encryption Security Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF182C25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock, size: 14, color: Color(0xFFD4A373)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payments protected end-to-end · encrypted in transit & at rest',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            // "Pay with" header
            Text(
              'Pay with',
              style: GoogleFonts.playfairDisplay(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Card / Wallet / Bank 3-way toggle cards
            Row(
              children: [
                _buildMethodSelector(
                  key: 'card',
                  icon: Icons.credit_card,
                  label: 'Card',
                ),
                const SizedBox(width: 12),
                _buildMethodSelector(
                  key: 'wallet',
                  icon: Icons.phone_android,
                  label: 'Wallet',
                ),
                const SizedBox(width: 12),
                _buildMethodSelector(
                  key: 'bank',
                  icon: Icons.account_balance_outlined,
                  label: 'Bank',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Active Payment Account Card with "Change ->" trigger
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedMethod == 'card'
                              ? _cardOption
                              : _selectedMethod == 'wallet'
                                  ? _walletOption
                                  : _bankOption,
                          style: GoogleFonts.playfairDisplay(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedMethod == 'card'
                              ? _cardExpiry
                              : _selectedMethod == 'wallet'
                                  ? _walletSubtitle
                                  : _bankSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: _showChangeMethodModal,
                    child: const Text(
                      'Change →',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFC07040),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // AMOUNT DUE NOW & "Pay securely" button Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AMOUNT DUE NOW',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Rs $depositAmount',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _isProcessing || _isPaymentDone ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF182C25),
                    disabledBackgroundColor:
                        _isPaymentDone ? Colors.grey.shade400 : const Color(0xFF182C25).withOpacity(0.7),
                    minimumSize: const Size(150, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock, size: 15, color: Color(0xFFD4A373)),
                            const SizedBox(width: 6),
                            Text(
                              _isPaymentDone ? 'Paid' : 'Pay securely',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ],
            ),

            // Dynamic Animated Digital Receipt Section
            if (_isPaymentDone) ...[
              const SizedBox(height: 28),
              const Center(
                child: Text(
                  '— after payment —',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Digital receipt',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // White Ticket Card with side circular cutouts and dashed lines
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Top checkmark + Payment Successful header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFF182C25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Payment successful',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$_transactionId · ${DateFormat('MMM dd, h:mm a').format(_paymentTimestamp)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Ticket cutouts and dashed separator line
                    const _DashedTicketDivider(),

                    // Receipt Details Table
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      child: Column(
                        children: [
                          _buildReceiptRow('Service', widget.booking.serviceItem),
                          const SizedBox(height: 8),
                          _buildReceiptRow('Paid via', _getMethodDisplayName()),
                          const SizedBox(height: 8),
                          _buildReceiptRow('Deposit paid', 'Rs $depositAmount'),
                        ],
                      ),
                    ),

                    // Ticket cutouts and dashed separator line
                    const _DashedTicketDivider(),

                    // Share receipt 3 Action Icons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Share receipt',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Row(
                            children: [
                              // SMS / Message Icon
                              _buildActionCircleButton(
                                icon: Icons.mail_outline,
                                tooltip: 'Send SMS',
                                onTap: _sendReceiptViaSms,
                              ),
                              const SizedBox(width: 10),
                              // Call Provider Icon
                              _buildActionCircleButton(
                                icon: Icons.phone_outlined,
                                tooltip: 'Contact Pro',
                                onTap: _callProviderWithReceipt,
                              ),
                              const SizedBox(width: 10),
                              // Print Icon
                              _buildActionCircleButton(
                                icon: Icons.print_outlined,
                                tooltip: 'Print Receipt',
                                onTap: _printReceipt,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // "Done" Full-Width Dark Button
              ElevatedButton(
                onPressed: () {
                  // Direct navigation back to My Bookings or Home screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF182C25),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary simulation button to jump directly to Rating screen
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CompletedJobReviewScreen(booking: widget.booking),
                      ),
                    );
                  },
                  icon: const Icon(Icons.star_outline, size: 16, color: Color(0xFFC07040)),
                  label: const Text(
                    'Simulate Service Completion & Rate Pro →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC07040),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMethodSelector({
    required String key,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _selectedMethod == key;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = key),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF182C25) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? const Color(0xFF182C25) : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFFD4A373) : AppColors.textPrimary,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Custom Dashed Line with ticket cutouts on both left and right edges
class _DashedTicketDivider extends StatelessWidget {
  const _DashedTicketDivider();

  @override
  Widget build(BuildContext context) {
    const double radius = 8.0;
    return SizedBox(
      height: radius * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Dashed line across center
          LayoutBuilder(
            builder: (context, constraints) {
              final boxWidth = constraints.maxWidth;
              const dashWidth = 4.0;
              const dashSpace = 4.0;
              final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(dashCount, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                    color: const Color(0xFFE2E8F0),
                  );
                }),
              );
            },
          ),
          // Left cutout notch circle (matches background screen tone)
          Positioned(
            left: -radius,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F6),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Right cutout notch circle (matches background screen tone)
          Positioned(
            right: -radius,
            child: Container(
              width: radius * 2,
              height: radius * 2,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F6),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
