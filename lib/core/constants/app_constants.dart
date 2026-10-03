import 'package:flutter/material.dart';

/// App Constants & Responsive Scaling for Reference UI Size: 390 × 844
class AppConstants {
  static const String appName = 'FixIt Home';
  static const String currency = 'Rs.';

  // Target Reference Screen Dimensions (Milestone 02 requirement)
  static const double referenceWidth = 390.0;
  static const double referenceHeight = 844.0;

  // Service Categories from Milestone 01/02
  static const List<Map<String, dynamic>> serviceCategories = [
    {'id': 'plumbing', 'name': 'Plumbing', 'icon': Icons.plumbing, 'count': '18 providers'},
    {'id': 'electrical', 'name': 'Electrical', 'icon': Icons.electric_bolt, 'count': '24 providers'},
    {'id': 'cleaning', 'name': 'Cleaning', 'icon': Icons.cleaning_services, 'count': '32 providers'},
    {'id': 'carpentry', 'name': 'Carpentry', 'icon': Icons.handyman, 'count': '15 providers'},
    {'id': 'painting', 'name': 'Painting', 'icon': Icons.format_paint, 'count': '12 providers'},
    {'id': 'gardening', 'name': 'Gardening', 'icon': Icons.yard, 'count': '9 providers'},
  ];
}

/// Helper for responsive scaling against reference UI size (390 x 844)
class ResponsiveHelper {
  final BuildContext context;
  late double screenWidth;
  late double screenHeight;

  ResponsiveHelper(this.context) {
    final mediaQuery = MediaQuery.of(context);
    screenWidth = mediaQuery.size.width;
    screenHeight = mediaQuery.size.height;
  }

  double scaleWidth(double size) {
    return (size / AppConstants.referenceWidth) * screenWidth;
  }

  double scaleHeight(double size) {
    return (size / AppConstants.referenceHeight) * screenHeight;
  }

  double scaleFont(double size) {
    final scale = screenWidth / AppConstants.referenceWidth;
    return (size * scale).clamp(size * 0.85, size * 1.25);
  }
}
