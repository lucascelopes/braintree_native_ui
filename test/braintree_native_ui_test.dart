import 'package:flutter_test/flutter_test.dart';
import 'package:braintree_native_ui/braintree_native_ui.dart';
import 'package:braintree_native_ui/braintree_native_ui_platform_interface.dart';
import 'package:braintree_native_ui/braintree_native_ui_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockBraintreeNativeUiPlatform
    with MockPlatformInterfaceMixin
    implements BraintreeNativeUiPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<String?> tokenizeCard({
    required String authorization,
    required String number,
    required String expirationMonth,
    required String expirationYear,
    String? cvv,
  }) => Future.value('fake-nonce');

  @override
  Future<String?> performThreeDSecure({
    required String authorization,
    required String nonce,
    required String amount,
  }) => Future.value('verified-nonce');

  @override
  Future<String?> collectDeviceData({required String authorization}) =>
      Future.value('device-data');

  @override
  Future<String?> requestGooglePayPayment({
    required String authorization,
    required String amount,
    required String currencyCode,
  }) => Future.value('google-nonce');

  @override
  Future<String?> requestApplePayPayment({
    required String authorization,
    required String merchantIdentifier,
    required String countryCode,
    required String currencyCode,
    required String amount,
  }) => Future.value('apple-nonce');
}

void main() {
  final BraintreeNativeUiPlatform initialPlatform =
      BraintreeNativeUiPlatform.instance;

  test('$MethodChannelBraintreeNativeUi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBraintreeNativeUi>());
  });

  test('getPlatformVersion', () async {
    BraintreeNativeUi braintreeNativeUiPlugin = BraintreeNativeUi();
    MockBraintreeNativeUiPlatform fakePlatform =
        MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(await braintreeNativeUiPlugin.getPlatformVersion(), '42');
  });

  test('tokenizeCard delegates to platform', () async {
    final plugin = BraintreeNativeUi();
    final fakePlatform = MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(
      await plugin.tokenizeCard(
        authorization: 'auth',
        number: '4111111111111111',
        expirationMonth: '12',
        expirationYear: '2030',
      ),
      'fake-nonce',
    );
  });

  test('performThreeDSecure delegates to platform', () async {
    final plugin = BraintreeNativeUi();
    final fakePlatform = MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(
      await plugin.performThreeDSecure(
        authorization: 'auth',
        nonce: 'fake-nonce',
        amount: '10.00',
      ),
      'verified-nonce',
    );
  });

  test('collectDeviceData delegates to platform', () async {
    final plugin = BraintreeNativeUi();
    final fakePlatform = MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(
      await plugin.collectDeviceData(authorization: 'auth'),
      'device-data',
    );
  });

  test('requestGooglePayPayment delegates to platform', () async {
    final plugin = BraintreeNativeUi();
    final fakePlatform = MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(
      await plugin.requestGooglePayPayment(
        authorization: 'auth',
        amount: '10.00',
        currencyCode: 'USD',
      ),
      'google-nonce',
    );
  });

  test('requestApplePayPayment delegates to platform', () async {
    final plugin = BraintreeNativeUi();
    final fakePlatform = MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(
      await plugin.requestApplePayPayment(
        authorization: 'auth',
        merchantIdentifier: 'merchant.test',
        countryCode: 'US',
        currencyCode: 'USD',
        amount: '10.00',
      ),
      'apple-nonce',
    );
  });
}
