package io.flutter.plugins.share

import android.annotation.TargetApi
import android.app.PendingIntent
import android.content.*
import android.os.Build

class ShareReceiver : BroadcastReceiver() {

    companion object {
        private val LOCK = Object()

        private const val EXTRA_RECEIVER_TOKEN = "receiver_token"

        private var sTargetChosenReceiveAction: String? = null
        private var sLastRegisteredReceiver: ShareReceiver? = null
        var callback: ((packageName: String) -> Unit)? = null

        @TargetApi(Build.VERSION_CODES.LOLLIPOP_MR1)
        fun getSharingSenderIntent(context: Context): IntentSender {
            synchronized (LOCK) {
                if (sTargetChosenReceiveAction == null) {
                    sTargetChosenReceiveAction = "${context.packageName}/${ShareReceiver::class.java.name}_ACTION"
                }
                if (sLastRegisteredReceiver != null) {
                    context.unregisterReceiver(sLastRegisteredReceiver)
                }
                sLastRegisteredReceiver = ShareReceiver()
                context.registerReceiver(sLastRegisteredReceiver, IntentFilter(sTargetChosenReceiveAction))
            }

            val receiver = Intent(sTargetChosenReceiveAction).apply {
                setPackage(context.packageName)
                putExtra(EXTRA_RECEIVER_TOKEN, sLastRegisteredReceiver.hashCode())
            }
            val pendingIntent = PendingIntent.getBroadcast(context, 0, receiver, PendingIntent.FLAG_CANCEL_CURRENT or PendingIntent.FLAG_ONE_SHOT)
            return pendingIntent.intentSender
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        synchronized (LOCK) {
            if (sLastRegisteredReceiver != this) return;
            context.applicationContext.unregisterReceiver(sLastRegisteredReceiver);
            sLastRegisteredReceiver = null;
        }

        if (!intent.hasExtra(EXTRA_RECEIVER_TOKEN) || intent.getIntExtra(EXTRA_RECEIVER_TOKEN, 0) != this.hashCode()) {
            return
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val target: ComponentName? = intent.getParcelableExtra(Intent.EXTRA_CHOSEN_COMPONENT)
            val packageName = target?.flattenToString() ?: ""
            callback?.invoke(packageName)
            callback = null
        }
    }

}