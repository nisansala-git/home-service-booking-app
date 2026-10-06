import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'booking_confirmation_screen.dart';

/// Member 2 (IT23707122): Availability & Booking Screen (Variant B Advanced)
/// Requirements & Usability Traceability:
/// - FR003: Provider shows upfront price / quote before booking confirmed
/// - NFR007: Scalability & Concurrency — Prevents double-booking of time slots with real-time lock
/// - Milestone 03 CRUD:
///   1. CREATE: Create new booking request with escrow deposit breakdown
///   2. UPDATE: Reserve and lock selected time slot in real-time with countdown timer
class AvailabilityBookingScreen extends StatefulWidget {
  final ServiceProvider provider;
  final Map<String, dynamic>? initialService;

  const AvailabilityBookingScreen({
    super.key,
    required this.provider,
    this.initialService,
  });

  @override
  State<AvailabilityBookingScreen> createState() => _AvailabilityBookingScreenState();
}

class _AvailabilityBookingScreenState extends State<AvailabilityBookingScreen> {
  late DateTime _selectedDate;
  late String _selectedSlot;
  late Map<String, dynamic> _selectedService;
  final _addressController = TextEditingController(text: '5 Wallowa ST, Mickleham, VIC 3064');
  final _notesController = TextEditingController();
  final AppStateService _appState = AppStateService();

  // NFR007: Concurrency & Slot Reservation Hold Timer
  Timer? _countdownTimer;
  int _secondsRemaining = 600; // 10 minutes lock

  final List<String> _morningSlots = [
    '08:30 AM - 10:00 AM',
    '10:00 AM - 11:30 AM',
    '11:30 AM - 01:00 PM',
  ];

  final List<String> _afternoonSlots = [
    '01:30 PM - 03:00 PM',
    '03:00 PM - 04:30 PM',
    '04:30 PM - 06:00 PM',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _selectedSlot = '10:00 AM - 11:30 AM';
    _selectedService = widget.initialService ?? widget.provider.pricingTable.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _lockCurrentSlot();
      }
    });
    _startHoldTimer();
  }

  void _startHoldTimer() {
    _countdownTimer?.cancel();
    _secondsRemaining = 600;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  void _lockCurrentSlot() {
    final slotKey = '${_selectedDate.year}-${_selectedDate.month}-${_selectedDate.day}_$_selectedSlot';
    _appState.lockSlot(slotKey);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _onSlotSelected(String slot) {
    setState(() {
      _selectedSlot = slot;
      _secondsRemaining = 600; // reset 10m lock
    });
    _lockCurrentSlot();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 1),
        content: Text('Reserved $slot for 10 minutes.'),
      ),
    );
  }

  void _confirmBooking() {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter service address.')),
      );
      return;
    }

    final double price = (_selectedService['price'] as double);
    final double deposit = (price * 0.2).clamp(300.0, 1000.0); // 20% deposit

    // CRUD: Create Booking (FR004)
    final newBooking = _appState.createBooking(
      providerId: widget.provider.id,
      providerName: widget.provider.name,
      customerId: 'user_poornima',
      customerName: 'Poornima Madubashini',
      customerPhone: '077 123 4567',
      serviceCategory: widget.provider.category,
      serviceItem: _selectedService['item'] as String,
      bookingDate: _selectedDate,
      timeSlot: _selectedSlot,
      totalPrice: price,
      depositAmount: deposit,
      address: _addressController.text.trim(),
      notes: _notesController.text.trim(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingConfirmationScreen(booking: newBooking),
      ),
    );
  }

  String _formatTimer(int totalSeconds) {
    final m = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final double currentPrice = (_selectedService['price'] as double);
    final double deposit = (currentPrice * 0.2).clamp(300.0, 1000.0);
    final double balance = currentPrice - deposit;

    final dates = List.generate(7, (i) => DateTime.now().add(Duration(days: i + 1)));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Select Date & Time'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider Mini Card Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(widget.provider.imageUrl),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        Text('${widget.provider.category.toUpperCase()} • Rating ${widget.provider.rating} ★', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Instant Book', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // NFR007: Slot Conflict Lock Countdown Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Soft blue security banner
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_clock, size: 20, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Slot Reserved Against Double-Booking (NFR007)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                        ),
                        Text(
                          'Holding this slot for ${_formatTimer(_secondsRemaining)} to complete booking.',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF1E40AF)),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatTimer(_secondsRemaining),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1D4ED8)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Select Service Type Dropdown
            const Text('Selected Service Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Map<String, dynamic>>(
                  isExpanded: true,
                  value: _selectedService,
                  items: widget.provider.pricingTable.map((item) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: item,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis),
                          ),
                          Text('Rs. ${(item['price'] as double).toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedService = val);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Date Selection Strip (Mon-Sun)
            const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: dates.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, idx) {
                  final d = dates[idx];
                  final isSelected = d.day == _selectedDate.day && d.month == _selectedDate.month;
                  final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final dayName = dayNames[d.weekday - 1];

                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = d);
                      _lockCurrentSlot();
                    },
                    child: Container(
                      width: 58,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            dayName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${d.day}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Time Slots (Morning vs Afternoon Grouping - Milestone 02 Variant B)
            const Text('Available Time Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),

            const Text('MORNING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 6),
            ..._morningSlots.map((slot) => _buildSlotCard(slot, 'High demand')),

            const SizedBox(height: 12),
            const Text('AFTERNOON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary, letterSpacing: 1)),
            const SizedBox(height: 6),
            ..._afternoonSlots.map((slot) => _buildSlotCard(slot, 'Available')),

            const SizedBox(height: 20),

            // Service Address Input
            const Text('Service Location Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                hintText: 'Enter your address',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
            ),

            const SizedBox(height: 16),

            // Special Notes / Defect Details
            const Text('Job Notes & Instructions (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'e.g. Main tap is leaking under the basin; parking on driveway',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 24),

            // Transparent Upfront Cost Breakdown Card (Solves M01 Theme 1)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text('Upfront Cost Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildCostRow('Total Service Fee (Fixed)', 'Rs. ${currentPrice.toInt()}'),
                  _buildCostRow('Escrow Deposit Due (20%)', 'Rs. ${deposit.toInt()}', isHighlighted: true),
                  _buildCostRow('Balance on Job Completion', 'Rs. ${balance.toInt()}'),
                  const Divider(height: 16),
                  const Row(
                    children: [
                      Icon(Icons.check_circle_outline, size: 14, color: AppColors.success),
                      SizedBox(width: 6),
                      Text('100% Refundable if cancelled 4+ hrs ahead', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Confirm Booking CTA
            ElevatedButton(
              onPressed: _confirmBooking,
              child: Text('Confirm Booking (Deposit: Rs. ${deposit.toInt()})'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotCard(String slot, String badge) {
    final isSelected = _selectedSlot == slot;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _onSlotSelected(slot),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.cardBorder,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 18,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    slot,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accent : AppColors.surfaceMuted,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: isHighlighted ? AppColors.primary : AppColors.textSecondary, fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isHighlighted ? AppColors.primary : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
