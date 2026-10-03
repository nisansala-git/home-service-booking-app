import 'package:flutter/foundation.dart';
import '../models/models.dart';
import 'mock_data.dart';

/// Central state manager handling CRUD operations for all 4 member modules
class AppStateService extends ChangeNotifier {
  static final AppStateService _instance = AppStateService._internal();
  factory AppStateService() => _instance;
  AppStateService._internal();

  // Active user role switcher (for viva and evaluation: Homeowner vs Provider)
  String _activeRole = 'homeowner'; // 'homeowner' | 'provider'
  String get activeRole => _activeRole;

  void setRole(String role) {
    _activeRole = role;
    notifyListeners();
  }

  // --- MEMBER 1: Discovery, Search & Provider Registration CRUD ---
  List<ServiceProvider> _providers = List.from(MockData.providers);
  List<ServiceProvider> get providers => _providers;

  // READ (Filtered)
  List<ServiceProvider> getProvidersByCategory(String? category, {String query = ''}) {
    return _providers.where((p) {
      final matchesCategory = category == null || category.isEmpty || p.category.toLowerCase() == category.toLowerCase();
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query.toLowerCase()) ||
          p.category.toLowerCase().contains(query.toLowerCase()) ||
          p.about.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesQuery;
    }).toList();
  }

  // CREATE (FR001, FR002): Register new provider
  void registerProvider(ServiceProvider newProvider) {
    _providers.insert(0, newProvider);
    notifyListeners();
  }

  // UPDATE: Update provider details
  void updateProvider(ServiceProvider updatedProvider) {
    final index = _providers.indexWhere((p) => p.id == updatedProvider.id);
    if (index != -1) {
      _providers[index] = updatedProvider;
      notifyListeners();
    }
  }

  // DELETE: Deactivate provider
  void removeProvider(String providerId) {
    _providers.removeWhere((p) => p.id == providerId);
    notifyListeners();
  }

  // --- MEMBER 2: Availability, Booking & Digital Contract CRUD ---
  List<Booking> _bookings = List.from(MockData.initialBookings);
  List<Booking> get bookings => _bookings;

  // CREATE (FR004): Create booking
  Booking createBooking({
    required String providerId,
    required String providerName,
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String serviceCategory,
    required String serviceItem,
    required DateTime bookingDate,
    required String timeSlot,
    required double totalPrice,
    required double depositAmount,
    required String address,
    String notes = '',
  }) {
    final newBooking = Booking(
      id: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      customerId: customerId,
      customerName: customerName,
      customerPhone: customerPhone,
      providerId: providerId,
      providerName: providerName,
      serviceCategory: serviceCategory,
      serviceItem: serviceItem,
      bookingDate: bookingDate,
      timeSlot: timeSlot,
      totalPrice: totalPrice,
      depositAmount: depositAmount,
      remainingAmount: totalPrice - depositAmount,
      status: 'confirmed',
      address: address,
      notes: notes,
      createdAt: DateTime.now(),
    );

    _bookings.insert(0, newBooking);

    // Auto-create notification for provider (Member 4 integration)
    createNotification(
      recipientId: providerId,
      title: 'New Booking Confirmed',
      message: '$customerName booked $serviceItem for $timeSlot.',
      type: 'new_request',
      bookingId: newBooking.id,
    );

    notifyListeners();
    return newBooking;
  }

  // UPDATE (FR006): Sign digital contract and confirm deposit
  void signContractAndPayDeposit(String bookingId, String signature) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = Booking(
        id: old.id,
        customerId: old.customerId,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        providerId: old.providerId,
        providerName: old.providerName,
        serviceCategory: old.serviceCategory,
        serviceItem: old.serviceItem,
        bookingDate: old.bookingDate,
        timeSlot: old.timeSlot,
        totalPrice: old.totalPrice,
        depositAmount: old.depositAmount,
        remainingAmount: old.remainingAmount,
        status: 'deposit_paid',
        address: old.address,
        notes: old.notes,
        isContractSigned: true,
        signature: signature,
        createdAt: old.createdAt,
      );

      createNotification(
        recipientId: old.providerId,
        title: 'Contract Signed & Deposit Paid',
        message: '${old.customerName} signed the contract and paid Rs. ${old.depositAmount.toInt()}.',
        type: 'deposit_received',
        bookingId: old.id,
      );

      notifyListeners();
    }
  }

  // UPDATE (Status): Provider accepts/declines/completes job
  void updateBookingStatus(String bookingId, String newStatus) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _bookings[index];
      _bookings[index] = Booking(
        id: old.id,
        customerId: old.customerId,
        customerName: old.customerName,
        customerPhone: old.customerPhone,
        providerId: old.providerId,
        providerName: old.providerName,
        serviceCategory: old.serviceCategory,
        serviceItem: old.serviceItem,
        bookingDate: old.bookingDate,
        timeSlot: old.timeSlot,
        totalPrice: old.totalPrice,
        depositAmount: old.depositAmount,
        remainingAmount: old.remainingAmount,
        status: newStatus,
        address: old.address,
        notes: old.notes,
        isContractSigned: old.isContractSigned,
        signature: old.signature,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  // DELETE: Cancel booking
  void cancelBooking(String bookingId) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      updateBookingStatus(bookingId, 'cancelled');
    }
  }

  // --- MEMBER 3: Secure Payment, Receipts & Completed Job Reviews CRUD ---
  List<Review> _reviews = List.from(MockData.initialReviews);
  List<Review> get reviews => _reviews;

  List<Review> getReviewsForProvider(String providerId) {
    return _reviews.where((r) => r.providerId == providerId).toList();
  }

  // CREATE (FR010): Submit job review
  void submitReview({
    required String bookingId,
    required String providerId,
    required String customerName,
    required double rating,
    required String comment,
    required List<String> tags,
  }) {
    final newReview = Review(
      id: 'REV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      bookingId: bookingId,
      providerId: providerId,
      customerName: customerName,
      rating: rating,
      comment: comment,
      tags: tags,
      createdAt: DateTime.now(),
    );

    _reviews.insert(0, newReview);
    updateBookingStatus(bookingId, 'completed');
    notifyListeners();
  }

  // --- MEMBER 4: Notifications, Job Details & History CRUD ---
  List<AppNotification> _notifications = List.from(MockData.initialNotifications);
  List<AppNotification> get notifications => _notifications;

  List<AppNotification> getNotificationsFor(String recipientId) {
    return _notifications.where((n) => n.recipientId == recipientId).toList();
  }

  void createNotification({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    required String bookingId,
  }) {
    _notifications.insert(
      0,
      AppNotification(
        id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        recipientId: recipientId,
        title: title,
        message: message,
        type: type,
        bookingId: bookingId,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void markNotificationAsRead(String notifId) {
    final index = _notifications.indexWhere((n) => n.id == notifId);
    if (index != -1) {
      final old = _notifications[index];
      _notifications[index] = AppNotification(
        id: old.id,
        recipientId: old.recipientId,
        title: old.title,
        message: old.message,
        type: old.type,
        bookingId: old.bookingId,
        timestamp: old.timestamp,
        isRead: true,
      );
      notifyListeners();
    }
  }

  void clearNotification(String notifId) {
    _notifications.removeWhere((n) => n.id == notifId);
    notifyListeners();
  }
}
