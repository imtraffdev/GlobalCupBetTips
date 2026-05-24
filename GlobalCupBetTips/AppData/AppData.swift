import Foundation

final class AppData {
    static var shared = AppData()

    var hcData = DBStatable<GlobalCupRemoteState>(defaultValueIfNil: .init(wasUpdatedFromServer: false, webEnabled: false))
}
