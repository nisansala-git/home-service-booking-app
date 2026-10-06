import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_booking_app/services/app_state_service.dart';
import 'package:home_service_booking_app/models/models.dart';

void main() {
  group('Milestone 03 Functional Test Cases & CRUD Verification', () {
    late AppStateService appState;

    setUp(() {
      appState = AppStateService();
    });

    test('TC-01 [Member 1 CRUD]: Register new service provider (Create & Read)', () {
      final initialCount = appState.providers.length;
      final newProv = ServiceProvider(
        id: 'prov_test_1',
        name: 'Saman Kumara',
        category: 'electrical',
        rating: 5.0,
        reviewCount: 0,
        jobsCompleted: 0,
        onTimePercentage: 100,
        experienceYears: 3,
        startingPrice: 1500.0,
        distanceKm: 2.1,
        imageUrl: '',
        about: 'Certified residential electrician.',
        pastWorkImages: [],
        pricingTable: [
          {'item': 'Inspection', 'price': 1500.0, 'unit': 'base'},
        ],
      );

      appState.registerProvider(newProv);
      expect(appState.providers.length, initialCount + 1);

      final searchResults = appState.getProvidersByCategory('electrical', query: 'Saman');
      expect(searchResults.any((p) => p.name == 'Saman Kumara'), isTrue);
    });

    test('TC-02 [Member 2 CRUD]: Create service booking and sign digital contract (Create & Update)', () {
      final booking = appState.createBooking(
        providerId: 'prov_kamal',
        providerName: 'Kamal Perera',
        customerId: 'user_poornima',
        customerName: 'Poornima Madubashini',
        customerPhone: '077 123 4567',
        serviceCategory: 'plumbing',
        serviceItem: 'Pipe leak repair',
        bookingDate: DateTime.now().add(const Duration(days: 1)),
        timeSlot: '10:00 AM - 11:30 AM',
        totalPrice: 2500.0,
        depositAmount: 500.0,
        address: '5 Wallowa ST, Mickleham',
      );

      expect(booking.id.startsWith('BK-'), isTrue);
      expect(booking.status, 'confirmed');

      // Update: Sign digital contract & deposit
      appState.signContractAndPayDeposit(booking.id, 'test_signature_bytes');
      final updated = appState.bookings.firstWhere((b) => b.id == booking.id);
      expect(updated.isContractSigned, isTrue);
      expect(updated.status, 'deposit_paid');
    });

    test('TC-02B [Member 2 Advanced CRUD]: Reschedule and Cancel booking (Update & Delete)', () {
      final booking = appState.createBooking(
        providerId: 'prov_kamal',
        providerName: 'Kamal Perera',
        customerId: 'user_poornima',
        customerName: 'Poornima Madubashini',
        customerPhone: '077 123 4567',
        serviceCategory: 'plumbing',
        serviceItem: 'Tap repair',
        bookingDate: DateTime.now().add(const Duration(days: 2)),
        timeSlot: '08:30 AM - 10:00 AM',
        totalPrice: 1200.0,
        depositAmount: 300.0,
        address: '5 Wallowa ST',
      );

      // Update: Reschedule
      appState.updateBookingDetails(
        bookingId: booking.id,
        newTimeSlot: '01:30 PM - 03:00 PM',
        newNotes: 'Gate passcode is 1234',
      );
      final rescheduled = appState.bookings.firstWhere((b) => b.id == booking.id);
      expect(rescheduled.timeSlot, '01:30 PM - 03:00 PM');
      expect(rescheduled.notes, 'Gate passcode is 1234');

      // Delete: Cancel booking
      appState.cancelBooking(booking.id);
      final cancelled = appState.bookings.firstWhere((b) => b.id == booking.id);
      expect(cancelled.status, 'cancelled');
    });

    test('TC-02C [Member 2 Advanced CRUD]: Contract custom amendment & Review helpful vote (Create & Update)', () {
      final booking = appState.bookings.first;
      appState.addCustomScopeTerm(booking.id, 'Includes 30-day warranty on rubber washers');
      final updated = appState.bookings.firstWhere((b) => b.id == booking.id);
      expect(updated.customTerms.contains('Includes 30-day warranty on rubber washers'), isTrue);

      final review = appState.reviews.first;
      final initialVotes = review.helpfulVotes;
      appState.voteHelpfulReview(review.id);
      final updatedReview = appState.reviews.firstWhere((r) => r.id == review.id);
      expect(updatedReview.helpfulVotes, initialVotes + 1);
    });

    test('TC-02D [Member 2 Advanced CRUD]: In-App Provider Chat messaging (Create & Delete)', () {
      final initialCount = appState.chatMessages.length;
      appState.sendChatMessage(
        bookingId: 'BK-1001',
        providerId: 'prov_kamal',
        senderId: 'customer',
        senderName: 'Poornima',
        text: 'Where should you park?',
      );
      expect(appState.chatMessages.length, initialCount + 1);

      final newMsg = appState.chatMessages.last;
      expect(newMsg.text, 'Where should you park?');

      appState.deleteChatMessage(newMsg.id);
      expect(appState.chatMessages.any((m) => m.id == newMsg.id), isFalse);
    });

    test('TC-03 [Member 3 CRUD]: Accept job request & Submit verified review (Update & Create)', () {
      final booking = appState.bookings.first;
      appState.updateBookingStatus(booking.id, 'in_progress');
      expect(appState.bookings.firstWhere((b) => b.id == booking.id).status, 'in_progress');

      final initialReviews = appState.reviews.length;
      appState.submitReview(
        bookingId: booking.id,
        providerId: booking.providerId,
        customerName: 'Poornima M.',
        rating: 5.0,
        comment: 'Excellent plumbing fix! Clear pricing.',
        tags: ['On time', 'Fair price'],
      );

      expect(appState.reviews.length, initialReviews + 1);
      expect(appState.bookings.firstWhere((b) => b.id == booking.id).status, 'completed');
    });

    test('TC-04 [Member 4 CRUD]: Notification dispatch & Dismissal (Create & Delete)', () {
      final initialNotifs = appState.notifications.length;
      appState.createNotification(
        recipientId: 'prov_kamal',
        title: 'Emergency Tap Replacement',
        message: 'Customer requested immediate service.',
        type: 'new_request',
        bookingId: 'BK-TEST',
      );

      expect(appState.notifications.length, initialNotifs + 1);
      final newNotifId = appState.notifications.first.id;

      appState.clearNotification(newNotifId);
      expect(appState.notifications.any((n) => n.id == newNotifId), isFalse);
    });
  });
}
