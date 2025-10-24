
package com.sorinnydev.take_your_pills  // 🔥 소문자로 수정

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Bundle
import android.util.Log

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.sorinnydev.take_your_pills/notification"
    private var methodChannel: MethodChannel? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 MainActivity 초기화")
        
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        )
        
        Log.d("MainActivity", "✅ MethodChannel 생성 완료")
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onCreate 호출")
        
        // 🔥 앱이 종료된 상태에서 알림 탭으로 실행된 경우
        handleIntent(intent)
    }
    
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
        Log.d("MainActivity", "🤖 onNewIntent 호출")
        
        // 🔥 앱이 백그라운드에 있을 때 알림 탭
        handleIntent(intent)
    }
    
    private fun handleIntent(intent: Intent?) {
        if (intent == null) {
            Log.d("MainActivity", "❌ Intent가 null")
            return
        }
        
        Log.d("MainActivity", "📦 Intent 데이터:")
        Log.d("MainActivity", "   Action: ${intent.action}")
        Log.d("MainActivity", "   Data: ${intent.data}")
        Log.d("MainActivity", "   Extras: ${intent.extras}")
        
        // 🔥 알림에서 전달된 payload 확인
        val payload = intent.getStringExtra("payload")
        
        if (payload != null) {
            Log.d("MainActivity", "✅ Payload 발견: $payload")
            
            // 🔥 Flutter로 reminderId 전달
            methodChannel?.invokeMethod("onNotificationTap", payload)
            Log.d("MainActivity", "✅ Flutter로 전달 완료")
        } else {
            Log.d("MainActivity", "❌ Payload를 찾을 수 없음")
            
            // 🔥 extras에서 찾아보기
            intent.extras?.let { extras ->
                for (key in extras.keySet()) {
                    val value = extras.get(key)
                    Log.d("MainActivity", "   Extra - $key: $value")
                }
            }
        }
        
        Log.d("MainActivity", "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    }
}
