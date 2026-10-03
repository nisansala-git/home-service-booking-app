import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'availability_booking_screen.dart';

/// Member 2 (IT23707122): Provider Profile Screen (Variant A)
/// Requirements: FR003 (Upfront pricing table), FR005 (Verified reviews & past work)
class ProviderProfileScreen extends StatelessWidget {
  final ServiceProvider provider;

  const ProviderProfileScreen({super.key, required this.provider});

  @override
  Widget build(BuildContext context) {
    final reviews = AppStateService().getReviewsForProvider(provider.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Hero Cover with Back Button
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    provider.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Provider Body Details
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: Name, Verification Badge, Category
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  provider.name,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 6),
                                if (provider.isVerified)
                                  const Icon(Icons.verified, color: AppColors.primary, size: 20),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${provider.category.toUpperCase()} • ${provider.distanceKm} km away',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: AppColors.starFilled),
                            const SizedBox(width: 4),
                            Text(
                              provider.rating.toString(),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Trust Badges Row (Milestone 01 Theme 4 Trust signals)
                  Row(
                    children: [
                      _buildTrustPill(Icons.shield_outlined, 'ID Verified'),
                      const SizedBox(width: 8),
                      _buildTrustPill(Icons.health_and_safety_outlined, 'Insured'),
                      const SizedBox(width: 8),
                      _buildTrustPill(Icons.history, '${provider.jobsCompleted} Jobs Done'),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // UPFRONT PRICING TABLE (Variant A - Explicit solution for Homeowner #1 complaint)
                  const Text(
                    'Upfront Fixed Pricing',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Transparent rates guaranteed before booking begins.',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: provider.pricingTable.map((item) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text(item['unit'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                              Text(
                                'Rs. ${(item['price'] as double).toInt()}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // About Section
                  const Text('About Provider', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    provider.about,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                  ),

                  const SizedBox(height: 24),

                  // Past Work Gallery (Evidence from Milestone 01 Theme 4)
                  if (provider.pastWorkImages.isNotEmpty) ...[
                    const Text('Past Work Gallery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: provider.pastWorkImages.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, idx) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              provider.pastWorkImages[idx],
                              width: 120,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Booking History Stats
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceMuted,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCol('${provider.jobsCompleted}', 'Completed'),
                        _buildStatDivider(),
                        _buildStatCol('${provider.onTimePercentage}%', 'On-Time'),
                        _buildStatDivider(),
                        _buildStatCol('${provider.experienceYears} Yrs', 'Experience'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Verified Customer Reviews Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Verified Reviews (${reviews.length})',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                      ),
                      const Row(
                        children: [
                          Icon(Icons.shield, size: 14, color: AppColors.success),
                          SizedBox(width: 4),
                          Text('100% Genuine', style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (reviews.isEmpty)
                    const Text('No reviews submitted yet for this provider.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                  else
                    ...reviews.map((r) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                StarRating(rating: r.rating, size: 14),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.comment, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            if (r.tags.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                children: r.tags.map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceMuted,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(t, style: const TextStyle(fontSize: 10, color: AppColors.textPrimary)),
                                )).toList(),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                  const SizedBox(height: 80), // Padding for sticky bottom footer
                ],
              ),
            ),
          ),
        ],
      ),

      // Sticky Bottom Footer: From Rs X / Check Availability (Variant A)
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
                  const Text('Starting from', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  Text(
                    'Rs. ${provider.startingPrice.toInt()}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AvailabilityBookingScreen(provider: provider),
                      ),
                    );
                  },
                  child: const Text('Check Availability'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildStatCol(String title, String label) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildStatDivider() {
    return Container(width: 1, height: 28, color: AppColors.cardBorder);
  }
}
