# braintree_native_ui.podspec
Pod::Spec.new do |s|
  s.name             = 'braintree_native_ui'
  s.version          = '0.3.9'
  s.summary          = 'Braintree SDK integration with custom UI and 3DS2.'
  s.description      = <<-DESC
Tokenize cards, perform 3D Secure verification and collect device data using
the official Braintree iOS SDK without relying on Drop-in UI.
  DESC

  s.homepage         = 'https://github.com/lucascelopes/braintree_native_ui'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'braintree_native_ui contributors' => 'support@example.com' }
  s.source           = { :path => '.' }

  s.platform         = :ios, '14.0'        # v6 exige iOS 14+ (Xcode 14.3+, Swift 5.8+)
  s.swift_version    = '5.8'               # <— subir para 5.8+ (recomendado pela v6)
  s.static_framework = true
  s.frameworks       = 'PassKit'
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.dependency       'Flutter'

  # Arquivos Swift do plugin
  s.source_files         = 'Classes/**/*'
  s.public_header_files  = 'Classes/**/*.h'

  # Braintree v6 — módulos canônicos (veja docs: Card, 3DS, Apple Pay, DataCollector)
  # Créditos (tokenize): BTCardClient(apiClient:) + tokenize(card)            → iOS v6 docs
  # 3DS v2: BTThreeDSecureClient(apiClient:).startPaymentFlow(...) + delegate → iOS v6 docs
  # Apple Pay: BTApplePayClient(apiClient:).paymentRequest / tokenize(payment)→ iOS v6 docs
  # Device data: BTDataCollector(apiClient:).collectDeviceData(...)           → iOS v6 docs
  s.dependency 'Braintree/Core',          '~> 6.36'
  s.dependency 'Braintree/Card',          '~> 6.36'
  s.dependency 'Braintree/ThreeDSecure',  '~> 6.36'
  s.dependency 'Braintree/DataCollector', '~> 6.36'
  s.dependency 'Braintree/ApplePay',      '~> 6.36'

  # Se você também expuser fluxos PayPal/Venmo no plugin Swift, adicione:
  # s.dependency 'Braintree/PayPal',       '~> 6.36'
  # s.dependency 'Braintree/Venmo',        '~> 6.36'

  # Privacy manifest opcional (se você usar APIs de “reason required”)
  # s.resource_bundles = { 'braintree_native_ui_privacy' => ['Resources/PrivacyInfo.xcprivacy'] }
end
