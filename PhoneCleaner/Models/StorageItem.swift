import Foundation

enum StorageCategory: String, CaseIterable, Identifiable {
    case photos = "Photos & Videos"
    case apps = "Apps"
    case documents = "Documents"
    case messages = "Messages"
    case system = "System"
    case other = "Other"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .photos: return "photo.on.rectangle.angled"
        case .apps: return "square.grid.2x2"
        case .documents: return "doc.fill"
        case .messages: return "message.fill"
        case .system: return "gearshape.fill"
        case .other: return "folder.fill"
        }
    }
    
    var color: String {
        switch self {
        case .photos: return "blue"
        case .apps: return "purple"
        case .documents: return "green"
        case .messages: return "orange"
        case .system: return "red"
        case .other: return "gray"
        }
    }
}

struct StorageItem: Identifiable {
    let id = UUID()
    let category: StorageCategory
    var usedSpace: Int64
    var percentage: Double
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
}

struct StorageAnalysis {
    var totalSpace: Int64
    var usedSpace: Int64
    var freeSpace: Int64
    var items: [StorageItem]
    
    var usedPercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(usedSpace) / Double(totalSpace) * 100
    }
    
    var freePercentage: Double {
        guard totalSpace > 0 else { return 0 }
        return Double(freeSpace) / Double(totalSpace) * 100
    }
    
    var formattedUsedSpace: String {
        ByteCountFormatter.string(fromByteCount: usedSpace, countStyle: .file)
    }
    
    var formattedTotalSpace: String {
        ByteCountFormatter.string(fromByteCount: totalSpace, countStyle: .file)
    }
    
    var formattedFreeSpace: String {
        ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }
}
