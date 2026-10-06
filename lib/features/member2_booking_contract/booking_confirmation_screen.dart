import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'digital_contract_deposit_screen.dart';
import 'provider_chat_screen.dart';

/// Member 2 (IT23707122): Booking Confirmation Screen (Variant B Advanced)
/// Requirements & Usability Traceability:
/// - FR004: Immediate, automated booking confirmation with visible status
/// - NFR002: Performance — Confirmation returned within seconds
/// - Milestone 02 Section g Fixes:
///   1. "Add an estimated arrival window to the Booking Confirmation screen" (User 01/02 feedback)
///   2. "Add a Message provider action to the Booking Confirmation screen" (User 01/02 feedback)
/// - Milestone 03 CRUD:
///   1. READ: Booking verification pass, barcode, and status
///   2. UPDATE: Reschedule / modify booking appointment details
///   3. DELETE: Cancel booking request
class BookingConfirmationScreen extends StatefulWidget {
  final Booking booking;

  const BookingConfirmationScreen({super.key, required this.booking});

  @override
  State<BookingConfirmationScreen> createState() => _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final AppStateService _appState = AppStateService();

  void _showRescheduleModal(BuildContext context, Booking activeBooking) {
    String selectedSlot = activeBooking.timeSlot;
    final addressCtrl = TextEditingController(text: activeBooking.address);
    final notesCtrl = TextEditingController(text: activeBooking.notes);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            top: 20,
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Modify Booking / Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Time Slot', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: selectedSlot,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
                items: [
                  '08:30 AM - 10:00 AM',
                  '10:00 AM - 11:30 AM',
                  '11:30 AM - 01:00 PM',
                  '01:30 PM - 03:00 PM',
                  '03:00 PM - 04:30 PM',
                  '04:30 PM - 06:00 PM',
                ].map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)))).toList(),
                onChanged: (val) {
                  if (val != null) setModalState(() => selectedSlot = val);
                },
              ),
              const SizedBox(height: 12),
              const Text('Service Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: addressCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Special Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // CRUD: UPDATE Booking Details
                    _appState.updateBookingDetails(
                      bookingId: activeBooking.id,
                      newTimeSlot: selectedSlot,
                      newAddress: addressCtrl.text.trim(),
                      newNotes: notesCtrl.text.trim(),
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking schedule updated successfully!')),
                    );
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Booking activeBooking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? Since the contract is not finalized, no deposit penalty applies.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Keep Booking')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 36),
            ),
            onPressed: () {
              // CRUD: DELETE / Cancel Booking
              _appState.cancelBooking(activeBooking.id);
              final messenger = ScaffoldMessenger.of(context);
              Navigator.of(ctx).pop();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              messenger.showSnackBar(
                const SnackBar(content: Text('Booking has been cancelled.')),
              );
            },
            child: const Text('Cancel Booking', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final currentBookings = _appState.bookings;
        final activeBooking = currentBookings.firstWhere(
          (b) => b.id == widget.booking.id,
          orElse: () => widget.booking,
        );

        final provider = _appState.providers.firstWhere(
          (p) => p.id == activeBooking.providerId,
          orElse: () => _appState.providers.first,
        );

        return Scaffold(
          appBar: const CustomAppBar(title: 'Booking Confirmed'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Success Animated Badge
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F5E9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 54, color: AppColors.success),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Your Booking is Confirmed!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Dispatched to ${activeBooking.providerName} in real time.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),

                const SizedBox(height: 18),

                // Milestone 02 Section g Fix 1: Estimated Arrival Window Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.schedule, color: AppColors.success, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Estimated Arrival Window',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                            ),
                            Text(
                              '${activeBooking.bookingDate.day}/${activeBooking.bookingDate.month}/${activeBooking.bookingDate.year} • ${activeBooking.timeSlot}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                            ),
                            const Text(
                              'Expected job duration: 1.5 – 2.0 hours',
                              style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Milestone 02 Section g Fix 2: Contact Provider Action Shortcuts
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProviderChatScreen(
                                provider: provider,
                                booking: activeBooking,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.primary),
                        label: const Text('Message Provider', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 40),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(color: AppColors.cardBorder),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Calling ${activeBooking.providerName}...')),
                          );
                        },
                        icon: const Icon(Icons.call_outlined, size: 16, color: AppColors.textPrimary),
                        label: const Text('Call Provider', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Ticket-Style Summary Card with Barcode (Milestone 02 Variant B)
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.cardBorder),
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
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    activeBooking.serviceItem,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                ),
                                Text(
                                  'Rs. ${activeBooking.totalPrice.toInt()}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _buildRow('Provider', activeBooking.providerName),
                            _buildRow('Category', activeBooking.serviceCategory.toUpperCase()),
                            _buildRow('Slot', activeBooking.timeSlot),
                            _buildRow('Location', activeBooking.address),
                            _buildRow('Booking ID', activeBooking.id),
                            _buildRow('Required Deposit', 'Rs. ${activeBooking.depositAmount.toInt()} (Held in Escrow)'),
                            if (activeBooking.notes.isNotEmpty)
                              _buildRow('Notes', activeBooking.notes),
                          ],
                        ),
                      ),

                      // Ticket Perforated Line Visual
                      Row(
                        children: [
                          Container(
                            width: 14,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.only(topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                            ),
                          ),
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Flex(
                                  direction: Axis.horizontal,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    (constraints.constrainWidth() / 10).floor(),
                                    (_) => const SizedBox(width: 5, height: 1, child: DecoratedBox(decoration: BoxDecoration(color: Colors.grey))),
                                  ),
                                );
                              },
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                            ),
                          ),
                        ],
                      ),

                      // Simulated Barcode / QR Section
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Digital Verification Pass', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                Text(activeBooking.id, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                              ],
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_calendar_outlined, size: 20, color: AppColors.primary),
                                  tooltip: 'Reschedule',
                                  onPressed: () => _showRescheduleModal(context, activeBooking),
                                ),
                                const Icon(Icons.qr_code_2, size: 36, color: AppColors.textPrimary),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // "What Happens Next" Stepper (Solves Milestone 01 Theme 2: Weak Confirmation Moment)
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
                      const Text('What happens next?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 14),
                      _buildStepperStep('1', 'Booking Confirmed', 'Provider has accepted the requested slot.', true),
                      _buildStepperStep('2', 'Digital Agreement & Deposit', 'Lock upfront price and refundable deposit.', activeBooking.isContractSigned),
                      _buildStepperStep('3', 'Service Delivery & Payment', 'Provider arrives on-site. Remaining released on sign-off.', false),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Main Action Buttons
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DigitalContractDepositScreen(booking: activeBooking),
                      ),
                    );
                  },
                  child: const Text('Proceed to Contract & Deposit'),
                ),
                const SizedBox(height: 10),

                // Secondary Actions: Reschedule & Cancel (CRUD operations)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.textSecondary),
                      onPressed: () => _showRescheduleModal(context, activeBooking),
                      label: const Text('Modify Booking', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    const Text(' • ', style: TextStyle(color: Colors.grey)),
                    TextButton.icon(
                      icon: const Icon(Icons.cancel_outlined, size: 16, color: AppColors.error),
                      onPressed: () => _showCancelDialog(context, activeBooking),
                      label: const Text('Cancel Booking', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperStep(String num, String title, String desc, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: isDone ? AppColors.success : AppColors.surfaceMuted,
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(num, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDone ? AppColors.textPrimary : AppColors.textSecondary)),
                Text(desc, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
