
import 'braintree_native_ui_platform_interface.dart';

class BraintreeNativeUi {
  Future<String?> getPlatformVersion() {
    return BraintreeNativeUiPlatform.instance.getPlatformVersion();
  }
}
