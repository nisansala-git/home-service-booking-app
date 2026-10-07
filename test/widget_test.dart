import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:home_service_booking_app/main.dart';
import 'package:home_service_booking_app/features/member2_booking_contract/provider_profile_screen.dart';
import 'package:home_service_booking_app/features/member2_booking_contract/availability_booking_screen.dart';
import 'package:home_service_booking_app/features/member2_booking_contract/provider_chat_screen.dart';
import 'package:home_service_booking_app/services/mock_data.dart';

final Uint8List _kTransparentImage = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49,
  0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06,
  0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44,
  0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D,
  0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) => _TestHttpClient();
}

class _TestHttpClient implements HttpClient {
  @override
  bool autoUncompress = true;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl) {
      return Future.value(_TestHttpClientRequest());
    }
    return null;
  }
}

class _TestHttpClientRequest implements HttpClientRequest {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(_TestHttpClientResponse());
    }
    return super.noSuchMethod(invocation);
  }
}

class _TestHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;
  @override
  int get contentLength => _kTransparentImage.length;
  @override
  HttpClientResponseCompressionState get compressionState => HttpClientResponseCompressionState.notCompressed;

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.value(_kTransparentImage).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    HttpOverrides.global = _TestHttpOverrides();
  });
  testWidgets('FixIt Home smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FixItHomeApp());
    await tester.pumpAndSettle();

    expect(find.text('FixIt Home'), findsWidgets);
    expect(find.text('Verified Home Services'), findsOneWidget);
  });

  testWidgets('Member 2 screens layout and back navigation test', (WidgetTester tester) async {
    final testProvider = MockData.providers.first;

    // Test ProviderProfileScreen renders without unbounded width errors
    await tester.pumpWidget(
      MaterialApp(
        home: ProviderProfileScreen(provider: testProvider),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Kamal Perera'), findsWidgets);
    expect(find.text('Check Availability'), findsOneWidget);
    expect(find.text('Chat'), findsOneWidget);

    // Tap Chat to verify navigation to ProviderChatScreen
    await tester.tap(find.text('Chat'));
    await tester.pumpAndSettle();

    expect(find.byType(ProviderChatScreen), findsOneWidget);

    // Tap back button in ProviderChatScreen
    final backIcon = find.byIcon(Icons.arrow_back_ios_new);
    expect(backIcon, findsOneWidget);
    await tester.tap(backIcon);
    await tester.pumpAndSettle();

    // Verify returned back to ProviderProfileScreen
    expect(find.byType(ProviderProfileScreen), findsOneWidget);

    // Tap Check Availability
    await tester.tap(find.text('Check Availability'));
    await tester.pumpAndSettle();

    expect(find.byType(AvailabilityBookingScreen), findsOneWidget);

    // Tap back button in AvailabilityBookingScreen
    expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    // Verify back on ProviderProfileScreen
    expect(find.byType(ProviderProfileScreen), findsOneWidget);
  });
}

