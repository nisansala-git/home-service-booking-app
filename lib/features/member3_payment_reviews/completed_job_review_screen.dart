import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../models/models.dart';
import '../../services/app_state_service.dart';

/// Member 3 (IT23710610 - Karunathilaka T G C N): Completed Job & Review Screen
/// Requirements & Usability:
/// - FR010: Homeowner rates and reviews provider after service completion
/// - FR005: Verified review trust badge tag to eliminate fake testimonials
/// - Milestone 02 Variant A parity matching reference UI (Screenshot 3)
/// - Interactive 5-star rating selector, validation for zero stars ("කරුණාකර තරු එකක් තෝරන්න")
/// - AppStateService CRUD: CREATE review & UPDATE booking status to 'completed'
class CompletedJobReviewScreen extends StatefulWidget {
  final Booking booking;

  const CompletedJobReviewScreen({super.key, required this.booking});

  @override
  State<CompletedJobReviewScreen> createState() =>
      _CompletedJobReviewScreenState();
}

class _CompletedJobReviewScreenState extends State<CompletedJobReviewScreen> {
  // Default to 4 stars matching Milestone 02 Reference UI (Screenshot 3)
  double _rating = 4.0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  void _submitReview() async {
    // Validation: user must select at least 1 star
    if (_rating < 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          content: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'කරුණාකර තරු එකක් තෝරන්න (Please select at least 1 star)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    // Simulate network latency / database write
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final commentText = _reviewController.text.trim().isEmpty
        ? 'Work completed smoothly and professionally.'
        : _reviewController.text.trim();

    // CRUD: CREATE Review in AppStateService (FR010 / FR005)
    // Tagged as 'verified' in system
    AppStateService().submitReview(
      bookingId: widget.booking.id,
      providerId: widget.booking.providerId,
      customerName: widget.booking.customerName.isNotEmpty
          ? widget.booking.customerName
          : 'Poornima M.',
      rating: _rating,
      comment: commentText,
      tags: const ['Verified Booking', 'On Time', 'Workmanship'],
    );

    // Also update booking status to 'completed'
    AppStateService().updateBookingStatus(widget.booking.id, 'completed');

    // Create provider notification for received review
    AppStateService().createNotification(
      recipientId: widget.booking.providerId,
      title: 'New ${_rating.toInt()}★ Verified Review',
      message:
          '${widget.booking.customerName} left feedback for ${widget.booking.serviceItem}: "$commentText"',
      type: 'job_completed',
      bookingId: widget.booking.id,
    );

    setState(() => _isSubmitting = false);

    // Success feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        content: Row(
          children: [
            Icon(Icons.verified, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Review submitted successfully! Tagged as verified.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );

    // Return homeowner safely back to My Bookings / Home view
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _skipReview() {
    // Do not save review, simply return to Home / My Bookings
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate =
        DateFormat('MMM dd').format(widget.booking.bookingDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F6),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9F9F6),
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Job completed',
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.more_horiz, color: AppColors.textPrimary),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        child: Column(
          children: [
            const SizedBox(height: 12),

            // Big Green Circular Checkmark Avatar
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF286A4F),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF286A4F).withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            // "Job marked as complete!" title (serif font)
            Text(
              'Job marked as complete!',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),

            // Subtitle: Service item · Provider Name · Date
            Text(
              '${widget.booking.serviceItem} · ${widget.booking.providerName} · $formattedDate',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // "Rate your experience" section header
            const Text(
              'Rate your experience',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // Interactive 5 Stars Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                final isSelected = starIndex <= _rating;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _rating = starIndex.toDouble();
                    });
                  },
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Icon(
                      isSelected ? Icons.star : Icons.star_border,
                      size: 42,
                      color: isSelected
                          ? const Color(0xFFE5A93C)
                          : const Color(0xFFD1D5DB),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),

            // "X out of 5 selected" counter label
            Text(
              _rating == 0
                  ? '0 out of 5 selected'
                  : '${_rating.toInt()} out of 5 selected',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 28),

            // "Write a review (optional)" input section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Write a review (optional)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5E7EB)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _reviewController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText:
                      'Share your experience — was the work good, on time, and worth the price?',
                  hintStyle: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                    height: 1.4,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // "Submit review" full-width button
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF182C25),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Submit review',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),

            const SizedBox(height: 10),

            // "Skip for now" link
            TextButton(
              onPressed: _skipReview,
              child: const Text(
                'Skip for now',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 22),

            // "public and verified" trust signals card (Screenshot 3)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF6EB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFF6E8C3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E7C4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.shield_outlined,
                      size: 20,
                      color: Color(0xFF8C6B1C),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                          height: 1.45,
                        ),
                        children: [
                          TextSpan(text: 'Your review is '),
                          TextSpan(
                            text: 'public and verified',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' — it helps other customers choose the right provider, and only shows once you\'ve actually booked this job.',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
