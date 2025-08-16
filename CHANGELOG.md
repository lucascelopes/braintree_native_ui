## [0.4.0] - 2025-08-16
### Corrigido
- Correções técnicas e melhorias gerais.

## [0.3.7] - 2025-08-15
### Alterado
- Atualizado código Swift para compatibilidade total com **Braintree iOS SDK v6.36**.
- Substituído uso obsoleto de `tokenizeCard` por `tokenize(_:)` de `BTCardClient`.
- Refatoração do fluxo de **3D Secure 2** para utilizar `BTThreeDSecureClient` canônico.
- Coleta de device data ajustada para API `collectDeviceData` única, cobrindo PayPal e cartão.
- Importações adaptadas com `#if canImport(...)` para compatibilidade com diferentes setups (CocoaPods vs SPM).
- Melhor tratamento de erros usando helper `asFlutterError(...)` para retornar `FlutterError` padronizado.
- Código de Apple Pay revisado para usar `BTApplePayClient` com `PKPaymentAuthorizationResult` (iOS 14+).

### Corrigido
- Erros de compilação Swift:
  - `"Argument passed to call that takes no arguments"`
  - `"Value of type 'BTCardClient' has no member 'tokenizeCard'"`
  - `"Cannot find 'BTThreeDSecureDriver' in scope"`
  - `"Value of type 'BTDataCollector' has no member 'collectCardFraudData'"`
- Erros por importações incorretas quando usando subspecs do Braintree no CocoaPods.
- Retorno `nil` não tipado que causava falhas de compilação.

### Adicionado
- `s.frameworks = 'PassKit'` no `.podspec` para evitar erro de compilação no Apple Pay.
- Checagem de argumentos em todos os métodos públicos para evitar crashes.
- Comentários claros sobre cada fluxo (tokenização, 3DS, device data, Apple Pay).

## 0.3.2
- Correções nos imports Braintree/Apple Pay.

## 0.3.1
- Correções nos imports Braintree/Core.

## 0.3.0
- Ajuste de imports condicionais para compatibilidade com CocoaPods e SPM.
- Adicionada validação do Podspec na pipeline de CI.

## 0.2.5
- Corrigido erros iOS CocoaPods.

## 0.2.1
- Correções IOS 13+.

## 0.2.0
- Integrações de pagamento via Google Pay e Apple Pay.

## 0.1.1
- Adicionada dependência `plugin_platform_interface`.
- Exemplos de uso com `TextField`.
- Documentação inicial para Google Pay e Apple Pay.

## 0.1.0

- Primeira versão funcional do plugin.
- Suporte à tokenização de cartões de crédito.
- Execução de verificação 3‑D Secure 2 nativa.
- Coleta de *device data* para prevenção de fraudes.
- Exemplos, testes unitários e documentação básica.
