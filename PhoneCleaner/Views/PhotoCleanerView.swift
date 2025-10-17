import SwiftUI
import Photos

struct PhotoCleanerView: View {
    @EnvironmentObject var photoManager: PhotoManager
    @State private var showDeleteConfirmation = false
    @State private var photosToDelete: [PhotoItem] = []
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                if photoManager.authorizationStatus != .authorized && photoManager.authorizationStatus != .limited {
                    PhotoPermissionView()
                } else if photoManager.isAnalyzing {
                    AnalyzingView(progress: photoManager.analysisProgress)
                } else if let result = photoManager.analysisResult {
                    PhotoResultsView(result: result, photosToDelete: $photosToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                } else {
                    PhotoInitialView()
                }
            }
            .navigationTitle("Photo Cleaner")
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                if photoManager.analysisResult != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            Task {
                                await photoManager.analyzePhotoLibrary()
                            }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
            .alert("Delete Photos", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    photosToDelete.removeAll()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        try? await photoManager.deletePhotos(photosToDelete)
                        photosToDelete.removeAll()
                    }
                }
            } message: {
                Text("Are you sure you want to delete \(photosToDelete.count) photo(s)? This action cannot be undone.")
            }
        }
    }
}

struct PhotoPermissionView: View {
    @EnvironmentObject var photoManager: PhotoManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Photo Access Required")
                .font(.title)
                .fontWeight(.bold)
            
            Text("To help you find and remove duplicate or low-quality photos, we need access to your photo library.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    _ = await photoManager.requestAuthorization()
                }
            } label: {
                Text("Grant Access")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct AnalyzingView: View {
    let progress: Double
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView(value: progress) {
                Text("Analyzing your photos...")
                    .font(.headline)
            }
            .progressViewStyle(.linear)
            .padding(.horizontal)
            
            Text("\(Int(progress * 100))% complete")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
    }
}

struct PhotoInitialView: View {
    @EnvironmentObject var photoManager: PhotoManager
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "photo.stack")
                .font(.system(size: 80))
                .foregroundColor(.blue)
            
            Text("Ready to Clean")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Scan your photo library to find duplicates, blurry photos, and low-quality images.")
                .font(.body)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await photoManager.analyzePhotoLibrary()
                }
            } label: {
                Text("Start Scanning")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(15)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct PhotoResultsView: View {
    let result: PhotoAnalysisResult
    @Binding var photosToDelete: [PhotoItem]
    @Binding var showDeleteConfirmation: Bool
    @State private var selectedSegment = 0
    
    var body: some View {
        VStack(spacing: 0) {
            ResultsSummaryCard(result: result)
                .padding()
            
            Picker("Category", selection: $selectedSegment) {
                Text("Duplicates").tag(0)
                Text("Low Quality").tag(1)
                Text("Blurry").tag(2)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 12) {
                    switch selectedSegment {
                    case 0:
                        DuplicatesSection(groups: result.duplicates, photosToDelete: $photosToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                    case 1:
                        PhotoGridSection(photos: result.lowQualityPhotos, title: "Low Quality Photos", photosToDelete: $photosToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                    case 2:
                        PhotoGridSection(photos: result.blurryPhotos, title: "Blurry Photos", photosToDelete: $photosToDelete, showDeleteConfirmation: $showDeleteConfirmation)
                    default:
                        EmptyView()
                    }
                }
                .padding()
            }
        }
    }
}

struct ResultsSummaryCard: View {
    let result: PhotoAnalysisResult
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(result.totalIssues) Issues Found")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Potential savings: \(result.formattedSavings)")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.green)
            }
            
            HStack(spacing: 16) {
                SummaryStatView(title: "Duplicates", value: "\(result.duplicates.reduce(0) { $0 + $1.count })", color: .blue)
                SummaryStatView(title: "Low Quality", value: "\(result.lowQualityPhotos.count)", color: .orange)
                SummaryStatView(title: "Blurry", value: "\(result.blurryPhotos.count)", color: .red)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct SummaryStatView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(10)
    }
}

struct DuplicatesSection: View {
    let groups: [DuplicateGroup]
    @Binding var photosToDelete: [PhotoItem]
    @Binding var showDeleteConfirmation: Bool
    
    var body: some View {
        if groups.isEmpty {
            Text("No duplicate photos found")
                .foregroundColor(.gray)
                .padding()
        } else {
            ForEach(groups) { group in
                DuplicateGroupCard(group: group, photosToDelete: $photosToDelete, showDeleteConfirmation: $showDeleteConfirmation)
            }
        }
    }
}

struct DuplicateGroupCard: View {
    let group: DuplicateGroup
    @Binding var photosToDelete: [PhotoItem]
    @Binding var showDeleteConfirmation: Bool
    @State private var selectedPhotos: Set<String> = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("\(group.count) similar photos")
                    .font(.headline)
                
                Spacer()
                
                Text("Save \(group.formattedSavings)")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(group.photos) { photo in
                        PhotoThumbnailView(photo: photo, isSelected: selectedPhotos.contains(photo.id)) {
                            if selectedPhotos.contains(photo.id) {
                                selectedPhotos.remove(photo.id)
                            } else {
                                selectedPhotos.insert(photo.id)
                            }
                        }
                    }
                }
            }
            
            Button {
                photosToDelete = group.photos.filter { selectedPhotos.contains($0.id) }
                if !photosToDelete.isEmpty {
                    showDeleteConfirmation = true
                }
            } label: {
                Text("Delete Selected (\(selectedPhotos.count))")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(selectedPhotos.isEmpty ? Color.gray : Color.red)
                    .cornerRadius(10)
            }
            .disabled(selectedPhotos.isEmpty)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct PhotoThumbnailView: View {
    let photo: PhotoItem
    let isSelected: Bool
    let onTap: () -> Void
    @State private var thumbnail: UIImage?
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let thumbnail = thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 100, height: 100)
                    .cornerRadius(10)
            }
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .background(Circle().fill(Color.white))
                    .offset(x: -5, y: 5)
            }
        }
        .onTapGesture {
            onTap()
        }
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true
        
        PHCachingImageManager.default().requestImage(
            for: photo.asset,
            targetSize: CGSize(width: 200, height: 200),
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            self.thumbnail = image
        }
    }
}

struct PhotoGridSection: View {
    let photos: [PhotoItem]
    let title: String
    @Binding var photosToDelete: [PhotoItem]
    @Binding var showDeleteConfirmation: Bool
    @State private var selectedPhotos: Set<String> = []
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if photos.isEmpty {
                Text("No \(title.lowercased()) found")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                HStack {
                    Text("\(photos.count) photos")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button("Select All") {
                        if selectedPhotos.count == photos.count {
                            selectedPhotos.removeAll()
                        } else {
                            selectedPhotos = Set(photos.map { $0.id })
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal)
                
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(photos) { photo in
                        PhotoThumbnailView(photo: photo, isSelected: selectedPhotos.contains(photo.id)) {
                            if selectedPhotos.contains(photo.id) {
                                selectedPhotos.remove(photo.id)
                            } else {
                                selectedPhotos.insert(photo.id)
                            }
                        }
                    }
                }
                
                Button {
                    photosToDelete = photos.filter { selectedPhotos.contains($0.id) }
                    if !photosToDelete.isEmpty {
                        showDeleteConfirmation = true
                    }
                } label: {
                    Text("Delete Selected (\(selectedPhotos.count))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedPhotos.isEmpty ? Color.gray : Color.red)
                        .cornerRadius(10)
                }
                .disabled(selectedPhotos.isEmpty)
                .padding(.horizontal)
            }
        }
    }
}

struct PhotoCleanerView_Previews: PreviewProvider {
    static var previews: some View {
        PhotoCleanerView()
            .environmentObject(PhotoManager())
            .preferredColorScheme(.dark)
    }
}
