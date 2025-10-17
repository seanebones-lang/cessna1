import Foundation
import Combine

class DashboardViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var storageStatus: StorageStatus = .unknown
    @Published var quickStats: QuickStats?
    
    enum StorageStatus {
        case healthy
        case warning
        case critical
        case unknown
        
        var color: String {
            switch self {
            case .healthy: return "green"
            case .warning: return "yellow"
            case .critical: return "red"
            case .unknown: return "gray"
            }
        }
        
        var title: String {
            switch self {
            case .healthy: return "Storage Healthy"
            case .warning: return "Storage Warning"
            case .critical: return "Storage Critical"
            case .unknown: return "Analyzing..."
            }
        }
        
        var message: String {
            switch self {
            case .healthy: return "Your device has plenty of free space."
            case .warning: return "Consider cleaning up to free more space."
            case .critical: return "Your device is running low on storage."
            case .unknown: return "Tap to analyze your storage."
            }
        }
    }
    
    struct QuickStats {
        var totalSpace: String
        var usedSpace: String
        var freeSpace: String
        var usedPercentage: Double
        var potentialSavings: String
        var issuesFound: Int
    }
    
    func updateStats(storage: StorageAnalysis?, photoAnalysis: PhotoAnalysisResult?) {
        if let storage = storage {
            let usedPercent = Double(storage.usedSpace) / Double(storage.totalSpace) * 100
            
            if usedPercent < 70 {
                storageStatus = .healthy
            } else if usedPercent < 90 {
                storageStatus = .warning
            } else {
                storageStatus = .critical
            }
            
            let potentialSavings = photoAnalysis?.potentialSavings ?? 0
            
            quickStats = QuickStats(
                totalSpace: storage.formattedTotalSpace,
                usedSpace: storage.formattedUsedSpace,
                freeSpace: storage.formattedFreeSpace,
                usedPercentage: usedPercent,
                potentialSavings: ByteCountFormatter.string(fromByteCount: potentialSavings, countStyle: .file),
                issuesFound: photoAnalysis?.totalIssues ?? 0
            )
        }
    }
    
    func performQuickClean() async {
        await MainActor.run {
            isLoading = true
        }
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        await MainActor.run {
            isLoading = false
        }
    }
}
