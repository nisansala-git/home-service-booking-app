import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../services/app_state_service.dart';

/// Member 4 (IT23630802): Provider Notifications & Job Details (Variant B)
/// Requirements: FR007 (Push notifications & job request updates), User Story 6
class ProviderNotificationsScreen extends StatefulWidget {
  const ProviderNotificationsScreen({super.key});

  @override
  State<ProviderNotificationsScreen> createState() => _ProviderNotificationsScreenState();
}

class _ProviderNotificationsScreenState extends State<ProviderNotificationsScreen> {
  final AppStateService _appState = AppStateService();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final notifs = _appState.getNotificationsFor('prov_kamal');

        return Scaffold(
          appBar: const CustomAppBar(title: 'Provider Notifications'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Chronological Notification List (Variant B)
                const Text('Recent Alerts & Job Updates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),

                if (notifs.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: const Center(child: Text('No notifications yet.', style: TextStyle(color: AppColors.textSecondary))),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: notifs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final n = notifs[index];
                      return Dismissible(
                        key: Key(n.id),
                        onDismissed: (_) {
                          _appState.clearNotification(n.id);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification cleared.')));
                        },
                        child: InkWell(
                          onTap: () => _appState.markNotificationAsRead(n.id),
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: n.isRead ? AppColors.surface : const Color(0xFFF1F8F5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: n.isRead ? AppColors.cardBorder : AppColors.primaryLight.withOpacity(0.5),
                                width: n.isRead ? 1 : 1.5,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundColor: n.type == 'new_request'
                                      ? AppColors.primary
                                      : (n.type == 'deposit_received' ? AppColors.warning : AppColors.info),
                                  child: Icon(
                                    n.type == 'deposit_received' ? Icons.monetization_on_outlined : Icons.notifications_active,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        n.title,
                                        style: TextStyle(
                                          fontWeight: n.isRead ? FontWeight.w600 : FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        n.message,
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Featured Job Details Card (Variant B)
                const Text('Active Job Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),

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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Poornima Madubashini', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          StatusBadge(status: 'deposit_paid'),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text('Pipe leak repair • Rs. 2,500 total', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      const Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: AppColors.primary),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text('5 Wallowa ST, Mickleham (1.8 km)', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Job Status Progress Stepper (Variant B)
                      const Text('Job Status Lifecycle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 10),
                      _buildStatusStep('Request Accepted', true),
                      _buildStatusStep('Contract Signed by Customer', true),
                      _buildStatusStep('Deposit Received (Rs. 500 in Escrow)', true),
                      _buildStatusStep('Job in Progress / On-site', false),
                      _buildStatusStep('Customer Final Review & Sign-off', false),

                      const SizedBox(height: 18),

                      // Action Buttons (Variant B: Get Directions / Message Customer)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening Navigation route to 5 Wallowa ST...')),
                                );
                              },
                              icon: const Icon(Icons.navigation_outlined, size: 18),
                              label: const Text('Get Directions', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening direct in-app chat with customer...')),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Message Customer', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusStep(String title, bool isDone) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isDone ? AppColors.success : AppColors.cardBorder,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isDone ? FontWeight.w600 : FontWeight.normal,
              color: isDone ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
