import FirebaseCore
import FirebaseMessaging
import Flutter
import UIKit
import UserNotifications

fileprivate var pendingApnsToken: Data?
fileprivate var lastApnsError: String?

fileprivate func deliverApnsToken() {
  guard let token = pendingApnsToken, FirebaseApp.app() != nil else { return }
  Messaging.messaging().setAPNSToken(token, type: .unknown)
  pendingApnsToken = nil
  lastApnsError = nil
}

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    application.registerForRemoteNotifications()
    return launched
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    pendingApnsToken = deviceToken
    deliverApnsToken()
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    lastApnsError = error.localizedDescription
    NSLog("APNs register failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    application.registerForRemoteNotifications()
    deliverApnsToken()
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if notification.request.content.userInfo["gcm.message_id"] != nil {
      completionHandler([.badge])
      return
    }
    completionHandler([.alert, .badge, .sound])
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    completionHandler()
  }
}

fileprivate var pluginsRegistered = false
fileprivate var pushChannelInstalled = false

fileprivate func registerPlugins(on controller: FlutterViewController) {
  if pluginsRegistered { return }
  pluginsRegistered = true
  controller.loadViewIfNeeded()
  GeneratedPluginRegistrant.register(with: controller)
}

fileprivate func installPushChannel(on controller: FlutterViewController) {
  if pushChannelInstalled { return }
  pushChannelInstalled = true
  let channel = FlutterMethodChannel(
    name: "e_auction/push",
    binaryMessenger: controller.binaryMessenger
  )
  channel.setMethodCallHandler { call, result in
    if call.method == "registerApns" {
      let center = UNUserNotificationCenter.current()
      center.getNotificationSettings { settings in
        let finish: (String?) -> Void = { message in
          DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
            deliverApnsToken()
            result(message ?? lastApnsError)
          }
        }
        switch settings.authorizationStatus {
        case .denied:
          finish("การแจ้งเตือนถูกปิดในตั้งค่าของ iPhone")
        case .notDetermined:
          center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if let error {
              finish(error.localizedDescription)
              return
            }
            finish(granted ? nil : "ยังไม่อนุญาตการแจ้งเตือน")
          }
        default:
          finish(nil)
        }
      }
      return
    }
    result(FlutterMethodNotImplemented)
  }
}

fileprivate func forwardOpenURLs(_ contexts: Set<UIOpenURLContext>) {
  let application = UIApplication.shared
  guard let delegate = application.delegate else { return }
  for context in contexts {
    var options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    if let source = context.options.sourceApplication {
      options[.sourceApplication] = source
    }
    if let annotation = context.options.annotation {
      options[.annotation] = annotation
    }
    _ = delegate.application?(application, open: context.url, options: options)
  }
}

/// iOS 27 ที่คอมไพล์ด้วย Xcode 27 ต้องเปิดแอปผ่าน UIScene ไม่งั้นระบบปิดแอปทันที
@objc(SceneDelegate)
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  var window: UIWindow?

  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    guard let windowScene = scene as? UIWindowScene else { return }

    let activeWindow: UIWindow
    if let existing = window ?? windowScene.windows.first {
      window = existing
      activeWindow = existing
    } else {
      let created = UIWindow(windowScene: windowScene)
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      created.rootViewController = storyboard.instantiateInitialViewController()
      created.makeKeyAndVisible()
      window = created
      activeWindow = created
    }

    if let appDelegate = UIApplication.shared.delegate as? FlutterAppDelegate {
      appDelegate.window = activeWindow
    }
    if activeWindow.rootViewController == nil {
      let storyboard = UIStoryboard(name: "Main", bundle: nil)
      activeWindow.rootViewController = storyboard.instantiateInitialViewController()
      activeWindow.makeKeyAndVisible()
    }
    if let controller = activeWindow.rootViewController as? FlutterViewController {
      registerPlugins(on: controller)
      installPushChannel(on: controller)
    }
    if !connectionOptions.urlContexts.isEmpty {
      forwardOpenURLs(connectionOptions.urlContexts)
    }
  }

  func sceneDidBecomeActive(_ scene: UIScene) {
    UIApplication.shared.registerForRemoteNotifications()
    deliverApnsToken()
  }

  func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
    forwardOpenURLs(URLContexts)
  }

  func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
    let application = UIApplication.shared
    _ = application.delegate?.application?(application, continue: userActivity) { _ in }
  }
}
