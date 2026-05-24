import SwiftUI
import UIKit
import WebKit

final class GlobalCupWebNavigationController: ObservableObject {
    @Published var GlobalCupCanGoBack = false
    @Published var GlobalCupCanGoForward = false

    private weak var GlobalCupWebView: WKWebView?

    func GlobalCupAttach(_ GlobalCupWebView: WKWebView) {
        self.GlobalCupWebView = GlobalCupWebView
        GlobalCupUpdateState()
    }

    func GlobalCupUpdateState() {
        GlobalCupCanGoBack = GlobalCupWebView?.canGoBack ?? false
        GlobalCupCanGoForward = GlobalCupWebView?.canGoForward ?? false
    }

    func GlobalCupGoBack() {
        guard let GlobalCupWebView, GlobalCupWebView.canGoBack else { return }
        GlobalCupWebView.goBack()
        GlobalCupUpdateStateSoon()
    }

    func GlobalCupGoForward() {
        guard let GlobalCupWebView, GlobalCupWebView.canGoForward else { return }
        GlobalCupWebView.goForward()
        GlobalCupUpdateStateSoon()
    }

    private func GlobalCupUpdateStateSoon() {
        GlobalCupUpdateState()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.GlobalCupUpdateState()
        }
    }
}

struct GlobalCupGateWebContainer: View {
    let GlobalCupURL: URL
    let GlobalCupOnBlockedResponse: () -> Void
    @State private var GlobalCupIsVisible = false
    @StateObject private var GlobalCupNavigationController = GlobalCupWebNavigationController()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlobalCupGateWebView(GlobalCupURL: GlobalCupURL, GlobalCupOnReady: {
                GlobalCupIsVisible = true
            }, GlobalCupOnBlockedResponse: GlobalCupOnBlockedResponse, GlobalCupOnWebViewReady: { GlobalCupWebView in
                GlobalCupNavigationController.GlobalCupAttach(GlobalCupWebView)
            }, GlobalCupOnNavigationStateChange: { GlobalCupCanGoBack, GlobalCupCanGoForward in
                GlobalCupNavigationController.GlobalCupCanGoBack = GlobalCupCanGoBack
                GlobalCupNavigationController.GlobalCupCanGoForward = GlobalCupCanGoForward
            })
            .opacity(GlobalCupIsVisible ? 1 : 0)

            GlobalCupWebNavigationOverlay(
                GlobalCupCanGoBack: GlobalCupNavigationController.GlobalCupCanGoBack,
                GlobalCupCanGoForward: GlobalCupNavigationController.GlobalCupCanGoForward,
                GlobalCupGoBack: GlobalCupNavigationController.GlobalCupGoBack,
                GlobalCupGoForward: GlobalCupNavigationController.GlobalCupGoForward
            )
            .opacity(GlobalCupIsVisible ? 1 : 0)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            GlobalCupOrientationController.GlobalCupCurrent = UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
        }
        .onDisappear {
            GlobalCupOrientationController.GlobalCupCurrent = .portrait
        }
    }
}

struct GlobalCupGateWebView: UIViewRepresentable {
    let GlobalCupURL: URL
    let GlobalCupOnReady: () -> Void
    let GlobalCupOnBlockedResponse: () -> Void
    let GlobalCupOnWebViewReady: (WKWebView) -> Void
    let GlobalCupOnNavigationStateChange: (Bool, Bool) -> Void

    func makeCoordinator() -> GlobalCupCoordinator {
        GlobalCupCoordinator(
            GlobalCupOnReady: GlobalCupOnReady,
            GlobalCupOnBlockedResponse: GlobalCupOnBlockedResponse,
            GlobalCupOnNavigationStateChange: GlobalCupOnNavigationStateChange
        )
    }

    func makeUIView(context GlobalCupContext: Context) -> WKWebView {
        let GlobalCupConfiguration = WKWebViewConfiguration()
        GlobalCupConfiguration.websiteDataStore = .default()
        GlobalCupConfiguration.allowsInlineMediaPlayback = true
        GlobalCupConfiguration.allowsAirPlayForMediaPlayback = true
        GlobalCupConfiguration.defaultWebpagePreferences.allowsContentJavaScript = true
        GlobalCupConfiguration.preferences.javaScriptCanOpenWindowsAutomatically = true
        GlobalCupConfiguration.mediaTypesRequiringUserActionForPlayback = []

        let GlobalCupWebView = WKWebView(frame: .zero, configuration: GlobalCupConfiguration)
        GlobalCupWebView.navigationDelegate = GlobalCupContext.coordinator
        GlobalCupWebView.uiDelegate = GlobalCupContext.coordinator
        GlobalCupWebView.allowsBackForwardNavigationGestures = true
        GlobalCupWebView.customUserAgent = GlobalCupWebUserAgent.GlobalCupSafariLike
        GlobalCupWebView.isOpaque = true
        GlobalCupWebView.backgroundColor = .black
        GlobalCupWebView.scrollView.backgroundColor = .black
        GlobalCupWebView.scrollView.contentInsetAdjustmentBehavior = .automatic
        GlobalCupContext.coordinator.GlobalCupWebView = GlobalCupWebView
        GlobalCupOnWebViewReady(GlobalCupWebView)
        GlobalCupWebView.load(GlobalCupWebUserAgent.GlobalCupSafariRequest(GlobalCupURL: GlobalCupURL))
        return GlobalCupWebView
    }

    func updateUIView(_ GlobalCupWebView: WKWebView, context GlobalCupContext: Context) {}

    final class GlobalCupCoordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let GlobalCupOnReady: () -> Void
        let GlobalCupOnBlockedResponse: () -> Void
        let GlobalCupOnNavigationStateChange: (Bool, Bool) -> Void
        weak var GlobalCupWebView: WKWebView?

        init(
            GlobalCupOnReady: @escaping () -> Void,
            GlobalCupOnBlockedResponse: @escaping () -> Void,
            GlobalCupOnNavigationStateChange: @escaping (Bool, Bool) -> Void
        ) {
            self.GlobalCupOnReady = GlobalCupOnReady
            self.GlobalCupOnBlockedResponse = GlobalCupOnBlockedResponse
            self.GlobalCupOnNavigationStateChange = GlobalCupOnNavigationStateChange
        }

        func webView(_ GlobalCupWebView: WKWebView, decidePolicyFor GlobalCupNavigationAction: WKNavigationAction, decisionHandler GlobalCupDecisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let GlobalCupURL = GlobalCupNavigationAction.request.url else {
                GlobalCupDecisionHandler(.allow)
                return
            }
            if GlobalCupNavigationAction.targetFrame == nil, ["http", "https"].contains(GlobalCupURL.scheme?.lowercased()) {
                GlobalCupWebView.load(GlobalCupNavigationAction.request)
                GlobalCupDecisionHandler(.cancel)
                return
            }
            if let GlobalCupScheme = GlobalCupURL.scheme?.lowercased(), !["http", "https", "about"].contains(GlobalCupScheme) {
                UIApplication.shared.open(GlobalCupURL)
                GlobalCupDecisionHandler(.cancel)
                return
            }
            GlobalCupDecisionHandler(.allow)
        }

        func webView(_ GlobalCupWebView: WKWebView, didCommit GlobalCupNavigation: WKNavigation!) {
            GlobalCupUpdateNavigationState(GlobalCupWebView)
        }

        func webView(_ GlobalCupWebView: WKWebView, didFinish GlobalCupNavigation: WKNavigation!) {
            GlobalCupUpdateNavigationState(GlobalCupWebView)
        }

        func webView(_ GlobalCupWebView: WKWebView, didFail GlobalCupNavigation: WKNavigation!, withError GlobalCupError: Error) {
            GlobalCupUpdateNavigationState(GlobalCupWebView)
        }

        func webView(_ GlobalCupWebView: WKWebView, didFailProvisionalNavigation GlobalCupNavigation: WKNavigation!, withError GlobalCupError: Error) {
            GlobalCupUpdateNavigationState(GlobalCupWebView)
        }

        func webView(_ GlobalCupWebView: WKWebView, decidePolicyFor GlobalCupNavigationResponse: WKNavigationResponse, decisionHandler GlobalCupDecisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if GlobalCupNavigationResponse.isForMainFrame,
               let GlobalCupResponse = GlobalCupNavigationResponse.response as? HTTPURLResponse,
               (400...599).contains(GlobalCupResponse.statusCode) {
                GlobalCupDecisionHandler(.cancel)
                DispatchQueue.main.async { [GlobalCupOnBlockedResponse] in GlobalCupOnBlockedResponse() }
                return
            }
            if GlobalCupNavigationResponse.isForMainFrame {
                DispatchQueue.main.async { [GlobalCupOnReady] in GlobalCupOnReady() }
            }
            GlobalCupDecisionHandler(.allow)
        }

        func webView(_ GlobalCupWebView: WKWebView, createWebViewWith GlobalCupConfiguration: WKWebViewConfiguration, for GlobalCupNavigationAction: WKNavigationAction, windowFeatures GlobalCupWindowFeatures: WKWindowFeatures) -> WKWebView? {
            if let GlobalCupRequestURL = GlobalCupNavigationAction.request.url {
                GlobalCupWebView.load(GlobalCupWebUserAgent.GlobalCupSafariRequest(GlobalCupURL: GlobalCupRequestURL))
            } else {
                GlobalCupWebView.load(GlobalCupNavigationAction.request)
            }
            return nil
        }

        func webViewDidClose(_ GlobalCupWebView: WKWebView) {
            self.GlobalCupWebView?.goBack()
        }

        func webView(
            _ GlobalCupWebView: WKWebView,
            runJavaScriptAlertPanelWithMessage GlobalCupMessage: String,
            initiatedByFrame GlobalCupFrame: WKFrameInfo,
            completionHandler GlobalCupCompletionHandler: @escaping () -> Void
        ) {
            GlobalCupPresentWebDialog(
                GlobalCupTitle: GlobalCupWebView.url?.host ?? "Message",
                GlobalCupMessage: GlobalCupMessage,
                GlobalCupActions: [UIAlertAction(title: "OK", style: .default) { _ in GlobalCupCompletionHandler() }],
                GlobalCupFallback: GlobalCupCompletionHandler
            )
        }

        func webView(
            _ GlobalCupWebView: WKWebView,
            runJavaScriptConfirmPanelWithMessage GlobalCupMessage: String,
            initiatedByFrame GlobalCupFrame: WKFrameInfo,
            completionHandler GlobalCupCompletionHandler: @escaping (Bool) -> Void
        ) {
            GlobalCupPresentWebDialog(
                GlobalCupTitle: GlobalCupWebView.url?.host ?? "Confirm",
                GlobalCupMessage: GlobalCupMessage,
                GlobalCupActions: [
                    UIAlertAction(title: "Cancel", style: .cancel) { _ in GlobalCupCompletionHandler(false) },
                    UIAlertAction(title: "OK", style: .default) { _ in GlobalCupCompletionHandler(true) }
                ],
                GlobalCupFallback: { GlobalCupCompletionHandler(false) }
            )
        }

        func webView(
            _ GlobalCupWebView: WKWebView,
            runJavaScriptTextInputPanelWithPrompt GlobalCupPrompt: String,
            defaultText GlobalCupDefaultText: String?,
            initiatedByFrame GlobalCupFrame: WKFrameInfo,
            completionHandler GlobalCupCompletionHandler: @escaping (String?) -> Void
        ) {
            let GlobalCupAlert = UIAlertController(title: GlobalCupWebView.url?.host ?? "Input", message: GlobalCupPrompt, preferredStyle: .alert)
            GlobalCupAlert.addTextField { GlobalCupTextField in
                GlobalCupTextField.text = GlobalCupDefaultText
            }
            GlobalCupAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in GlobalCupCompletionHandler(nil) })
            GlobalCupAlert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                GlobalCupCompletionHandler(GlobalCupAlert.textFields?.first?.text)
            })
            GlobalCupPresentAlertController(GlobalCupAlert, GlobalCupFallback: { GlobalCupCompletionHandler(nil) })
        }

        func webView(
            _ GlobalCupWebView: WKWebView,
            requestMediaCapturePermissionFor GlobalCupOrigin: WKSecurityOrigin,
            initiatedByFrame GlobalCupFrame: WKFrameInfo,
            type GlobalCupType: WKMediaCaptureType,
            decisionHandler GlobalCupDecisionHandler: @escaping (WKPermissionDecision) -> Void
        ) {
            GlobalCupDecisionHandler(.prompt)
        }

        private func GlobalCupUpdateNavigationState(_ GlobalCupWebView: WKWebView) {
            DispatchQueue.main.async { [GlobalCupOnNavigationStateChange] in
                GlobalCupOnNavigationStateChange(GlobalCupWebView.canGoBack, GlobalCupWebView.canGoForward)
            }
        }

        private func GlobalCupPresentWebDialog(
            GlobalCupTitle: String,
            GlobalCupMessage: String,
            GlobalCupActions: [UIAlertAction],
            GlobalCupFallback: @escaping () -> Void
        ) {
            let GlobalCupAlert = UIAlertController(title: GlobalCupTitle, message: GlobalCupMessage, preferredStyle: .alert)
            GlobalCupActions.forEach(GlobalCupAlert.addAction)
            GlobalCupPresentAlertController(GlobalCupAlert, GlobalCupFallback: GlobalCupFallback)
        }

        private func GlobalCupPresentAlertController(_ GlobalCupAlert: UIAlertController, GlobalCupFallback: @escaping () -> Void) {
            DispatchQueue.main.async {
                guard let GlobalCupPresenter = UIApplication.shared.GlobalCupTopMostViewController() else {
                    GlobalCupFallback()
                    return
                }

                if GlobalCupPresenter.presentedViewController == nil {
                    GlobalCupPresenter.present(GlobalCupAlert, animated: true)
                } else {
                    GlobalCupFallback()
                }
            }
        }
    }
}

struct GlobalCupWebNavigationOverlay: View {
    var GlobalCupCanGoBack: Bool
    var GlobalCupCanGoForward: Bool
    var GlobalCupGoBack: () -> Void
    var GlobalCupGoForward: () -> Void

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 10) {
                GlobalCupNavButton(GlobalCupSystemName: "chevron.left", GlobalCupEnabled: GlobalCupCanGoBack, GlobalCupAction: GlobalCupGoBack)
                GlobalCupNavButton(GlobalCupSystemName: "chevron.right", GlobalCupEnabled: GlobalCupCanGoForward, GlobalCupAction: GlobalCupGoForward)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 52)
            .padding(.horizontal, 14)
            .background(Color.black.opacity(0.92))
        }
        .allowsHitTesting(GlobalCupCanGoBack || GlobalCupCanGoForward)
    }

    private func GlobalCupNavButton(GlobalCupSystemName: String, GlobalCupEnabled: Bool, GlobalCupAction: @escaping () -> Void) -> some View {
        Button(action: GlobalCupAction) {
            Image(systemName: GlobalCupSystemName)
                .font(.system(size: 14, weight: .heavy))
                .foregroundStyle(GlobalCupEnabled ? Color.white : Color.white.opacity(0.28))
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(GlobalCupEnabled ? 0.14 : 0.06), in: Circle())
                .contentShape(Circle())
        }
        .disabled(!GlobalCupEnabled)
        .buttonStyle(.plain)
    }
}

private enum GlobalCupWebUserAgent {
    static var GlobalCupSafariLike: String {
        let GlobalCupOSVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let GlobalCupMajorVersion = UIDevice.current.systemVersion.split(separator: ".").first.map(String.init) ?? "18"
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(GlobalCupOSVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(GlobalCupMajorVersion).0 Mobile/15E148 Safari/604.1"
    }

    static func GlobalCupSafariRequest(GlobalCupURL: URL) -> URLRequest {
        var GlobalCupRequest = URLRequest(url: GlobalCupURL, timeoutInterval: 30)
        GlobalCupRequest.setValue(GlobalCupSafariLike, forHTTPHeaderField: "User-Agent")
        GlobalCupRequest.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        GlobalCupRequest.setValue(Locale.preferredLanguages.prefix(3).joined(separator: ","), forHTTPHeaderField: "Accept-Language")
        return GlobalCupRequest
    }
}

private extension UIApplication {
    func GlobalCupTopMostViewController(
        GlobalCupBase: UIViewController? = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController
    ) -> UIViewController? {
        if let GlobalCupNavigationController = GlobalCupBase as? UINavigationController {
            return GlobalCupTopMostViewController(GlobalCupBase: GlobalCupNavigationController.visibleViewController)
        }

        if let GlobalCupTabBarController = GlobalCupBase as? UITabBarController {
            return GlobalCupTopMostViewController(GlobalCupBase: GlobalCupTabBarController.selectedViewController)
        }

        if let GlobalCupPresented = GlobalCupBase?.presentedViewController {
            return GlobalCupTopMostViewController(GlobalCupBase: GlobalCupPresented)
        }

        return GlobalCupBase
    }
}
