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
}

void main() {
  final BraintreeNativeUiPlatform initialPlatform = BraintreeNativeUiPlatform.instance;

  test('$MethodChannelBraintreeNativeUi is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelBraintreeNativeUi>());
  });

  test('getPlatformVersion', () async {
    BraintreeNativeUi braintreeNativeUiPlugin = BraintreeNativeUi();
    MockBraintreeNativeUiPlatform fakePlatform = MockBraintreeNativeUiPlatform();
    BraintreeNativeUiPlatform.instance = fakePlatform;

    expect(await braintreeNativeUiPlugin.getPlatformVersion(), '42');
  });
}
