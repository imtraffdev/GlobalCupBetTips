import Foundation

enum GlobalCupRegion: String, CaseIterable, Identifiable {
    case europe = "Europe"
    case americas = "Americas"
    case africa = "Africa"
    case asiaPacific = "Asia Pacific"

    var id: String { rawValue }
}
