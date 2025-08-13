import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braintree_native_ui/braintree_native_ui_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelBraintreeNativeUi platform = MethodChannelBraintreeNativeUi();
  const MethodChannel channel = MethodChannel('braintree_native_ui');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getPlatformVersion':
              return '42';
            case 'tokenizeCard':
              return 'fake-nonce';
            case 'performThreeDSecure':
              return 'verified-nonce';
            case 'collectDeviceData':
              return 'device-data';
            case 'requestGooglePayPayment':
              return 'google-nonce';
            case 'requestApplePayPayment':
              return 'apple-nonce';
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('tokenizeCard', () async {
    final nonce = await platform.tokenizeCard(
      authorization: 'auth',
      number: '4111111111111111',
      expirationMonth: '12',
      expirationYear: '2030',
    );
    expect(nonce, 'fake-nonce');
  });

  test('performThreeDSecure', () async {
    final verifiedNonce = await platform.performThreeDSecure(
      authorization: 'auth',
      nonce: 'fake-nonce',
      amount: '10.00',
    );
    expect(verifiedNonce, 'verified-nonce');
  });

  test('collectDeviceData', () async {
    final data = await platform.collectDeviceData(authorization: 'auth');
    expect(data, 'device-data');
  });

  test('requestGooglePayPayment', () async {
    final nonce = await platform.requestGooglePayPayment(
      authorization: 'auth',
      amount: '10.00',
      currencyCode: 'USD',
    );
    expect(nonce, 'google-nonce');
  });

  test('requestApplePayPayment', () async {
    final nonce = await platform.requestApplePayPayment(
      authorization: 'auth',
      merchantIdentifier: 'merchant.test',
      countryCode: 'US',
      currencyCode: 'USD',
      amount: '10.00',
    );
    expect(nonce, 'apple-nonce');
  });
}
