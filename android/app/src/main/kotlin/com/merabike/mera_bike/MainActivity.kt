package com.merabike.mera_bike

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/// Backs lib/data/file_channel.dart: the system "Save as" / "Open" dialogs
/// for JSON backups, with no extra packages.
class MainActivity : FlutterActivity() {
    private var pendingResult: MethodChannel.Result? = null
    private var pendingText: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "merabike/files")
            .setMethodCallHandler { call, result ->
                if (pendingResult != null) {
                    result.error("busy", "A file dialog is already open", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "saveAs" -> {
                        pendingResult = result
                        pendingText = call.argument<String>("text")
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, call.argument<String>("fileName"))
                        }
                        startActivityForResult(intent, SAVE_REQUEST)
                    }
                    "open" -> {
                        pendingResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            // Some file providers don't label .json files, so allow any.
                            type = "*/*"
                        }
                        startActivityForResult(intent, OPEN_REQUEST)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // FlutterActivity is a plain Activity (not a ComponentActivity), so this
    // callback is how results come back.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != SAVE_REQUEST && requestCode != OPEN_REQUEST) return
        val result = pendingResult ?: return
        val text = pendingText
        pendingResult = null
        pendingText = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(if (requestCode == SAVE_REQUEST) false else null)
            return
        }
        try {
            if (requestCode == SAVE_REQUEST) {
                contentResolver.openOutputStream(uri, "w")!!.use {
                    it.write((text ?: "").toByteArray(Charsets.UTF_8))
                }
                result.success(true)
            } else {
                val bytes = contentResolver.openInputStream(uri)!!.use { it.readBytes() }
                result.success(bytes.toString(Charsets.UTF_8))
            }
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
    }

    private companion object {
        const val SAVE_REQUEST = 4101
        const val OPEN_REQUEST = 4102
    }
}
