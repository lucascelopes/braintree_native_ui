#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint braintree_native_ui.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'braintree_native_ui'
  s.version          = '0.1.0'
  s.summary          = 'Braintree SDK integration with custom UI and 3DS2.'
  s.description      = <<-DESC
Tokenize cards, perform 3D Secure verification and collect device data using
the official Braintree iOS SDK without relying on Drop-in UI.
                       DESC
  s.homepage         = 'https://github.com/lucascelopes/braintree_native_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'braintree_native_ui contributors' => 'support@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

s.dependency 'Braintree/Card'
s.dependency 'Braintree/ThreeDSecure'
s.dependency 'Braintree/DataCollector'
s.dependency 'Braintree/ApplePay'


  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'braintree_native_ui_privacy' => ['Resources/PrivacyInfo.xcprivacy']}
end
