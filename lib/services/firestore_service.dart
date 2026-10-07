import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/models.dart';
import 'mock_data.dart';

/// Firestore persistence layer for FixIt Home.
/// All collections mirror the in-memory AppStateService data.
/// UI code never touches this class directly — only AppStateService does.
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  factory FirestoreService() => _instance;
  FirestoreService._internal();

  // Lazy — only accessed after Firebase.initializeApp() has been called
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Collection references
  CollectionReference<Map<String, dynamic>> get _providers =>
      _db.collection('providers');
  CollectionReference<Map<String, dynamic>> get _bookings =>
      _db.collection('bookings');
  CollectionReference<Map<String, dynamic>> get _reviews =>
      _db.collection('reviews');
  CollectionReference<Map<String, dynamic>> get _notifications =>
      _db.collection('notifications');
  CollectionReference<Map<String, dynamic>> get _chatMessages =>
      _db.collection('chatMessages');

  // ---------------------------------------------------------------------------
  // SEED: Write mock data to Firestore if collections are empty (first run)
  // ---------------------------------------------------------------------------
  Future<void> seedIfEmpty() async {
    await Future.wait([
      _seedCollection(
        _providers,
        MockData.providers.map((p) => MapEntry(p.id, p.toMap())).toList(),
      ),
      _seedCollection(
        _bookings,
        MockData.initialBookings.map((b) => MapEntry(b.id, b.toMap())).toList(),
      ),
      _seedCollection(
        _reviews,
        MockData.initialReviews.map((r) => MapEntry(r.id, r.toMap())).toList(),
      ),
      _seedCollection(
        _notifications,
        MockData.initialNotifications
            .map((n) => MapEntry(n.id, n.toMap()))
            .toList(),
      ),
    ]);
  }

  Future<void> _seedCollection(
    CollectionReference<Map<String, dynamic>> ref,
    List<MapEntry<String, Map<String, dynamic>>> entries,
  ) async {
    final snapshot = await ref.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final batch = _db.batch();
      for (final entry in entries) {
        batch.set(ref.doc(entry.key), entry.value);
      }
      await batch.commit();
    }
  }

  // ---------------------------------------------------------------------------
  // LOAD: Read all data from Firestore on startup
  // ---------------------------------------------------------------------------
  Future<List<ServiceProvider>> loadProviders() async {
    final snap = await _providers.get();
    return snap.docs
        .map((d) => ServiceProvider.fromMap(d.data(), d.id))
        .toList();
  }

  Future<List<Booking>> loadBookings() async {
    final snap = await _bookings.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Booking.fromMap(d.data(), d.id)).toList();
  }

  Future<List<Review>> loadReviews() async {
    final snap = await _reviews.orderBy('createdAt', descending: true).get();
    return snap.docs.map((d) => Review.fromMap(d.data(), d.id)).toList();
  }

  Future<List<AppNotification>> loadNotifications() async {
    final snap =
        await _notifications.orderBy('timestamp', descending: true).get();
    return snap.docs.map((d) {
      final data = d.data();
      return AppNotification(
        id: d.id,
        recipientId: data['recipientId'] ?? '',
        title: data['title'] ?? '',
        message: data['message'] ?? '',
        type: data['type'] ?? '',
        bookingId: data['bookingId'] ?? '',
        timestamp:
            DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
        isRead: data['isRead'] ?? false,
      );
    }).toList();
  }

  Future<List<ChatMessage>> loadChatMessages() async {
    final snap =
        await _chatMessages.orderBy('timestamp', descending: false).get();
    return snap.docs.map((d) => ChatMessage.fromMap(d.data(), d.id)).toList();
  }

  // ---------------------------------------------------------------------------
  // PROVIDERS CRUD
  // ---------------------------------------------------------------------------
  Future<void> saveProvider(ServiceProvider provider) async {
    await _providers.doc(provider.id).set(provider.toMap());
  }

  Future<void> updateProvider(ServiceProvider provider) async {
    await _providers.doc(provider.id).set(provider.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteProvider(String providerId) async {
    await _providers.doc(providerId).delete();
  }

  // ---------------------------------------------------------------------------
  // BOOKINGS CRUD
  // ---------------------------------------------------------------------------
  Future<void> saveBooking(Booking booking) async {
    await _bookings.doc(booking.id).set(booking.toMap());
  }

  Future<void> updateBooking(Booking booking) async {
    await _bookings.doc(booking.id).set(booking.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteBooking(String bookingId) async {
    await _bookings.doc(bookingId).delete();
  }

  // ---------------------------------------------------------------------------
  // REVIEWS CRUD
  // ---------------------------------------------------------------------------
  Future<void> saveReview(Review review) async {
    await _reviews.doc(review.id).set(review.toMap());
  }

  Future<void> updateReview(Review review) async {
    await _reviews.doc(review.id).set(review.toMap(), SetOptions(merge: true));
  }

  // ---------------------------------------------------------------------------
  // NOTIFICATIONS CRUD
  // ---------------------------------------------------------------------------
  Future<void> saveNotification(AppNotification notif) async {
    await _notifications.doc(notif.id).set(notif.toMap());
  }

  Future<void> updateNotification(AppNotification notif) async {
    await _notifications
        .doc(notif.id)
        .set(notif.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteNotification(String notifId) async {
    await _notifications.doc(notifId).delete();
  }

  // ---------------------------------------------------------------------------
  // CHAT MESSAGES CRUD
  // ---------------------------------------------------------------------------
  Future<void> saveChatMessage(ChatMessage msg) async {
    await _chatMessages.doc(msg.id).set(msg.toMap());
  }

  Future<void> deleteChatMessage(String messageId) async {
    await _chatMessages.doc(messageId).delete();
  }
}
