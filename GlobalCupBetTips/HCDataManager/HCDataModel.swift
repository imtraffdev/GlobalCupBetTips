import Foundation

struct GlobalCupRemoteState: Codable, DatabaseObject {
    static var dataBaseKey: String = "global_cup_remote_state"

    let wasUpdatedFromServer: Bool?
    let webEnabled: Bool?
}
