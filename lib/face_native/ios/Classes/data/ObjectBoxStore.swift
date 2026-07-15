import ObjectBox
import Foundation

class ObjectBoxStore {
    private static var _store: Store?
    private static var currentTenantKey: String?
    
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
    
    static func initialize(tenantKey: String) -> Bool {
        // Check if already initialized with the same tenant key
        if isInitialized && currentTenantKey == tenantKey {
            print("ObjectBoxStore: Already initialized with same tenant key: \(tenantKey)")
            return true
        }
        
        // Close existing store if initialized with different tenant key
        if isInitialized && currentTenantKey != tenantKey {
            print("ObjectBoxStore: Re-initializing ObjectBoxStore with new tenant key: \(tenantKey)")
            close()
        }
        
        do {
            print("ObjectBoxStore: Initializing ObjectBoxStore with tenant key: \(tenantKey)")
            
            // Create directory for the specific tenant
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let objectBoxDir = documentsURL.appendingPathComponent("objectbox_\(tenantKey)")
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: objectBoxDir.path) {
                try fileManager.createDirectory(at: objectBoxDir, withIntermediateDirectories: true)
            }
            
            // Initialize ObjectBox store using generated convenience initializer
            // The EntityInfo.generated.swift file provides Store(directoryPath:) initializer
            _store = try Store(directoryPath: objectBoxDir.path)
            currentTenantKey = tenantKey
            
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
        currentTenantKey = nil
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

