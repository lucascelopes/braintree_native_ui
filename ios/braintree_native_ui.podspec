Pod::Spec.new do |s|
  s.name             = 'braintree_native_ui'
  s.version          = '0.4.0'
  s.summary          = 'Braintree SDK integration with custom UI and 3DS2.'
  s.description      = <<-DESC
Tokenize cards, perform 3D Secure verification and collect device data using
the official Braintree iOS SDK without relying on Drop-in UI.
  DESC

  s.homepage         = 'https://github.com/lucascelopes/braintree_native_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'braintree_native_ui contributors' => 'support@example.com' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '14.0'
  s.swift_version    = '5.0'
  s.source_files     = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency       'Flutter'

  # Braintree v6.x
  s.dependency 'Braintree/Core',          '~> 6.36'
  s.dependency 'Braintree/Card',          '~> 6.36'
  s.dependency 'Braintree/ThreeDSecure',  '~> 6.36'
  s.dependency 'Braintree/DataCollector', '~> 6.36'
  s.dependency 'Braintree/ApplePay',      '~> 6.36'

  s.static_framework = true
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.frameworks = 'PassKit'
end
