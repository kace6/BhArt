import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bhart/screens/home_screen.dart';
import 'package:bhart/screens/login_screen.dart';
import 'package:bhart/screens/buyer/buyer_feed.dart';
import 'package:bhart/models/parsed_product.dart';

void main() {
  group('HomeScreen Tests', () {
    testWidgets('Home screen shows BhArt title and both entry tiles without overflow', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('BhArt'), findsOneWidget);
      expect(find.text('मैं बेचना चाहता हूँ'), findsOneWidget);
      expect(find.text('मैं खरीदना चाहता हूँ'), findsOneWidget);
    });

    testWidgets('Home screen handles small screen constraints without overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 480);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      expect(find.text('BhArt'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('ParsedProduct Model Tests', () {
    test('Correctly parses standard JSON', () {
      final json = {
        'name': 'Clay Diya',
        'nameHi': 'मिट्टी का दीया',
        'material': 'Clay',
        'quantity': 10,
        'userSuggestedPrice': 150,
        'descriptionEn': 'Handmade diya',
        'descriptionHi': 'हस्तनिर्मित दीया',
      };

      final product = ParsedProduct.fromJson(json);
      expect(product.name, 'Clay Diya');
      expect(product.quantity, 10);
      expect(product.userSuggestedPrice, 150);
    });

    test('Gracefully handles stringified numbers from LLMs', () {
      final json = {
        'name': 'Bamboo Basket',
        'quantity': '5',
        'userSuggestedPrice': '450',
      };

      final product = ParsedProduct.fromJson(json);
      expect(product.quantity, 5);
      expect(product.userSuggestedPrice, 450);
    });
  });

  group('LoginScreen Tests', () {
    testWidgets('Send OTP button enables when 10 phone digits are entered', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      final sendOtpBtnFinder = find.widgetWithText(ElevatedButton, 'OTP भेजें (Send OTP)');
      expect(tester.widget<ElevatedButton>(sendOtpBtnFinder).onPressed, isNull);

      final phoneFieldFinder = find.byType(TextField);
      await tester.enterText(phoneFieldFinder, '9876543210');
      await tester.pump();

      expect(tester.widget<ElevatedButton>(sendOtpBtnFinder).onPressed, isNotNull);
    });
  });

  group('BuyerFeed Tests', () {
    testWidgets('Displays fallback items and filters via search query', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BuyerFeed(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Silver Filigree Earrings'), findsOneWidget);
      expect(find.text('Woven Bamboo Basket'), findsOneWidget);

      final searchFinder = find.byType(TextField);
      await tester.enterText(searchFinder, 'Bamboo');
      await tester.pumpAndSettle();

      expect(find.text('Woven Bamboo Basket'), findsOneWidget);
      expect(find.text('Silver Filigree Earrings'), findsNothing);
    });
  });
}