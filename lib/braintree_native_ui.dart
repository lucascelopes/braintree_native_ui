import 'braintree_native_ui_platform_interface.dart';

/// Dart facade for the Braintree native SDKs.
///
/// Each method delegates to a platform implementation via
/// [BraintreeNativeUiPlatform]. The native code is responsible for
/// interacting with the official Braintree Android and iOS SDKs.
class BraintreeNativeUi {
  /// Returns the platform version reported by the host platform.
  Future<String?> getPlatformVersion() {
    return BraintreeNativeUiPlatform.instance.getPlatformVersion();
  }

  /// Tokenizes a credit card using the Braintree SDK and returns the
  /// resulting payment method nonce.
  ///
  /// [authorization] is either a client token or tokenization key.
  Future<String?> tokenizeCard({
    required String authorization,
    required String number,
    required String expirationMonth,
    required String expirationYear,
    String? cvv,
  }) {
    return BraintreeNativeUiPlatform.instance.tokenizeCard(
      authorization: authorization,
      number: number,
      expirationMonth: expirationMonth,
      expirationYear: expirationYear,
      cvv: cvv,
    );
  }

  /// Performs a 3‑D Secure verification for the given [nonce] and [amount].
  ///
  /// Returns the verified nonce if the challenge succeeds.
  Future<String?> performThreeDSecure({
    required String authorization,
    required String nonce,
    required String amount,
    String? email,
    Map<String, String>? billingAddress,
  }) {
    return BraintreeNativeUiPlatform.instance.performThreeDSecure(
      authorization: authorization,
      nonce: nonce,
      amount: amount,
      email: email,
      billingAddress: billingAddress,
    );
  }

  /// Collects device data used for fraud protection.
  Future<String?> collectDeviceData({
    required String authorization,
    bool forCard = false,
  }) {
    return BraintreeNativeUiPlatform.instance.collectDeviceData(
      authorization: authorization,
      forCard: forCard,
    );
  }

  /// Launches Google Pay and returns the payment method nonce.
  Future<String?> requestGooglePayPayment({
    required String authorization,
    required String amount,
    required String currencyCode,
  }) {
    return BraintreeNativeUiPlatform.instance.requestGooglePayPayment(
      authorization: authorization,
      amount: amount,
      currencyCode: currencyCode,
    );
  }

  /// Launches Apple Pay and returns the payment method nonce.
  Future<String?> requestApplePayPayment({
    required String authorization,
    required String merchantIdentifier,
    required String countryCode,
    required String currencyCode,
    required String amount,
  }) {
    return BraintreeNativeUiPlatform.instance.requestApplePayPayment(
      authorization: authorization,
      merchantIdentifier: merchantIdentifier,
      countryCode: countryCode,
      currencyCode: currencyCode,
      amount: amount,
    );
  }
}
