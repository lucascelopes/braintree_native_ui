import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:braintree_native_ui/braintree_native_ui_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelBraintreeNativeUi platform = MethodChannelBraintreeNativeUi();
  const MethodChannel channel = MethodChannel('braintree_native_ui');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return '42';
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });
}
