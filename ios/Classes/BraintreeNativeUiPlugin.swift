import Flutter
import UIKit
import BraintreeCore
import BraintreeCard
import BraintreeThreeDSecure
import BraintreeDataCollector
import BraintreeApplePay
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
      let viewController = UIApplication.shared.keyWindow?.rootViewController
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

    let driver = BTThreeDSecureDriver(apiClient: apiClient, delegate: nil)
    driver.verifyCard(with: request, viewController: viewController) { tokenizedCard, error in
      if let error = error {
        result(FlutterError(code: "3ds_error", message: error.localizedDescription, details: nil))
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
    collector.collectDeviceData { deviceData, _ in
      result(deviceData)
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
      let viewController = UIApplication.shared.keyWindow?.rootViewController
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
    }
  }

  func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
    controller.dismiss(animated: true, completion: nil)
  }
}
