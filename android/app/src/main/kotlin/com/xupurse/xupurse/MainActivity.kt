package com.xupurse.xupurse

import android.Manifest
import android.app.Activity
import android.content.ContentUris
import android.content.ContentValues
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.DocumentsContract
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * 定时备份落盘通道。
 *
 * 备份必须写在应用沙箱之外：应用私有目录（app_flutter）会随卸载一起被删，
 * 放在那里等于没有备份。两种落点：
 *  - 默认：MediaStore 写公共 `Download/XuPurse/`（Android 10+ 免运行时权限）。
 *  - 自选目录：用户通过 SAF（ACTION_OPEN_DOCUMENT_TREE）授权任意文件夹，
 *    拿到可持久化的树 URI 后按 DocumentsContract 读写；分区存储下这是
 *    唯一能写任意路径（含 SD 卡、中文目录名）的合规方式。
 */
class MainActivity : FlutterActivity() {
    private val channelName = "xupurse/public_backup"
    private val folder = "XuPurse"
    private val pickTreeRequest = 0x5150
    private var pendingPick: MethodChannel.Result? = null
    private val storagePermRequest = 0x5151

    /** Android 9 及以下：等权限结果后重试的那次写入。 */
    private var pendingSave: Triple<String, String, MethodChannel.Result>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        // —— 默认位置：公共 Download/XuPurse/ ——
                        "save" -> saveWithPermissionCheck(
                            call.argument<String>("name") ?: "",
                            call.argument<String>("content") ?: "",
                            result,
                        )
                        "read" -> result.success(read(call.argument<String>("name") ?: ""))
                        "list" -> result.success(list())
                        "delete" -> result.success(delete(call.argument<String>("name") ?: ""))
                        "location" -> result.success("Download/$folder/")
                        // —— 自选目录：SAF 树 URI ——
                        "pickTree" -> pickTree(result)
                        "saveTo" -> result.success(
                            saveTo(
                                treeArg(call),
                                call.argument<String>("name") ?: "",
                                call.argument<String>("content") ?: "",
                            ),
                        )
                        "readFrom" -> result.success(readFrom(treeArg(call), call.argument<String>("name") ?: ""))
                        "listIn" -> result.success(listIn(treeArg(call)))
                        "deleteIn" -> result.success(deleteIn(treeArg(call), call.argument<String>("name") ?: ""))
                        "treeLabel" -> result.success(treeLabel(treeArg(call)))
                        else -> result.notImplemented()
                    }
                } catch (t: Throwable) {
                    result.error("public_backup_failed", t.message ?: t.toString(), null)
                }
            }
    }

    private fun treeArg(call: MethodCall): Uri =
        Uri.parse(call.argument<String>("tree") ?: throw IllegalArgumentException("tree uri missing"))

    // —— SAF 目录选择 ——

    private fun pickTree(result: MethodChannel.Result) {
        if (pendingPick != null) {
            result.error("pick_in_progress", "已有目录选择窗口在等待", null)
            return
        }
        pendingPick = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
            // 让选择器直接暴露内部存储根，方便选 /storage/emulated/0/... 下的目录
            putExtra("android.content.extra.SHOW_ADVANCED", true)
        }
        try {
            startActivityForResult(intent, pickTreeRequest)
        } catch (t: Throwable) {
            pendingPick = null
            result.error("pick_failed", t.message ?: "无法打开目录选择器", null)
        }
    }

    @Deprecated("FlutterActivity 仍走 onActivityResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == pickTreeRequest) {
            val result = pendingPick
            pendingPick = null
            val uri = data?.data
            if (resultCode == Activity.RESULT_OK && uri != null) {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_GRANT_WRITE_URI_PERMISSION,
                    )
                } catch (_: SecurityException) {
                    // 某些第三方文件管理器不给持久化权限：本次仍可用，重启后需重选
                }
                result?.success(uri.toString())
            } else {
                result?.success(null) // 用户取消
            }
            return
        }
        super.onActivityResult(requestCode, resultCode, data)
    }

    /** 树 URI 的可读标签，如 `primary:1111/记账/xupurse`（Dart 侧再美化）。 */
    private fun treeLabel(tree: Uri): String = try {
        DocumentsContract.getTreeDocumentId(tree)
    } catch (_: Throwable) {
        tree.toString()
    }

    private fun childrenUri(tree: Uri): Uri = DocumentsContract.buildChildDocumentsUriUsingTree(
        tree,
        DocumentsContract.getTreeDocumentId(tree),
    )

    /** 在树里按文件名找 document uri；找不到返回 null。 */
    private fun findDoc(tree: Uri, name: String): Uri? {
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )
        contentResolver.query(childrenUri(tree), projection, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                if (cursor.getString(1) == name) {
                    return DocumentsContract.buildDocumentUriUsingTree(tree, cursor.getString(0))
                }
            }
        }
        return null
    }

    private fun saveTo(tree: Uri, name: String, content: String): String {
        if (name.isEmpty()) throw IllegalArgumentException("name is empty")
        val target = findDoc(tree, name) ?: run {
            val parent = DocumentsContract.buildDocumentUriUsingTree(
                tree,
                DocumentsContract.getTreeDocumentId(tree),
            )
            DocumentsContract.createDocument(contentResolver, parent, "application/json", name)
                ?: throw IllegalStateException("createDocument failed")
        }
        contentResolver.openOutputStream(target, "wt")?.use { out ->
            out.write(content.toByteArray(Charsets.UTF_8))
            out.flush()
        } ?: throw IllegalStateException("openOutputStream failed")
        return name
    }

    private fun readFrom(tree: Uri, name: String): String? {
        val doc = findDoc(tree, name) ?: return null
        contentResolver.openInputStream(doc)?.use { input ->
            return input.readBytes().toString(Charsets.UTF_8)
        }
        return null
    }

    private fun listIn(tree: Uri): List<Map<String, Any>> {
        val out = ArrayList<Map<String, Any>>()
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            DocumentsContract.Document.COLUMN_SIZE,
            DocumentsContract.Document.COLUMN_LAST_MODIFIED,
        )
        contentResolver.query(childrenUri(tree), projection, null, null, null)?.use { cursor ->
            while (cursor.moveToNext()) {
                out.add(
                    mapOf(
                        "name" to (cursor.getString(0) ?: ""),
                        "size" to if (cursor.isNull(1)) 0L else cursor.getLong(1),
                        "modified" to if (cursor.isNull(2)) 0L else cursor.getLong(2),
                    ),
                )
            }
        }
        return out
    }

    private fun deleteIn(tree: Uri, name: String): Boolean {
        val doc = findDoc(tree, name) ?: return false
        return try {
            DocumentsContract.deleteDocument(contentResolver, doc)
        } catch (_: Throwable) {
            false
        }
    }

    // —— 默认位置：公共 Download 目录 ——

    /** Android 9 及以下写公共目录需要 legacy 权限，缺就先向用户申请再写。 */
    private fun needsLegacyPermission(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.Q &&
            checkSelfPermission(Manifest.permission.WRITE_EXTERNAL_STORAGE) !=
            PackageManager.PERMISSION_GRANTED

    private fun saveWithPermissionCheck(name: String, content: String, result: MethodChannel.Result) {
        if (!needsLegacyPermission()) {
            result.success(save(name, content))
            return
        }
        if (pendingSave != null) {
            result.error("save_in_progress", "正在等待存储权限授权", null)
            return
        }
        pendingSave = Triple(name, content, result)
        try {
            requestPermissions(arrayOf(Manifest.permission.WRITE_EXTERNAL_STORAGE), storagePermRequest)
        } catch (t: Throwable) {
            pendingSave = null
            result.error("permission_failed", t.message ?: "无法申请存储权限", null)
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        if (requestCode == storagePermRequest) {
            val pending = pendingSave
            pendingSave = null
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            if (pending != null) {
                if (granted) {
                    try {
                        pending.third.success(save(pending.first, pending.second))
                    } catch (t: Throwable) {
                        pending.third.error("public_backup_failed", t.message ?: t.toString(), null)
                    }
                } else {
                    pending.third.error(
                        "permission_denied",
                        "未授予「存储」权限，自动备份无法写入公共 Download/XuPurse/，请到系统设置里允许",
                        null,
                    )
                }
            }
            return
        }
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    }

    private fun relativePath(): String = "${Environment.DIRECTORY_DOWNLOADS}/$folder/"

    private fun collectionUri(): Uri =
        MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)

    /** 写入（同名覆盖）。返回展示路径。 */
    private fun save(name: String, content: String): String {
        if (name.isEmpty()) throw IllegalArgumentException("name is empty")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = collectionUri()
            val where = "${MediaStore.Downloads.DISPLAY_NAME}=? AND ${MediaStore.Downloads.RELATIVE_PATH}=?"
            val args = arrayOf(name, relativePath())
            var uri: Uri? = null
            contentResolver.query(collection, arrayOf(MediaStore.Downloads._ID), where, args, null)
                ?.use { cursor -> if (cursor.moveToFirst()) uri = ContentUris.withAppendedId(collection, cursor.getLong(0)) }

            val target = uri ?: run {
                val values = ContentValues().apply {
                    put(MediaStore.Downloads.DISPLAY_NAME, name)
                    put(MediaStore.Downloads.MIME_TYPE, "application/json")
                    put(MediaStore.Downloads.RELATIVE_PATH, relativePath())
                    put(MediaStore.Downloads.IS_PENDING, 1)
                }
                contentResolver.insert(collection, values) ?: throw IllegalStateException("insert failed")
            }
            contentResolver.openOutputStream(target, "wt")?.use { out ->
                out.write(content.toByteArray(Charsets.UTF_8))
                out.flush()
            } ?: throw IllegalStateException("openOutputStream failed")
            contentResolver.update(
                target,
                ContentValues().apply { put(MediaStore.Downloads.IS_PENDING, 0) },
                null,
                null,
            )
            return "Download/$folder/$name"
        }

        // Android 9 及以下：直接写公共下载目录（Manifest 已按 maxSdk=28 申请 legacy 权限）
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), folder)
        if (!dir.exists() && !dir.mkdirs()) throw IllegalStateException("mkdirs failed: $dir")
        val file = File(dir, name)
        file.writeText(content)
        return file.absolutePath
    }

    /** 读取；不存在返回 null。 */
    private fun read(name: String): String? {
        if (name.isEmpty()) return null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = collectionUri()
            val where = "${MediaStore.Downloads.DISPLAY_NAME}=? AND ${MediaStore.Downloads.RELATIVE_PATH}=?"
            val args = arrayOf(name, relativePath())
            contentResolver.query(collection, arrayOf(MediaStore.Downloads._ID), where, args, null)
                ?.use { cursor ->
                    if (!cursor.moveToFirst()) return null
                    val uri = ContentUris.withAppendedId(collection, cursor.getLong(0))
                    contentResolver.openInputStream(uri)?.use { input ->
                        return input.readBytes().toString(Charsets.UTF_8)
                    }
                }
            return null
        }
        val file = File(
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), folder),
            name,
        )
        return if (file.exists()) file.readText() else null
    }

    /** 列出目录下所有文件（name/size/modified）。 */
    private fun list(): List<Map<String, Any>> {
        val out = ArrayList<Map<String, Any>>()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = collectionUri()
            val projection = arrayOf(
                MediaStore.Downloads.DISPLAY_NAME,
                MediaStore.Downloads.SIZE,
                MediaStore.Downloads.DATE_MODIFIED,
            )
            contentResolver.query(
                collection,
                projection,
                "${MediaStore.Downloads.RELATIVE_PATH}=?",
                arrayOf(relativePath()),
                "${MediaStore.Downloads.DATE_MODIFIED} DESC",
            )?.use { cursor ->
                while (cursor.moveToNext()) {
                    out.add(
                        mapOf(
                            "name" to (cursor.getString(0) ?: ""),
                            "size" to cursor.getLong(1),
                            "modified" to cursor.getLong(2) * 1000L,
                        ),
                    )
                }
            }
            return out
        }
        val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), folder)
        dir.listFiles()?.forEach { f ->
            if (f.isFile) {
                out.add(mapOf("name" to f.name, "size" to f.length(), "modified" to f.lastModified()))
            }
        }
        return out
    }

    /** 删除；返回是否删掉。 */
    private fun delete(name: String): Boolean {
        if (name.isEmpty()) return false
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val collection = collectionUri()
            val where = "${MediaStore.Downloads.DISPLAY_NAME}=? AND ${MediaStore.Downloads.RELATIVE_PATH}=?"
            val args = arrayOf(name, relativePath())
            return contentResolver.delete(collection, where, args) > 0
        }
        val file = File(
            File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), folder),
            name,
        )
        return file.exists() && file.delete()
    }
}
