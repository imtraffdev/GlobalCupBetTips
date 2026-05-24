import Foundation

public protocol DatabaseObject: Codable {
    static var dataBaseKey: String { get }
}
