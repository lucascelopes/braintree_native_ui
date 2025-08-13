import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'braintree_native_ui_platform_interface.dart';

/// An implementation of [BraintreeNativeUiPlatform] that uses method channels.
class MethodChannelBraintreeNativeUi extends BraintreeNativeUiPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('braintree_native_ui');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<String?> tokenizeCard({
    required String authorization,
    required String number,
    required String expirationMonth,
    required String expirationYear,
    String? cvv,
  }) async {
    final nonce = await methodChannel.invokeMethod<String>('tokenizeCard', {
      'authorization': authorization,
      'number': number,
      'expirationMonth': expirationMonth,
      'expirationYear': expirationYear,
      'cvv': cvv,
    });
    return nonce;
  }

  @override
  Future<String?> performThreeDSecure({
    required String authorization,
    required String nonce,
    required String amount,
  }) async {
    final verifiedNonce = await methodChannel.invokeMethod<String>(
      'performThreeDSecure',
      {'authorization': authorization, 'nonce': nonce, 'amount': amount},
    );
    return verifiedNonce;
  }

  @override
  Future<String?> collectDeviceData({required String authorization}) async {
    final deviceData = await methodChannel.invokeMethod<String>(
      'collectDeviceData',
      {'authorization': authorization},
    );
    return deviceData;
  }

  @override
  Future<String?> requestGooglePayPayment({
    required String authorization,
    required String amount,
    required String currencyCode,
  }) async {
    return await methodChannel.invokeMethod<String>('requestGooglePayPayment', {
      'authorization': authorization,
      'amount': amount,
      'currencyCode': currencyCode,
    });
  }

  @override
  Future<String?> requestApplePayPayment({
    required String authorization,
    required String merchantIdentifier,
    required String countryCode,
    required String currencyCode,
    required String amount,
  }) async {
    return await methodChannel.invokeMethod<String>('requestApplePayPayment', {
      'authorization': authorization,
      'merchantIdentifier': merchantIdentifier,
      'countryCode': countryCode,
      'currencyCode': currencyCode,
      'amount': amount,
    });
  }
}
