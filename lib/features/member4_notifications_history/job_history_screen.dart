import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/app_state_service.dart';
import '../member1_discovery_auth/search_results_screen.dart';

/// Member 4 (IT23630802): Job History Screen (Variant B)
/// Requirements: FR005 (Visible work & job history), User 04 Testing Recommendation (Book Again shortcut)
class JobHistoryScreen extends StatefulWidget {
  const JobHistoryScreen({super.key});

  @override
  State<JobHistoryScreen> createState() => _JobHistoryScreenState();
}

class _JobHistoryScreenState extends State<JobHistoryScreen> {
  final AppStateService _appState = AppStateService();
  String _selectedStatusFilter = 'All'; // All | Completed | Cancelled

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        var completedList = _appState.bookings.where((b) {
          if (_selectedStatusFilter == 'Completed') return b.status == 'completed';
          if (_selectedStatusFilter == 'Cancelled') return b.status == 'cancelled';
          return b.status == 'completed' || b.status == 'cancelled';
        }).toList();

        return Column(
          children: [
            // Status Filter Tabs (User 04 Testing Recommendation: "useful to have filters")
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: ['All', 'Completed', 'Cancelled'].map((status) {
                  final isSelected = _selectedStatusFilter == status;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(status),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
                      ),
                      onSelected: (_) => setState(() => _selectedStatusFilter = status),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Job List
            Expanded(
              child: completedList.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history_toggle_off, size: 50, color: Colors.grey.shade400),
                          const SizedBox(height: 10),
                          const Text('No past job records found.', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          const Text('Completed jobs and past receipts will appear here.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: completedList.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final b = completedList[index];
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
                                  Text(b.serviceItem, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  StatusBadge(status: b.status),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text('Provider: ${b.providerName} (${b.serviceCategory})', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.calendar_month, size: 14, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  Text('${b.bookingDate.day}/${b.bookingDate.month}/${b.bookingDate.year}', style: const TextStyle(fontSize: 12)),
                                  const SizedBox(width: 14),
                                  const Icon(Icons.receipt_outlined, size: 14, color: AppColors.textSecondary),
                                  const SizedBox(width: 4),
                                  Text(b.id, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                ],
                              ),
                              const Divider(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Paid: Rs. ${b.totalPrice.toInt()}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                  ),
                                  // User 04 testing recommendation: "Book again" shortcut
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      minimumSize: const Size(110, 34),
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => SearchResultsScreen(
                                            selectedCategory: b.serviceCategory.toLowerCase(),
                                          ),
                                        ),
                                      );
                                    },
                                    icon: const Icon(Icons.repeat, size: 16),
                                    label: const Text('Book Again', style: TextStyle(fontSize: 12)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
