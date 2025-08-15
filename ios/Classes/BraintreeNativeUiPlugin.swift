import Flutter
import UIKit

// CocoaPods => umbrella "Braintree"; SPM => módulos separados.
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
    FlutterError(code: domain, message: message, details: ["code": code])
  }

  /// Cria o BTAPIClient obrigatório na v6 (tokenization key ou client token)
  private func makeAPIClient(_ authorization: String) throws -> BTAPIClient {
    if let api = BTAPIClient(authorization: authorization) {
      return api
    }
    throw NSError(domain: "braintree_native_ui", code: -10,
                  userInfo: [NSLocalizedDescriptionKey: "Falha ao inicializar BTAPIClient"])
  }

  // MARK: - Tokenize Card (v6: BTCardClient(apiClient:).tokenize(_:))

  private func tokenize(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String,
      let number = args["number"] as? String,
      let expMonth = args["expirationMonth"] as? String,
      let expYear  = args["expirationYear"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing card parameters"))
      return
    }
    let cvv = args["cvv"] as? String

    do {
      let apiClient = try makeAPIClient(authorization)
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
    } catch {
      result(asFlutterError("client_error", -2, error.localizedDescription))
    }
  }

  // MARK: - 3D Secure 2 (v6: BTThreeDSecureClient(apiClient:).startPaymentFlow)

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

    do {
      let apiClient = try makeAPIClient(authorization)
      let threeDSClient = BTThreeDSecureClient(apiClient: apiClient)

      let request = BTThreeDSecureRequest()
      request.nonce = nonce
      request.amount = NSDecimalNumber(string: amount)
      request.delegate = self // v6 requer implementar onLookupComplete e chamar next()

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
    } catch {
      result(asFlutterError("client_error", -2, error.localizedDescription))
    }
  }

  // MARK: - Device Data (fraude) v6: BTDataCollector(apiClient:).collectDeviceData

  private func collectDeviceData(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard
      let args = call.arguments as? [String: Any],
      let authorization = args["authorization"] as? String
    else {
      result(asFlutterError("arg_error", -1, "Missing authorization"))
      return
    }

    do {
      let apiClient = try makeAPIClient(authorization)
      let collector = BTDataCollector(apiClient: apiClient)
      collector.collectDeviceData { deviceData, error in
        if let error = error as NSError? {
          result(self.asFlutterError("data_error", error.code, error.localizedDescription))
        } else {
          result(deviceData ?? NSNull())
        }
      }
    } catch {
      result(asFlutterError("client_error", -2, error.localizedDescription))
    }
  }

  // MARK: - Apple Pay (v6: BTApplePayClient(apiClient:).paymentRequest + tokenize(_:))

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

    do {
      let apiClient = try makeAPIClient(authorization)
      let applePayClient = BTApplePayClient(apiClient: apiClient)

      // Helper oficial preenche country/currency/merchantId/supportedNetworks com base na configuração do gateway.
      // Depois ajustamos campos específicos do seu fluxo (items, capabilities etc.). :contentReference[oaicite:1]{index=1}
      applePayClient.paymentRequest { paymentRequest, error in
        if let error = error {
          result(self.asFlutterError("apple_pay_error", -1, error.localizedDescription))
          return
        }
        guard var request = paymentRequest else {
          result(self.asFlutterError("apple_pay_error", -2, "Unable to create PKPaymentRequest"))
          return
        }

        // Garante os campos esperados pelo seu app/conta:
        request.merchantIdentifier = merchantId
        request.countryCode = countryCode
        request.currencyCode = currencyCode
        request.merchantCapabilities = .capability3DS
        request.paymentSummaryItems = [
          PKPaymentSummaryItem(label: "Total", amount: NSDecimalNumber(string: amount))
        ]

        guard let controller = PKPaymentAuthorizationViewController(paymentRequest: request) else {
          result(self.asFlutterError("apple_pay_unavailable", -3, "Apple Pay not available"))
          return
        }

        self.applePayDelegate = ApplePayDelegate(client: applePayClient, completion: result)
        controller.delegate = self.applePayDelegate
        viewController.present(controller, animated: true, completion: nil)
      }
    } catch {
      result(asFlutterError("client_error", -2, error.localizedDescription))
    }
  }
}

// MARK: - 3DS Delegate: obrigatório chamar next() no lookup (v6)
extension BraintreeNativeUiPlugin: BTThreeDSecureRequestDelegate {
  public func onLookupComplete(_ request: BTThreeDSecureRequest,
                               result: BTThreeDSecureResult,
                               next: @escaping () -> Void) {
    // Pode inspecionar 'result.lookup' aqui se quiser customizar UI antes do challenge.
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
    // v6: método renomeado — use tokenize(_:), não tokenizeApplePay(_:) :contentReference[oaicite:2]{index=2}
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
