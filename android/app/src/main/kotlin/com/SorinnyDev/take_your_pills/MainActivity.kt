
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
    private val checkInterval = 500L
    private var isCheckingNotification = false
    private val processedNotifications = mutableSetOf<Int>()
    
    companion object {
        var isAppInForeground = false
        var pendingNotificationPayload: String? = null
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateAppState" -> {
                    val isInForeground = call.argument<Boolean>("isInForeground") ?: false
                    isAppInForeground = isInForeground
                    Log.d("MainActivity", "📱 앱 상태 업데이트: $isInForeground")
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }

        Log.d("MainActivity", "✅ MethodChannel 설정 완료")
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🚀 MainActivity onCreate 호출")

        handleIntent(intent)

        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🔄 onNewIntent 호출")
        setIntent(intent)
        handleIntent(intent)
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }

    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d("MainActivity", "⚠️  Intent가 null입니다")
            return
        }

        val payload = intent.getStringExtra("payload")
        Log.d("MainActivity", "📦 Intent Payload: $payload")
        Log.d("MainActivity", "📱 현재 앱 상태: ${if (isAppInForeground) "포그라운드" else "백그라운드"}")

        if (payload != null) {
            if (isAppInForeground) {
                Log.d("MainActivity", "🔥 포그라운드 알림 → 즉시 Flutter 호출")
                sendToFlutter(payload)
            } else {
                Log.d("MainActivity", "⏳ 백그라운드 알림 → 대기 중...")
                pendingNotificationPayload = payload
                startNotificationCheck()
            }
        }
    }

    override fun onResume() {
        super.onResume()
        isAppInForeground = true

        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onResume 호출 - 포그라운드 진입")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        startNotificationCheck()
    }

    override fun onPause() {
        super.onPause()
        isAppInForeground = false

        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "⏸️ onPause 호출 - 백그라운드 진입")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        stopNotificationCheck()
        processedNotifications.clear()
    }

    private fun startNotificationCheck() {
        if (isCheckingNotification) {
            Log.d("MainActivity", "⚠️  이미 알림 체크 중")
            return
        }

        isCheckingNotification = true
        Log.d("MainActivity", "🔍 알림 체크 시작...")

        handler.post(object : Runnable {
            override fun run() {
                if (!isCheckingNotification) return

                // 🔥 1. 대기 중인 알림 처리
                if (methodChannel != null && pendingNotificationPayload != null) {
                    val payload = pendingNotificationPayload
                    pendingNotificationPayload = null

                    Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                    Log.d("MainActivity", "✅ Flutter 준비 완료 → 알림 전달")
                    Log.d("MainActivity", "   Payload: $payload")

                    sendToFlutter(payload!!)

                    Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
                }

                // 🔥 2. 활성 알림 체크 (포그라운드 전용)
                if (isAppInForeground) {
                    checkAndHandleActiveNotifications()
                }

                // 🔥 3. 다음 체크 예약
                handler.postDelayed(this, checkInterval)
            }
        })
    }

    private fun stopNotificationCheck() {
        isCheckingNotification = false
        handler.removeCallbacksAndMessages(null)
        Log.d("MainActivity", "🛑 알림 체크 중지")
    }

    private fun checkAndHandleActiveNotifications() {
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val activeNotifications: Array<StatusBarNotification> = notificationManager.activeNotifications

        if (activeNotifications.isEmpty()) {
            return
        }

        for (notification in activeNotifications) {
            val notificationId = notification.id
            
            // 🔥 이미 처리한 알림은 스킵
            if (processedNotifications.contains(notificationId)) {
                continue
            }

            // 🔥 우리 채널의 알림만 처리
            if (notification.notification.channelId != "medication_channel") {
                continue
            }

            Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
            Log.d("MainActivity", "🔔 활성 알림 감지!")
            Log.d("MainActivity", "   ID: $notificationId")
            Log.d("MainActivity", "   Channel: ${notification.notification.channelId}")
            
            // 🔥 알림 ID를 payload로 사용
            processedNotifications.add(notificationId)
            
            sendToFlutter(notificationId.toString())
            
            Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        }
    }

    private fun sendToFlutter(payload: String) {
        if (methodChannel == null) {
            Log.e("MainActivity", "❌ MethodChannel이 null입니다!")
            return
        }

        try {
            val reminderId = payload.toIntOrNull()
            if (reminderId == null) {
                Log.e("MainActivity", "❌ Payload를 Int로 변환 실패: $payload")
                return
            }

            Log.d("MainActivity", "🚀 Flutter 메서드 호출: onForegroundNotification")
            Log.d("MainActivity", "   ReminderId: $reminderId")

            methodChannel?.invokeMethod("onForegroundNotification", reminderId)

            Log.d("MainActivity", "✅ Flutter 호출 완료!")
        } catch (e: Exception) {
            Log.e("MainActivity", "❌ Flutter 호출 실패: ${e.message}")
            e.printStackTrace()
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        stopNotificationCheck()
        Log.d("MainActivity", "🛑 MainActivity onDestroy")
    }
}
