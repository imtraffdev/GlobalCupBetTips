import SwiftUI
import UIKit

@main
struct GlobalCupBetTipsApp: App {
    @UIApplicationDelegateAdaptor(GlobalCupAppDelegate.self) private var GlobalCupAppDelegateState

    var body: some Scene {
        WindowGroup {
            GlobalCupRootPresenter()
        }
    }
}

@MainActor
final class GlobalCupAppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        GlobalCupOrientationController.GlobalCupCurrent
    }
}

@MainActor
enum GlobalCupOrientationController {
    static var GlobalCupCurrent: UIInterfaceOrientationMask = .portrait {
        didSet {
            let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
            for scene in scenes {
                for window in scene.windows {
                    GlobalCupUpdate(from: window.rootViewController)
                }
                if #available(iOS 16.0, *) {
                    scene.requestGeometryUpdate(.iOS(interfaceOrientations: GlobalCupCurrent))
                }
            }
        }
    }

    private static func GlobalCupUpdate(from viewController: UIViewController?) {
        viewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        if let navigation = viewController as? UINavigationController {
            GlobalCupUpdate(from: navigation.visibleViewController)
        }
        if let tab = viewController as? UITabBarController {
            GlobalCupUpdate(from: tab.selectedViewController)
        }
        if let presented = viewController?.presentedViewController {
            GlobalCupUpdate(from: presented)
        }
    }
}
