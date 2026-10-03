import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Reusable App Bar with Clean Design
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBack = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
      leading: showBack
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textPrimary),
              onPressed: () => Navigator.of(context).maybePop(),
            )
          : null,
      actions: actions,
      elevation: 0,
      backgroundColor: AppColors.background,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

/// Star Rating Display Widget
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color color;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 16,
    this.color = AppColors.starFilled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return Icon(Icons.star, size: size, color: color);
        } else if (index < rating) {
          return Icon(Icons.star_half, size: size, color: color);
        } else {
          return Icon(Icons.star_border, size: size, color: AppColors.starEmpty);
        }
      }),
    );
  }
}

/// Status Chip Widget (Confirmed, In Progress, Completed, etc.)
class StatusBadge extends StatelessWidget {
  final String status;

  const StatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;

    switch (status.toLowerCase()) {
      case 'confirmed':
        bg = const Color(0xFFE8F5E9);
        fg = AppColors.success;
        label = 'Confirmed';
        break;
      case 'deposit_paid':
      case 'awaiting deposit':
        bg = const Color(0xFFFFF3E0);
        fg = AppColors.warning;
        label = 'Deposit Paid';
        break;
      case 'in_progress':
        bg = const Color(0xFFE1F5FE);
        fg = AppColors.info;
        label = 'In Progress';
        break;
      case 'completed':
        bg = const Color(0xFFE8F5E9);
        fg = AppColors.success;
        label = 'Completed';
        break;
      case 'cancelled':
        bg = const Color(0xFFFFEBEE);
        fg = AppColors.error;
        label = 'Cancelled';
        break;
      default:
        bg = AppColors.surfaceMuted;
        fg = AppColors.textSecondary;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
