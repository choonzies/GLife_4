import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

void main() {
  group('Flutter Auth App Test', () {
    final emailField = find.byValueKey('email-field');
    final passwordField = find.byValueKey('password-field');
    final signInButton = find.byValueKey('login-button');
    final homePage = find.byType('HomePage');
    final error = find.byValueKey('error-message'); // Added key for snackbar

    FlutterDriver? driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      if (driver != null) {
        driver?.close();
      }
    });

    test('login fails with incorrect email and password', () async {
      await driver?.tap(emailField);
      await driver?.enterText('test@g.com');
      await driver?.tap(passwordField);
      await driver?.enterText('wrong');
      await driver?.tap(signInButton);
      await driver?.waitUntilNoTransientCallbacks();

      expect(await driver?.getText(error), 'Incorrect Email or Password');
    });

    test('login succeeds with correct email and password', () async {
      await driver?.tap(emailField);
      await driver?.enterText('test@g.com');
      await driver?.tap(passwordField);
      await driver?.enterText('123456');
      await driver?.tap(signInButton);

      await driver?.waitFor(homePage);
      expect(homePage, isNotNull);
    });
  });
}
