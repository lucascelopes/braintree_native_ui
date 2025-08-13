package com.nagazakisoftware.braintree_native_ui

import android.app.Activity
import android.content.Context
import androidx.annotation.NonNull
import com.braintreepayments.api.BraintreeClient
import com.braintreepayments.api.Card
import com.braintreepayments.api.CardClient
import com.braintreepayments.api.DataCollector
import com.braintreepayments.api.GooglePayClient
import com.braintreepayments.api.GooglePayRequest
import com.braintreepayments.api.ThreeDSecureClient
import com.braintreepayments.api.ThreeDSecureRequest
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Android implementation that bridges to the official Braintree SDK.
 */
class BraintreeNativeUiPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, ActivityAware {
  private lateinit var channel: MethodChannel
  private lateinit var context: Context
  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    context = binding.applicationContext
    channel = MethodChannel(binding.binaryMessenger, "braintree_native_ui")
    channel.setMethodCallHandler(this)
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }

  // ActivityAware
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getPlatformVersion" -> result.success("Android ${android.os.Build.VERSION.RELEASE}")
      "tokenizeCard" -> tokenize(call, result)
      "performThreeDSecure" -> threeDSecure(call, result)
      "collectDeviceData" -> collectDeviceData(call, result)
      "requestGooglePayPayment" -> googlePay(call, result)
      else -> result.notImplemented()
    }
  }

  private fun tokenize(call: MethodCall, result: MethodChannel.Result) {
    val authorization = call.argument<String>("authorization")
    val number = call.argument<String>("number")
    val expMonth = call.argument<String>("expirationMonth")
    val expYear = call.argument<String>("expirationYear")
    val cvv = call.argument<String>("cvv")

    if (authorization == null || number == null || expMonth == null || expYear == null) {
      result.error("arg_error", "Missing card parameters", null)
      return
    }

    val btClient = BraintreeClient(activity ?: context, authorization)
    val cardClient = CardClient(btClient)
    val card = Card()
    card.number = number
    card.expirationMonth = expMonth
    card.expirationYear = expYear
    card.cvv = cvv

    cardClient.tokenize(card) { cardNonce, error ->
      if (error != null) {
        result.error("tokenize_error", error.message, null)
      } else {
        result.success(cardNonce?.string)
      }
    }
  }

  private fun threeDSecure(call: MethodCall, result: MethodChannel.Result) {
    val authorization = call.argument<String>("authorization")
    val nonce = call.argument<String>("nonce")
    val amount = call.argument<String>("amount")

    val activity = activity
    if (authorization == null || nonce == null || amount == null || activity == null) {
      result.error("arg_error", "Missing parameters", null)
      return
    }

    val btClient = BraintreeClient(activity, authorization)
    val request = ThreeDSecureRequest()
    request.nonce = nonce
    request.amount = amount

    val threeDSClient = ThreeDSecureClient(btClient)
    threeDSClient.performVerification(activity, request) { threeDSResult, error ->
      if (error != null) {
        result.error("3ds_error", error.message, null)
      } else {
        result.success(threeDSResult?.tokenizedCard?.nonce)
      }
    }
  }

  private fun collectDeviceData(call: MethodCall, result: MethodChannel.Result) {
    val authorization = call.argument<String>("authorization")
    val activity = activity
    if (authorization == null || activity == null) {
      result.error("arg_error", "Missing parameters", null)
      return
    }

    val btClient = BraintreeClient(activity, authorization)
    val collector = DataCollector(btClient)
    collector.collectDeviceData(activity) { deviceData, error ->
      if (error != null) {
        result.error("collector_error", error.message, null)
      } else {
        result.success(deviceData)
      }
    }
  }

  private fun googlePay(call: MethodCall, result: MethodChannel.Result) {
    val authorization = call.argument<String>("authorization")
    val amount = call.argument<String>("amount")
    val currencyCode = call.argument<String>("currencyCode")
    val activity = activity
    if (authorization == null || amount == null || currencyCode == null || activity == null) {
      result.error("arg_error", "Missing parameters", null)
      return
    }

    val btClient = BraintreeClient(activity, authorization)
    val googlePayClient = GooglePayClient(btClient)
    val request = GooglePayRequest()
    request.totalPrice = amount
    request.currencyCode = currencyCode
    googlePayClient.requestPayment(activity, request) { nonce, error ->
      if (error != null) {
        result.error("google_pay_error", error.message, null)
      } else {
        result.success(nonce?.string)
      }
    }
  }
}
