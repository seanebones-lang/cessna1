import Foundation
import UIKit

class StorageManager: ObservableObject {
    @Published var storageAnalysis: StorageAnalysis?
    @Published var isAnalyzing = false
    @Published var recommendations: [CleanupRecommendation] = []
    
    func analyzeStorage() async {
        await MainActor.run {
            isAnalyzing = true
        }
        
        let fileManager = FileManager.default
        
        let totalSpace = getTotalDiskSpace()
        let freeSpace = getFreeDiskSpace()
        let usedSpace = totalSpace - freeSpace
        
        var items: [StorageItem] = []
        
        let documentsSize = await getDirectorySize(fileManager.urls(for: .documentDirectory, in: .userDomainMask).first)
        items.append(StorageItem(
            category: .documents,
            usedSpace: documentsSize,
            percentage: Double(documentsSize) / Double(totalSpace) * 100
        ))
        
        let cachesSize = await getDirectorySize(fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first)
        items.append(StorageItem(
            category: .other,
            usedSpace: cachesSize,
            percentage: Double(cachesSize) / Double(totalSpace) * 100
        ))
        
        let librarySize = await getDirectorySize(fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first)
        items.append(StorageItem(
            category: .apps,
            usedSpace: librarySize,
            percentage: Double(librarySize) / Double(totalSpace) * 100
        ))
        
        let estimatedPhotosSize = usedSpace - documentsSize - cachesSize - librarySize
        items.append(StorageItem(
            category: .photos,
            usedSpace: max(estimatedPhotosSize, 0),
            percentage: Double(max(estimatedPhotosSize, 0)) / Double(totalSpace) * 100
        ))
        
        let analysis = StorageAnalysis(
            totalSpace: totalSpace,
            usedSpace: usedSpace,
            freeSpace: freeSpace,
            items: items.sorted { $0.usedSpace > $1.usedSpace }
        )
        
        await MainActor.run {
            self.storageAnalysis = analysis
            self.isAnalyzing = false
        }
        
        await generateRecommendations()
    }
    
    private func getTotalDiskSpace() -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let totalSpace = attributes[.systemSize] as? Int64 else {
            return 0
        }
        return totalSpace
    }
    
    private func getFreeDiskSpace() -> Int64 {
        guard let attributes = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = attributes[.systemFreeSize] as? Int64 else {
            return 0
        }
        return freeSpace
    }
    
    private func getDirectorySize(_ url: URL?) async -> Int64 {
        guard let url = url else { return 0 }
        
        let fileManager = FileManager.default
        var totalSize: Int64 = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory,
                  !isDirectory,
                  let fileSize = resourceValues.fileSize else {
                continue
            }
            totalSize += Int64(fileSize)
        }
        
        return totalSize
    }
    
    private func generateRecommendations() async {
        var newRecommendations: [CleanupRecommendation] = []
        
        let junkFiles = await findJunkFiles()
        if !junkFiles.isEmpty {
            let totalSize = junkFiles.reduce(0) { $0 + $1.size }
            if totalSize > 100_000_000 {
                newRecommendations.append(CleanupRecommendation(
                    title: "Clear Junk Files",
                    description: "Remove temporary files and caches that are no longer needed.",
                    potentialSavings: totalSize,
                    priority: .high,
                    action: .deleteFiles(junkFiles)
                ))
            }
        }
        
        if let analysis = storageAnalysis {
            if Double(analysis.freeSpace) / Double(analysis.totalSpace) < 0.1 {
                newRecommendations.append(CleanupRecommendation(
                    title: "Low Storage Space",
                    description: "Your device is running low on storage. Consider removing unused apps or media.",
                    potentialSavings: 0,
                    priority: .critical,
                    action: .clearCache
                ))
            }
        }
        
        await MainActor.run {
            self.recommendations = newRecommendations.sorted { $0.priority > $1.priority }
        }
    }
    
    func findJunkFiles() async -> [JunkFile] {
        var junkFiles: [JunkFile] = []
        let fileManager = FileManager.default
        
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let cacheFiles = await findFilesInDirectory(cachesURL, ofType: .cache)
            junkFiles.append(contentsOf: cacheFiles)
        }
        
        if let tempURL = fileManager.urls(for: .itemReplacementDirectory, in: .userDomainMask).first {
            let tempFiles = await findFilesInDirectory(tempURL, ofType: .temporary)
            junkFiles.append(contentsOf: tempFiles)
        }
        
        if let downloadsURL = fileManager.urls(for: .downloadsDirectory, in: .userDomainMask).first {
            let downloadFiles = await findFilesInDirectory(downloadsURL, ofType: .downloads)
            let oldDownloads = downloadFiles.filter { file in
                let daysSinceModified = Calendar.current.dateComponents([.day], from: file.lastModified, to: Date()).day ?? 0
                return daysSinceModified > 30
            }
            junkFiles.append(contentsOf: oldDownloads)
        }
        
        return junkFiles
    }
    
    private func findFilesInDirectory(_ url: URL, ofType type: JunkFileType) async -> [JunkFile] {
        var files: [JunkFile] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey],
            options: [.skipsHiddenFiles]
        ) else {
            return files
        }
        
        for case let fileURL as URL in enumerator {
            guard let resourceValues = try? fileURL.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isDirectoryKey]),
                  let isDirectory = resourceValues.isDirectory,
                  !isDirectory,
                  let fileSize = resourceValues.fileSize,
                  let modificationDate = resourceValues.contentModificationDate else {
                continue
            }
            
            let junkFile = JunkFile(
                name: fileURL.lastPathComponent,
                path: fileURL,
                size: Int64(fileSize),
                type: type,
                lastModified: modificationDate
            )
            files.append(junkFile)
        }
        
        return files
    }
    
    func deleteJunkFiles(_ files: [JunkFile]) async throws {
        for file in files {
            try FileManager.default.removeItem(at: file.path)
        }
        
        await analyzeStorage()
    }
    
    func clearCache() async throws {
        let fileManager = FileManager.default
        
        if let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first {
            let contents = try fileManager.contentsOfDirectory(at: cachesURL, includingPropertiesForKeys: nil)
            for file in contents {
                try? fileManager.removeItem(at: file)
            }
        }
        
        URLCache.shared.removeAllCachedResponses()
        
        await analyzeStorage()
    }
}
