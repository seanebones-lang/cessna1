import Foundation

struct AppItem: Identifiable, Comparable {
    let id = UUID()
    let name: String
    let bundleIdentifier: String
    var size: Int64
    var lastUsed: Date?
    var isSystem: Bool
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var lastUsedText: String {
        guard let lastUsed = lastUsed else {
            return "Never used"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastUsed, relativeTo: Date())
    }
    
    static func < (lhs: AppItem, rhs: AppItem) -> Bool {
        lhs.size > rhs.size
    }
}

struct JunkFile: Identifiable {
    let id = UUID()
    let name: String
    let path: URL
    let size: Int64
    let type: JunkFileType
    let lastModified: Date
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
}

enum JunkFileType: String, CaseIterable {
    case cache = "Cache Files"
    case temporary = "Temporary Files"
    case downloads = "Old Downloads"
    case logs = "Log Files"
    case other = "Other"
    
    var iconName: String {
        switch self {
        case .cache: return "externaldrive.fill"
        case .temporary: return "clock.fill"
        case .downloads: return "arrow.down.circle.fill"
        case .logs: return "doc.text.fill"
        case .other: return "questionmark.circle.fill"
        }
    }
    
    var color: String {
        switch self {
        case .cache: return "blue"
        case .temporary: return "orange"
        case .downloads: return "green"
        case .logs: return "purple"
        case .other: return "gray"
        }
    }
}

struct CleanupRecommendation: Identifiable {
    let id = UUID()
    let title: String
    let description: String
    let potentialSavings: Int64
    let priority: Priority
    let action: CleanupAction
    
    enum Priority: Int, Comparable {
        case low = 0
        case medium = 1
        case high = 2
        case critical = 3
        
        var color: String {
            switch self {
            case .low: return "green"
            case .medium: return "yellow"
            case .high: return "orange"
            case .critical: return "red"
            }
        }
        
        static func < (lhs: Priority, rhs: Priority) -> Bool {
            lhs.rawValue < rhs.rawValue
        }
    }
    
    enum CleanupAction {
        case deleteFiles([JunkFile])
        case deleteDuplicates([PhotoItem])
        case removeApp(AppItem)
        case compressMedia
        case clearCache
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file)
    }
}
