
package com.sorinnydev.take_your_pills

import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.service.notification.StatusBarNotification
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.sorinnydev.take_your_pills/notification"
    private var methodChannel: MethodChannel? = null
    private val handler = Handler(Looper.getMainLooper())
    private var isAppInForeground = false
    private var notificationCheckRunnable: Runnable? = null

    companion object {
        private const val CHECK_INTERVAL = 500L // 0.5초마다 체크
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateAppState" -> {
                    val isInForeground = call.argument<Boolean>("isInForeground") ?: false
                    isAppInForeground = isInForeground
                    
                    Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    Log.d("MainActivity", "📱 앱 상태 업데이트: ${if (isInForeground) "포그라운드" else "백그라운드"}")
                    Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    
                    if (isInForeground) {
                        startNotificationCheck()
                    } else {
                        stopNotificationCheck()
                    }
                    
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 MainActivity onCreate")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onNewIntent 호출")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        handleIntent(intent)
    }

    override fun onResume() {
        super.onResume()
        isAppInForeground = true
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onResume 호출 - 포그라운드 진입")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // 🔥 포그라운드 진입 시 알림 체크 시작
        startNotificationCheck()
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onPause 호출 - 백그라운드 진입")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        
        // 🔥 백그라운드 진입 시 알림 체크 중지
        stopNotificationCheck()
    }

    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 🔥 알림 체크 시작 (0.5초마다 반복)
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private fun startNotificationCheck() {
        stopNotificationCheck() // 기존 체크 중지
        
        notificationCheckRunnable = object : Runnable {
            override fun run() {
                if (isAppInForeground) {
                    checkAndHandleActiveNotifications()
                    handler.postDelayed(this, CHECK_INTERVAL)
                }
            }
        }
        
        handler.post(notificationCheckRunnable!!)
        Log.d("MainActivity", "✅ 알림 체크 시작 (${CHECK_INTERVAL}ms 간격)")
    }

    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 🔥 알림 체크 중지
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private fun stopNotificationCheck() {
        notificationCheckRunnable?.let {
            handler.removeCallbacks(it)
            notificationCheckRunnable = null
            Log.d("MainActivity", "⏹️ 알림 체크 중지")
        }
    }

    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// 🔥 활성 알림 체크 및 Flutter 호출
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private fun checkAndHandleActiveNotifications() {
        try {
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            val activeNotifications: Array<StatusBarNotification> = notificationManager.activeNotifications
            
            if (activeNotifications.isNotEmpty()) {
                Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                Log.d("MainActivity", "🔔 활성 알림 감지: ${activeNotifications.size}개")
                
                for (notification in activeNotifications) {
                    val notificationId = notification.id
                    val extras = notification.notification.extras
                    val title = extras.getString("android.title")
                    
                    Log.d("MainActivity", "   📍 ID: $notificationId")
                    Log.d("MainActivity", "   📍 Title: $title")
                    
                    // 🔥 약 알림인 경우에만 처리
                    if (title?.contains("약 먹을 시간") == true) {
                        Log.d("MainActivity", "   ✅ 약 알림 확인! Flutter로 전달")
                        
                        // 🔥 Flutter로 reminderId 전달
                        methodChannel?.invokeMethod("onForegroundNotification", notificationId)
                        
                        // 🔥 알림 취소
                        notificationManager.cancel(notificationId)
                        Log.d("MainActivity", "   ✅ 알림 취소 완료")
                        
                        break // 하나만 처리
                    }
                }
                
                Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            }
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ 알림 체크 실패: ${e.message}")
        }
    }

    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    /// Intent 처리 (백그라운드에서 알림 탭 시)
    /// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
    private fun handleIntent(intent: Intent?) {
        intent?.let {
            Log.d("MainActivity", "🔍 Intent 확인")
            Log.d("MainActivity", "   Action: ${it.action}")
            Log.d("MainActivity", "   Extras: ${it.extras?.keySet()?.joinToString()}")
            
            // 🔥 알림 탭으로 실행된 경우
            if (it.hasExtra("notification_id")) {
                val notificationId = it.getIntExtra("notification_id", -1)
                Log.d("MainActivity", "   📍 Notification ID: $notificationId")
                
                if (notificationId != -1) {
                    // 🔥 Flutter로 전달
                    methodChannel?.invokeMethod("onNotificationTap", notificationId)
                    Log.d("MainActivity", "   ✅ Flutter로 알림 탭 전달 완료")
                }
            }
        }
    }
}
