package com.example.eclub_app

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.workmanager.WorkmanagerPlugin

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.eclub_app/audio_processing"

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Register the background service plugin
        WorkmanagerPlugin.setPluginRegistrantCallback { flutterEngine ->
            // Your other plugins can be registered here
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getSpectrogram") {
                val path = call.argument<String>("path")
                if (path != null) {
                    try {
                        val spectrogram = SpectrogramUtil.getSpectrogram(path)
                        result.success(spectrogram)
                    } catch (e: Exception) {
                        result.error("SPECTROGRAM_ERROR", "Error generating spectrogram: ${e.message}", null)
                    }
                } else {
                    result.error("INVALID_ARGUMENT", "File path cannot be null", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}