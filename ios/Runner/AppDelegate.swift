
import UIKit
import Flutter
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // 🔥 알림 권한 요청
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // 🔥 MethodChannel 설정
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "com.sorinnydev.take_your_pills/notification",
      binaryMessenger: controller.binaryMessenger
    )

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 🔥 포그라운드에서 알림 수신 시 호출
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🍎 iOS 포그라운드 알림 수신")
    
    let userInfo = notification.request.content.userInfo
    if let payload = userInfo["payload"] as? String {
      print("   Payload: \(payload)")
      
      // 🔥 Flutter로 전달
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.methodChannel?.invokeMethod("onForegroundNotification", arguments: payload)
        print("   ✅ Flutter로 전달 완료")
      }
      
      // 🔥 알림 표시 안 함 (iOS 버전별 분기)
      if #available(iOS 14.0, *) {
        completionHandler([])
      } else {
        completionHandler([])
      }
    } else {
      print("   ⚠️  Payload 없음")
      
      // 🔥 iOS 버전별 알림 표시 옵션
      if #available(iOS 14.0, *) {
        completionHandler([.banner, .sound, .badge])
      } else {
        completionHandler([.alert, .sound, .badge])
      }
    }
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  }
  
  // 🔥 백그라운드에서 알림 탭 시 호출
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🍎 iOS 백그라운드 알림 탭")
    
    let userInfo = response.notification.request.content.userInfo
    if let payload = userInfo["payload"] as? String {
      print("   Payload: \(payload)")
      
      // 🔥 Flutter로 전달
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        self.methodChannel?.invokeMethod("onNotificationTap", arguments: payload)
        print("   ✅ Flutter로 전달 완료")
      }
    }
    
    completionHandler()
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  }
}
