package com.iwrqk.app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant.registerWith

class MainActivity: FlutterActivity() {
    private val backChannel = "android/on_back"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        registerWith(flutterEngine);
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, backChannel).setMethodCallHandler { methodCall, result ->
            if (methodCall.method == "backHome") {
                result.success(true)
                moveTaskToBack(false)
            }
        }
    }

    override fun onBackPressed() {
        flutterEngine?.dartExecutor?.binaryMessenger?.let { MethodChannel(it, backChannel).invokeMethod("onBack", null) }
    }
}
