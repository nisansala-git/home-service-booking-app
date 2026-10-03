import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';

/// Member 3 (IT23710610): Completed Job & Review Screen (Variant A)
/// Requirements: FR010 (Rate/review provider after completion), FR005 (Verified review trust signals)
class CompletedJobReviewScreen extends StatefulWidget {
  final Booking booking;

  const CompletedJobReviewScreen({super.key, required this.booking});

  @override
  State<CompletedJobReviewScreen> createState() => _CompletedJobReviewScreenState();
}

class _CompletedJobReviewScreenState extends State<CompletedJobReviewScreen> {
  double _rating = 5.0;
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _availableTags = ['On time', 'Great work', 'Polite', 'Cleaned up', 'Fair price', 'Expert advice'];
  final List<String> _selectedTags = ['On time', 'Great work'];

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() {
    // CRUD: Create Review (FR010)
    AppStateService().submitReview(
      bookingId: widget.booking.id,
      providerId: widget.booking.providerId,
      customerName: widget.booking.customerName,
      rating: _rating,
      comment: _reviewController.text.trim().isEmpty ? 'Work completed professionally.' : _reviewController.text.trim(),
      tags: _selectedTags,
    );

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.verified, color: AppColors.primary),
            SizedBox(width: 8),
            Text('Review Published!'),
          ],
        ),
        content: const Text(
          'Thank you for your verified feedback. Your review helps build transparent quality standards on FixIt Home.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Rate Your Experience'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Job Marked as Completed Checkmark (Variant A)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.task_alt, size: 50, color: AppColors.success),
            ),
            const SizedBox(height: 12),
            const Text(
              'Job Completed!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.booking.serviceItem} by ${widget.booking.providerName}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),

            const SizedBox(height: 24),

            // 5-Star Interactive Rating (Variant A)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  const Text('How would you rate the overall service?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        iconSize: 36,
                        icon: Icon(
                          starValue <= _rating ? Icons.star : Icons.star_border,
                          color: starValue <= _rating ? AppColors.starFilled : AppColors.starEmpty,
                        ),
                        onPressed: () => setState(() => _rating = starValue),
                      );
                    }),
                  ),
                  Text(
                    _getRatingLabel(_rating),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Quick Tag Pills (Milestone 02 Variant A)
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('What went well?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTags.map((tag) {
                final isSelected = _selectedTags.contains(tag);
                return FilterChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: isSelected ? AppColors.primary : AppColors.cardBorder),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedTags.add(tag);
                      } else {
                        _selectedTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // Written Review Box
            Align(
              alignment: Alignment.centerLeft,
              child: const Text('Write a detailed review (optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Share feedback about punctuality, pricing transparency, and workmanship...',
              ),
            ),

            const SizedBox(height: 16),

            // Trust Note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your review is verified and timestamped. It will appear directly on the provider\'s profile.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
              onPressed: _submitReview,
              child: const Text('Submit Verified Review'),
            ),
            const SizedBox(height: 10),

            // Skip for Now Link
            TextButton(
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
              child: const Text('Skip for now', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingLabel(double rating) {
    if (rating >= 5.0) return 'Excellent Service!';
    if (rating >= 4.0) return 'Very Good Service';
    if (rating >= 3.0) return 'Average Service';
    if (rating >= 2.0) return 'Needs Improvement';
    return 'Poor Experience';
  }
}
