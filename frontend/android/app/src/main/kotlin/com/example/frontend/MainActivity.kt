package com.example.frontend

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.finwise/upi"
    private val UPI_REQUEST_CODE = 123
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "launchUpi") {
                val uriStr = call.argument<String>("uri")
                if (uriStr != null) {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_VIEW)
                    intent.data = Uri.parse(uriStr)
                    val chooser = Intent.createChooser(intent, "Pay with")
                    if (chooser.resolveActivity(packageManager) != null) {
                        startActivityForResult(chooser, UPI_REQUEST_CODE)
                    } else {
                        result.error("APP_NOT_FOUND", "No UPI app found", null)
                        pendingResult = null
                    }
                } else {
                    result.error("INVALID_URI", "URI cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == UPI_REQUEST_CODE) {
            if (data != null) {
                val res = data.getStringExtra("response") ?: "No Response"
                pendingResult?.success(res)
            } else {
                pendingResult?.success("Canceled")
            }
            pendingResult = null
        }
    }
}
