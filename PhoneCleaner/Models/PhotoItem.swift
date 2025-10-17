import Foundation
import Photos
import UIKit

enum PhotoQuality {
    case excellent
    case good
    case fair
    case poor
    case blurry
    
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .blurry: return "Blurry"
        }
    }
    
    var color: String {
        switch self {
        case .excellent: return "green"
        case .good: return "blue"
        case .fair: return "yellow"
        case .poor: return "orange"
        case .blurry: return "red"
        }
    }
}

struct PhotoItem: Identifiable, Hashable {
    let id: String
    let asset: PHAsset
    var quality: PhotoQuality
    var fileSize: Int64
    var isDuplicate: Bool
    var duplicateGroupId: String?
    var similarity: Double?
    
    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var creationDate: Date? {
        asset.creationDate
    }
    
    var isVideo: Bool {
        asset.mediaType == .video
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PhotoItem, rhs: PhotoItem) -> Bool {
        lhs.id == rhs.id
    }
}

struct DuplicateGroup: Identifiable {
    let id: String
    var photos: [PhotoItem]
    var potentialSavings: Int64
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file)
    }
    
    var count: Int {
        photos.count
    }
}

struct PhotoAnalysisResult {
    var totalPhotos: Int
    var totalVideos: Int
    var duplicates: [DuplicateGroup]
    var lowQualityPhotos: [PhotoItem]
    var blurryPhotos: [PhotoItem]
    var potentialSavings: Int64
    
    var totalIssues: Int {
        duplicates.reduce(0) { $0 + $1.count } + lowQualityPhotos.count + blurryPhotos.count
    }
    
    var formattedSavings: String {
        ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file)
    }
}
