package io.flutter.plugins.share

import android.annotation.TargetApi
import android.app.Activity
import android.app.PendingIntent
import android.content.*
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.text.TextUtils
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugin.common.PluginRegistry.Registrar


/** SharePlugin */
public class SharePlugin: FlutterPlugin, MethodCallHandler {

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var methodChannel : MethodChannel
  private lateinit var eventChannel : EventChannel
  private lateinit var context: Context
  private var activity: Activity? = null
  private val receiver = ShareReceiver()

  private val messageStreamHandler = MessageStreamHandler()

  // This static function is optional and equivalent to onAttachedToEngine. It supports the old
  // pre-Flutter-1.12 Android projects. You are encouraged to continue supporting
  // plugin registration via this function while apps migrate to use the new Android APIs
  // post-flutter-1.12 via https://flutter.dev/go/android-project-migration.
  //
  // It is encouraged to share logic between onAttachedToEngine and registerWith to keep
  // them functionally equivalent. Only one of onAttachedToEngine or registerWith will be called
  // depending on the user's project. onAttachedToEngine or registerWith must both be defined
  // in the same class.
  companion object {
    @JvmStatic
    fun registerWith(registrar: Registrar) {
      val instance = SharePlugin()
      instance.context = registrar.context()
      instance.activity = registrar.activity()
      instance.methodChannel = MethodChannel(registrar.messenger(), CHANNEL_METHOD)
      instance.methodChannel.setMethodCallHandler(instance)
      instance.eventChannel = EventChannel(registrar.messenger(), CHANNEL_RECEIVER)
      instance.eventChannel.setStreamHandler(instance.messageStreamHandler)
    }

    private const val CHANNEL_METHOD = "plugins.flutter.io/share"
    private const val CHANNEL_RECEIVER = "plugins.flutter.io/receiveshare"
    
    const val TITLE = "title"
    const val TEXT = "text"
    const val PATH = "path"
    const val TYPE = "type"
    const val PACKAGE = "package"
    const val IS_MULTIPLE = "is_multiple"
    const val COUNT = "count"

    enum class ShareType(var mimeType: String) {

      TYPE_PLAIN_TEXT("text/plain"),
      TYPE_IMAGE("image/*"),
      TYPE_FILE("*/*");

      override fun toString(): String {
        return mimeType
      }

      companion object {
        fun fromMimeType(mimeType: String): ShareType? {
          for (shareType in values()) {
            if (shareType.mimeType == mimeType) {
              return shareType
            }
          }
          return null
        }
      }

    }
  }

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel = MethodChannel(flutterPluginBinding.getFlutterEngine().getDartExecutor(), CHANNEL_METHOD)
    methodChannel.setMethodCallHandler(this);
    eventChannel = EventChannel(flutterPluginBinding.flutterEngine.dartExecutor, CHANNEL_RECEIVER)
    eventChannel.setStreamHandler(messageStreamHandler)
  }

  /*
  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    instance.context = binding.activity
    instance.activity = binding.activity
  }
  */

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method.equals("share")) {
      require(call.arguments is Map<*, *>) { "Map argument expected" }
      // Android does not support showing the share sheet at a particular point on screen.
      val packageName = call.argument(PACKAGE) ?: ""
      val isMultiple = call.argument(IS_MULTIPLE) ?: false
      if (isMultiple) {
        val dataList = ArrayList<Uri>()
        var i = 0
        while (call.hasArgument(i.toString())) {
          dataList.add(Uri.parse(call.argument(i.toString()) ?: ""))
          i++
        }
        val type = call.argument(TYPE) ?: ""
        val title = call.argument(TITLE) ?: ""
        shareMultiple(dataList, type, title, packageName)
      } else {
        val shareType = ShareType.fromMimeType((call.argument(TYPE) ?: ""))
        val title = call.argument(TITLE) ?: ""
        val text = call.argument(TEXT) ?: ""
        val path = call.argument(PATH) ?: ""
        if (shareType == ShareType.TYPE_PLAIN_TEXT) {
          share(text, shareType, title, packageName)
        } else {
          share(path, text, shareType, title, packageName)
        }
      }
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    methodChannel.setMethodCallHandler(null)
    context.unregisterReceiver(receiver)
  }

  private fun share(text: String, shareType: ShareType, title: String, packageName: String) {
    share("", text, shareType, title, packageName)
  }

  private fun share(path: String?, text: String?, shareType: ShareType?, title: String, packageName: String) {
    require(!(ShareType.TYPE_PLAIN_TEXT != shareType && (path == null || path.isEmpty()))) { "Non-empty path expected" }
    require(!(ShareType.TYPE_PLAIN_TEXT == shareType && (text == null || text.isEmpty()))) { "Non-empty text expected" }
    requireNotNull(shareType) { "Non-empty mimeType expected" }

    val shareIntent = Intent().apply {
      action = Intent.ACTION_SEND
      type = shareType.toString()
      if (!TextUtils.isEmpty(packageName)) {
        setPackage(packageName)
      }
      if (!TextUtils.isEmpty(title)) {
        putExtra(Intent.EXTRA_SUBJECT, title)
      }
      if (shareType != ShareType.TYPE_PLAIN_TEXT) {
        putExtra(Intent.EXTRA_STREAM, Uri.parse(path))
        if (!TextUtils.isEmpty(text)) {
          putExtra(Intent.EXTRA_TEXT, text)
        }
      } else {
        putExtra(Intent.EXTRA_TEXT, text)
      }
    }

    val data = mapOf<String, Any>(
            PACKAGE to packageName,
            TYPE to shareType.mimeType,
            PATH to (path ?: ""),
            TEXT to (text ?: ""),
            TITLE to title
    )

    shareNow(shareIntent, data)
  }

  private fun shareMultiple(dataList: ArrayList<Uri>?, mimeType: String?, title: String, packageName: String) {
    require(!(dataList == null || dataList.isEmpty())) { "Non-empty data expected" }
    require(!(mimeType == null || mimeType.isEmpty())) { "Non-empty mimeType expected" }

    val shareIntent = Intent().apply {
      action = Intent.ACTION_SEND_MULTIPLE
      type = mimeType
      if (!TextUtils.isEmpty(packageName)) {
        setPackage(packageName)
      }
      if (!TextUtils.isEmpty(title)) {
        putExtra(Intent.EXTRA_SUBJECT, title)
      }
      putParcelableArrayListExtra(Intent.EXTRA_STREAM, dataList)
    }

    val data = mutableMapOf<String, Any>(
            PACKAGE to packageName,
            IS_MULTIPLE to true,
            TYPE to mimeType,
            TITLE to title,
            COUNT to dataList.size
    )
    dataList.forEachIndexed { index, uri -> data[index.toString()] = uri.toString() }

    shareNow(shareIntent, data)
  }

  private fun shareNow(target: Intent, data: Map<String, Any>) {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
      ShareReceiver.callback = { packageName ->
        messageStreamHandler.send(data.plus(PACKAGE to packageName))
      }
      val sender = ShareReceiver.getSharingSenderIntent(context)
      val chooserIntent = Intent.createChooser(target, null /* dialog title optional */, sender)
      activity?.startActivity(chooserIntent)
      return
    }

    val chooserIntent = Intent.createChooser(target, null /* dialog title optional */)
    if (activity != null) {
      activity!!.startActivity(chooserIntent)
    } else {
      chooserIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
      context.startActivity(chooserIntent)
    }
    messageStreamHandler.send(data.plus(PACKAGE to "unknown"))
  }

  class MessageStreamHandler : EventChannel.StreamHandler {

    private var eventSink: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
      eventSink = sink
    }

    fun send(data: Map<String, Any>) {
      Handler(Looper.getMainLooper()).post {
        eventSink?.success(data)
      }
    }

    override fun onCancel(p0: Any?) {
      eventSink = null
    }
  }

}
