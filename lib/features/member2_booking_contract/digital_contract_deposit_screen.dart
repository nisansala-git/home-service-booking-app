import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import '../member3_payment_reviews/secure_payment_receipt_screen.dart';

/// Member 2 (IT23707122): Digital Contract & Deposit Screen (Variant B Advanced)
/// Requirements & Usability Traceability:
/// - FR006: Digital contract + deposit before job starts to protect both parties
/// - Milestone 01 Theme 6 (Carpenter Rajeewa): "Making a good contract before starting the work, and taking a deposit before work starts"
/// - Milestone 02 Section g Fixes:
///   1. "State refundability explicitly next to the deposit amount, not only inside full agreement text" (User 01/02 feedback)
///   2. "Keep condensed Key terms bullets as default view; de-emphasize full-agreement link further" (User 01/02 feedback)
/// - Milestone 03 CRUD:
///   1. UPDATE: Sign & formalize digital contract in state and database
///   2. CREATE: Add custom scope amendment or warranty clause to agreement
///   3. DELETE: Clear and reset signature canvas
class DigitalContractDepositScreen extends StatefulWidget {
  final Booking booking;

  const DigitalContractDepositScreen({super.key, required this.booking});

  @override
  State<DigitalContractDepositScreen> createState() => _DigitalContractDepositScreenState();
}

class _DigitalContractDepositScreenState extends State<DigitalContractDepositScreen> {
  bool _agreedToTerms = false;
  bool _hasSigned = false;
  String? _signedName; // set when Quick Sign is used
  Uint8List? _uploadedSignatureBytes;
  String? _uploadedSignatureName;
  bool _pickingSignature = false;
  final List<Offset?> _points = [];
  final AppStateService _appState = AppStateService();
  final TextEditingController _amendmentController = TextEditingController();

  Future<void> _pickSignatureImage() async {
    if (_pickingSignature) return;
    setState(() => _pickingSignature = true);
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final size = await file.length();
      if (size == null || size <= 0 || size > 5 * 1024 * 1024) {
        throw StateError('Choose a signature image smaller than 5 MB.');
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
        throw StateError('Choose a signature image smaller than 5 MB.');
      }
      if (!mounted) return;
      setState(() {
        _uploadedSignatureBytes = bytes;
        _uploadedSignatureName = file.name;
        _points.clear();
        _signedName = null;
        _hasSigned = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Uploaded signature: ${file.name}')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not upload signature: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _pickingSignature = false);
    }
  }

  @override
  void dispose() {
    _amendmentController.dispose();
    super.dispose();
  }

  void _showAddAmendmentModal() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Scope Amendment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add a specific warranty or task requirement to the formal contract terms:',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amendmentController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. 30-day warranty on pipe seals; disposal of old parts included.',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final text = _amendmentController.text.trim();
              if (text.isNotEmpty) {
                // CRUD: CREATE custom contract scope amendment
                _appState.addCustomScopeTerm(widget.booking.id, text);
                _amendmentController.clear();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Custom clause added to digital contract!')),
                );
              }
            },
            child: const Text('Add Clause'),
          ),
        ],
      ),
    );
  }

  void _showFullLegalAgreement(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollCtrl,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Full Service Agreement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const Divider(),
              const Text(
                'STANDARD FIXIT HOME SERVICE CONTRACT (SRI LANKA)\n\n'
                '1. PARTIES & SCOPE\n'
                'This digital agreement is entered into between the Homeowner and the Service Provider. The Provider agrees to perform the designated task in a workmanlike manner following industry standards.\n\n'
                '2. FIXED PRICING GUARANTEE\n'
                'The agreed price represents the final labor cost. If unseen structural complications occur on-site, the Provider cannot bill additional fees without an in-app change-order signed by the Homeowner.\n\n'
                '3. DEPOSIT & ESCROW HOLD\n'
                'The initial deposit is held in escrow by FixIt Home. It shall not be released directly to the provider until service completion and customer confirmation.\n\n'
                '4. CANCELLATION & REFUNDS\n'
                'Cancellations made 4 or more hours before the booking window are 100% refunded to the customer payment method with no penalty.\n\n'
                '5. DISPUTE RESOLUTION\n'
                'Any dispute regarding workmanship or scope shall be adjudicated via FixIt Home customer support with photo evidence.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _quickSign(String name) {
    // Generate a flowing cursive-style signature from the person's name
    // The strokes simulate a natural flowing cursive signature
    final List<Offset?> strokes = [];
    final double startX = 18.0;
    final double baseY = 80.0;

    // First name initial — tall rising loop
    strokes.addAll([
      Offset(startX, baseY + 10),
      Offset(startX + 4, baseY - 22),
      Offset(startX + 10, baseY + 8),
      Offset(startX + 16, baseY - 8),
      Offset(startX + 22, baseY + 12),
      null,
    ]);

    // Flowing middle body — continuous cursive wave
    double x = startX + 28;
    for (int i = 0; i < 8; i++) {
      final double wave = (i % 2 == 0) ? -14.0 : 6.0;
      strokes.add(Offset(x, baseY + wave));
      x += 16;
    }
    strokes.add(null);

    // Final flourish — underline sweep
    strokes.addAll([
      Offset(startX + 10, baseY + 22),
      Offset(startX + 80, baseY + 22),
      Offset(startX + 120, baseY + 18),
      Offset(startX + 145, baseY + 12),
      null,
    ]);

    setState(() {
      _points.clear();
      _points.addAll(strokes);
      _signedName = name;
      _uploadedSignatureBytes = null;
      _uploadedSignatureName = null;
      _hasSigned = true;
    });
  }

  void _proceedToPayment(Booking activeBooking) {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check the confirmation box to agree to the terms.')),
      );
      return;
    }

    if (!_hasSigned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please draw your signature, upload a signature image, or tap Quick Sign.')),
      );
      return;
    }

    // CRUD: UPDATE sign digital contract and lock deposit in state
    final sigHash = _uploadedSignatureBytes != null
        ? 'SHA256-IMAGE-SIG-${_uploadedSignatureName ?? "VERIFIED"}'
        : 'SHA256-CANVAS-SIG-VALIDATED';
    _appState.signContractAndPayDeposit(activeBooking.id, sigHash);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SecurePaymentReceiptScreen(booking: activeBooking),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final activeBooking = _appState.bookings.firstWhere(
          (b) => b.id == widget.booking.id,
          orElse: () => widget.booking,
        );

        final deposit = activeBooking.depositAmount;
        final remaining = activeBooking.remainingAmount;

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
                const SizedBox(height: 4),
                Text(
                  'Formal agreement between you and ${activeBooking.providerName}.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),

                const SizedBox(height: 18),

                // Milestone 02 Section g Fix 1: Explicit Refundability Guarantee Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified_user, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '100% Refundable Deposit Guarantee',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            Text(
                              'Full instant refund if cancelled up to 4 hours before your slot. Zero cancellation fees.',
                              style: TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Deposit / Remaining Split Bar (Variant B)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Deposit Due Now', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${deposit.toInt()}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                            const Text('Locked in Escrow', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 42, color: AppColors.cardBorder),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text('Remaining After Job', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 2),
                            Text(
                              'Rs. ${remaining.toInt()}',
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Text('Payable on inspection', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.description_outlined, size: 20, color: AppColors.primary),
                              SizedBox(width: 8),
                              Text('Key Agreement Terms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            ],
                          ),
                          TextButton(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            onPressed: () => _showFullLegalAgreement(context),
                            child: const Text('View Full (5 paras)', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildTermItem('1. Scope of Work', 'Agreed for ${activeBooking.serviceItem} at designated address.'),
                      _buildTermItem('2. Upfront Pricing Lock', 'Rs. ${activeBooking.totalPrice.toInt()} fixed rate. Any modifications require mutual in-app signoff.'),
                      _buildTermItem('3. Carpenter Scope Protection (M01 Theme 6)', 'Protects provider from unauthorized mid-job changes & protects customer from sudden price hikes.'),
                      _buildTermItem('4. Escrow Protection', 'Deposit held securely. Final balance released only after customer inspection.'),

                      // Custom amendments dynamically added
                      if (activeBooking.customTerms.isNotEmpty) ...[
                        const Divider(height: 18),
                        const Text('Custom Amendments Added:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        const SizedBox(height: 6),
                        ...activeBooking.customTerms.map((term) => _buildTermItem('• Custom Clause', term)),
                      ],

                      const SizedBox(height: 8),
                      // Action to Add Custom Scope Term (CRUD: CREATE)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 36),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _showAddAmendmentModal,
                          icon: const Icon(Icons.add, size: 14),
                          label: const Text('+ Add Custom Amendment / Warranty', style: TextStyle(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Digital Signature Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Digital Signature', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Row(
                      children: [
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: _pickingSignature
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(strokeWidth: 1.5),
                                )
                              : const Icon(Icons.upload_file, size: 13, color: AppColors.primary),
                          label: const Text('Upload Image', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          onPressed: _pickingSignature ? null : _pickSignatureImage,
                        ),
                        TextButton.icon(
                          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          icon: const Icon(Icons.draw, size: 13, color: AppColors.primary),
                          label: const Text('Quick Sign', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                          onPressed: () => _quickSign(activeBooking.providerName.split(' ').first),
                        ),
                        if (_hasSigned)
                          TextButton.icon(
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                            icon: const Icon(Icons.clear, size: 13, color: AppColors.error),
                            label: const Text('Clear', style: TextStyle(fontSize: 11, color: AppColors.error)),
                            onPressed: () {
                              // CRUD: DELETE / Reset signature
                              setState(() {
                                _points.clear();
                                _signedName = null;
                                _uploadedSignatureBytes = null;
                                _uploadedSignatureName = null;
                                _hasSigned = false;
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Draw with finger/mouse, upload handwritten signature photo, or tap Quick Sign.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),

                // Clean Drawing Canvas / Uploaded Signature Preview
                Container(
                  height: 130,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _hasSigned ? AppColors.primary : AppColors.cardBorder,
                      width: _hasSigned ? 1.5 : 1,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        if (_uploadedSignatureBytes != null)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              child: Image.memory(
                                _uploadedSignatureBytes!,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.description, size: 32, color: AppColors.primary),
                                    const SizedBox(height: 4),
                                    Text(
                                      _uploadedSignatureName ?? 'Signature File',
                                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onPanStart: (DragStartDetails details) {
                              setState(() {
                                _points.add(details.localPosition);
                                _hasSigned = true;
                                _signedName = null;
                                _uploadedSignatureBytes = null;
                                _uploadedSignatureName = null;
                              });
                            },
                            onPanUpdate: (DragUpdateDetails details) {
                              setState(() {
                                _points.add(details.localPosition);
                                _hasSigned = true;
                              });
                            },
                            onPanEnd: (DragEndDetails details) {
                              setState(() {
                                _points.add(null);
                              });
                            },
                            child: CustomPaint(
                              painter: SignaturePainter(points: _points),
                              size: Size.infinite,
                            ),
                          ),
                        if (!_hasSigned)
                          const Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.draw_outlined, size: 18, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(
                                  'Draw your signature here with finger/mouse',
                                  style: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        if (_hasSigned)
                          Positioned(
                            bottom: 6,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _uploadedSignatureBytes != null
                                    ? 'ID: SHA256-IMAGE-SIG'
                                    : 'ID: SHA256-DIGITAL-STAMP',
                                style: const TextStyle(fontSize: 9, color: Colors.grey),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                // Show label when Handwritten Signature was uploaded or Quick Sign was used
                if (_hasSigned && _uploadedSignatureBytes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, size: 13, color: Color(0xFF15803D)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            'Official handwritten signature uploaded (${_uploadedSignatureName ?? "photo"})',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_hasSigned && _signedName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, size: 13, color: Color(0xFF15803D)),
                        const SizedBox(width: 5),
                        const Text(
                          'Digitally signed — signature generated for this session',
                          style: TextStyle(fontSize: 10, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // Terms Checkbox
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreedToTerms,
                  onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I confirm that the service scope and refundable deposit terms are clear and agreed.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),

                const SizedBox(height: 24),

                // Accept & Pay Deposit CTA (hands off to Member 3 Payment Screen)
                ElevatedButton(
                  onPressed: () => _proceedToPayment(activeBooking),
                  child: Text('Sign & Lock Rs. ${deposit.toInt()} Deposit'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF0F172A)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      } else if (points[i] != null && points[i + 1] == null) {
        canvas.drawCircle(points[i]!, 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
