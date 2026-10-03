import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/app_state_service.dart';
import '../member2_booking_contract/digital_contract_deposit_screen.dart';
import '../member3_payment_reviews/completed_job_review_screen.dart';
import 'job_history_screen.dart';

/// Member 4 (IT23630802): My Bookings / Job History (Variant A)
/// Requirements: FR005 (Booking history & tracking), User Story 4
class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AppStateService _appState = AppStateService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
        final activeBookings = _appState.bookings.where((b) => b.status != 'completed' && b.status != 'cancelled').toList();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('My Bookings & History', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            bottom: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(text: 'Active (${activeBookings.length})'),
                const Tab(text: 'Past Job History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              // Tab 1: Active / Upcoming Bookings
              activeBookings.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          const Text('No active bookings right now', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          const Text('Browse home services on the home screen to book a pro.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: activeBookings.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = activeBookings[index];
                        return Container(
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
                                  Text(
                                    b.serviceItem,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  StatusBadge(status: b.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Provider: ${b.providerName} (${b.serviceCategory})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.event, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text('${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year} • ${b.timeSlot}', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(b.address, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), maxLines: 1)),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Agreed', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
                                      Text('Rs. ${b.totalPrice.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary)),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      if (!b.isContractSigned)
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.primary,
                                            minimumSize: const Size(120, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => DigitalContractDepositScreen(booking: b),
                                              ),
                                            );
                                          },
                                          child: const Text('Sign & Pay Deposit', style: TextStyle(fontSize: 12, color: Colors.white)),
                                        )
                                      else
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            minimumSize: const Size(120, 36),
                                            padding: const EdgeInsets.symmetric(horizontal: 12),
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => CompletedJobReviewScreen(booking: b),
                                              ),
                                            );
                                          },
                                          child: const Text('Complete & Rate', style: TextStyle(fontSize: 12, color: Colors.white)),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

              // Tab 2: Completed / Job History View (Variant B)
              const JobHistoryScreen(),
            ],
          ),
        );
      },
    );
  }
}
