import UIKit
import Flutter

@main
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
    
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  // 🔥 포그라운드 알림 수신
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    // 🔥 Flutter Local Notifications의 payload 가져오기
    let request = notification.request
    let identifier = request.identifier
    
    // 🔥 identifier에서 reminderId 추출 (flutter_local_notifications는 id를 identifier로 사용)
    let reminderId = Int(identifier) ?? 0
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🍎 iOS 포그라운드 알림 수신")
    print("   Identifier: \(identifier)")
    print("   ReminderId: \(reminderId)")
    
    // 🔥 Flutter로 전달
    methodChannel?.invokeMethod("onForegroundNotification", arguments: reminderId)
    
    // 🔥 시스템 알림 표시
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .badge])
    } else {
      completionHandler([.alert, .sound, .badge])
    }
    
    print("   ✅ Flutter 호출 완료")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
  }
  
  // 🔥 백그라운드 알림 탭
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let request = response.notification.request
    let identifier = request.identifier
    
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    print("🍎 iOS 백그라운드 알림 탭")
    print("   Identifier: \(identifier)")
    
    // 🔥 String으로 전달 (Flutter에서 int.tryParse로 변환)
    methodChannel?.invokeMethod("onNotificationTap", arguments: identifier)
    
    print("   ✅ Flutter 호출 완료")
    print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    
    completionHandler()
  }
}
