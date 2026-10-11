import 'dart:io' show Platform, File, Directory;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'completed_job_review_screen.dart';

/// Member 3 (IT23710610 - Karunathilaka T G C N): Secure Payment & Receipt Screen
/// Requirements & Usability:
/// - FR009: Secure in-app payment with digital receipt
/// - NFR004: Payment data encrypted in transit & at rest (256-bit TLS)
/// - Typeable Card Number (4 auto-advancing segmented boxes) without forced saved selections
/// - Full interactive input forms for Card, Wallet, and Bank with comprehensive form validation
/// - Genuine PDF download directly to the laptop's Downloads directory (Web and Desktop)
/// - "Done" button navigates directly to CompletedJobReviewScreen (Job reviews page)
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

  // --- CARD FORM CONTROLLERS & FOCUS NODES ---
  final TextEditingController _cardHolderController =
      TextEditingController(text: 'Poornima Maligaspe');
  final TextEditingController _cardPart1 =
      TextEditingController(text: '4417');
  final TextEditingController _cardPart2 =
      TextEditingController(text: '1254');
  final TextEditingController _cardPart3 =
      TextEditingController(text: '3340');
  final TextEditingController _cardPart4 =
      TextEditingController(text: '1092');
  final TextEditingController _cvvController =
      TextEditingController(text: '417');

  final FocusNode _cardHolderFocus = FocusNode();
  final FocusNode _focus1 = FocusNode();
  final FocusNode _focus2 = FocusNode();
  final FocusNode _focus3 = FocusNode();
  final FocusNode _focus4 = FocusNode();
  final FocusNode _cvvFocus = FocusNode();

  String _selectedCardType = 'VISA'; // 'VISA' | 'MasterCard'
  String _cardExpiryMonth = '08';
  String _cardExpiryYear = '2028';
  bool _saveCardForFuture = true;

  // --- WALLET FORM CONTROLLERS ---
  String _walletProvider = 'FriMi'; // 'FriMi' | 'Genie' | 'eZ Cash' | 'mCash'
  final TextEditingController _walletHolderController =
      TextEditingController(text: 'Poornima Maligaspe');
  final TextEditingController _walletPhoneController =
      TextEditingController(text: '0771234567');
  final TextEditingController _walletPinController =
      TextEditingController(text: '9102');
  bool _saveWalletForFuture = true;

  // --- BANK FORM CONTROLLERS ---
  String _selectedBankName = 'Commercial Bank of Ceylon';
  final TextEditingController _bankHolderController =
      TextEditingController(text: 'Poornima Maligaspe');
  final TextEditingController _bankAccountController =
      TextEditingController(text: '801044297741');
  final TextEditingController _bankBranchController =
      TextEditingController(text: 'Colombo Fort Branch (001)');
  bool _saveBankForFuture = true;

  // --- FORM VALIDATION ERRORS ---
  String? _cardHolderError;
  String? _cardNumberError;
  String? _cvvError;
  String? _walletHolderError;
  String? _walletPhoneError;
  String? _walletPinError;
  String? _bankHolderError;
  String? _bankAccountError;
  String? _bankBranchError;

  // --- PROMO CODE / VOUCHER STATE ---
  final TextEditingController _promoController = TextEditingController();
  int _appliedDiscount = 0;
  String? _appliedPromoCode;
  String? _promoMessage;
  bool _isPromoValid = false;

  // --- PAYMENT TRANSACTION STATE ---
  bool _isProcessing = false;
  bool _isPaymentDone = false;
  bool _isGeneratingPdf = false;
  String _transactionId = 'TXN-80101';
  late DateTime _paymentTimestamp;

  @override
  void initState() {
    super.initState();
    _paymentTimestamp = DateTime.now();
  }

  @override
  void dispose() {
    _cardHolderController.dispose();
    _cardPart1.dispose();
    _cardPart2.dispose();
    _cardPart3.dispose();
    _cardPart4.dispose();
    _cvvController.dispose();

    _cardHolderFocus.dispose();
    _focus1.dispose();
    _focus2.dispose();
    _focus3.dispose();
    _focus4.dispose();
    _cvvFocus.dispose();

    _walletHolderController.dispose();
    _walletPhoneController.dispose();
    _walletPinController.dispose();
    _bankHolderController.dispose();
    _bankAccountController.dispose();
    _bankBranchController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // Calculate net payable amount taking promo discount into account
  int get _netDepositAmount {
    final base = widget.booking.depositAmount.toInt();
    final net = base - _appliedDiscount;
    return net > 0 ? net : 50; // minimum deposit of Rs 50
  }

  // --- FORM VALIDATION LOGIC ---
  bool _validateForm() {
    bool isValid = true;
    setState(() {
      _cardHolderError = null;
      _cardNumberError = null;
      _cvvError = null;
      _walletHolderError = null;
      _walletPhoneError = null;
      _walletPinError = null;
      _bankHolderError = null;
      _bankAccountError = null;
      _bankBranchError = null;

      if (_selectedMethod == 'card') {
        // Cardholder name validation
        final name = _cardHolderController.text.trim();
        if (name.isEmpty) {
          _cardHolderError =
              'Cardholder name is required (කාඩ්පත් හිමියාගේ නම ඇතුළත් කරන්න)';
          isValid = false;
        } else if (name.length < 3) {
          _cardHolderError = 'Name must be at least 3 characters long';
          isValid = false;
        }

        // Card number validation (all 4 segmented boxes must have 4 digits)
        final p1 = _cardPart1.text.trim();
        final p2 = _cardPart2.text.trim();
        final p3 = _cardPart3.text.trim();
        final p4 = _cardPart4.text.trim();
        if (p1.length != 4 || p2.length != 4 || p3.length != 4 || p4.length != 4) {
          _cardNumberError =
              'Please enter all 16 digits (ඉලක්කම් 16 ම ඇතුළත් කරන්න)';
          isValid = false;
        }

        // CVV validation
        final cvv = _cvvController.text.trim();
        if (cvv.length != 3) {
          _cvvError = 'CVV must be 3 digits (ඉලක්කම් 3 ක CVV ඇතුළත් කරන්න)';
          isValid = false;
        }
      } else if (_selectedMethod == 'wallet') {
        // Wallet holder name validation
        final name = _walletHolderController.text.trim();
        if (name.isEmpty) {
          _walletHolderError = 'Account name is required (නම ඇතුළත් කරන්න)';
          isValid = false;
        }

        // Phone validation (10 digits starting with 07)
        final phone = _walletPhoneController.text.replaceAll(' ', '').trim();
        final phoneReg = RegExp(r'^07\d{8}$');
        if (phone.isEmpty || !phoneReg.hasMatch(phone)) {
          _walletPhoneError =
              'Enter a valid 10-digit mobile number starting with 07 (උදා: 0771234567)';
          isValid = false;
        }

        // PIN validation
        final pin = _walletPinController.text.trim();
        if (pin.length < 4) {
          _walletPinError = 'PIN must be at least 4 digits (ඉලක්කම් 4 ක PIN)';
          isValid = false;
        }
      } else if (_selectedMethod == 'bank') {
        // Bank account holder validation
        final name = _bankHolderController.text.trim();
        if (name.isEmpty) {
          _bankHolderError = 'Account holder name is required (නම ඇතුළත් කරන්න)';
          isValid = false;
        }

        // Bank account number validation (8-16 digits)
        final acc = _bankAccountController.text.trim();
        if (acc.length < 8 || acc.length > 18) {
          _bankAccountError =
              'Enter valid account number (8-18 digits) / වලංගු ගිණුම් අංකය';
          isValid = false;
        }

        // Branch validation
        final branch = _bankBranchController.text.trim();
        if (branch.isEmpty) {
          _bankBranchError = 'Branch name is required (ශාඛාවේ නම ඇතුළත් කරන්න)';
          isValid = false;
        }
      }
    });

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Please fill in all required payment details correctly (කරුණාකර වැරදි නිවැරදි කරන්න).',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return isValid;
  }

  void _applyPromoCode() {
    final code = _promoController.text.trim().toUpperCase();
    if (code == 'FIXIT50' || code == 'DISCOUNT50' || code == 'SAVE50') {
      setState(() {
        _appliedDiscount = 50;
        _appliedPromoCode = code;
        _isPromoValid = true;
        _promoMessage = 'Promo applied: Rs. 50 discount deducted from deposit!';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Promo code applied successfully! Saved Rs. 50.'),
            ],
          ),
        ),
      );
    } else if (code.isEmpty) {
      setState(() {
        _promoMessage = 'Please enter a promo code (Try: FIXIT50)';
        _isPromoValid = false;
      });
    } else {
      setState(() {
        _promoMessage = 'Invalid promo code. Try "FIXIT50" for Rs. 50 off.';
        _isPromoValid = false;
      });
    }
  }

  void _processPayment() async {
    // Run validation first!
    if (!_validateForm()) return;

    setState(() => _isProcessing = true);

    // Simulate 256-bit TLS secure gateway network authorization
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    // Generate unique transaction ID
    final txn =
        'TXN-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    // Update state via AppStateService (CRUD operation: update booking & trigger notification)
    AppStateService().updateBookingStatus(widget.booking.id, 'deposit_paid');
    AppStateService().createNotification(
      recipientId: widget.booking.providerId,
      title: 'Deposit Received (Rs. $_netDepositAmount)',
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
        final phone = _walletPhoneController.text.trim();
        final last4 =
            phone.length >= 4 ? phone.substring(phone.length - 4) : '9102';
        return '$_walletProvider • • • • $last4';
      case 'bank':
        final acc = _bankAccountController.text.trim();
        final last4 = acc.length >= 4 ? acc.substring(acc.length - 4) : '7741';
        final bankShort = _selectedBankName.split(' ').first;
        return '$bankShort Bank • • • • $last4';
      case 'card':
      default:
        final last4 = _cardPart4.text.trim().isNotEmpty
            ? _cardPart4.text.trim()
            : '1092';
        return '$_selectedCardType • • • • $last4';
    }
  }

  // --- GENUINE PDF GENERATION & LAPTOP DOWNLOAD ---
  Future<Uint8List> _generatePdfReceiptBytes() async {
    final pdf = pw.Document();

    final dateFormatted =
        DateFormat('yyyy-MM-dd HH:mm').format(_paymentTimestamp);
    final custName = widget.booking.customerName.isNotEmpty
        ? widget.booking.customerName
        : 'Poornima Maligaspe';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FIXIT HOME (PVT) LTD',
                        style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#182C25'),
                        ),
                      ),
                      pw.SizedBox(height: 3),
                      pw.Text(
                        'Official Escrow Digital Receipt & Tax Invoice',
                        style: const pw.TextStyle(
                            fontSize: 11, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        'Tax Reg # VAT-2024-99810-LK | Central Bank LankaPay Regulated',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey600),
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#E8F5E9'),
                      borderRadius:
                          const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('#2E7D32'), width: 1.5),
                    ),
                    child: pw.Text(
                      'PAID - ESCROW HOLD',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#2E7D32'),
                      ),
                    ),
                  ),
                ],
              ),
              pw.Divider(thickness: 1, height: 24),

              // Transaction Overview Table
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Transaction ID:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                        pw.Text(_transactionId,
                            style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#182C25'))),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Booking Reference:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                        pw.Text('#${widget.booking.id}',
                            style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#182C25'))),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Payment Date:',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey600)),
                        pw.Text(dateFormatted,
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#182C25'))),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 18),

              // Customer & Provider Information
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CUSTOMER DETAILS',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#182C25'))),
                        pw.SizedBox(height: 4),
                        pw.Text('Name: $custName',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                            'Phone: ${widget.booking.customerPhone.isNotEmpty ? widget.booking.customerPhone : "077 123 4567"}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text('Escrow Role: Verified Homeowner',
                            style: const pw.TextStyle(
                                fontSize: 9, color: PdfColors.grey700)),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('SERVICE PROVIDER',
                            style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColor.fromHex('#182C25'))),
                        pw.SizedBox(height: 4),
                        pw.Text('Provider: ${widget.booking.providerName}',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                            'Service: ${widget.booking.serviceItem} (${widget.booking.serviceCategory})',
                            style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                            'Appointment: ${DateFormat('yyyy-MM-dd').format(widget.booking.bookingDate)} at ${widget.booking.timeSlot}',
                            style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 24),

              // Itemized Bill Table
              pw.Text('PAYMENT BREAKDOWN',
                  style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#182C25'))),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(
                    color: PdfColor.fromHex('#E2E8F0'), width: 1),
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F1F5F9')),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Description',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Payment Method',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Amount (LKR)',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              'Total Estimated Service Fee (${widget.booking.serviceItem})',
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Estimate Quotation',
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              'Rs. ${(widget.booking.depositAmount * 5).toInt()}',
                              textAlign: pw.TextAlign.right,
                              style: const pw.TextStyle(fontSize: 9))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              'Advance Escrow Deposit (15% Upfront)',
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(_getMethodDisplayName(),
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                              'Rs. ${widget.booking.depositAmount.toInt()}',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  if (_appliedDiscount > 0)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text(
                                'Promotional Voucher Discount ($_appliedPromoCode)',
                                style: const pw.TextStyle(
                                    fontSize: 9, color: PdfColors.green800))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('Applied',
                                style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(
                            padding: const pw.EdgeInsets.all(6),
                            child: pw.Text('-Rs. $_appliedDiscount',
                                textAlign: pw.TextAlign.right,
                                style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.green800))),
                      ],
                    ),
                  pw.TableRow(
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('Escrow Shield Guarantee Fee',
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('FixIt Waiver',
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text('FREE',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontSize: 9,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green800))),
                    ],
                  ),
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#F8FAFC')),
                    children: [
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('TOTAL PAID (ESCROW SECURED)',
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 10,
                                  color: PdfColor.fromHex('#182C25')))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Status: Confirmed',
                              style: const pw.TextStyle(fontSize: 9))),
                      pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Rs. $_netDepositAmount',
                              textAlign: pw.TextAlign.right,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 12,
                                  color: PdfColor.fromHex('#182C25')))),
                    ],
                  ),
                ],
              ),

              pw.SizedBox(height: 20),

              // Security & Escrow Protection Notice
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#FEF3C7'),
                  borderRadius:
                      const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: PdfColor.fromHex('#FDE68A')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('FixIt 100% Escrow Shield Protection Guarantee:',
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#92400E'))),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'This advance payment is securely held in trust. Funds will only be disbursed to the service provider after the job is completed and signed off by the homeowner.',
                      style: const pw.TextStyle(
                          fontSize: 8.5, color: PdfColors.grey800),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Footer with Digital Seal
              pw.Divider(thickness: 1),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'FixIt Home Support: help@fixithome.lk | +94 11 754 4801\nGenerated automatically via FixIt Escrow Payments',
                    style: const pw.TextStyle(
                        fontSize: 8, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'AUTHENTIC DIGITAL TAX RECEIPT\nVerified by Central Bank LankaPay',
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#182C25')),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _downloadPdfReceiptDirectlyToLaptop() async {
    setState(() => _isGeneratingPdf = true);

    try {
      final pdfBytes = await _generatePdfReceiptBytes();
      final filename = 'FixIt_Receipt_$_transactionId.pdf';
      String? localSavedPath;

      // 1. On Windows Desktop: Save directly to the user's Downloads folder
      if (!kIsWeb) {
        try {
          final userProfile = Platform.environment['USERPROFILE'] ??
              Platform.environment['HOME'] ??
              '';
          if (userProfile.isNotEmpty) {
            final downloadsDir = Directory('$userProfile\\Downloads');
            if (downloadsDir.existsSync()) {
              final targetFile = File('${downloadsDir.path}\\$filename');
              await targetFile.writeAsBytes(pdfBytes);
              localSavedPath = targetFile.path;
            }
          }
        } catch (e) {
          debugPrint('[PDF Save to Disk Error] $e');
        }
      }

      // 2. Trigger browser download on Web / system download dialog
      await Printing.sharePdf(bytes: pdfBytes, filename: filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    localSavedPath != null
                        ? 'PDF downloaded directly to your laptop Downloads folder: $filename'
                        : 'PDF receipt downloaded: $filename',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[PDF Generation Error] $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Could not download PDF: $e'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  // --- SHARE RECEIPT: EMAIL RECEIPT DIALOG ---
  void _sendReceiptViaEmail() {
    final custEmail =
        widget.booking.customerName.toLowerCase().replaceAll(' ', '.');
    final emailController = TextEditingController(
      text: '${custEmail.isNotEmpty ? custEmail : "poornima.m"}@gmail.com',
    );
    bool isSending = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Row(
            children: [
              Icon(Icons.email_outlined, color: Color(0xFF182C25)),
              SizedBox(width: 8),
              Text('Email Digital Receipt', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'An official PDF receipt and tax invoice will be sent to your email address:',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Recipient Email',
                  prefixIcon: const Icon(Icons.mail, size: 18),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Subject: FixIt Home Payment Receipt - $_transactionId',
                        style: const TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(
                      '• Service: ${widget.booking.serviceItem}\n'
                      '• Amount Paid: Rs. $_netDepositAmount (Escrow Hold)\n'
                      '• Date: ${DateFormat('yyyy-MM-dd HH:mm').format(_paymentTimestamp)}\n'
                      '• Provider: ${widget.booking.providerName}',
                      style: const TextStyle(
                          fontSize: 11, height: 1.4, color: AppColors.textSecondary),
                    ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: isSending
                  ? null
                  : () async {
                      setModalState(() => isSending = true);
                      await Future.delayed(const Duration(milliseconds: 700));
                      if (context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.success,
                            content: Text(
                              'Official PDF receipt sent to ${emailController.text}!',
                            ),
                          ),
                        );
                      }
                    },
              icon: isSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(isSending ? 'Sending...' : 'Send Receipt'),
            ),
          ],
        ),
      ),
    );
  }

  // --- SHARE RECEIPT: SMS RECEIPT DIALOG ---
  void _sendReceiptViaSms() {
    final deposit = _netDepositAmount;
    final phone = widget.booking.customerPhone.isNotEmpty
        ? widget.booking.customerPhone
        : '077 123 4567';
    final smsBody =
        'FixIt Home Receipt: ${widget.booking.serviceItem} (Ref: ${widget.booking.id}). Deposit of Rs. $deposit paid via ${_getMethodDisplayName()}. Transaction ID: $_transactionId on ${DateFormat('MMM dd, yyyy h:mm a').format(_paymentTimestamp)}. Verified in Escrow.';

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
              'A copy of this digital receipt will be sent to $phone:',
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
                style: const TextStyle(
                    fontSize: 11, height: 1.4, color: AppColors.textPrimary),
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('SMS receipt dispatched successfully to $phone.'),
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

  @override
  Widget build(BuildContext context) {
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
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
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

            const SizedBox(height: 16),

            // --- BOOKING / SERVICE SUMMARY CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.handyman_outlined,
                                  size: 18, color: Color(0xFF182C25)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.booking.serviceItem,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Provider: ${widget.booking.providerName}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 12, color: Color(0xFFD97706)),
                            SizedBox(width: 3),
                            Text(
                              '4.9',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            DateFormat('MMM dd, yyyy')
                                .format(widget.booking.bookingDate),
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 13, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text(
                            widget.booking.timeSlot,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      Text(
                        'Ref: #${widget.booking.id}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

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
                const SizedBox(width: 10),
                _buildMethodSelector(
                  key: 'wallet',
                  icon: Icons.phone_android,
                  label: 'Wallet',
                ),
                const SizedBox(width: 10),
                _buildMethodSelector(
                  key: 'bank',
                  icon: Icons.account_balance_outlined,
                  label: 'Bank',
                ),
              ],
            ),

            const SizedBox(height: 18),

            // --- DETAILED PAYMENT METHOD ENTRY CONTAINER ---
            // Render specific interactive form based on selected tab
            if (_selectedMethod == 'card')
              _buildCardDetailsForm()
            else if (_selectedMethod == 'wallet')
              _buildWalletDetailsForm()
            else
              _buildBankDetailsForm(),

            const SizedBox(height: 18),

            // --- PROMO CODE / VOUCHER REDEMPTION FIELD ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_offer_outlined,
                          size: 16, color: Color(0xFFC07040)),
                      const SizedBox(width: 8),
                      const Text(
                        'Promo Code / Voucher',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (_appliedDiscount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '-Rs 50 APPLIED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 38,
                          child: TextField(
                            controller: _promoController,
                            textCapitalization: TextCapitalization.characters,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Enter code (e.g. FIXIT50)',
                              hintStyle: const TextStyle(
                                  fontSize: 12, color: Color(0xFF9CA3AF)),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFD1D5DB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _applyPromoCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF182C25),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          minimumSize: const Size(60, 38),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Apply',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  if (_promoMessage != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _promoMessage!,
                      style: TextStyle(
                        fontSize: 11,
                        color: _isPromoValid
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 18),

            // --- PRICE BREAKDOWN SUMMARY CARD ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildPriceRow(
                      'Service Estimate',
                      'Rs ${(widget.booking.depositAmount * 5).toInt()}'),
                  const SizedBox(height: 6),
                  _buildPriceRow(
                      'Advance Escrow Deposit (15%)',
                      'Rs ${widget.booking.depositAmount.toInt()}'),
                  if (_appliedDiscount > 0) ...[
                    const SizedBox(height: 6),
                    _buildPriceRow(
                      'Promo Discount ($_appliedPromoCode)',
                      '-Rs $_appliedDiscount',
                      isHighlight: true,
                    ),
                  ],
                  const SizedBox(height: 6),
                  _buildPriceRow('FixIt Escrow Shield Protection', 'FREE',
                      isFree: true),
                  const Divider(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Payable Now',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Rs $_netDepositAmount',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF182C25),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                    Row(
                      children: [
                        Text(
                          'Rs $_netDepositAmount',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_appliedDiscount > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            'Rs ${widget.booking.depositAmount.toInt()}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF9CA3AF),
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed:
                      _isProcessing || _isPaymentDone ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF182C25),
                    disabledBackgroundColor: _isPaymentDone
                        ? Colors.grey.shade400
                        : const Color(0xFF182C25).withValues(alpha: 0.7),
                    minimumSize: const Size(140, 48),
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
                            const Icon(Icons.lock,
                                size: 15, color: Color(0xFFD4A373)),
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
                      color: Colors.black.withValues(alpha: 0.04),
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
                            child: const Icon(Icons.check,
                                size: 20, color: Colors.white),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
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
                          ),
                        ],
                      ),
                    ),

                    // Ticket cutouts and dashed separator line
                    const _DashedTicketDivider(),

                    // Receipt Details Table
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      child: Column(
                        children: [
                          _buildReceiptRow(
                              'Service', widget.booking.serviceItem),
                          const SizedBox(height: 8),
                          _buildReceiptRow('Paid via', _getMethodDisplayName()),
                          const SizedBox(height: 8),
                          _buildReceiptRow(
                              'Deposit paid', 'Rs $_netDepositAmount'),
                        ],
                      ),
                    ),

                    // Ticket cutouts and dashed separator line
                    const _DashedTicketDivider(),

                    // Share receipt 3 Action Icons (Email, SMS, PDF Download)
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
                              // Email Receipt Icon
                              _buildActionCircleButton(
                                icon: Icons.mail_outline,
                                tooltip: 'Email Receipt',
                                onTap: _sendReceiptViaEmail,
                              ),
                              const SizedBox(width: 10),
                              // SMS / Message Icon
                              _buildActionCircleButton(
                                icon: Icons.phone_outlined,
                                tooltip: 'SMS Receipt',
                                onTap: _sendReceiptViaSms,
                              ),
                              const SizedBox(width: 10),
                              // Print / Genuine PDF Download Icon directly to Laptop!
                              _buildActionCircleButton(
                                icon: _isGeneratingPdf
                                    ? Icons.hourglass_top
                                    : Icons.download_outlined,
                                tooltip: 'Download PDF to Laptop',
                                onTap: _isGeneratingPdf
                                    ? () {}
                                    : _downloadPdfReceiptDirectlyToLaptop,
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
              // USER REQUIREMENT: Navigates directly to CompletedJobReviewScreen (Job reviews page), NOT to home!
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CompletedJobReviewScreen(booking: widget.booking),
                    ),
                  );
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
                  icon: const Icon(Icons.star_outline,
                      size: 16, color: Color(0xFFC07040)),
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

  // --- 1. CARD DETAILS FORM (Purely Typeable, Auto-Advancing Segments, Full Validation) ---
  Widget _buildCardDetailsForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _cardNumberError != null || _cardHolderError != null
              ? AppColors.error
              : const Color(0xFFD1D5DB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar matching Screenshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.credit_card, size: 20, color: Color(0xFF4B5563)),
                    SizedBox(width: 8),
                    Text(
                      'Credit or Debit Card',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ],
                ),
                // Helper clear / sample quick fill action
                InkWell(
                  onTap: () {
                    setState(() {
                      if (_cardPart1.text.isNotEmpty) {
                        _cardPart1.clear();
                        _cardPart2.clear();
                        _cardPart3.clear();
                        _cardPart4.clear();
                        _cardHolderController.clear();
                        _cvvController.clear();
                      } else {
                        _cardPart1.text = '4417';
                        _cardPart2.text = '1254';
                        _cardPart3.text = '3340';
                        _cardPart4.text = '1092';
                        _cardHolderController.text = 'Poornima Maligaspe';
                        _cvvController.text = '417';
                      }
                      _cardNumberError = null;
                      _cardHolderError = null;
                      _cvvError = null;
                    });
                  },
                  child: Text(
                    _cardPart1.text.isNotEmpty ? 'Clear' : 'Sample',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFC07040),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cardholder Name
                _buildFieldLabel('Cardholder Name'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _cardHolderController,
                    focusNode: _cardHolderFocus,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_cardHolderError != null) {
                        setState(() => _cardHolderError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'Name appears on your card',
                      hintStyle: const TextStyle(
                          fontSize: 12, color: Color(0xFF9CA3AF)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _cardHolderError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _cardHolderError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_cardHolderError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _cardHolderError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],

                const SizedBox(height: 14),

                // Card Number with 4 segmented boxes (Typeable with auto-advance)
                _buildFieldLabel('Card Number'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _buildSegmentedCardBox(
                        controller: _cardPart1,
                        focusNode: _focus1,
                        nextFocus: _focus2,
                        prevFocus: null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSegmentedCardBox(
                        controller: _cardPart2,
                        focusNode: _focus2,
                        nextFocus: _focus3,
                        prevFocus: _focus1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSegmentedCardBox(
                        controller: _cardPart3,
                        focusNode: _focus3,
                        nextFocus: _focus4,
                        prevFocus: _focus2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _buildSegmentedCardBox(
                        controller: _cardPart4,
                        focusNode: _focus4,
                        nextFocus: _cvvFocus,
                        prevFocus: _focus3,
                      ),
                    ),
                  ],
                ),
                if (_cardNumberError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _cardNumberError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],

                const SizedBox(height: 14),

                // Card Types (VISA & MasterCard badges)
                _buildFieldLabel('Card Types'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildCardBrandBadge(
                      brand: 'VISA',
                      isSelected: _selectedCardType == 'VISA',
                      onTap: () => setState(() => _selectedCardType = 'VISA'),
                    ),
                    const SizedBox(width: 10),
                    _buildCardBrandBadge(
                      brand: 'MasterCard',
                      isSelected: _selectedCardType == 'MasterCard',
                      onTap: () =>
                          setState(() => _selectedCardType = 'MasterCard'),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Expiration Date (MM / YYYY) dropdowns
                _buildFieldLabel('Expiration Date'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _cardExpiryMonth,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            items: List.generate(12, (index) {
                              final m = (index + 1).toString().padLeft(2, '0');
                              return DropdownMenuItem(value: m, child: Text(m));
                            }),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _cardExpiryMonth = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('/',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9CA3AF))),
                    ),
                    Expanded(
                      child: Container(
                        height: 40,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _cardExpiryYear,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, size: 20),
                            style: const TextStyle(
                                fontSize: 13, color: AppColors.textPrimary),
                            items: ['2025', '2026', '2027', '2028', '2029', '2030']
                                .map((y) => DropdownMenuItem(
                                    value: y, child: Text(y)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _cardExpiryYear = val);
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // CVV (Typeable with 3 digits)
                _buildFieldLabel('CVV'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SizedBox(
                      width: 120,
                      height: 40,
                      child: TextField(
                        controller: _cvvController,
                        focusNode: _cvvFocus,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        maxLength: 3,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        style: const TextStyle(fontSize: 13),
                        onChanged: (_) {
                          if (_cvvError != null) {
                            setState(() => _cvvError = null);
                          }
                        },
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '•••',
                          hintStyle: const TextStyle(
                              fontSize: 14,
                              letterSpacing: 2,
                              color: Color(0xFF9CA3AF)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: _cvvError != null
                                  ? AppColors.error
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: _cvvError != null
                                  ? AppColors.error
                                  : const Color(0xFFD1D5DB),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message:
                          'CVV is the 3-digit security code printed on the back of your card.',
                      child: IconButton(
                        icon: const Icon(Icons.help_outline,
                            size: 18, color: Color(0xFF6B7280)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                              title: const Row(
                                children: [
                                  Icon(Icons.security,
                                      color: Color(0xFF182C25)),
                                  SizedBox(width: 8),
                                  Text('What is CVV?',
                                      style: TextStyle(fontSize: 16)),
                                ],
                              ),
                              content: const Text(
                                'Card Verification Value (CVV2) is a 3-digit security code on the signature strip of Visa and MasterCard cards. It helps protect you against online card fraud.',
                                style: TextStyle(
                                    fontSize: 13,
                                    height: 1.4,
                                    color: AppColors.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Got it'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                if (_cvvError != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _cvvError!,
                    style: const TextStyle(fontSize: 11, color: AppColors.error),
                  ),
                ],

                const SizedBox(height: 14),

                // Trust Badges
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shield, size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text(
                            'Mastercard\nSecureCode',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.verified,
                              size: 14, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 4),
                          Text(
                            'Verified by\nVISA',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.lock, size: 14, color: Color(0xFFD97706)),
                          SizedBox(width: 4),
                          Text(
                            'Secured by\nthawte',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                height: 1.1,
                                color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Checkbox
                InkWell(
                  onTap: () {
                    setState(
                        () => _saveCardForFuture = !_saveCardForFuture);
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _saveCardForFuture,
                        activeColor: const Color(0xFF182C25),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() =>
                              _saveCardForFuture = val ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'I agree to have my payment details securely saved for future purchases',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 2. WALLET DETAILS FORM (With Validation) ---
  Widget _buildWalletDetailsForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _walletPhoneError != null || _walletHolderError != null
              ? AppColors.error
              : const Color(0xFFD1D5DB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.phone_android, size: 20, color: Color(0xFF4B5563)),
                SizedBox(width: 8),
                Text(
                  'Digital Wallet (LankaQR / Mobile Cash)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Select Wallet Provider'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['FriMi', 'Genie', 'eZ Cash', 'mCash'].map((p) {
                    final isSel = _walletProvider == p;
                    return ChoiceChip(
                      label: Text(p),
                      selected: isSel,
                      selectedColor: const Color(0xFF182C25),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSel ? Colors.white : AppColors.textPrimary,
                      ),
                      backgroundColor: const Color(0xFFF3F4F6),
                      onSelected: (val) {
                        if (val) setState(() => _walletProvider = p);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('Account Holder Name'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _walletHolderController,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_walletHolderError != null) {
                        setState(() => _walletHolderError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Poornima Maligaspe',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _walletHolderError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _walletHolderError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_walletHolderError != null) ...[
                  const SizedBox(height: 4),
                  Text(_walletHolderError!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.error)),
                ],
                const SizedBox(height: 14),
                _buildFieldLabel('Registered Mobile Number (10 Digits)'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _walletPhoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_walletPhoneError != null) {
                        setState(() => _walletPhoneError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '0771234567',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _walletPhoneError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _walletPhoneError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_walletPhoneError != null) ...[
                  const SizedBox(height: 4),
                  Text(_walletPhoneError!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.error)),
                ],
                const SizedBox(height: 14),
                _buildFieldLabel('Wallet PIN / One-Touch Authorization'),
                const SizedBox(height: 6),
                SizedBox(
                  width: 140,
                  height: 42,
                  child: TextField(
                    controller: _walletPinController,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_walletPinError != null) {
                        setState(() => _walletPinError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: '••••',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _walletPinError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _walletPinError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_walletPinError != null) ...[
                  const SizedBox(height: 4),
                  Text(_walletPinError!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.error)),
                ],
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.qr_code, size: 16, color: Color(0xFF182C25)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LankaQR Certified · Regulated by Central Bank of Sri Lanka',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(
                        () => _saveWalletForFuture = !_saveWalletForFuture);
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _saveWalletForFuture,
                        activeColor: const Color(0xFF182C25),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() =>
                              _saveWalletForFuture = val ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Save wallet details for fast 1-tap booking checkouts',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 3. BANK DETAILS FORM (With Validation) ---
  Widget _buildBankDetailsForm() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _bankAccountError != null || _bankHolderError != null
              ? AppColors.error
              : const Color(0xFFD1D5DB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB)),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.account_balance,
                    size: 20, color: Color(0xFF4B5563)),
                SizedBox(width: 8),
                Text(
                  'Direct Bank Transfer (LankaPay CEFT / SLIPS)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFieldLabel('Select Bank'),
                const SizedBox(height: 6),
                Container(
                  height: 42,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBankName,
                      isExpanded: true,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textPrimary),
                      items: [
                        'Commercial Bank of Ceylon',
                        'Hatton National Bank (HNB)',
                        'Sampath Bank',
                        'Bank of Ceylon (BOC)',
                        'Nations Trust Bank',
                      ].map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBankName = val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _buildFieldLabel('Account Holder Name'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _bankHolderController,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_bankHolderError != null) {
                        setState(() => _bankHolderError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Poornima Maligaspe',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _bankHolderError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _bankHolderError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_bankHolderError != null) ...[
                  const SizedBox(height: 4),
                  Text(_bankHolderError!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.error)),
                ],
                const SizedBox(height: 14),
                _buildFieldLabel('Account Number'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _bankAccountController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_bankAccountError != null) {
                        setState(() => _bankAccountError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. 801044297741',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _bankAccountError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _bankAccountError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_bankAccountError != null) ...[
                  const SizedBox(height: 4),
                  Text(_bankAccountError!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.error)),
                ],
                const SizedBox(height: 14),
                _buildFieldLabel('Branch Name / Code'),
                const SizedBox(height: 6),
                SizedBox(
                  height: 42,
                  child: TextField(
                    controller: _bankBranchController,
                    style: const TextStyle(fontSize: 13),
                    onChanged: (_) {
                      if (_bankBranchError != null) {
                        setState(() => _bankBranchError = null);
                      }
                    },
                    decoration: InputDecoration(
                      hintText: 'e.g. Colombo Fort Branch (001)',
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _bankBranchError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                          color: _bankBranchError != null
                              ? AppColors.error
                              : const Color(0xFFD1D5DB),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_bankBranchError != null) ...[
                  const SizedBox(height: 4),
                  Text(_bankBranchError!,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.error)),
                ],
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.flash_on, size: 16, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'LankaPay CEFTS Real-time Clearing · Instant Escrow Hold',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF374151)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    setState(
                        () => _saveBankForFuture = !_saveBankForFuture);
                  },
                  child: Row(
                    children: [
                      Checkbox(
                        value: _saveBankForFuture,
                        activeColor: const Color(0xFF182C25),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onChanged: (val) {
                          setState(() =>
                              _saveBankForFuture = val ?? false);
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Authorize direct debit mandate for secure escrow settlement',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- SUB-WIDGET HELPERS ---
  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Color(0xFF374151),
      ),
    );
  }

  Widget _buildSegmentedCardBox({
    required TextEditingController controller,
    required FocusNode focusNode,
    required FocusNode? nextFocus,
    required FocusNode? prevFocus,
  }) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: _cardNumberError != null
              ? AppColors.error
              : const Color(0xFFD1D5DB),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
        ),
        onChanged: (value) {
          if (_cardNumberError != null) {
            setState(() => _cardNumberError = null);
          }
          if (value.length == 4 && nextFocus != null) {
            nextFocus.requestFocus();
          } else if (value.isEmpty && prevFocus != null) {
            prevFocus.requestFocus();
          }
        },
        decoration: const InputDecoration(
          counterText: '',
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildCardBrandBadge({
    required String brand,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF1F5F9) : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? const Color(0xFF182C25) : const Color(0xFFD1D5DB),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              brand == 'VISA' ? Icons.payment : Icons.credit_card,
              size: 16,
              color: brand == 'VISA'
                  ? const Color(0xFF1D4ED8)
                  : const Color(0xFFDC2626),
            ),
            const SizedBox(width: 6),
            Text(
              brand,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFF182C25) : const Color(0xFF4B5563),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value,
      {bool isHighlight = false, bool isFree = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isHighlight
                ? const Color(0xFF16A34A)
                : AppColors.textSecondary,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isFree
                ? const Color(0xFF16A34A)
                : isHighlight
                    ? const Color(0xFF16A34A)
                    : AppColors.textPrimary,
          ),
        ),
      ],
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
              color:
                  isSelected ? const Color(0xFF182C25) : const Color(0xFFE5E7EB),
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
