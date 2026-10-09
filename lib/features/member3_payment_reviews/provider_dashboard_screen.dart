import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../services/app_state_service.dart';
import '../member4_notifications_history/provider_notifications_screen.dart';

/// Representation of an incoming live job request
class LiveJobRequest {
  final String id;
  final String customerName;
  final String serviceCategory;
  final String serviceItem;
  final String distance;
  final String requestedAgo;
  final double price;
  final String avatarInitials;
  final Color avatarColor;
  final String timeSlot;
  final String address;

  LiveJobRequest({
    required this.id,
    required this.customerName,
    required this.serviceCategory,
    required this.serviceItem,
    required this.distance,
    required this.requestedAgo,
    required this.price,
    required this.avatarInitials,
    required this.avatarColor,
    required this.timeSlot,
    required this.address,
  });
}

/// Representation of a confirmed scheduled appointment for today
class ScheduledJob {
  final String id;
  final String time;
  final String customerName;
  final String serviceCategory;
  final String serviceItem;
  final double price;
  final String status;

  ScheduledJob({
    required this.id,
    required this.time,
    required this.customerName,
    required this.serviceCategory,
    required this.serviceItem,
    required this.price,
    this.status = 'Confirmed',
  });
}

/// Member 3 (IT23710610 - Karunathilaka T G C N): Provider Dashboard / Job Requests Screen
/// Requirements & Usability:
/// - FR007: Real-time job requests for providers & live push dispatch
/// - NFR007: Schedule visibility & conflict-free appointment management
/// - Milestone 02 Variant A parity matching Reference UI (Screenshot 4)
/// - CRUD Operations:
///   • Read: Provider live requests & today's schedule
///   • Create/Update: Accept incoming job and move to Today's schedule
///   • Delete: Decline incoming job and dismiss from queue
/// - Availability toggle: Online/Offline real-time status switcher with "Live" indicator
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  bool _isOnline = true;
  int _bottomNavIndex = 0;
  final AppStateService _appState = AppStateService();

  // Active live requests list (Matches Screenshot 4: Nadeesha S. & Ruwan D.)
  final List<LiveJobRequest> _liveRequests = [
    LiveJobRequest(
      id: 'REQ-101',
      customerName: 'Nadeesha S.',
      serviceCategory: 'Cleaning',
      serviceItem: 'Cleaning',
      distance: '2.1 km',
      requestedAgo: 'requested 2 min ago',
      price: 2000.0,
      avatarInitials: 'NS',
      avatarColor: const Color(0xFF1E3A2F), // dark teal
      timeSlot: '2:30 PM - 4:00 PM',
      address: '14/B Flower Road, Colombo 07',
    ),
    LiveJobRequest(
      id: 'REQ-102',
      customerName: 'Ruwan D.',
      serviceCategory: 'Plumbing',
      serviceItem: 'Plumbing',
      distance: '3.4 km',
      requestedAgo: 'requested 5 min ago',
      price: 1800.0,
      avatarInitials: 'RD',
      avatarColor: const Color(0xFF8D6E63), // warm brown
      timeSlot: '5:00 PM - 6:30 PM',
      address: '28 Havelock Road, Colombo 05',
    ),
  ];

  // Today's schedule list (Matches Screenshot 4: Sunil F. & Priya J.)
  final List<ScheduledJob> _todaySchedule = [
    ScheduledJob(
      id: 'SCH-201',
      time: '1:00 PM',
      customerName: 'Sunil F.',
      serviceCategory: 'Electrical',
      serviceItem: 'Electrical',
      price: 2200.0,
      status: 'Confirmed',
    ),
    ScheduledJob(
      id: 'SCH-202',
      time: '4:30 PM',
      customerName: 'Priya J.',
      serviceCategory: 'Cleaning',
      serviceItem: 'Cleaning',
      price: 1600.0,
      status: 'Confirmed',
    ),
  ];

  // CRUD: Accept Incoming Job Request (Create/Update in AppStateService)
  void _acceptJob(LiveJobRequest req) {
    setState(() {
      // Remove from live queue
      _liveRequests.removeWhere((r) => r.id == req.id);

      // Add to Today's schedule
      _todaySchedule.add(
        ScheduledJob(
          id: req.id,
          time: req.timeSlot.split(' - ').first,
          customerName: req.customerName,
          serviceCategory: req.serviceCategory,
          serviceItem: req.serviceItem,
          price: req.price,
          status: 'Confirmed',
        ),
      );
    });

    // CRUD: Register in AppStateService
    final newBooking = _appState.createBooking(
      providerId: 'prov_kamal',
      providerName: 'Kamal Perera',
      customerId: 'user_${req.customerName.replaceAll(' ', '_').toLowerCase()}',
      customerName: req.customerName,
      customerPhone: '077 555 4321',
      serviceCategory: req.serviceCategory,
      serviceItem: req.serviceItem,
      bookingDate: DateTime.now(),
      timeSlot: req.timeSlot,
      totalPrice: req.price,
      depositAmount: (req.price * 0.2).roundToDouble(),
      address: req.address,
      notes: 'Accepted via Provider Dashboard',
    );

    // Update status to confirmed / deposit_paid
    _appState.updateBookingStatus(newBooking.id, 'confirmed');

    // Notify provider
    _appState.createNotification(
      recipientId: 'prov_kamal',
      title: 'Job Accepted: ${req.serviceItem}',
      message:
          'You accepted ${req.customerName}\'s request for ${req.timeSlot}. Moved to Today\'s schedule.',
      type: 'new_request',
      bookingId: newBooking.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Job accepted! ${req.customerName} added to Today\'s schedule.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CRUD: Decline Incoming Job Request (Delete operation in AppStateService)
  void _declineJob(LiveJobRequest req) {
    setState(() {
      _liveRequests.removeWhere((r) => r.id == req.id);
    });

    // Notify provider
    _appState.createNotification(
      recipientId: 'prov_kamal',
      title: 'Job Request Declined',
      message: 'You declined the request from ${req.customerName} (${req.serviceItem}).',
      type: 'new_request',
      bookingId: req.id,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text('Request from ${req.customerName} declined and dismissed.'),
      ),
    );
  }

  void _toggleOnlineStatus() {
    setState(() {
      _isOnline = !_isOnline;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: _isOnline ? AppColors.success : Colors.grey.shade800,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        content: Row(
          children: [
            Icon(
              _isOnline ? Icons.wifi : Icons.wifi_off,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              _isOnline
                  ? 'You are now Online. Live requests appear instantly.'
                  : 'You are now Offline. Incoming requests paused.',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final unreadNotifs = _appState
            .getNotificationsFor('prov_kamal')
            .where((n) => !n.isRead)
            .length;

        return Scaffold(
          backgroundColor: const Color(0xFFF9F9F6),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Navigation Row: Circular Back button + Circular Bell Notification button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildCircularHeaderButton(
                              icon: Icons.arrow_back,
                              onTap: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                }
                              },
                            ),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildCircularHeaderButton(
                                  icon: Icons.notifications_none,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ProviderNotificationsScreen(),
                                      ),
                                    );
                                  },
                                ),
                                if (unreadNotifs > 0)
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: AppColors.error,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          '$unreadNotifs',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // "Hi, Kamal" Title & Online Toggle Pill (Screenshot 4)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Hi, Kamal',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            InkWell(
                              onTap: _toggleOnlineStatus,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF182C25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _isOnline
                                            ? const Color(0xFF4ADE80)
                                            : Colors.grey,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _isOnline ? 'Online' : 'Offline',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Subtitle: "Live — new requests appear instantly"
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _isOnline
                                    ? const Color(0xFFC07040)
                                    : Colors.grey,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isOnline
                                  ? 'Live — new requests appear instantly'
                                  : 'Offline — tap switch above to go live',
                              style: TextStyle(
                                fontSize: 12,
                                color: _isOnline
                                    ? const Color(0xFF6B7280)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // "New requests (X)" Header
                        Text(
                          'New requests (${_liveRequests.length})',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Live Requests Card List
                        if (_liveRequests.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Center(
                              child: Text(
                                'No pending requests at the moment.\nNew customer requests will pop up live here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _liveRequests.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final req = _liveRequests[index];
                              return _buildRequestCard(req);
                            },
                          ),

                        const SizedBox(height: 28),

                        // "Today's schedule" Header
                        Text(
                          "Today's schedule",
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Scheduled Jobs List
                        if (_todaySchedule.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: const Center(
                              child: Text(
                                'No confirmed jobs scheduled for today.',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _todaySchedule.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = _todaySchedule[index];
                              return _buildScheduleCard(item);
                            },
                          ),
                      ],
                    ),
                  ),
                ),

                // Bottom Navigation Bar matching Screenshot 4 (Requests / Bookings / Profile)
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF9F9F6),
                    border: Border(
                      top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildBottomNavItem(
                        index: 0,
                        icon: Icons.grid_view_outlined,
                        activeIcon: Icons.grid_view,
                        label: 'Requests',
                      ),
                      _buildBottomNavItem(
                        index: 1,
                        icon: Icons.calendar_today_outlined,
                        activeIcon: Icons.calendar_today,
                        label: 'Bookings',
                      ),
                      _buildBottomNavItem(
                        index: 2,
                        icon: Icons.person_outline,
                        activeIcon: Icons.person,
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Circular white header button
  Widget _buildCircularHeaderButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: AppColors.textPrimary),
      ),
    );
  }

  // Request Card Widget (Screenshot 4)
  Widget _buildRequestCard(LiveJobRequest req) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar with initials + Name + Distance/Time
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: req.avatarColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    req.avatarInitials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${req.customerName} — ${req.serviceCategory}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${req.distance} · ${req.requestedAgo}',
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

          const SizedBox(height: 14),

          // Price Row
          Text(
            'Rs ${req.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 14),

          // Accept / Decline Buttons (Screenshot 4)
          Row(
            children: [
              // Accept button
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptJob(req),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF182C25),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Decline button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _declineJob(req),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    minimumSize: const Size(0, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Decline',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Schedule Card Widget (Screenshot 4)
  Widget _buildScheduleCard(ScheduledJob item) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
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
                Text(
                  '${item.time} — ${item.customerName}, ${item.serviceCategory}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Confirmed · Rs ${item.price.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'Confirmed',
              style: TextStyle(
                color: Color(0xFF2E7D32),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Bottom Navigation Bar Item (Screenshot 4)
  Widget _buildBottomNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
  }) {
    final isSelected = _bottomNavIndex == index;
    return InkWell(
      onTap: () {
        setState(() => _bottomNavIndex = index);
        if (index == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 1),
              content: Text('Switched to Bookings Schedule view'),
            ),
          );
        } else if (index == 2) {
          _showProfileBottomSheet();
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            size: 22,
            color: isSelected ? const Color(0xFF182C25) : Colors.grey,
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? const Color(0xFF182C25) : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFF182C25),
              child: Text('KP', style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            const SizedBox(height: 10),
            const Text(
              'Kamal Perera',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              'Master Plumber • Colombo & Gampaha',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProfileMetric('Rating', '4.8 ★'),
                _buildProfileMetric('Completed', '212 jobs'),
                _buildProfileMetric('On Time', '98%'),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF182C25),
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMetric(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF182C25))),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
