import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'braintree_native_ui_method_channel.dart';

abstract class BraintreeNativeUiPlatform extends PlatformInterface {
  /// Constructs a BraintreeNativeUiPlatform.
  BraintreeNativeUiPlatform() : super(token: _token);

  static final Object _token = Object();

  static BraintreeNativeUiPlatform _instance = MethodChannelBraintreeNativeUi();

  /// The default instance of [BraintreeNativeUiPlatform] to use.
  ///
  /// Defaults to [MethodChannelBraintreeNativeUi].
  static BraintreeNativeUiPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [BraintreeNativeUiPlatform] when
  /// they register themselves.
  static set instance(BraintreeNativeUiPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
