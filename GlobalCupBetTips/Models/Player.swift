import Foundation

struct GlobalCupPlayer: Hashable, Identifiable {
    var id: String { name }
    var name: String
    var goalProbability: Double
    var faultProbability: Double
}
