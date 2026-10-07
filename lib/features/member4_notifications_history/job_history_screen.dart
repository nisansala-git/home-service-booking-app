import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import '../member1_discovery_auth/search_results_screen.dart';

/// ============================================================================
/// Member 4 (IT23630802 - Musharaf M J M)
/// Screen: Chronological Job History & Verified Work Summary
/// Assigned Module: Notifications, Job Lifecycle & History
/// Requirements: FR005 (Visible work & job history), User 04 Testing Recommendation
/// ============================================================================
class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  final AppStateService _appState = AppStateService();
  String _selectedStatusFilter = 'All'; // 'All' | 'Completed' | 'Cancelled'
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Plumbing',
    'Cleaning',
    'Carpentry',
    'Electrical',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final isProvider = _appState.activeRole == 'provider';

        // Filter chronological past jobs (completed or cancelled)
        final pastJobs = _appState.bookings.where((b) {
          // Perspective filter: if provider, show provider jobs; else show homeowner jobs
          final matchesRole = isProvider
              ? b.providerId == 'prov_kamal'
              : true; // Shows homeowner bookings

          // Status filter
          final matchesStatus = _selectedStatusFilter == 'All'
              ? (b.status == 'completed' || b.status == 'cancelled')
              : b.status == _selectedStatusFilter.toLowerCase();

          // Category filter
          final matchesCategory = _selectedCategory == 'All' ||
              b.serviceCategory.toLowerCase() == _selectedCategory.toLowerCase();

          // Search query
          final matchesQuery = _searchQuery.isEmpty ||
              b.serviceItem.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.providerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              b.id.toLowerCase().contains(_searchQuery.toLowerCase());

          return matchesRole && matchesStatus && matchesCategory && matchesQuery;
        }).toList();

        // Calculate KPI summary figures
        final completedJobsCount =
            pastJobs.where((b) => b.status == 'completed').length;
        final totalAmount = pastJobs
            .where((b) => b.status == 'completed')
            .fold<double>(0.0, (sum, b) => sum + b.totalPrice);

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: CustomAppBar(
            title: isProvider ? 'Provider Job History' : 'Past Service History',
            showBack: Navigator.canPop(context),
            actions: [
              IconButton(
                tooltip: 'Export Statement',
                icon: const Icon(Icons.ios_share, color: AppColors.primary),
                onPressed: () => _exportSummaryDialog(context, pastJobs, totalAmount),
              ),
            ],
          ),
          body: Column(
            children: [
              // Header Summary KPI Metrics Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildKpiItem(
                        'Jobs Archived',
                        '$completedJobsCount',
                        Icons.verified_outlined,
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      _buildKpiItem(
                        isProvider ? 'Total Earned' : 'Total Spent',
                        'Rs. ${totalAmount.toInt()}',
                        Icons.payments_outlined,
                      ),
                      Container(width: 1, height: 32, color: Colors.white24),
                      _buildKpiItem(
                        'Reliability',
                        '99%',
                        Icons.thumb_up_alt_outlined,
                      ),
                    ],
                  ),
                ),
              ),

              // Search Bar & Filter Controls
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: InputDecoration(
                    hintText: 'Search past jobs, service pros, receipt ID...',
                    prefixIcon:
                        const Icon(Icons.search, size: 20, color: AppColors.textSecondary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),

              // Category & Status Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    // Status filters
                    ...['All', 'Completed', 'Cancelled'].map((status) {
                      final isSelected = _selectedStatusFilter == status;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedStatusFilter = status),
                        ),
                      );
                    }),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 24, color: AppColors.cardBorder),
                    const SizedBox(width: 8),

                    // Category filters
                    ..._categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          selectedColor: AppColors.accentLight,
                          backgroundColor: AppColors.surface,
                          labelStyle: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.cardBorder,
                            ),
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // Chronological Job History List
              Expanded(
                child: pastJobs.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: pastJobs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final booking = pastJobs[index];
                          final review = _findReview(booking.id);
                          return _buildHistoryCard(context, booking, review, isProvider);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildKpiItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.accentLight),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // Individual Job History Card
  Widget _buildHistoryCard(
    BuildContext context,
    Booking booking,
    Review? review,
    bool isProvider,
  ) {
    final isCompleted = booking.status == 'completed';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Item name + Status Badge
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
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 4),

          // Role-specific counterparty info
          Text(
            isProvider
                ? 'Client: ${booking.customerName} • ${booking.serviceCategory}'
                : 'Provider: ${booking.providerName} • ${booking.serviceCategory}',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),

          // Date & Receipt ID
          Row(
            children: [
              const Icon(Icons.event, size: 14, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}',
                style: const TextStyle(fontSize: 12),
              ),
              const SizedBox(width: 14),
              const Icon(Icons.receipt_outlined,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                booking.id,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          // Verified Review snippet if available
          if (review != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAF8),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StarRating(rating: review.rating, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        'Verified Review (${review.rating.toStringAsFixed(1)})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${review.comment}"',
                    style: const TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (review.tags.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: review.tags.map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],

          const Divider(height: 20),

          // Bottom Price & Action Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCompleted ? 'Total Paid' : 'Status',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    isCompleted
                        ? 'Rs. ${booking.totalPrice.toInt()}'
                        : 'Cancelled',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isCompleted ? AppColors.primary : AppColors.error,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  // Receipt Dialog
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 34),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                    onPressed: () => _showReceiptModal(context, booking, review),
                    icon: const Icon(Icons.receipt, size: 14),
                    label: const Text('Receipt', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 8),

                  // Rebook button (User 04 HCI recommendation)
                  if (!isProvider && isCompleted)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(100, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SearchResultsScreen(
                              selectedCategory:
                                  booking.serviceCategory.toLowerCase(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.repeat, size: 14),
                      label:
                          const Text('Book Again', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Receipt Modal Dialog
  void _showReceiptModal(
      BuildContext context, Booking booking, Review? review) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified, color: AppColors.success, size: 24),
            const SizedBox(width: 8),
            const Text(
              'Official E-Receipt',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Receipt Reference: ${booking.id}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary)),
            const Divider(height: 16),
            _buildReceiptLine('Service Provided', booking.serviceItem),
            _buildReceiptLine('Category', booking.serviceCategory),
            _buildReceiptLine('Service Provider', booking.providerName),
            _buildReceiptLine('Customer', booking.customerName),
            _buildReceiptLine(
                'Date Fulfilled',
                '${booking.bookingDate.day}/${booking.bookingDate.month}/${booking.bookingDate.year}'),
            const Divider(height: 16),
            _buildReceiptLine(
                'Deposit Paid (Escrow)', 'Rs. ${booking.depositAmount.toInt()}'),
            _buildReceiptLine('Remaining Balance Settled',
                'Rs. ${booking.remainingAmount.toInt()}'),
            const SizedBox(height: 4),
            _buildReceiptLine(
              'Total Amount Paid',
              'Rs. ${booking.totalPrice.toInt()}',
              isBold: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(110, 36),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Receipt for ${booking.id} exported as PDF.'),
                ),
              );
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Save PDF'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptLine(String left, String right, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            left,
            style: TextStyle(
              fontSize: 12,
              color: isBold ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            right,
            style: TextStyle(
              fontSize: 12,
              color: isBold ? AppColors.primary : AppColors.textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _exportSummaryDialog(
      BuildContext context, List<Booking> pastJobs, double totalAmount) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export History & Tax Statement',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Found ${pastJobs.length} records totaling Rs. ${totalAmount.toInt()}. Select your export format below.',
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf, color: AppColors.error),
              title: const Text('Download Annual PDF Report'),
              subtitle: const Text('Itemized with Sri Lankan VAT and escrow breakdown'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Exporting PDF statement...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart, color: AppColors.success),
              title: const Text('Export to CSV / Excel'),
              subtitle: const Text('Raw ledger for personal bookkeeping'),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV downloaded to device storage.')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off, size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No past records found',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            const Text(
              'Adjust your search terms or filter chips above to view past records.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Review? _findReview(String bookingId) {
    try {
      return _appState.reviews.firstWhere((r) => r.bookingId == bookingId);
    } catch (_) {
      return null;
    }
  }
}
