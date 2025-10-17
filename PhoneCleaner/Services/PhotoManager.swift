import Foundation
import Photos
import UIKit
import Accelerate
import CoreImage

class PhotoManager: ObservableObject {
    @Published var authorizationStatus: PHAuthorizationStatus = .notDetermined
    @Published var analysisResult: PhotoAnalysisResult?
    @Published var isAnalyzing = false
    @Published var analysisProgress: Double = 0.0
    
    private let imageManager = PHCachingImageManager()
    private let ciContext = CIContext(options: [.useSoftwareRenderer: false])
    
    func requestAuthorization() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.authorizationStatus = status
        }
        return status == .authorized || status == .limited
    }
    
    func analyzePhotoLibrary() async {
        await MainActor.run {
            isAnalyzing = true
            analysisProgress = 0.0
        }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let allVideos = PHAsset.fetchAssets(with: .video, options: fetchOptions)
        
        var photoItems: [PhotoItem] = []
        var totalSize: Int64 = 0
        
        let total = allPhotos.count + allVideos.count
        var processed = 0
        
        for index in 0..<allPhotos.count {
            let asset = allPhotos[index]
            let size = await getAssetSize(asset)
            let quality = await analyzePhotoQuality(asset)
            
            let item = PhotoItem(
                id: asset.localIdentifier,
                asset: asset,
                quality: quality,
                fileSize: size,
                isDuplicate: false,
                duplicateGroupId: nil,
                similarity: nil
            )
            
            photoItems.append(item)
            totalSize += size
            processed += 1
            
            await MainActor.run {
                analysisProgress = Double(processed) / Double(total) * 0.5
            }
        }
        
        for index in 0..<allVideos.count {
            let asset = allVideos[index]
            let size = await getAssetSize(asset)
            
            let item = PhotoItem(
                id: asset.localIdentifier,
                asset: asset,
                quality: .good,
                fileSize: size,
                isDuplicate: false,
                duplicateGroupId: nil,
                similarity: nil
            )
            
            photoItems.append(item)
            totalSize += size
            processed += 1
            
            await MainActor.run {
                analysisProgress = 0.5 + Double(processed - allPhotos.count) / Double(total) * 0.3
            }
        }
        
        await MainActor.run {
            analysisProgress = 0.8
        }
        
        let duplicateGroups = await findDuplicates(in: photoItems)
        
        await MainActor.run {
            analysisProgress = 0.9
        }
        
        let lowQualityPhotos = photoItems.filter { $0.quality == .poor && !$0.isDuplicate }
        let blurryPhotos = photoItems.filter { $0.quality == .blurry && !$0.isDuplicate }
        
        let potentialSavings = duplicateGroups.reduce(0) { $0 + $1.potentialSavings } +
            lowQualityPhotos.reduce(0) { $0 + $1.fileSize } +
            blurryPhotos.reduce(0) { $0 + $1.fileSize }
        
        let result = PhotoAnalysisResult(
            totalPhotos: allPhotos.count,
            totalVideos: allVideos.count,
            duplicates: duplicateGroups,
            lowQualityPhotos: lowQualityPhotos,
            blurryPhotos: blurryPhotos,
            potentialSavings: potentialSavings
        )
        
        await MainActor.run {
            self.analysisResult = result
            self.analysisProgress = 1.0
            self.isAnalyzing = false
        }
    }
    
    private func getAssetSize(_ asset: PHAsset) async -> Int64 {
        await withCheckedContinuation { continuation in
            let resources = PHAssetResource.assetResources(for: asset)
            var totalSize: Int64 = 0
            
            for resource in resources {
                if let size = resource.value(forKey: "fileSize") as? Int64 {
                    totalSize += size
                }
            }
            
            continuation.resume(returning: totalSize > 0 ? totalSize : Int64(asset.pixelWidth * asset.pixelHeight * 4))
        }
    }
    
    private func analyzePhotoQuality(_ asset: PHAsset) async -> PhotoQuality {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 300, height: 300),
                contentMode: .aspectFit,
                options: options
            ) { image, _ in
                guard let image = image, let cgImage = image.cgImage else {
                    continuation.resume(returning: .fair)
                    return
                }
                
                let sharpness = self.calculateSharpness(cgImage)
                
                if sharpness < 0.15 {
                    continuation.resume(returning: .blurry)
                } else if sharpness < 0.3 {
                    continuation.resume(returning: .poor)
                } else if sharpness < 0.5 {
                    continuation.resume(returning: .fair)
                } else if sharpness < 0.7 {
                    continuation.resume(returning: .good)
                } else {
                    continuation.resume(returning: .excellent)
                }
            }
        }
    }
    
    private func calculateSharpness(_ cgImage: CGImage) -> Double {
        guard let ciImage = CIImage(image: UIImage(cgImage: cgImage)) else {
            return 0.5
        }
        
        let filter = CIFilter(name: "CIEdges")
        filter?.setValue(ciImage, forKey: kCIInputImageKey)
        filter?.setValue(1.0, forKey: kCIInputIntensityKey)
        
        guard let outputImage = filter?.outputImage,
              let cgOutput = ciContext.createCGImage(outputImage, from: outputImage.extent) else {
            return 0.5
        }
        
        let width = cgOutput.width
        let height = cgOutput.height
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var pixelData = [UInt8](repeating: 0, count: width * height)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return 0.5
        }
        
        context.draw(cgOutput, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let sum = pixelData.reduce(0) { $0 + Int($1) }
        let average = Double(sum) / Double(width * height)
        
        return min(average / 255.0, 1.0)
    }
    
    private func findDuplicates(in photos: [PhotoItem]) async -> [DuplicateGroup] {
        var groups: [String: [PhotoItem]] = [:]
        var processedHashes: Set<String> = []
        
        for i in 0..<photos.count {
            let photo1 = photos[i]
            
            guard !photo1.isVideo else { continue }
            
            let hash1 = await calculatePerceptualHash(photo1.asset)
            
            if processedHashes.contains(hash1) {
                continue
            }
            
            var similarPhotos: [PhotoItem] = [photo1]
            
            for j in (i + 1)..<photos.count {
                let photo2 = photos[j]
                
                guard !photo2.isVideo else { continue }
                
                let hash2 = await calculatePerceptualHash(photo2.asset)
                
                let similarity = hammingDistance(hash1, hash2)
                
                if similarity <= 5 {
                    var duplicatePhoto = photo2
                    duplicatePhoto.isDuplicate = true
                    duplicatePhoto.similarity = 1.0 - Double(similarity) / 64.0
                    duplicatePhoto.duplicateGroupId = hash1
                    similarPhotos.append(duplicatePhoto)
                    processedHashes.insert(hash2)
                }
            }
            
            if similarPhotos.count > 1 {
                var group = DuplicateGroup(
                    id: hash1,
                    photos: similarPhotos,
                    potentialSavings: 0
                )
                
                let sortedPhotos = similarPhotos.sorted { $0.quality.hashValue > $1.quality.hashValue }
                let photosToRemove = Array(sortedPhotos.dropFirst())
                group.potentialSavings = photosToRemove.reduce(0) { $0 + $1.fileSize }
                
                groups[hash1] = similarPhotos
            }
            
            processedHashes.insert(hash1)
        }
        
        return groups.map { key, photos in
            let sortedPhotos = photos.sorted { $0.quality.hashValue > $1.quality.hashValue }
            let photosToRemove = Array(sortedPhotos.dropFirst())
            return DuplicateGroup(
                id: key,
                photos: photos,
                potentialSavings: photosToRemove.reduce(0) { $0 + $1.fileSize }
            )
        }.sorted { $0.potentialSavings > $1.potentialSavings }
    }
    
    private func calculatePerceptualHash(_ asset: PHAsset) async -> String {
        await withCheckedContinuation { continuation in
            let options = PHImageRequestOptions()
            options.deliveryMode = .fastFormat
            options.isSynchronous = false
            options.isNetworkAccessAllowed = false
            
            imageManager.requestImage(
                for: asset,
                targetSize: CGSize(width: 8, height: 8),
                contentMode: .aspectFill,
                options: options
            ) { image, _ in
                guard let image = image,
                      let cgImage = image.cgImage else {
                    continuation.resume(returning: String(repeating: "0", count: 64))
                    return
                }
                
                let hash = self.generateDifferenceHash(cgImage)
                continuation.resume(returning: hash)
            }
        }
    }
    
    private func generateDifferenceHash(_ cgImage: CGImage) -> String {
        let width = 9
        let height = 8
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        var pixelData = [UInt8](repeating: 0, count: width * height)
        
        guard let context = CGContext(
            data: &pixelData,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return String(repeating: "0", count: 64)
        }
        
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        var hash = ""
        
        for y in 0..<height {
            for x in 0..<(width - 1) {
                let leftPixel = pixelData[y * width + x]
                let rightPixel = pixelData[y * width + x + 1]
                hash += leftPixel < rightPixel ? "1" : "0"
            }
        }
        
        return hash
    }
    
    private func hammingDistance(_ hash1: String, _ hash2: String) -> Int {
        var distance = 0
        for (char1, char2) in zip(hash1, hash2) {
            if char1 != char2 {
                distance += 1
            }
        }
        return distance
    }
    
    func deletePhotos(_ photos: [PhotoItem]) async throws {
        let assetsToDelete = photos.map { $0.asset }
        
        try await PHPhotoLibrary.shared().performChanges {
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }
        
        await analyzePhotoLibrary()
    }
}
