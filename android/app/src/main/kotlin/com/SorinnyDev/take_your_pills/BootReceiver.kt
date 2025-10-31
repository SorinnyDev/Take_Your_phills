
package com.sorinnydev.take_your_pills

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || 
            intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            
            Log.d("BootReceiver", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Log.d("BootReceiver", "🔄 재부팅 감지! 알림 재예약 시작...")
            Log.d("BootReceiver", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            
            // 🔥 앱 실행해서 알림 재예약
            val launchIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
            
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                launchIntent.putExtra("boot_completed", true)
                context.startActivity(launchIntent)
                Log.d("BootReceiver", "✅ 앱 실행 완료")
            } else {
                Log.e("BootReceiver", "❌ 앱 실행 실패")
            }
        }
    }
}
