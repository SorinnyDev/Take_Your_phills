
package com.sorinnydev.take_your_pills

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.util.Log
import android.app.NotificationManager
import android.service.notification.StatusBarNotification

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sorinnydev.take_your_pills/notification"
    private var methodChannel: MethodChannel? = null
    private var hasCheckedNotifications = false

    companion object {
        var isAppInForeground = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        Log.d("MainActivity", "✅ MethodChannel 초기화 완료")
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAppState" -> {
                    result.success(isAppInForeground)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onCreate 호출")
        
        handleNotificationIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onNewIntent 호출 (백그라운드 → 포그라운드)")
        
        handleNotificationIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onResume 호출 - 포그라운드 진입")
        
        isAppInForeground = true
        println("✅ MainActivity - 앱 포그라운드 진입")
        
        if (!hasCheckedNotifications) {
            hasCheckedNotifications = true
            checkAndHandleActiveNotifications()
        }
    }

    override fun onPause() {
        super.onPause()
        hasCheckedNotifications = false
        isAppInForeground = false
        Log.d("MainActivity", "🤖 onPause - 플래그 리셋")
        println("⏸️ MainActivity - 앱 백그라운드 진입")
    }

    private fun checkAndHandleActiveNotifications() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val activeNotifications = notificationManager.activeNotifications
        
        Log.d("MainActivity", "📦 활성 알림 개수: ${activeNotifications.size}")
        
        if (activeNotifications.size > 0) {
            val notification = activeNotifications[0]
            val extras = notification.notification.extras
            val payload = extras?.getString("payload")
            
            Log.d("MainActivity", "   ✅ 포그라운드 알림 감지: payload=$payload")
            
            for (n in activeNotifications) {
                notificationManager.cancel(n.id)
            }
            
            if (payload != null) {
                methodChannel?.invokeMethod("onForegroundNotification", payload)
                Log.d("MainActivity", "   ✅ Flutter로 포그라운드 알림 전달 완료")
            }
        } else {
            Log.d("MainActivity", "   ℹ️  활성 알림 없음")
        }
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private fun handleNotificationIntent(intent: Intent?) {
        if (intent == null) {
            Log.d("MainActivity", "   ⚠️  Intent가 null입니다")
            return
        }

        val reminderId = intent.getStringExtra("reminderId")
        if (reminderId != null) {
            Log.d("MainActivity", "📱 알림 탭 감지: reminderId=$reminderId")
            methodChannel?.invokeMethod("onNotificationTap", reminderId)
            return
        }

        val payload = intent.getStringExtra("payload")
        if (payload != null) {
            Log.d("MainActivity", "✅ Payload 발견: $payload")
            methodChannel?.invokeMethod("onNotificationTap", payload)
        }
    }
}
