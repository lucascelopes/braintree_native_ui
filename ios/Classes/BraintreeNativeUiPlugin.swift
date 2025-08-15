import Flutter
import UIKit

// CocoaPods => umbrella "Braintree"; SPM/Carthage => módulos separados.
#if canImport(BraintreeCore)
import BraintreeCore
#else
import Braintree
#endif

#if canImport(BraintreeCard)
import BraintreeCard
#else
import Braintree
#endif

#if canImport(BraintreeThreeDSecure)
import BraintreeThreeDSecure
#else
import Braintree
#endif

#if canImport(BraintreeDataCollector)
import BraintreeDataCollector
#else
import Braintree
#endif

#if canImport(BraintreeApplePay)
import BraintreeApplePay
#else
import Braintree
#endif

import PassKit

public class BraintreeNativeUiPlugin: NSObject, FlutterPlugin {

  // MARK: - Flutter bootstrap

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "braintree_native_ui", binaryMessenger: registrar.messenger())
    let instance = BraintreeNativeUiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  // MARK: - Flutter bridge

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)

    case "tokenizeCard":
      tokenize(call: call, result: result)

    case "performThreeDSecure":
      threeDSecure(call: call, result: result)

    case "collectDeviceData":
      collectDeviceData(call: call, result: result)

    case "requestApplePayPayment":
      applePay(call: call, result: result)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Utils

  private func rootViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?
        .rootViewController
    } else {
      return UIApplication.shared.keyWindow?.rootViewController
    }
  }

  private func asFlutterError(_ domain: String, _ code: Int = -1, _ message: String) -> FlutterError {
    FlutterError(code: domain, message: message, details: ["code": code])
  }

  // MARK: - Card: tokenização (v6: BTCardClient(apiClient:))

  private func tokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let number = args["number"] as? String,
      let expMonth = args["expirationMonth"] as? String,
      let expYear = args["expirationYear"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing card parameters"))
      return
    }
    let cvv = args["cvv"] as? String

    let apiClient = BTAPIClient(authorization: authorization)
    let cardClient = BTCardClient(apiClient: apiClient)

    let card = BTCard()
    card.number = number
    card.expirationMonth = expMonth
    card.expirationYear = expYear
    card.cvv = cvv

    cardClient.tokenize(card) { tokenizedCard, error in
      if let error = error as NSError? {
        result(self.asFlutterError("tokenize_error", error.code, error.localizedDescription))
        return
      }
      guard let nonce = tokenizedCard?.nonce else {
        result(self.asFlutterError("tokenize_error", -3, "Tokenization returned no nonce"))
        return
      }
      result(nonce)
    }
  }

  // MARK: - 3D Secure 2 (v6: BTThreeDSecureClient + delegate)

  private var threeDSecureClient: BTThreeDSecureClient?

  private func threeDSecure(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let nonce = args["nonce"] as? String,
      let amountStr = args["amount"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing parameters"))
      return
    }

    let apiClient = BTAPIClient(authorization: authorization)
    let threeDSClient = BTThreeDSecureClient(apiClient: apiClient)
    self.threeDSecureClient = threeDSClient // manter forte durante o flow

    let request = BTThreeDSecureRequest()
    // `amount` em v6 aceita numérico (docs exemplificam 10.00). Vamos converter a partir da string.
    if let decimal = Decimal(string: amountStr) {
      request.amount = decimal as NSDecimalNumber // compatível com as versões atuais do SDK
    } else {
      request.amount = NSDecimalNumber(string: amountStr) // fallback
    }
    request.nonce = nonce

    if let email = args["email"] as? String {
      request.email = email
    }
    if let billing = args["billingAddress"] as? [String: String] {
      let address = BTThreeDSecurePostalAddress()
      address.givenName = billing["givenName"]
      address.surname = billing["surname"]
      address.streetAddress = billing["streetAddress"]
      address.extendedAddress = billing["extendedAddress"]
      address.locality = billing["locality"]
      address.region = billing["region"]
      address.postalCode = billing["postalCode"]
      address.countryCodeAlpha2 = billing["countryCodeAlpha2"]
      request.billingAddress = address
    }

    // Delegate correto na v6
    request.threeDSecureRequestDelegate = self

    threeDSClient.startPaymentFlow(request) { result3DS, error in
      if let error = error as NSError? {
        let text = error.localizedDescription.lowercased()
        let code = error.code
        if text.contains("cancel") || text.contains("canceled") || text.contains("cancelled") {
          result(self.asFlutterError("3ds_canceled", code, error.localizedDescription))
        } else {
          result(self.asFlutterError("3ds_error", code, error.localizedDescription))
        }
        return
      }
      guard let nonce = result3DS?.tokenizedCard?.nonce else {
        result(self.asFlutterError("3ds_error", -3, "3DS finished without tokenized card"))
        return
      }
      result(nonce)
    }
  }

  // MARK: - Device Data (Fraude) v6

  private func collectDeviceData(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing authorization"))
      return
    }

    let apiClient = BTAPIClient(authorization: authorization)
    let collector = BTDataCollector(apiClient: apiClient)
    collector.collectDeviceData { deviceData, error in
      if let error = error as NSError? {
        result(self.asFlutterError("data_error", error.code, error.localizedDescription))
      } else {
        result(deviceData ?? NSNull())
      }
    }
  }

  // MARK: - Apple Pay (manual PKPaymentRequest + tokenize)

  private var applePayDelegate: ApplePayDelegate?

  private func applePay(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let merchantId = args["merchantIdentifier"] as? String,
      let countryCode = args["countryCode"] as? String,
      let currencyCode = args["currencyCode"] as? String,
      let amount = args["amount"] as? String,
      let viewController = rootViewController()
    else {
      result(asFlutterError("arg_error", -1, "Missing parameters"))
      return
    }

    let apiClient = BTAPIClient(authorization: authorization)
    let applePayClient = BTApplePayClient(apiClient: apiClient)

    // Construímos manualmente o PKPaymentRequest (evita erro de 'no member paymentRequest')
    let paymentRequest = PKPaymentRequest()
    paymentRequest.merchantIdentifier = merchantId
    paymentRequest.countryCode = countryCode
    paymentRequest.currencyCode = currencyCode
    paymentRequest.merchantCapabilities = PKMerchantCapability.capability3DS
    paymentRequest.supportedNetworks = [.visa, .masterCard, .amex, .discover]
    paymentRequest.paymentSummaryItems = [
      PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: amount))
    ]

    guard let controller = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
      result(asFlutterError("apple_pay_unavailable", -1, "Apple Pay not available"))
      return
    }

    applePayDelegate = ApplePayDelegate(client: applePayClient, completion: result)
    controller.delegate = applePayDelegate
    viewController.present(controller, animated: true, completion: nil)
  }
}

// MARK: - 3DS Delegate (v6) — label correto: `lookupResult`
extension BraintreeNativeUiPlugin: BTThreeDSecureRequestDelegate {
  public func onLookupComplete(
    _ request: BTThreeDSecureRequest,
    lookupResult result: BTThreeDSecureResult,
    next: @escaping () -> Void
  ) {
    // Aqui você pode inspecionar 'result.lookup' e preparar UI, se quiser.
    next()
  }
}

// MARK: - Apple Pay Delegate

class ApplePayDelegate: NSObject, PKPaymentAuthorizationViewControllerDelegate {
  let client: BTApplePayClient
  let completion: FlutterResult
  private var didComplete = false

  init(client: BTApplePayClient, completion: @escaping FlutterResult) {
    self.client = client
    self.completion = completion
  }

  func paymentAuthorizationViewController(
    _ controller: PKPaymentAuthorizationViewController,
    didAuthorizePayment payment: PKPayment,
    handler completionHandler: @escaping (PKPaymentAuthorizationResult) -> Void
  ) {
    client.tokenize(payment) { nonce, error in
      if let error = error {
        completionHandler(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
        self.completion(FlutterError(code: "apple_pay_error", message: error.localizedDescription, details: nil))
      } else {
        completionHandler(PKPaymentAuthorizationResult(status: .success, errors: nil))
        self.completion(nonce?.nonce)
      }
      self.didComplete = true
    }
  }

  func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
    controller.dismiss(animated: true) {
      if !self.didComplete {
        self.completion(FlutterError(code: "apple_pay_canceled", message: "User canceled Apple Pay", details: nil))
      }
    }
  }
}
