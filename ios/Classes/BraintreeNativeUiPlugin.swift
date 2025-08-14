import Flutter
import UIKit
#if canImport(BraintreeCore)
import BraintreeCore
import BraintreeCard
import BraintreeThreeDSecure
import BraintreeDataCollector
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

  private func tokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let number = args["number"] as? String,
      let expMonth = args["expirationMonth"] as? String,
      let expYear = args["expirationYear"] as? String
    else {
      result(FlutterError(code: "arg_error", message: "Missing card parameters", details: nil))
      return
    }
    let cvv = args["cvv"] as? String

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(FlutterError(code: "auth_error", message: "Invalid authorization", details: nil))
      return
    }
    let cardClient = BTCardClient(apiClient: apiClient)
    let card = BTCard(number: number, expirationMonth: expMonth, expirationYear: expYear, cvv: cvv)
    cardClient.tokenize(card) { tokenizedCard, error in
      if let error = error {
        result(FlutterError(code: "tokenize_error", message: error.localizedDescription, details: nil))
      } else {
        result(tokenizedCard?.nonce)
      }
    }
  }

  private func threeDSecure(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let nonce = args["nonce"] as? String,
      let amount = args["amount"] as? String,
      let viewController = rootViewController()
    else {
      result(FlutterError(code: "arg_error", message: "Missing parameters", details: nil))
      return
    }

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(FlutterError(code: "auth_error", message: "Invalid authorization", details: nil))
      return
    }

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

    let driver = BTThreeDSecureDriver(apiClient: apiClient, delegate: nil)
    driver.verifyCard(with: request, viewController: viewController) { tokenizedCard, error in
      if let nsError = error as NSError? {
        if nsError.domain == BTErrorDomain,
           nsError.code == BTPaymentFlowDriverErrorType.canceled.rawValue {
          result(FlutterError(code: "3ds_canceled", message: "User canceled 3DS authentication", details: nil))
        } else {
          result(FlutterError(code: "3ds_error", message: nsError.localizedDescription, details: nil))
        }
      } else {
        result(tokenizedCard?.nonce)
      }
    }
  }

  private func collectDeviceData(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String
    else {
      result(FlutterError(code: "arg_error", message: "Missing authorization", details: nil))
      return
    }

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(FlutterError(code: "auth_error", message: "Invalid authorization", details: nil))
      return
    }

    let collector = BTDataCollector(apiClient: apiClient)
    let forCard = args["forCard"] as? Bool ?? false
    if forCard {
      collector.collectCardFraudData { deviceData, _ in
        result(deviceData)
      }
    } else {
      collector.collectDeviceData { deviceData, _ in
        result(deviceData)
      }
    }
  }

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
      result(FlutterError(code: "arg_error", message: "Missing parameters", details: nil))
      return
    }

    guard let apiClient = BTAPIClient(authorization: authorization) else {
      result(FlutterError(code: "auth_error", message: "Invalid authorization", details: nil))
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
      result(FlutterError(code: "apple_pay_unavailable", message: "Apple Pay not available", details: nil))
      return
    }

    applePayDelegate = ApplePayDelegate(client: applePayClient, completion: result)
    controller.delegate = applePayDelegate
    viewController.present(controller, animated: true, completion: nil)
  }
}

class ApplePayDelegate: NSObject, PKPaymentAuthorizationViewControllerDelegate {
  let client: BTApplePayClient
  let completion: FlutterResult
  private var didComplete = false

  init(client: BTApplePayClient, completion: @escaping FlutterResult) {
    self.client = client
    self.completion = completion
  }

  func paymentAuthorizationViewController(_ controller: PKPaymentAuthorizationViewController, didAuthorizePayment payment: PKPayment, handler completionHandler: @escaping (PKPaymentAuthorizationResult) -> Void) {
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
