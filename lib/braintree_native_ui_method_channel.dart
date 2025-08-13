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
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
