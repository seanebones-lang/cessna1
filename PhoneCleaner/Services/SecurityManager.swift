import Foundation
import CryptoKit
import Security

class SecurityManager: ObservableObject {
    @Published var isVPNEnabled = false
    @Published var isEncryptionEnabled = false
    
    func securelyDeleteFile(at url: URL, passes: Int = 7) async throws {
        let fileManager = FileManager.default
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw SecurityError.fileNotFound
        }
        
        guard let fileSize = try? fileManager.attributesOfItem(atPath: url.path)[.size] as? Int64 else {
            throw SecurityError.cannotReadFile
        }
        
        let fileHandle = try FileHandle(forWritingTo: url)
        defer { try? fileHandle.close() }
        
        for pass in 0..<passes {
            try fileHandle.seek(toOffset: 0)
            
            let pattern: UInt8 = switch pass % 3 {
            case 0: 0xFF
            case 1: 0x00
            default: UInt8.random(in: 0...255)
            }
            
            let chunkSize = 8192
            let numberOfChunks = Int(fileSize) / chunkSize
            let remainderSize = Int(fileSize) % chunkSize
            
            let chunk = Data(repeating: pattern, count: chunkSize)
            
            for _ in 0..<numberOfChunks {
                try fileHandle.write(contentsOf: chunk)
            }
            
            if remainderSize > 0 {
                let remainderChunk = Data(repeating: pattern, count: remainderSize)
                try fileHandle.write(contentsOf: remainderChunk)
            }
            
            try fileHandle.synchronize()
        }
        
        try fileManager.removeItem(at: url)
    }
    
    func encryptData(_ data: Data, withKey key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.seal(data, using: key)
        
        guard let combined = sealedBox.combined else {
            throw SecurityError.encryptionFailed
        }
        
        return combined
    }
    
    func decryptData(_ data: Data, withKey key: SymmetricKey) throws -> Data {
        let sealedBox = try AES.GCM.SealedBox(combined: data)
        return try AES.GCM.open(sealedBox, using: key)
    }
    
    func generateEncryptionKey() -> SymmetricKey {
        return SymmetricKey(size: .bits256)
    }
    
    func saveKeyToKeychain(_ key: SymmetricKey, withIdentifier identifier: String) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        SecItemDelete(query as CFDictionary)
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityError.keychainError
        }
    }
    
    func loadKeyFromKeychain(withIdentifier identifier: String) throws -> SymmetricKey {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: identifier,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let keyData = result as? Data else {
            throw SecurityError.keychainError
        }
        
        return SymmetricKey(data: keyData)
    }
    
    func hashData(_ data: Data) -> String {
        let hash = SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

enum SecurityError: Error, LocalizedError {
    case fileNotFound
    case cannotReadFile
    case encryptionFailed
    case decryptionFailed
    case keychainError
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound:
            return "The file could not be found."
        case .cannotReadFile:
            return "Unable to read the file."
        case .encryptionFailed:
            return "Encryption failed."
        case .decryptionFailed:
            return "Decryption failed."
        case .keychainError:
            return "Keychain operation failed."
        }
    }
}
