import SwiftUI
import UIKit
import WebKit

struct GlobalCupGateWebContainer: View {
    let GlobalCupURL: URL
    let GlobalCupOnBlockedResponse: () -> Void
    @State private var GlobalCupIsVisible = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            GlobalCupGateWebView(url: GlobalCupURL, onReady: {
                GlobalCupIsVisible = true
            }, onBlockedResponse: GlobalCupOnBlockedResponse)
            .opacity(GlobalCupIsVisible ? 1 : 0)
        }
        .onAppear {
            GlobalCupOrientationController.GlobalCupCurrent = UIDevice.current.userInterfaceIdiom == .pad ? .all : .allButUpsideDown
        }
        .onDisappear {
            GlobalCupOrientationController.GlobalCupCurrent = .portrait
        }
    }
}

struct GlobalCupGateWebView: UIViewRepresentable {
    let url: URL
    let onReady: () -> Void
    let onBlockedResponse: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onReady: onReady, onBlockedResponse: onBlockedResponse)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.customUserAgent = GlobalCupWebUserAgent.GlobalCupSafariLike
        webView.backgroundColor = .black
        webView.scrollView.backgroundColor = .black
        webView.load(GlobalCupWebUserAgent.GlobalCupSafariRequest(url: url))
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {}

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        let onReady: () -> Void
        let onBlockedResponse: () -> Void

        init(onReady: @escaping () -> Void, onBlockedResponse: @escaping () -> Void) {
            self.onReady = onReady
            self.onBlockedResponse = onBlockedResponse
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            if navigationAction.targetFrame == nil, ["http", "https"].contains(url.scheme?.lowercased()) {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            }
            if let scheme = url.scheme?.lowercased(), !["http", "https", "about"].contains(scheme) {
                UIApplication.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            if navigationResponse.isForMainFrame,
               let response = navigationResponse.response as? HTTPURLResponse,
               (400...599).contains(response.statusCode) {
                decisionHandler(.cancel)
                DispatchQueue.main.async { [onBlockedResponse] in onBlockedResponse() }
                return
            }
            if navigationResponse.isForMainFrame {
                DispatchQueue.main.async { [onReady] in onReady() }
            }
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let requestURL = navigationAction.request.url {
                webView.load(GlobalCupWebUserAgent.GlobalCupSafariRequest(url: requestURL))
            } else {
                webView.load(navigationAction.request)
            }
            return nil
        }
    }
}

private enum GlobalCupWebUserAgent {
    static var GlobalCupSafariLike: String {
        let osVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
        let majorVersion = UIDevice.current.systemVersion.split(separator: ".").first.map(String.init) ?? "18"
        return "Mozilla/5.0 (iPhone; CPU iPhone OS \(osVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/\(majorVersion).0 Mobile/15E148 Safari/604.1"
    }

    static func GlobalCupSafariRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, timeoutInterval: 30)
        request.setValue(GlobalCupSafariLike, forHTTPHeaderField: "User-Agent")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")
        request.setValue(Locale.preferredLanguages.prefix(3).joined(separator: ","), forHTTPHeaderField: "Accept-Language")
        return request
    }
}
