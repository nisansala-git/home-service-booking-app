import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';
import 'availability_booking_screen.dart';
import 'provider_chat_screen.dart';

/// Member 2 (IT23707122): Provider Profile Screen (Advanced Variant A + B Hybrid)
/// Requirements & Usability Traceability:
/// - FR003: Upfront pricing table visible immediately on profile
/// - FR005: Verified customer reviews, past work gallery, and accreditation signals
/// - Milestone 02 Variant B: Direct "Message" button to chat with provider before booking
/// - Milestone 03 CRUD:
///   1. READ: Real-time provider data, reviews, and pricing table
///   2. CREATE/DELETE: Bookmark & toggle favorite provider in customer favorites
///   3. UPDATE: Helpful voting on verified reviews
class ProviderProfileScreen extends StatefulWidget {
  final ServiceProvider provider;

  const ProviderProfileScreen({super.key, required this.provider});

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final AppStateService _appState = AppStateService();
  String _selectedReviewFilter = 'All';

  void _showTrustVerificationModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.verified_user, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Verified & Trusted Professional', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Platform background check passed', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildVerifyItem(Icons.badge_outlined, 'Government National ID Verified', 'Verified via Sri Lanka National ID database on 12 Jan 2026.'),
            _buildVerifyItem(Icons.security, 'Criminal Background Check Cleared', 'Police clearance certificate submitted and verified.'),
            _buildVerifyItem(Icons.health_and_safety_outlined, 'Public Liability Insurance Active', 'Covered up to Rs. 500,000 for accidental property damage.'),
            _buildVerifyItem(Icons.handyman_outlined, 'Certified Trade Experience', '${widget.provider.experienceYears}+ years verified field history with 100% genuine reviews.'),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerifyItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showImageDialog(BuildContext context, String imageUrl, int index) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(imageUrl, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
              onPressed: () => Navigator.pop(ctx),
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
        final isFav = _appState.isFavorite(widget.provider.id);
        final allReviews = _appState.getReviewsForProvider(widget.provider.id);

        final filteredReviews = allReviews.where((r) {
          if (_selectedReviewFilter == '5 Star') return r.rating >= 4.8;
          if (_selectedReviewFilter == '4 Star') return r.rating >= 4.0 && r.rating < 4.8;
          return true;
        }).toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              // Hero Cover with Back, Favorite (CRUD), and Share Buttons
              SliverAppBar(
                expandedHeight: 220,
                pinned: true,
                actions: [
                  // CRUD: Bookmark / Favorite Toggle
                  IconButton(
                    icon: CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? AppColors.accent : Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      _appState.toggleFavorite(widget.provider.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 1),
                          content: Text(isFav ? 'Removed from saved favorites' : 'Saved to favorites!'),
                        ),
                      );
                    },
                  ),
                  // Direct Message Shortcut in Header
                  IconButton(
                    icon: const CircleAvatar(
                      backgroundColor: Colors.black45,
                      child: Icon(Icons.chat_bubble_outline, color: Colors.white, size: 18),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderChatScreen(provider: widget.provider),
                        ),
                      );
                    },
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        widget.provider.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: AppColors.primary),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.black.withValues(alpha: 0.65), Colors.transparent, Colors.black.withValues(alpha: 0.4)],
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
                      // Header: Name, Verification Badge, Category, Distance
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        widget.provider.name,
                                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    if (widget.provider.isVerified)
                                      const Icon(Icons.verified, color: AppColors.primary, size: 20),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${widget.provider.category.toUpperCase()} • ${widget.provider.distanceKm} km away',
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
                                  widget.provider.rating.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Interactive Trust Badges Row (Milestone 01 Theme 4 Trust signals)
                      InkWell(
                        onTap: () => _showTrustVerificationModal(context),
                        borderRadius: BorderRadius.circular(10),
                        child: Row(
                          children: [
                            _buildTrustPill(Icons.shield_outlined, 'ID Verified'),
                            const SizedBox(width: 8),
                            _buildTrustPill(Icons.health_and_safety_outlined, 'Insured'),
                            const SizedBox(width: 8),
                            _buildTrustPill(Icons.history, '${widget.provider.jobsCompleted} Jobs Done'),
                            const Spacer(),
                            const Icon(Icons.info_outline, size: 16, color: AppColors.textSecondary),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // UPFRONT PRICING TABLE (Variant A - Explicit solution for Homeowner #1 complaint)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upfront Fixed Pricing',
                                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Transparent rates guaranteed before booking.',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('Price-Lock', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.success)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Column(
                          children: widget.provider.pricingTable.map((item) {
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AvailabilityBookingScreen(
                                      provider: widget.provider,
                                      initialService: item,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: const BoxDecoration(
                                  border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 0.5)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item['item'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                          Text(item['unit'] as String, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          'Rs. ${(item['price'] as double).toInt()}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textSecondary),
                                      ],
                                    ),
                                  ],
                                ),
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
                        widget.provider.about,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13),
                      ),

                      const SizedBox(height: 24),

                      // Past Work Gallery (Evidence from Milestone 01 Theme 4)
                      if (widget.provider.pastWorkImages.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Past Work Gallery', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                            Text('${widget.provider.pastWorkImages.length} photos', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.provider.pastWorkImages.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              return GestureDetector(
                                onTap: () => _showImageDialog(context, widget.provider.pastWorkImages[idx], idx),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    widget.provider.pastWorkImages[idx],
                                    width: 120,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
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
                            _buildStatCol('${widget.provider.jobsCompleted}', 'Completed'),
                            _buildStatDivider(),
                            _buildStatCol('${widget.provider.onTimePercentage}%', 'On-Time'),
                            _buildStatDivider(),
                            _buildStatCol('${widget.provider.experienceYears} Yrs', 'Experience'),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Verified Customer Reviews Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Verified Reviews (${allReviews.length})',
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
                      const SizedBox(height: 10),

                      // Review Filters
                      Row(
                        children: ['All', '5 Star', '4 Star'].map((filter) {
                          final isSelected = _selectedReviewFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.textPrimary)),
                              selected: isSelected,
                              selectedColor: AppColors.primary,
                              onSelected: (_) => setState(() => _selectedReviewFilter = filter),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),

                      if (filteredReviews.isEmpty)
                        const Text('No reviews match this filter.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))
                      else
                        ...filteredReviews.map((r) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
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
                                    Row(
                                      children: [
                                        Text(r.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified, size: 13, color: AppColors.success),
                                      ],
                                    ),
                                    StarRating(rating: r.rating, size: 13),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(r.comment, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3)),
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
                                const SizedBox(height: 8),
                                // CRUD: Helpful Upvote Button (UPDATE review)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        _appState.voteHelpfulReview(r.id);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            duration: Duration(seconds: 1),
                                            content: Text('Marked review as helpful!'),
                                          ),
                                        );
                                      },
                                      child: Row(
                                        children: [
                                          const Icon(Icons.thumb_up_alt_outlined, size: 12, color: AppColors.primary),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Helpful (${r.helpfulVotes})',
                                            style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
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

          // Sticky Bottom Footer: Direct "Message" Button + "Check Availability" (Variant B + A Hybrid)
          bottomSheet: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                        'Rs. ${widget.provider.startingPrice.toInt()}',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const SizedBox(width: 14),
                  // Message Provider Button (Variant B)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      side: const BorderSide(color: AppColors.primary),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProviderChatScreen(provider: widget.provider),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined, size: 16, color: AppColors.primary),
                    label: const Text('Chat', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  // Check Availability CTA (Variant A)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AvailabilityBookingScreen(provider: widget.provider),
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
      },
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
