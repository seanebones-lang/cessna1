import SwiftUI

struct DashboardView: View {
    @ObservedObject var viewModel: DashboardViewModel
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var photoManager: PhotoManager
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    StorageStatusCard(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    if let stats = viewModel.quickStats {
                        QuickStatsGrid(stats: stats)
                            .padding(.horizontal)
                    }
                    
                    if !storageManager.recommendations.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommendations")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(storageManager.recommendations.prefix(3)) { recommendation in
                                RecommendationCard(recommendation: recommendation)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    
                    QuickActionsSection()
                        .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
                .padding(.top)
            }
            .navigationTitle("APEX iPhone Cleaner PRO")
            .background(Color.black.ignoresSafeArea())
        }
    }
}

struct StorageStatusCard: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.storageStatus.title)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(viewModel.storageStatus.message)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Circle()
                    .fill(statusColor)
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: statusIcon)
                            .font(.title2)
                            .foregroundColor(.white)
                    )
            }
            
            if let stats = viewModel.quickStats {
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 15)
                    
                    Circle()
                        .trim(from: 0, to: stats.usedPercentage / 100)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [statusColor, statusColor.opacity(0.5)]),
                                center: .center,
                                startAngle: .degrees(0),
                                endAngle: .degrees(360 * stats.usedPercentage / 100)
                            ),
                            style: StrokeStyle(lineWidth: 15, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 1.5), value: stats.usedPercentage)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(stats.usedPercentage))%")
                            .font(.system(size: 36, weight: .bold))
                        Text("Used")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 200)
                .padding(.vertical)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private var statusColor: Color {
        switch viewModel.storageStatus {
        case .healthy: return .green
        case .warning: return .yellow
        case .critical: return .red
        case .unknown: return .gray
        }
    }
    
    private var statusIcon: String {
        switch viewModel.storageStatus {
        case .healthy: return "checkmark"
        case .warning: return "exclamationmark"
        case .critical: return "xmark"
        case .unknown: return "questionmark"
        }
    }
}

struct QuickStatsGrid: View {
    let stats: DashboardViewModel.QuickStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                StatCard(title: "Total Space", value: stats.totalSpace, icon: "internaldrive", color: .blue)
                StatCard(title: "Used Space", value: stats.usedSpace, icon: "square.fill", color: .orange)
            }
            
            HStack(spacing: 12) {
                StatCard(title: "Free Space", value: stats.freeSpace, icon: "square", color: .green)
                StatCard(title: "Can Save", value: stats.potentialSavings, icon: "arrow.down.circle", color: .purple)
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
}

struct RecommendationCard: View {
    let recommendation: CleanupRecommendation
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(priorityColor)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.title)
                    .font(.headline)
                
                Text(recommendation.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text(recommendation.formattedSavings)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private var priorityColor: Color {
        switch recommendation.priority {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
}

struct QuickActionsSection: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var photoManager: PhotoManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.title2)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                QuickActionButton(
                    title: "Scan Photos",
                    icon: "photo.on.rectangle.angled",
                    color: .blue
                ) {
                    Task {
                        if await photoManager.requestAuthorization() {
                            await photoManager.analyzePhotoLibrary()
                        }
                    }
                }
                
                QuickActionButton(
                    title: "Clear Cache",
                    icon: "trash.fill",
                    color: .orange
                ) {
                    Task {
                        try? await storageManager.clearCache()
                    }
                }
                
                QuickActionButton(
                    title: "Analyze Storage",
                    icon: "chart.pie.fill",
                    color: .green
                ) {
                    Task {
                        await storageManager.analyzeStorage()
                    }
                }
            }
        }
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView(viewModel: DashboardViewModel())
            .environmentObject(StorageManager())
            .environmentObject(PhotoManager())
            .preferredColorScheme(.dark)
    }
}
