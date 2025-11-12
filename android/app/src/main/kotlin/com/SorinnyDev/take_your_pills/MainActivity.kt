
package com.sorinnydev.take_your_pills

import android.content.Intent
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import android.util.Log
import android.app.NotificationManager
import android.content.Context
import android.os.Handler
import android.os.Looper

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sorinnydev.take_your_pills/notification"
    private var methodChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())

    companion object {
        var isAppInForeground = false
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateAppState" -> {
                    val isInForeground = call.argument<Boolean>("isInForeground") ?: false
                    isAppInForeground = isInForeground
                    Log.d("MainActivity", "📱 앱 상태 업데이트: ${if (isInForeground) "포그라운드" else "백그라운드"}")
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
        
        Log.d("MainActivity", "✅ MethodChannel 초기화 완료")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onCreate 호출")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    override fun onResume() {
        super.onResume()
        isAppInForeground = true
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onResume 호출 - 포그라운드 진입")
        println("✅ MainActivity - 앱 포그라운드 진입")
        
        // 🔥 약간의 딜레이 후 알림 체크 (알림이 표시될 시간을 줌)
        handler.postDelayed({
            checkAndHandleActiveNotifications()
        }, 100)
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false
        
        Log.d("MainActivity", "🤖 onPause - 플래그 리셋")
        println("⏸️ MainActivity - 앱 백그라운드 진입")
    }

    // 🔥 활성 알림 체크 및 처리
    private fun checkAndHandleActiveNotifications() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val activeNotifications = notificationManager.activeNotifications
        
        Log.d("MainActivity", "📦 활성 알림 개수: ${activeNotifications.size}")
        
        if (activeNotifications.isNotEmpty()) {
            for (notification in activeNotifications) {
                val extras = notification.notification.extras
                val payload = extras?.getString("payload")
                
                Log.d("MainActivity", "   ✅ 알림 감지: id=${notification.id}, payload=$payload")
                
                // 🔥 알림 제거
                notificationManager.cancel(notification.id)
                
                // 🔥 Flutter로 전달 (String이 아닌 Int로!)
                if (payload != null) {
                    val reminderId = payload.toIntOrNull()
                    if (reminderId != null) {
                        Log.d("MainActivity", "   🚀 Flutter로 전달: $reminderId (Int)")
                        methodChannel?.invokeMethod("onForegroundNotification", reminderId) // 🔥 Int로 전달
                    } else {
                        Log.e("MainActivity", "   ❌ Payload를 Int로 변환 실패: $payload")
                    }
                }
            }
        } else {
            Log.d("MainActivity", "   ℹ️  활성 알림 없음")
        }
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🔔 onNewIntent 호출")
        
        // 🔥 백그라운드에서 알림 탭한 경우
        if (!isAppInForeground) {
            val payload = intent.getStringExtra("payload")
            Log.d("MainActivity", "   ✅ 백그라운드 알림 탭 - Payload: $payload")
            
            if (payload != null) {
                val reminderId = payload.toIntOrNull()
                if (reminderId != null) {
                    methodChannel?.invokeMethod("onNotificationTap", reminderId)
                    Log.d("MainActivity", "   ✅ Flutter로 백그라운드 알림 전달 완료")
                }
            }
        }
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
