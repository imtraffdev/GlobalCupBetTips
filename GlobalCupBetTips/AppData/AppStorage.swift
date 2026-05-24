import Foundation
import Combine

@propertyWrapper
public class AppStorage<Value>: ObservableObject where Value: Codable {
    private let key:          String
    private var value:        Data?
    private let defaultValue: Value?
    private var container: UserDefaults = .standard
    private let publisher = PassthroughSubject<Value?, Never>()
    
    public init(
        _ key: String,
        _ defaultValue: Value?,
        _ container: UserDefaults = .standard
    ) {
        self.key          = key
        self.value        = container.data(forKey: key)
        self.defaultValue = defaultValue
        self.container    = container
    }
    
    public var wrappedValue: Value? {
        get {
            return try? container.getLFObject(forKey: key, castTo: Value?.self) }
        set {
            do {
                let encoder = JSONEncoder()
                
                let data = try encoder.encode(newValue)
                value = data
            } catch {
                print("Unable to Encode Data (\(error))")
               // Log.error("Unable to Encode Data (\(error.asResponseError as Any))")
            }
            
            if let optional = newValue as? AnyOptional, optional.isNil {
                container.removeObject(forKey: key)
            } else {
                try? container.setLFObject(newValue, forKey: key)
            }
            // updateValue - добавить если будет нужно
            //if useAutoPublisher {
            // publisher.send(try? convertDataToObject(data: value, castTo: Value?.self))
            //}
        }
    }
    
    private func convertDataToObject<Object>(data: Data?, castTo type: Object.Type) throws -> Object where Object: Decodable {
        guard let data = data else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
    
    
    public var projectedValue: AnyPublisher<Value?, Never> {
        publisher.eraseToAnyPublisher()
    }
}

public protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    public var isNil: Bool { self == nil }
}

extension AppStorage where Value: ExpressibleByNilLiteral {
    public convenience init(_ key: String, _ container: UserDefaults = .standard, useAutoPublihser: Bool) {
        self.init(key, nil, container)
    }
}


extension UserDefaults: ObjectSavable {
    func setLFObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable {
        let encoder = JSONEncoder()
        do {
            let data = try encoder.encode(object)
            set(data, forKey: forKey)
        } catch {
            throw ObjectSavableError.unableToEncode
        }
    }
    
    func getLFObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable {
        guard let data = data(forKey: forKey) else { throw ObjectSavableError.noValue }
        let decoder = JSONDecoder()
        do {
            let object = try decoder.decode(type, from: data)
            return object
        } catch {
            throw ObjectSavableError.unableToDecode
        }
    }
}

fileprivate protocol ObjectSavable {
    func setLFObject<Object>(_ object: Object, forKey: String) throws where Object: Encodable
    func getLFObject<Object>(forKey: String, castTo type: Object.Type) throws -> Object where Object: Decodable
}

enum ObjectSavableError: String, LocalizedError {
    case unableToEncode = "Unable to encode object into data"
    case noValue        = "No data object found for the given key"
    case unableToDecode = "Unable to decode object into given type"
    
    var errorDescription: String? {
        rawValue
    }
}

public class DBStatable<Object: DatabaseObject>: ObservableObject {
    
    let encoder = JSONEncoder()
    
    @Published public var value: Object? {
        didSet {
            let data1 = try? encoder.encode(value)
            let data2 = try? encoder.encode(currentVal)
            if data1 != data2 {
                currentVal = value
            }
        }
    }
    
    @AppStorage(Object.dataBaseKey, nil)
    private var currentVal: Object?
    private var cancellable = Set<AnyCancellable>()
    public init(defaultValueIfNil: Object) {
        self.value = currentVal
        if self.value == nil {
            self.value = defaultValueIfNil
        }
        $currentVal.sink(receiveValue: { thisValue in
            self.value = thisValue
        })
        .store(in: &cancellable)
    }
}
