import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'booking_confirmation_screen.dart';

/// Member 2 (IT23707122): Availability & Booking Screen (Variant B)
/// Requirements: FR003 (Upfront price quote), NFR007 (Conflict prevention & slot locking)
class AvailabilityBookingScreen extends StatefulWidget {
  final ServiceProvider provider;

  const AvailabilityBookingScreen({super.key, required this.provider});

  @override
  State<AvailabilityBookingScreen> createState() => _AvailabilityBookingScreenState();
}

class _AvailabilityBookingScreenState extends State<AvailabilityBookingScreen> {
  late DateTime _selectedDate;
  String _selectedSlot = '10:00 AM - 11:30 AM';
  late Map<String, dynamic> _selectedService;
  final _addressController = TextEditingController(text: '5 Wallowa ST, Mickleham, VIC 3064');
  final _notesController = TextEditingController();

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
    _selectedService = widget.provider.pricingTable.first;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
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
    final newBooking = AppStateService().createBooking(
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

  @override
  Widget build(BuildContext context) {
    final double currentPrice = (_selectedService['price'] as double);
    final double deposit = (currentPrice * 0.2).clamp(300.0, 1000.0);

    return Scaffold(
      appBar: const CustomAppBar(title: 'Select Date & Time'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          Text('Rs. ${(item['price'] as double).toInt()}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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

            // Date Strip (Upcoming 7 Days)
            const Text('Select Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SizedBox(
              height: 75,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final date = DateTime.now().add(Duration(days: i + 1));
                  final isSelected = _selectedDate.day == date.day && _selectedDate.month == date.month;

                  final daysOfWeek = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                  final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

                  return InkWell(
                    onTap: () => setState(() => _selectedDate = date),
                    borderRadius: BorderRadius.circular(12),
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
                            daysOfWeek[date.weekday - 1],
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            months[date.month - 1],
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected ? Colors.white70 : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Morning Time Slots (Variant B Grouping)
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Morning Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _morningSlots.map((slot) => _buildSlotChip(slot)).toList(),
            ),

            const SizedBox(height: 18),

            // Afternoon Time Slots (Variant B Grouping)
            Row(
              children: [
                const Icon(Icons.nights_stay_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Afternoon Slots', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _afternoonSlots.map((slot) => _buildSlotChip(slot)).toList(),
            ),

            const SizedBox(height: 16),

            // NFR007: Real-Time Conflict Handling Note (From Milestone 02 Variant B justification)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFB3E5FC)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_clock_outlined, size: 18, color: Color(0xFF0288D1)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live slot lock active: Your chosen slot is held exclusively for 10 minutes to prevent double-booking.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF01579B)),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Address Input
            const Text('Service Location Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                hintText: 'Enter complete street address',
                prefixIcon: Icon(Icons.home_outlined, color: AppColors.primary),
              ),
            ),

            const SizedBox(height: 14),

            // Additional Notes
            const Text('Job Details & Special Instructions (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Please bring extra piping connectors...',
              ),
            ),

            const SizedBox(height: 85),
          ],
        ),
      ),

      // Sticky Bottom Bar with Service Summary & Book Now Button
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Fixed Quote', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    'Rs. ${currentPrice.toInt()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  Text('Deposit now: Rs. ${deposit.toInt()}', style: const TextStyle(fontSize: 10, color: AppColors.warning, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: _confirmBooking,
                  child: const Text('Book Appointment'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotChip(String slot) {
    final isSelected = _selectedSlot == slot;
    return InkWell(
      onTap: () => setState(() => _selectedSlot = slot),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          slot,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
