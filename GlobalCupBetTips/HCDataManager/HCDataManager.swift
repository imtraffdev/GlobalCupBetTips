import Foundation
import Network
import WebKit

enum GlobalCupLaunchDestination: Equatable {
    case native
    case web(URL)
    case offline
}

enum GlobalCupRemoteGate {
    static let GlobalCupCheckURL = URL(string: "https://globalcuptipsa.biz/media/")!
    private static let GlobalCupTimeoutSeconds: TimeInterval = 6

    static func GlobalCupResolveDestination() async -> GlobalCupLaunchDestination {
        guard await GlobalCupHasNetworkConnection() else {
            return .offline
        }

        do {
            let response = try await GlobalCupFetchResponse()
            await GlobalCupSyncCookies(from: response)
            if (400...599).contains(response.statusCode) {
                return .native
            }
            return .web(GlobalCupCheckURL)
        } catch {
            let GlobalCupHasNetwork = await GlobalCupHasNetworkConnection()
            if GlobalCupIsOfflineError(error) || (GlobalCupIsTimeoutError(error) && !GlobalCupHasNetwork) {
                return .offline
            }
            return .native
        }
    }

    private static func GlobalCupFetchResponse() async throws -> HTTPURLResponse {
        try await withThrowingTaskGroup(of: HTTPURLResponse.self) { group in
            group.addTask {
                var GlobalCupRequest = URLRequest(url: GlobalCupCheckURL, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: GlobalCupTimeoutSeconds)
                GlobalCupRequest.httpMethod = "GET"
                GlobalCupRequest.httpShouldHandleCookies = true
                GlobalCupRequest.setValue(GlobalCupNativeUserAgent, forHTTPHeaderField: "User-Agent")
                let GlobalCupSession = URLSession(configuration: GlobalCupSessionConfiguration, delegate: GlobalCupRedirectDelegate(), delegateQueue: nil)
                let (_, GlobalCupResponse) = try await GlobalCupSession.data(for: GlobalCupRequest)
                guard let GlobalCupHTTPResponse = GlobalCupResponse as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                return GlobalCupHTTPResponse
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(GlobalCupTimeoutSeconds * 1_000_000_000))
                throw URLError(.timedOut)
            }
            guard let GlobalCupResponse = try await group.next() else {
                throw URLError(.unknown)
            }
            group.cancelAll()
            return GlobalCupResponse
        }
    }

    private static var GlobalCupSessionConfiguration: URLSessionConfiguration {
        let GlobalCupConfiguration = URLSessionConfiguration.default
        GlobalCupConfiguration.timeoutIntervalForRequest = GlobalCupTimeoutSeconds
        GlobalCupConfiguration.timeoutIntervalForResource = GlobalCupTimeoutSeconds
        GlobalCupConfiguration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        GlobalCupConfiguration.httpCookieStorage = .shared
        GlobalCupConfiguration.httpCookieAcceptPolicy = .always
        GlobalCupConfiguration.httpShouldSetCookies = true
        GlobalCupConfiguration.waitsForConnectivity = false
        GlobalCupConfiguration.httpAdditionalHeaders = [
            "User-Agent": GlobalCupNativeUserAgent,
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": Locale.preferredLanguages.prefix(3).joined(separator: ",")
        ]
        return GlobalCupConfiguration
    }

    private static func GlobalCupHasNetworkConnection() async -> Bool {
        await withCheckedContinuation { continuation in
            let GlobalCupMonitor = NWPathMonitor()
            let GlobalCupQueue = DispatchQueue(label: "GlobalCup.RemoteGate.NetworkPath")
            let GlobalCupState = GlobalCupContinuationState()
            GlobalCupMonitor.pathUpdateHandler = { GlobalCupPath in
                if GlobalCupState.GlobalCupResumeOnce() {
                    GlobalCupMonitor.cancel()
                    continuation.resume(returning: GlobalCupPath.status == .satisfied)
                }
            }
            GlobalCupMonitor.start(queue: GlobalCupQueue)
            GlobalCupQueue.asyncAfter(deadline: .now() + 1.5) {
                if GlobalCupState.GlobalCupResumeOnce() {
                    GlobalCupMonitor.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private static func GlobalCupIsOfflineError(_ error: Error) -> Bool {
        let GlobalCupNSError = error as NSError
        guard GlobalCupNSError.domain == NSURLErrorDomain else { return false }
        switch URLError.Code(rawValue: GlobalCupNSError.code) {
        case .notConnectedToInternet, .networkConnectionLost, .cannotFindHost, .cannotConnectToHost:
            return true
        default:
            return false
        }
    }

    private static func GlobalCupIsTimeoutError(_ error: Error) -> Bool {
        let GlobalCupNSError = error as NSError
        return GlobalCupNSError.domain == NSURLErrorDomain && URLError.Code(rawValue: GlobalCupNSError.code) == .timedOut
    }

    private static var GlobalCupNativeUserAgent: String {
        let GlobalCupAppName = Bundle.main.bundleIdentifier ?? "GlobalCup"
        let GlobalCupVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return "\(GlobalCupAppName)/\(GlobalCupVersion) CFNetwork/1490 Darwin/23.0.0"
    }

    private static func GlobalCupSyncCookies(from response: HTTPURLResponse) async {
        let GlobalCupResponseURL = response.url ?? GlobalCupCheckURL
        let GlobalCupHeaderCookies = HTTPCookie.cookies(withResponseHeaderFields: response.allHeaderFields as? [String: String] ?? [:], for: GlobalCupResponseURL)
        let GlobalCupStoredCookies = HTTPCookieStorage.shared.cookies(for: GlobalCupResponseURL) ?? []
        let GlobalCupCookies = Array(Dictionary(grouping: GlobalCupHeaderCookies + GlobalCupStoredCookies, by: \.name).compactMap { $0.value.last })
        let GlobalCupCookieStore = await WKWebsiteDataStore.default().httpCookieStore
        for GlobalCupCookie in GlobalCupCookies {
            await GlobalCupCookieStore.GlobalCupSetCookieAsync(GlobalCupCookie)
        }
    }

    private final class GlobalCupContinuationState: @unchecked Sendable {
        private let GlobalCupLock = NSLock()
        private var GlobalCupDidResume = false

        func GlobalCupResumeOnce() -> Bool {
            GlobalCupLock.lock()
            defer { GlobalCupLock.unlock() }
            guard !GlobalCupDidResume else { return false }
            GlobalCupDidResume = true
            return true
        }
    }

    final class GlobalCupRedirectDelegate: NSObject, URLSessionTaskDelegate {
        func urlSession(_ GlobalCupSession: URLSession, task GlobalCupTask: URLSessionTask, willPerformHTTPRedirection GlobalCupResponse: HTTPURLResponse, newRequest GlobalCupRequest: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
            var GlobalCupRedirected = GlobalCupRequest
            GlobalCupRedirected.setValue(GlobalCupNativeUserAgent, forHTTPHeaderField: "User-Agent")
            completionHandler(GlobalCupRedirected)
        }
    }
}

private extension WKHTTPCookieStore {
    func GlobalCupSetCookieAsync(_ cookie: HTTPCookie) async {
        await withCheckedContinuation { continuation in
            setCookie(cookie) {
                continuation.resume()
            }
        }
    }
}
