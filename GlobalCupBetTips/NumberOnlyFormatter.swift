import Foundation
import Combine

class NumberOnlyFormatter: Formatter {
    override func string(for obj: Any?) -> String? {
        guard let number = obj as? Int else { return nil }
        return String(number)
    }

    override func getObjectValue(_ obj: AutoreleasingUnsafeMutablePointer<AnyObject?>?, for string: String, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {
        guard let intValue = Int(string), intValue >= 0 && intValue <= 99 else { return false }
        obj?.pointee = intValue as AnyObject
        return true
    }
}
