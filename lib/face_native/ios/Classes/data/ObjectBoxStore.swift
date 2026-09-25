import ObjectBox
import Foundation

class ObjectBoxStore {
    private static var _store: Store?

    static var store: Store {
        get throws {
            guard let store = _store else {
                throw ObjectBoxError("ObjectBoxStore not initialized. Call init() first.")
            }
            return store
        }
    }
    
    static var isInitialized: Bool {
        return _store != nil
    }
    
    static func initialize() -> Bool {
        if isInitialized {
            print("ObjectBoxStore: Already initialized")
            return true
        }

        do {
            print("ObjectBoxStore: Initializing ObjectBoxStore")

            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let objectBoxDir = documentsURL.appendingPathComponent("objectbox")

            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: objectBoxDir.path) {
                try fileManager.createDirectory(at: objectBoxDir, withIntermediateDirectories: true)
            }
            
            // Initialize ObjectBox store using generated convenience initializer
            // The EntityInfo.generated.swift file provides Store(directoryPath:) initializer
            _store = try Store(directoryPath: objectBoxDir.path)

            print("ObjectBoxStore: Successfully initialized at \(objectBoxDir.path)")
            return true
        } catch {
            print("ObjectBoxStore: Failed to initialize - \(error)")
            return false
        }
    }
    
    static func close() {
        do {
            try _store?.close()
        } catch {
            print("ObjectBoxStore: Error closing store - \(error.localizedDescription)")
        }
        _store = nil
    }
}

struct ObjectBoxError: Error, CustomStringConvertible {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
    
    var description: String {
        return message
    }
}

