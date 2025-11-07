
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

    // 🔥 앱이 포그라운드인지 추적
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
                    // 🔥 Flutter에서 앱 상태 확인 가능
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

    // 🔥 포그라운드 진입 시 활성 알림 확인 및 자동 처리
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

    // 🔥 활성 알림 확인 및 자동 처리
    private fun checkAndHandleActiveNotifications() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val activeNotifications: Array<StatusBarNotification> = notificationManager.activeNotifications
        
        Log.d("MainActivity", "📦 활성 알림 개수: ${activeNotifications.size}")
        
        for (notification in activeNotifications) {
            Log.d("MainActivity", "   알림 ID: ${notification.id} 제거")
            notificationManager.cancel(notification.id)
        }
        
        Log.d("MainActivity", "✅ 모든 알림 제거 완료")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private fun handleNotificationIntent(intent: Intent?) {
        intent?.let {
            val reminderId = it.getStringExtra("reminderId")
            if (reminderId != null) {
                println("📱 MainActivity - 알림 탭 감지: reminderId=$reminderId")
                
                methodChannel?.invokeMethod(
                    "onNotificationTap",
                    reminderId
                )
            } else {
                handleIntent(it)
            }
        }
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d("MainActivity", "   ⚠️  Intent가 null입니다")
            Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            return
        }
        
        Log.d("MainActivity", "📦 Intent 데이터:")
        Log.d("MainActivity", "   Action: ${intent.action}")
        Log.d("MainActivity", "   Data: ${intent.data}")
        Log.d("MainActivity", "   Extras: ${intent.extras}")
        
        // 🔥 flutter_local_notifications의 payload 추출
        val payload = intent.getStringExtra("payload")
        
        if (payload != null) {
            Log.d("MainActivity", "✅ Payload 발견: $payload")
            
            // 🔥 Flutter로 전달
            methodChannel?.invokeMethod("onNotificationTap", payload)
            
            Log.d("MainActivity", "✅ Flutter로 전달 완료")
        } else {
            Log.d("MainActivity", "   ⚠️  Payload 없음")
        }
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
