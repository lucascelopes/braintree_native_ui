import Flutter
import UIKit

// CocoaPods fornece "Braintree" (umbrella). SPM/Carthage expõem módulos separados.
// Estes imports condicionais te dão compatibilidade com ambos.
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
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "braintree_native_ui", binaryMessenger: registrar.messenger())
    let instance = BraintreeNativeUiPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

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

  // MARK: - Helpers

  private func rootViewController() -> UIViewController? {
    if #available(iOS 13.0, *) {
      return UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .flatMap { $0.windows }
        .first { $0.isKeyWindow }?.rootViewController
    } else {
      return UIApplication.shared.keyWindow?.rootViewController
    }
  }

  private func asFlutterError(_ domain: String, _ code: Int = -1, _ message: String) -> FlutterError {
    return FlutterError(code: domain, message: message, details: ["code": code])
  }

  // MARK: - Tokenize Card (v6)

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

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(asFlutterError("auth_error", -2, "Invalid authorization"))
      return
    }

    let cardClient = BTCardClient(apiClient: apiClient)
    let card = BTCard(number: number, expirationMonth: expMonth, expirationYear: expYear, cvv: cvv)

    // v6: o método é tokenizeCard(_:) — NÃO existe tokenize(...)
    cardClient.tokenizeCard(card) { tokenizedCard, error in
      if let error = error {
        let ns = error as NSError
        result(self.asFlutterError("tokenize_error", ns.code, ns.localizedDescription))
        return
      }
      guard let nonce = tokenizedCard?.nonce else {
        result(self.asFlutterError("tokenize_error", -3, "Tokenization returned no nonce"))
        return
      }
      result(nonce)
    }
  }

  // MARK: - 3D Secure 2 (v6: BTThreeDSecureClient)

  private func threeDSecure(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let nonce = args["nonce"] as? String,
      let amount = args["amount"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing parameters"))
      return
    }

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(asFlutterError("auth_error", -2, "Invalid authorization"))
      return
    }

    let threeDSecureClient = BTThreeDSecureClient(apiClient: apiClient)
    let request = BTThreeDSecureRequest()
    request.nonce = nonce
    request.amount = NSDecimalNumber(string: amount)

    if let email = args["email"] as? String {
      request.email = email
    }
    if let billing = args["billingAddress"] as? [String: String] {
      let address = BTThreeDSecurePostalAddress()
      address.streetAddress = billing["streetAddress"]
      address.extendedAddress = billing["extendedAddress"]
      address.locality = billing["locality"]
      address.region = billing["region"]
      address.postalCode = billing["postalCode"]
      address.countryCodeAlpha2 = billing["countryCodeAlpha2"]
      request.billingAddress = address
    }

    threeDSecureClient.startPaymentFlow(request) { result3DS, error in
      if let error = error {
        let ns = error as NSError
        // Alguns integradores querem tratar "cancel" diferente:
        let lowered = ns.localizedDescription.lowercased()
        if lowered.contains("cancel") || lowered.contains("canceled") || lowered.contains("cancelled") {
          result(self.asFlutterError("3ds_canceled", ns.code, ns.localizedDescription))
        } else {
          result(self.asFlutterError("3ds_error", ns.code, ns.localizedDescription))
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

  // MARK: - Device Data (fraude) v6

  private func collectDeviceData(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing authorization"))
      return
    }

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(asFlutterError("auth_error", -2, "Invalid authorization"))
      return
    }

    let collector = BTDataCollector(apiClient: apiClient)
    // v6: collectDeviceData cobre os casos de fraude (cartão/PayPal)
    collector.collectDeviceData { deviceData, error in
      if let error = error {
        let ns = error as NSError
        result(self.asFlutterError("data_error", ns.code, ns.localizedDescription))
      } else {
        result(deviceData ?? NSNull())
      }
    }
  }

  // MARK: - Apple Pay

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

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(asFlutterError("auth_error", -2, "Invalid authorization"))
      return
    }

    let applePayClient = BTApplePayClient(apiClient: apiClient)
    let paymentRequest = PKPaymentRequest()
    paymentRequest.merchantIdentifier = merchantId
    paymentRequest.countryCode = countryCode
    paymentRequest.currencyCode = currencyCode
    paymentRequest.merchantCapabilities = .capability3DS
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
