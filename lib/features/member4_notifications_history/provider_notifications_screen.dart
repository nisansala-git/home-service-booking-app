import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';

/// ============================================================================
/// Member 4 (IT23630802 - Musharaf M J M)
/// Screen: Provider Notifications & Job Lifecycle Alerts
/// Assigned Module: Notifications, Job Lifecycle & History
/// Requirements: FR007 (Real-time job requests & alerts), CRUD operations
/// ============================================================================
class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  State<ProviderNotificationsScreen> createState() =>
      _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState
    extends State<ProviderNotificationsScreen> {
  final AppStateService _appState = AppStateService();
  String _selectedFilter = 'All'; // 'All' | 'Unread' | 'Requests' | 'Payments'
  final String _currentProviderId = 'prov_kamal'; // Active demo provider

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final allNotifs = _appState.getNotificationsFor(_currentProviderId);

        // Filter notifications based on chip selection
        final filteredNotifs = allNotifs.where((n) {
          if (_selectedFilter == 'Unread') return !n.isRead;
          if (_selectedFilter == 'Requests') return n.type == 'new_request';
          if (_selectedFilter == 'Payments') {
            return n.type == 'deposit_received' ||
                n.type == 'payment_received';
          }
          return true;
        }).toList();

        final unreadCount = allNotifs.where((n) => !n.isRead).length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: 'Provider Alerts & Inbox',
            showBack: Navigator.canPop(context),
            actions: [
              // Viva helper: Simulate alert (CREATE CRUD demo)
              IconButton(
                tooltip: 'Simulate Incoming Alert (Viva Demo)',
                icon: const Icon(
                  Icons.add_alert_outlined,
                  color: AppColors.primary,
                ),
                onPressed: () => _simulateIncomingJobAlert(context),
              ),
              // Mark all as read / Clear menu
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert,
                  color: AppColors.textPrimary,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                onSelected: (val) {
                  if (val == 'read_all') {
                    for (var n in allNotifs) {
                      if (!n.isRead) _appState.markNotificationAsRead(n.id);
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All alerts marked as read.'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  } else if (val == 'clear_all') {
                    _confirmClearAll(context, allNotifs);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'read_all',
                    child: Row(
                      children: [
                        Icon(Icons.done_all, size: 18, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        Icon(Icons.delete_sweep_outlined,
                            size: 18, color: AppColors.error),
                        SizedBox(width: 8),
                        Text('Clear all alerts'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 600));
              setState(() {});
            },
            child: CustomScrollView(
              slivers: [
                // Top status summary & Filter Chips
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Unread stats header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Activity Log',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                if (unreadCount > 0) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$unreadCount new',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            Text(
                              'Swipe card to dismiss',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Filter Chips
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('All', allNotifs.length),
                              _buildFilterChip('Unread', unreadCount),
                              _buildFilterChip(
                                'Requests',
                                allNotifs
                                    .where((n) => n.type == 'new_request')
                                    .length,
                              ),
                              _buildFilterChip(
                                'Payments',
                                allNotifs
                                    .where((n) =>
                                        n.type == 'deposit_received' ||
                                        n.type == 'payment_received')
                                    .length,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Notification Cards or Empty State
                if (filteredNotifs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(context),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final notif = filteredNotifs[index];
                          return _buildDismissibleNotificationCard(
                              context, notif);
                        },
                        childCount: filteredNotifs.length,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Filter Chip builder
  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text('$label ($count)'),
        labelStyle: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        ),
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        onSelected: (_) => setState(() => _selectedFilter = label),
      ),
    );
  }

  // Dismissible Notification Card (DELETE & UPDATE CRUD operations)
  Widget _buildDismissibleNotificationCard(
      BuildContext context, AppNotification notif) {
    final booking = _findAssociatedBooking(notif.bookingId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(notif.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(Icons.delete_outline, color: Colors.white, size: 24),
              SizedBox(width: 6),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        onDismissed: (direction) {
          // DELETE CRUD Operation
          _appState.clearNotification(notif.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Alert "${notif.title}" removed.'),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: AppColors.accent,
                onPressed: () {
                  // CREATE (Undo)
                  _appState.createNotification(
                    recipientId: notif.recipientId,
                    title: notif.title,
                    message: notif.message,
                    type: notif.type,
                    bookingId: notif.bookingId,
                  );
                },
              ),
            ),
          );
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // UPDATE CRUD: Mark as read
            if (!notif.isRead) {
              _appState.markNotificationAsRead(notif.id);
            }
            // Tap -> Open interactive Job Details bottom sheet
            _openJobDetailsModal(context, notif, booking);
          },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: notif.isRead
                  ? AppColors.surface
                  : const Color(0xFFF1F8F5), // Soft green tint for unread
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notif.isRead
                    ? AppColors.cardBorder
                    : AppColors.primaryLight.withOpacity(0.55),
                width: notif.isRead ? 1 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Semantic Type Icon Avatar
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _getNotificationIconBg(notif.type),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notif.type),
                    size: 20,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontWeight: notif.isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Relative Timestamp
                          Text(
                            _formatRelativeTime(notif.timestamp),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.message,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Associated Job tag + Tap hint
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceMuted,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.receipt_outlined,
                                  size: 11,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  notif.bookingId,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'View Details →',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!notif.isRead) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Interactive Job Details Bottom Sheet (Lifecycle Update CRUD)
  void _openJobDetailsModal(
      BuildContext context, AppNotification notif, Booking? booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            // Re-fetch booking from app state to ensure latest status
            final currentBooking = booking != null
                ? _appState.bookings.firstWhere(
                    (b) => b.id == booking.id,
                    orElse: () => booking,
                  )
                : null;

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Drag Handle
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

                    // Header: Customer name & Status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currentBooking?.customerName ??
                                    'Customer Request',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currentBooking != null
                                    ? '${currentBooking.serviceItem} • ${currentBooking.serviceCategory}'
                                    : notif.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentBooking != null)
                          StatusBadge(status: currentBooking.status),
                      ],
                    ),
                    const Divider(height: 24),

                    // Key job facts
                    if (currentBooking != null) ...[
                      _buildDetailRow(
                        Icons.calendar_today,
                        'Date & Time Slot',
                        '${currentBooking.bookingDate.day}/${currentBooking.bookingDate.month}/${currentBooking.bookingDate.year} (${currentBooking.timeSlot})',
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        Icons.location_on_outlined,
                        'Service Location',
                        currentBooking.address,
                      ),
                      const SizedBox(height: 10),
                      _buildDetailRow(
                        Icons.payments_outlined,
                        'Agreed Total Quote',
                        'Rs. ${currentBooking.totalPrice.toInt()} (Deposit: Rs. ${currentBooking.depositAmount.toInt()})',
                      ),
                      if (currentBooking.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _buildDetailRow(
                          Icons.notes,
                          'Homeowner Notes',
                          currentBooking.notes,
                        ),
                      ],
                      const Divider(height: 24),

                      // Interactive Job Lifecycle Stepper (UPDATE CRUD)
                      const Text(
                        'Job Lifecycle Progress',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),

                      _buildLifecycleStep(
                        '1. Booking Request Accepted',
                        true,
                        isCurrent: currentBooking.status == 'confirmed',
                      ),
                      _buildLifecycleStep(
                        '2. Digital Contract Signed by Homeowner',
                        currentBooking.isContractSigned,
                        isCurrent: false,
                      ),
                      _buildLifecycleStep(
                        '3. Escrow Deposit Secured (Rs. ${currentBooking.depositAmount.toInt()})',
                        currentBooking.status == 'deposit_paid' ||
                            currentBooking.status == 'in_progress' ||
                            currentBooking.status == 'completed',
                        isCurrent: currentBooking.status == 'deposit_paid',
                      ),
                      _buildLifecycleStep(
                        '4. Service In Progress (On-site)',
                        currentBooking.status == 'in_progress' ||
                            currentBooking.status == 'completed',
                        isCurrent: currentBooking.status == 'in_progress',
                      ),
                      _buildLifecycleStep(
                        '5. Job Completed & Verified Sign-off',
                        currentBooking.status == 'completed',
                        isCurrent: currentBooking.status == 'completed',
                      ),

                      const SizedBox(height: 20),

                      // Provider Action Controls to advance lifecycle status
                      if (currentBooking.status == 'deposit_paid')
                        ElevatedButton.icon(
                          onPressed: () {
                            _appState.updateBookingStatus(
                                currentBooking.id, 'in_progress');
                            _appState.createNotification(
                              recipientId: _currentProviderId,
                              title: 'Job Started: ${currentBooking.serviceItem}',
                              message:
                                  'You have initiated work on booking ${currentBooking.id}.',
                              type: 'job_update',
                              bookingId: currentBooking.id,
                            );
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Job status updated to IN PROGRESS.'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text('Start Work (Mark In-Progress)'),
                        )
                      else if (currentBooking.status == 'in_progress')
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.success,
                          ),
                          onPressed: () {
                            _appState.updateBookingStatus(
                                currentBooking.id, 'completed');
                            _appState.createNotification(
                              recipientId: _currentProviderId,
                              title: 'Job Completed: ${currentBooking.serviceItem}',
                              message:
                                  'Work finished for ${currentBooking.customerName}. Payment release pending review.',
                              type: 'job_completed',
                              bookingId: currentBooking.id,
                            );
                            setModalState(() {});
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Job marked as COMPLETED successfully!'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.check_circle_outline,
                              color: Colors.white),
                          label: const Text('Mark Job Completed'),
                        ),
                    ],

                    const SizedBox(height: 12),

                    // Quick Communication Row
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Navigating to ${currentBooking?.address ?? "client address"}...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Directions',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Calling ${currentBooking?.customerPhone ?? "077 123 4567"}...',
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone, size: 18),
                            label: const Text('Call Client',
                                style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLifecycleStep(String title, bool isCompleted,
      {bool isCurrent = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isCompleted
                ? Icons.check_circle
                : (isCurrent
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked),
            size: 18,
            color: isCompleted
                ? AppColors.success
                : (isCurrent ? AppColors.warning : AppColors.cardBorder),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    isCompleted || isCurrent ? FontWeight.w600 : FontWeight.normal,
                color: isCompleted
                    ? AppColors.textPrimary
                    : (isCurrent
                        ? AppColors.warning
                        : AppColors.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Empty State Widget
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Alerts Found',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'You are all caught up! New job requests and payment updates will appear here in real-time.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(200, 44),
              ),
              onPressed: () => _simulateIncomingJobAlert(context),
              icon: const Icon(Icons.add_alert, size: 16),
              label: const Text('Simulate Demo Alert'),
            ),
          ],
        ),
      ),
    );
  }

  // Viva helper: CREATE CRUD Demo
  void _simulateIncomingJobAlert(BuildContext context) {
    final newId =
        'BK-09${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    _appState.createNotification(
      recipientId: _currentProviderId,
      title: 'New Urgent Request from Poornima',
      message: 'Poornima Madubashini requested bathroom tap replacement.',
      type: 'new_request',
      bookingId: newId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.primary,
        content: Text('New alert dispatched to inbox (CREATE CRUD)!'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _confirmClearAll(
      BuildContext context, List<AppNotification> notifications) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text(
          'This will remove all alerts from your provider inbox.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () {
              for (var n in notifications) {
                _appState.clearNotification(n.id);
              }
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All notifications cleared.')),
              );
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  Booking? _findAssociatedBooking(String bookingId) {
    try {
      return _appState.bookings.firstWhere((b) => b.id == bookingId);
    } catch (_) {
      return null;
    }
  }

  Color _getNotificationIconBg(String type) {
    switch (type) {
      case 'new_request':
        return AppColors.primary;
      case 'deposit_received':
      case 'payment_received':
        return AppColors.warning;
      case 'job_completed':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'new_request':
        return Icons.work_outline;
      case 'deposit_received':
      case 'payment_received':
        return Icons.monetization_on_outlined;
      case 'job_completed':
        return Icons.check_circle_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String _formatRelativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
