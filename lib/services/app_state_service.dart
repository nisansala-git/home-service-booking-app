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

  // FAVORITES CRUD (Member 2 - Provider Profile)
  final Set<String> _favoriteProviderIds = {'prov_kamal'};
  Set<String> get favoriteProviderIds => _favoriteProviderIds;

  bool isFavorite(String providerId) => _favoriteProviderIds.contains(providerId);

  void toggleFavorite(String providerId) {
    if (_favoriteProviderIds.contains(providerId)) {
      _favoriteProviderIds.remove(providerId);
    } else {
      _favoriteProviderIds.add(providerId);
    }
    notifyListeners();
  }

  // SLOT LOCKING & CONFLICT PREVENT (Member 2 - NFR007 Concurrency)
  final Map<String, DateTime> _lockedSlots = {};

  bool isSlotLocked(String slotKey) {
    final lockedAt = _lockedSlots[slotKey];
    if (lockedAt == null) return false;
    // Release automatically after 10 minutes
    if (DateTime.now().difference(lockedAt).inMinutes > 10) {
      _lockedSlots.remove(slotKey);
      return false;
    }
    return true;
  }

  void lockSlot(String slotKey) {
    _lockedSlots[slotKey] = DateTime.now();
    notifyListeners();
  }

  // UPDATE: Reschedule or modify booking details (Member 2 - Booking Confirmation)
  void updateBookingDetails({
    required String bookingId,
    DateTime? newDate,
    String? newTimeSlot,
    String? newAddress,
    String? newNotes,
  }) {
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
        bookingDate: newDate ?? old.bookingDate,
        timeSlot: newTimeSlot ?? old.timeSlot,
        totalPrice: old.totalPrice,
        depositAmount: old.depositAmount,
        remainingAmount: old.remainingAmount,
        status: old.status,
        address: newAddress ?? old.address,
        notes: newNotes ?? old.notes,
        isContractSigned: old.isContractSigned,
        signature: old.signature,
        customTerms: old.customTerms,
        createdAt: old.createdAt,
      );

      createNotification(
        recipientId: old.providerId,
        title: 'Booking Schedule Updated',
        message: '${old.customerName} modified appointment schedule to ${newTimeSlot ?? old.timeSlot}.',
        type: 'schedule_updated',
        bookingId: old.id,
      );

      notifyListeners();
    }
  }

  // CREATE/UPDATE: Add custom scope amendment to contract (Member 2 - Digital Contract)
  void addCustomScopeTerm(String bookingId, String term) {
    final index = _bookings.indexWhere((b) => b.id == bookingId);
    if (index != -1) {
      final old = _bookings[index];
      final updatedTerms = List<String>.from(old.customTerms)..add(term);
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
        status: old.status,
        address: old.address,
        notes: old.notes,
        isContractSigned: old.isContractSigned,
        signature: old.signature,
        customTerms: updatedTerms,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
  }

  // DELETE: Cancel booking (Member 2 - Booking Confirmation)
  void cancelBooking(String bookingId) {
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
        status: 'cancelled',
        address: old.address,
        notes: old.notes,
        isContractSigned: old.isContractSigned,
        signature: old.signature,
        customTerms: old.customTerms,
        createdAt: old.createdAt,
      );

      createNotification(
        recipientId: old.providerId,
        title: 'Booking Cancelled',
        message: '${old.customerName} cancelled booking ${old.id}.',
        type: 'booking_cancelled',
        bookingId: old.id,
      );

      notifyListeners();
    }
  }

  // CHAT MESSAGES CRUD (Member 2 - In-App Provider Chat)
  final List<ChatMessage> _chatMessages = [
    ChatMessage(
      id: 'MSG-1',
      bookingId: 'BK-1001',
      providerId: 'prov_kamal',
      senderId: 'provider',
      senderName: 'Kamal Perera',
      text: 'Hello! I noticed your plumbing booking. Could you confirm if you have a shutoff valve accessible?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
    ),
    ChatMessage(
      id: 'MSG-2',
      bookingId: 'BK-1001',
      providerId: 'prov_kamal',
      senderId: 'customer',
      senderName: 'Poornima Madubashini',
      text: 'Yes, the main valve is right under the kitchen sink. Parking is free in our driveway.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ChatMessage(
      id: 'MSG-3',
      bookingId: 'BK-1001',
      providerId: 'prov_kamal',
      senderId: 'provider',
      senderName: 'Kamal Perera',
      text: 'Great! I will bring replacement washers and sealant. See you tomorrow at 10:00 AM.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];
  List<ChatMessage> get chatMessages => _chatMessages;

  List<ChatMessage> getMessagesForBooking(String bookingId) {
    return _chatMessages.where((m) => m.bookingId == bookingId).toList();
  }

  void sendChatMessage({
    required String bookingId,
    required String providerId,
    required String senderId,
    required String senderName,
    required String text,
  }) {
    _chatMessages.add(
      ChatMessage(
        id: 'MSG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        bookingId: bookingId,
        providerId: providerId,
        senderId: senderId,
        senderName: senderName,
        text: text,
        timestamp: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  void deleteChatMessage(String messageId) {
    _chatMessages.removeWhere((m) => m.id == messageId);
    notifyListeners();
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

  // UPDATE (FR005): Vote helpful on a review
  void voteHelpfulReview(String reviewId) {
    final index = _reviews.indexWhere((r) => r.id == reviewId);
    if (index != -1) {
      final old = _reviews[index];
      _reviews[index] = Review(
        id: old.id,
        bookingId: old.bookingId,
        providerId: old.providerId,
        customerName: old.customerName,
        rating: old.rating,
        comment: old.comment,
        tags: old.tags,
        helpfulVotes: old.helpfulVotes + 1,
        createdAt: old.createdAt,
      );
      notifyListeners();
    }
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

  void markAllNotificationsAsRead(String recipientId) {
    bool changed = false;
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].recipientId == recipientId && !_notifications[i].isRead) {
        final old = _notifications[i];
        _notifications[i] = AppNotification(
          id: old.id,
          recipientId: old.recipientId,
          title: old.title,
          message: old.message,
          type: old.type,
          bookingId: old.bookingId,
          timestamp: old.timestamp,
          isRead: true,
        );
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
    }
  }

  void clearAllNotifications(String recipientId) {
    _notifications.removeWhere((n) => n.recipientId == recipientId);
    notifyListeners();
  }

  void simulateIncomingJobAlert({
    required String providerId,
    required String customerName,
    required String serviceItem,
  }) {
    createNotification(
      recipientId: providerId,
      title: 'New Urgent Booking from $customerName',
      message: '$customerName booked $serviceItem. Tap to review details.',
      type: 'new_request',
      bookingId: 'BK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
  }
}
