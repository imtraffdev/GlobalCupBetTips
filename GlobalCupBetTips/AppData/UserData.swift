import Foundation

struct UserData: DatabaseObject {
    static var dataBaseKey: String = "UserData"
    
    var score: Int
    var purchasedAnimations: Set<String>
    var selectedAnimation: String
    
}
