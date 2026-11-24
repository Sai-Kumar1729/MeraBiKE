package com.merabike.mera_bike

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.DocumentsContract
import android.provider.DocumentsContract.Document
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

/// Backs lib/data/android_bridge.dart with no packages: the system Save as /
/// Open dialogs, a backup folder with lasting permission, the share sheet,
/// and the "Log refuel" home-screen shortcut.
class MainActivity : FlutterActivity() {
    private lateinit var channel: MethodChannel
    private var pendingResult: MethodChannel.Result? = null
    private var pendingText: String? = null
    private var launchAction: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        launchAction = shortcutAction(intent)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "merabike/android")
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "saveAs" -> startPicker(result, SAVE_REQUEST, Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    type = "application/json"
                    putExtra(Intent.EXTRA_TITLE, call.argument<String>("fileName"))
                }, call.argument<String>("text"))
                "open" -> startPicker(result, OPEN_REQUEST, Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                    addCategory(Intent.CATEGORY_OPENABLE)
                    // Some file providers don't label .json files, so allow any.
                    type = "*/*"
                }, null)
                "pickFolder" -> startPicker(result, FOLDER_REQUEST, Intent(Intent.ACTION_OPEN_DOCUMENT_TREE), null)
                "listFolder" -> inBackground(result) {
                    childDocuments(folder(call.argument("uri"))).map { it.second }
                }
                "writeToFolder" -> inBackground(result) {
                    writeFile(folder(call.argument("uri")), call.argument("name")!!, call.argument("text")!!)
                    null
                }
                "deleteFromFolder" -> inBackground(result) {
                    val tree = folder(call.argument("uri"))
                    val name = call.argument<String>("name")
                    childDocuments(tree).firstOrNull { it.second == name }?.let {
                        DocumentsContract.deleteDocument(
                            contentResolver,
                            DocumentsContract.buildDocumentUriUsingTree(tree, it.first),
                        )
                    }
                    null
                }
                "shareImage" -> {
                    try {
                        shareImage(call.argument("png")!!, call.argument("text") ?: "")
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("share", e.message, null)
                    }
                }
                "takeLaunchAction" -> {
                    result.success(launchAction)
                    launchAction = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        shortcutAction(intent)?.let { channel.invokeMethod("shortcut", it) }
    }

    private fun shortcutAction(intent: Intent?): String? =
        if (intent?.action == LOG_REFUEL_ACTION) "logRefuel" else null

    private fun startPicker(result: MethodChannel.Result, request: Int, intent: Intent, text: String?) {
        if (pendingResult != null) {
            result.error("busy", "A file dialog is already open", null)
            return
        }
        pendingResult = result
        pendingText = text
        startActivityForResult(intent, request)
    }

    // FlutterActivity is a plain Activity (not a ComponentActivity), so this
    // callback is how picker results come back.
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode !in setOf(SAVE_REQUEST, OPEN_REQUEST, FOLDER_REQUEST)) return
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
            when (requestCode) {
                SAVE_REQUEST -> {
                    contentResolver.openOutputStream(uri, "w")!!.use {
                        it.write((text ?: "").toByteArray(Charsets.UTF_8))
                    }
                    result.success(true)
                }
                OPEN_REQUEST -> {
                    val bytes = contentResolver.openInputStream(uri)!!.use { it.readBytes() }
                    result.success(bytes.toString(Charsets.UTF_8))
                }
                FOLDER_REQUEST -> {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                    result.success(mapOf("uri" to uri.toString(), "name" to folderName(uri)))
                }
            }
        } catch (e: Exception) {
            result.error("io", e.message, null)
        }
    }

    /// Runs file work off the UI thread and replies on it.
    private fun inBackground(result: MethodChannel.Result, work: () -> Any?) {
        Thread {
            try {
                val value = work()
                runOnUiThread { result.success(value) }
            } catch (e: Exception) {
                runOnUiThread { result.error("io", e.message, null) }
            }
        }.start()
    }

    /// The picked folder, if the app still has permission to write there.
    private fun folder(uri: String?): Uri {
        val tree = Uri.parse(uri ?: throw IOException("No backup folder"))
        val granted = contentResolver.persistedUriPermissions.any {
            it.uri == tree && it.isWritePermission
        }
        if (!granted) throw IOException("Access to the backup folder was lost. Pick the folder again.")
        return tree
    }

    private fun folderName(tree: Uri): String {
        val docUri = DocumentsContract.buildDocumentUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree),
        )
        contentResolver.query(docUri, arrayOf(Document.COLUMN_DISPLAY_NAME), null, null, null)?.use {
            if (it.moveToFirst()) return it.getString(0)
        }
        return "Backup folder"
    }

    /// (document id, display name) of the files directly in the folder.
    private fun childDocuments(tree: Uri): List<Pair<String, String>> {
        val children = DocumentsContract.buildChildDocumentsUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree),
        )
        val found = mutableListOf<Pair<String, String>>()
        contentResolver.query(
            children,
            arrayOf(Document.COLUMN_DOCUMENT_ID, Document.COLUMN_DISPLAY_NAME),
            null, null, null,
        )?.use { while (it.moveToNext()) found.add(it.getString(0) to it.getString(1)) }
        return found
    }

    private fun writeFile(tree: Uri, name: String, text: String) {
        val bytes = text.toByteArray(Charsets.UTF_8)
        val parent = DocumentsContract.buildDocumentUriUsingTree(
            tree, DocumentsContract.getTreeDocumentId(tree),
        )
        val existing = childDocuments(tree).firstOrNull { it.second == name }
        if (existing != null) {
            val doc = DocumentsContract.buildDocumentUriUsingTree(tree, existing.first)
            try {
                // "wt" truncates, so a shorter backup never leaves old bytes behind.
                contentResolver.openOutputStream(doc, "wt")!!.use { it.write(bytes) }
                return
            } catch (e: Exception) {
                // Some providers don't support "wt": replace the file instead.
                DocumentsContract.deleteDocument(contentResolver, doc)
            }
        }
        val created = DocumentsContract.createDocument(contentResolver, parent, "application/json", name)
            ?: throw IOException("Could not create $name")
        contentResolver.openOutputStream(created, "w")!!.use { it.write(bytes) }
    }

    private fun shareImage(png: ByteArray, text: String) {
        val dir = File(cacheDir, "shared").apply { mkdirs() }
        val file = File(dir, "merabike-mileage.png").apply { writeBytes(png) }
        val uri = FileProvider.getUriForFile(this, "$packageName.fileprovider", file)
        val send = Intent(Intent.ACTION_SEND).apply {
            type = "image/png"
            putExtra(Intent.EXTRA_STREAM, uri)
            putExtra(Intent.EXTRA_TEXT, text)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivity(Intent.createChooser(send, "Share your mileage"))
    }

    private companion object {
        const val SAVE_REQUEST = 4101
        const val OPEN_REQUEST = 4102
        const val FOLDER_REQUEST = 4103
        const val LOG_REFUEL_ACTION = "com.merabike.mera_bike.LOG_REFUEL"
    }
}
