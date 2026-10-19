import SwiftUI
import UIKit
import UserNotifications

@main
struct HydraApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var store = HydrationStore.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}

final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Il delegate va impostato all'avvio, così i pulsanti delle notifiche
        // funzionano anche quando l'app viene aperta in background.
        UNUserNotificationCenter.current().delegate = NotificationHandler.shared
        ReminderScheduler.registerCategories(settings: HydrationStore.shared.settings)
        return true
    }
}

final class NotificationHandler: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()

    // Mostra il promemoria anche se l'app è aperta.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let action = response.actionIdentifier
        DispatchQueue.main.async {
            HydrationStore.shared.handleNotificationAction(action, completion: completionHandler)
        }
    }
}
