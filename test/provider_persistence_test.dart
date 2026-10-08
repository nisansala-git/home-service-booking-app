import 'package:flutter_test/flutter_test.dart';
import 'package:home_service_booking_app/models/models.dart';

void main() {
  test('Provider record round trips without passwords or private contacts', () {
    final provider = ServiceProvider(
      id: 'auth-uid', name: 'New Provider', category: 'plumbing', rating: 0,
      reviewCount: 0, jobsCompleted: 0, onTimePercentage: 0, experienceYears: 0,
      startingPrice: 1200, distanceKm: 0, imageUrl: '', about: 'Plumbing in Kandy',
      isVerified: false, isBackgroundChecked: false, isInsured: false,
      isAvailableToday: true, pastWorkImages: [], pricingTable: [],
    );
    final record = provider.toMap();
    expect(record.keys, isNot(contains('password')));
    expect(record.keys, isNot(contains('email')));
    expect(record.keys, isNot(contains('phone')));
    final loaded = ServiceProvider.fromMap(record, 'auth-uid');
    expect(loaded.name, 'New Provider');
    expect(loaded.startingPrice, 1200);
    expect(loaded.isVerified, isFalse);
    expect(loaded.isAvailableToday, isTrue);
    record.remove('isAvailableToday');
    expect(ServiceProvider.fromMap(record, 'auth-uid').isAvailableToday, isFalse);
  });
}
