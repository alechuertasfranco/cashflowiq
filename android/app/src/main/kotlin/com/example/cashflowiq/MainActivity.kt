package com.example.cashflowiq

import android.content.Intent
import android.net.Uri
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {

    private val channel = "cashflowiq/sharing"
    private var pendingImagePath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel)
            .setMethodCallHandler { call, result ->
                if (call.method == "getSharedImage") {
                    result.success(pendingImagePath)
                    pendingImagePath = null
                } else {
                    result.notImplemented()
                }
            }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleShareIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleShareIntent(intent)
    }

    private fun handleShareIntent(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND) return
        if (intent.type?.startsWith("image/") != true) return

        @Suppress("DEPRECATION")
        val uri: Uri = intent.getParcelableExtra(Intent.EXTRA_STREAM) ?: return

        val dest = File(cacheDir, "shared_${System.currentTimeMillis()}.jpg")
        try {
            contentResolver.openInputStream(uri)?.use { it.copyTo(dest.outputStream()) }
            pendingImagePath = dest.absolutePath
        } catch (_: Exception) {}
    }
}
