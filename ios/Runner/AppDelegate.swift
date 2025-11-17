
import UIKit
import Flutter
import flutter_local_notifications

@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(
      name: "com.sorinnydev.take_your_pills/notification",
      binaryMessenger: controller.binaryMessenger
    )
    
    // 🔥 알림 센터 델리게이트 설정
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 🔥 포그라운드에서 알림 수신 시 호출
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    let reminderId = userInfo["reminderId"] as? String ?? ""
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🍎 iOS 포그라운드 알림 수신")
    print("   ReminderId: \(reminderId)")
    
    // 🔥 Flutter로 알림 전달
    methodChannel?.invokeMethod("onForegroundNotification", arguments: reminderId)
    
    // 🔥 시스템 알림도 표시 (배너 + 소리 + 뱃지)
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
    
    print("   ✅ 시스템 알림 표시 완료")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  }
  
  // 🔥 백그라운드에서 알림 탭 시 호출
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    let reminderId = userInfo["reminderId"] as? String ?? ""
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🍎 iOS 백그라운드 알림 탭")
    print("   ReminderId: \(reminderId)")
    
    // 🔥 Flutter로 알림 전달
    methodChannel?.invokeMethod("onNotificationTap", arguments: reminderId)
    
    print("   ✅ Flutter 메서드 호출 완료")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    completionHandler()
  }
}
