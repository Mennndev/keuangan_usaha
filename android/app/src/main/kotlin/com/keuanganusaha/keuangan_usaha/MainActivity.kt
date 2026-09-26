package com.keuanganusaha.keuangan_usaha

import android.app.Activity
import android.content.Intent
import android.net.Uri
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var backupResult: MethodChannel.Result? = null
    private var saveResult: MethodChannel.Result? = null
    private var pendingBackupBytes: ByteArray? = null
    private var pendingBackupName: String? = null
    private val requestCode = 7402
    private val saveRequestCode = 7403

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "keuangan_usaha/backup")
            .setMethodCallHandler { call, result ->
                if (backupResult != null || saveResult != null) {
                    result.error("busy", "Pemilih file sedang dibuka.", null)
                    return@setMethodCallHandler
                }
                when (call.method) {
                    "openBackup" -> {
                        backupResult = result
                        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                        }
                        startActivityForResult(intent, requestCode)
                    }
                    "saveBackup" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        if (bytes == null || fileName == null) {
                            result.error("invalid", "Isi file cadangan tidak valid.", null)
                            return@setMethodCallHandler
                        }
                        pendingBackupBytes = bytes
                        pendingBackupName = fileName
                        saveResult = result
                        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
                            addCategory(Intent.CATEGORY_OPENABLE)
                            type = "application/json"
                            putExtra(Intent.EXTRA_TITLE, fileName)
                        }
                        startActivityForResult(intent, saveRequestCode)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    @Deprecated("Deprecated in Android; retained for the document picker result")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == saveRequestCode) {
            val pending = saveResult ?: return
            saveResult = null
            if (resultCode != Activity.RESULT_OK) {
                pendingBackupBytes = null
                pendingBackupName = null
                pending.success(false)
                return
            }
            try {
                val uri = data?.data ?: throw IllegalStateException("Folder tujuan tidak dipilih.")
                val bytes = pendingBackupBytes ?: throw IllegalStateException("Isi cadangan tidak tersedia.")
                contentResolver.openOutputStream(uri, "w")?.use { it.write(bytes) }
                    ?: throw IllegalStateException("File tidak dapat disimpan.")
                pending.success(true)
            } catch (error: Exception) {
                pending.error("save_failed", error.message, null)
            } finally {
                pendingBackupBytes = null
                pendingBackupName = null
            }
            return
        }
        if (requestCode != this.requestCode) return
        val pending = backupResult ?: return
        backupResult = null
        if (resultCode != Activity.RESULT_OK) {
            pending.success(null)
            return
        }
        val uri: Uri = data?.data ?: run {
            pending.error("empty", "File tidak dipilih.", null)
            return
        }
        try {
            val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
                ?: throw IllegalStateException("File tidak dapat dibaca.")
            pending.success(mapOf("bytes" to bytes))
        } catch (error: Exception) {
            pending.error("read_failed", error.message, null)
        }
    }
}
