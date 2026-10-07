import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import '../member1_discovery_auth/search_results_screen.dart';
import '../member2_booking_contract/digital_contract_deposit_screen.dart';
import '../member3_payment_reviews/completed_job_review_screen.dart';

/// ============================================================================
/// Member 4 (IT23630802 - Musharaf M J M)
/// Screen: My Bookings & Full Job Lifecycle Tracker
/// Assigned Module: Notifications, Job Lifecycle & History
/// Requirements: FR005 (Booking history & tracking), User Story 4
/// ============================================================================
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppStateService _appState = AppStateService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final allBookings = _appState.bookings;

        // Categorize bookings for tabs
        final upcomingBookings = allBookings
            .where((b) => b.status == 'confirmed' || b.status == 'deposit_paid')
            .toList();

        final ongoingBookings =
            allBookings.where((b) => b.status == 'in_progress').toList();

        final completedBookings =
            allBookings.where((b) => b.status == 'completed').toList();

        final cancelledBookings =
            allBookings.where((b) => b.status == 'cancelled').toList();

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            elevation: 0,
            backgroundColor: AppColors.background,
            title: const Text(
              'My Service Bookings',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Upcoming (${upcomingBookings.length})'),
                Tab(text: 'Ongoing (${ongoingBookings.length})'),
                Tab(text: 'Completed (${completedBookings.length})'),
                Tab(text: 'Cancelled (${cancelledBookings.length})'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildBookingList(
                upcomingBookings,
                emptyTitle: 'No upcoming appointments',
                emptySubtitle:
                    'Need help around the house? Search qualified pros on FixIt Home.',
                tabType: 'upcoming',
              ),
              _buildBookingList(
                ongoingBookings,
                emptyTitle: 'No jobs in progress',
                emptySubtitle:
                    'Active services currently being carried out by technicians will show here.',
                tabType: 'ongoing',
              ),
              _buildBookingList(
                completedBookings,
                emptyTitle: 'No completed jobs yet',
                emptySubtitle:
                    'Finished service receipts and verified reviews will be archived here.',
                tabType: 'completed',
              ),
              _buildBookingList(
                cancelledBookings,
                emptyTitle: 'No cancelled bookings',
                emptySubtitle: 'Cancelled service inquiries will appear here.',
                tabType: 'cancelled',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBookingList(
    List<Booking> bookings, {
    required String emptyTitle,
    required String emptySubtitle,
    required String tabType,
  }) {
    if (bookings.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: AppColors.surfaceMuted,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.event_note_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                emptyTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                emptySubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 40),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchResultsScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Find a Service Pro'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _buildBookingCard(context, booking, tabType);
      },
    );
  }

  // Booking Card Widget
  Widget _buildBookingCard(
      BuildContext context, Booking booking, String tabType) {
    final provider = _findProvider(booking.providerId);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _openBookingLifecycleTimeline(context, booking),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Service Item & Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    booking.serviceItem,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 10),

            // Provider Info Row
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.accentLight,
                  backgroundImage: provider != null &&
                          provider.imageUrl.isNotEmpty
                      ? NetworkImage(provider.imageUrl)
                      : null,
                  child: provider == null || provider.imageUrl.isEmpty
                      ? const Icon(Icons.person,
                          size: 20, color: AppColors.primary)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.providerName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${booking.serviceCategory} • Ref: ${booking.id}',
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
            const SizedBox(height: 12),

            // Date & Location Info
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.event_available,
                          size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year} • ${booking.timeSlot}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          booking.address,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 20),

            // Pricing & Contextual Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Agreed Total',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Rs. ${booking.totalPrice.toInt()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                _buildActionButtons(context, booking),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Contextual Actions based on Booking Lifecycle Status
  Widget _buildActionButtons(BuildContext context, Booking booking) {
    if (booking.status == 'confirmed' && !booking.isContractSigned) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(130, 36),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DigitalContractDepositScreen(booking: booking),
            ),
          );
        },
        child: const Text(
          'Sign & Deposit',
          style: TextStyle(fontSize: 12, color: Colors.white),
        ),
      );
    }

    if (booking.status == 'deposit_paid' || booking.status == 'in_progress') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(80, 36),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () => _confirmCancelBooking(context, booking),
            child: const Text('Cancel', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            onPressed: () => _openBookingLifecycleTimeline(context, booking),
            child: const Text('Track Pro', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    if (booking.status == 'completed') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(95, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchResultsScreen(
                    selectedCategory: booking.serviceCategory.toLowerCase(),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.repeat, size: 14),
            label: const Text('Rebook', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              minimumSize: const Size(95, 36),
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompletedJobReviewScreen(booking: booking),
                ),
              );
            },
            icon: const Icon(Icons.star, size: 14, color: Colors.white),
            label: const Text('Review', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }

    // Cancelled status
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(110, 36),
      ),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SearchResultsScreen(
              selectedCategory: booking.serviceCategory.toLowerCase(),
            ),
          ),
        );
      },
      icon: const Icon(Icons.search, size: 14),
      label: const Text('Find Pro', style: TextStyle(fontSize: 12)),
    );
  }

  // Full Lifecycle Modal Timeline
  void _openBookingLifecycleTimeline(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(22),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.cardBorder,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.serviceItem,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Provider: ${booking.providerName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  StatusBadge(status: booking.status),
                ],
              ),
              const Divider(height: 24),

              const Text(
                'Job Lifecycle Progress',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 14),

              _buildStepItem(
                '1. Booking Placed',
                'Appointment requested for ${booking.timeSlot}',
                isDone: true,
              ),
              _buildStepItem(
                '2. Digital Contract Signed',
                booking.isContractSigned
                    ? 'Agreed to fixed quote and terms'
                    : 'Pending homeowner signature',
                isDone: booking.isContractSigned,
              ),
              _buildStepItem(
                '3. Escrow Deposit Secured',
                booking.status != 'confirmed' && booking.status != 'cancelled'
                    ? 'Rs. ${booking.depositAmount.toInt()} held safely in escrow'
                    : 'Awaiting deposit payment',
                isDone: booking.status == 'deposit_paid' ||
                    booking.status == 'in_progress' ||
                    booking.status == 'completed',
              ),
              _buildStepItem(
                '4. Service In Progress',
                booking.status == 'in_progress' ||
                        booking.status == 'completed'
                    ? 'Technician active on-site'
                    : 'Scheduled for arrival',
                isDone: booking.status == 'in_progress' ||
                    booking.status == 'completed',
              ),
              _buildStepItem(
                '5. Job Completed & Verified',
                booking.status == 'completed'
                    ? 'Work signed-off and escrow payment released'
                    : 'Pending inspection after completion',
                isDone: booking.status == 'completed',
                isLast: true,
              ),

              const SizedBox(height: 20),

              if (booking.status != 'completed' && booking.status != 'cancelled')
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _confirmCancelBooking(context, booking);
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Cancel This Booking'),
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStepItem(String title, String subtitle,
      {required bool isDone, bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Icon(
              isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 20,
              color: isDone ? AppColors.success : AppColors.cardBorder,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 26,
                color: isDone
                    ? AppColors.success.withOpacity(0.5)
                    : AppColors.cardBorder,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
                  color: isDone
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  // Soft Delete / Cancellation Flow (DELETE & UPDATE CRUD)
  void _confirmCancelBooking(BuildContext context, Booking booking) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Booking?'),
        content: Text(
          'Are you sure you want to cancel ${booking.serviceItem} with ${booking.providerName}? Any paid escrow deposit will be refunded per cancellation policy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              minimumSize: const Size(100, 38),
            ),
            onPressed: () {
              // UPDATE / SOFT-DELETE CRUD
              _appState.cancelBooking(booking.id);
              // Dispatch notification to provider
              _appState.createNotification(
                recipientId: booking.providerId,
                title: 'Booking Cancelled',
                message:
                    '${booking.customerName} cancelled booking ${booking.id} (${booking.serviceItem}).',
                type: 'job_cancelled',
                bookingId: booking.id,
              );
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Booking has been cancelled.')),
              );
            },
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );
  }

  ServiceProvider? _findProvider(String providerId) {
    try {
      return _appState.providers.firstWhere((p) => p.id == providerId);
    } catch (_) {
      return null;
    }
  }
}
