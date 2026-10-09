import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_booking_app/models/models.dart';
import 'package:home_service_booking_app/features/member3_payment_reviews/secure_payment_receipt_screen.dart';
import 'package:home_service_booking_app/features/member3_payment_reviews/completed_job_review_screen.dart';
import 'package:home_service_booking_app/features/member3_payment_reviews/provider_dashboard_screen.dart';

void main() {
  final testBooking = Booking(
    id: 'BK-TEST-001',
    customerId: 'user_poornima',
    customerName: 'Poornima Madubashini',
    customerPhone: '077 123 4567',
    providerId: 'prov_kamal',
    providerName: 'Kamal Perera',
    serviceCategory: 'Plumbing',
    serviceItem: 'Pipe leak repair',
    bookingDate: DateTime.now(),
    timeSlot: '10:00 AM - 11:30 AM',
    totalPrice: 2500.0,
    depositAmount: 300.0,
    remainingAmount: 2200.0,
    status: 'confirmed',
    address: '5 Wallowa ST, Mickleham',
    createdAt: DateTime.now(),
  );

  group('Member 3 Screens Test (IT23710610)', () {
    testWidgets('SecurePaymentReceiptScreen renders and switches methods',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SecurePaymentReceiptScreen(booking: testBooking),
        ),
      );
      await tester.pumpAndSettle();

      // Check Payment header and Pay With section
      expect(find.text('Payment'), findsOneWidget);
      expect(find.text('Pay with'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Bank'), findsOneWidget);
      expect(find.text('Rs 300'), findsOneWidget);
      expect(find.text('Pay securely'), findsOneWidget);

      // Tap Wallet method
      await tester.tap(find.text('Wallet'));
      await tester.pumpAndSettle();
      expect(find.text('FriMi / Genie • • • • 9102'), findsOneWidget);

      // Tap Bank method
      await tester.tap(find.text('Bank'));
      await tester.pumpAndSettle();
      expect(find.text('Commercial Bank • • • • 7741'), findsOneWidget);

      // Tap Card method again
      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();
      expect(find.text('Visa • • • • 4417'), findsOneWidget);

      // Process payment
      await tester.tap(find.text('Pay securely'));
      await tester.pump();
      // Wait for delayed simulation
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();

      // Receipt should be visible
      expect(find.text('Digital receipt'), findsOneWidget);
      expect(find.text('Payment successful'), findsOneWidget);
      expect(find.text('Pipe leak repair'), findsWidgets);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('CompletedJobReviewScreen star rating and validation test',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CompletedJobReviewScreen(booking: testBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Job completed'), findsOneWidget);
      expect(find.text('Job marked as complete!'), findsOneWidget);
      expect(find.text('Rate your experience'), findsOneWidget);
      expect(find.text('4 out of 5 selected'), findsOneWidget);
      expect(find.text('Submit review'), findsOneWidget);
      expect(find.text('Skip for now'), findsOneWidget);
    });

    testWidgets('ProviderDashboardScreen displays live requests and schedule',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProviderDashboardScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hi, Kamal'), findsOneWidget);
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('New requests (2)'), findsOneWidget);
      expect(find.text('Nadeesha S. — Cleaning'), findsOneWidget);
      expect(find.text('Ruwan D. — Plumbing'), findsOneWidget);
      expect(find.text("Today's schedule"), findsOneWidget);

      // Accept first job
      await tester.tap(find.text('Accept').first);
      await tester.pumpAndSettle();

      // New requests should decrement to 1
      expect(find.text('New requests (1)'), findsOneWidget);
    });
  });
}
