import SwiftUI

struct ContentView: View {
    @EnvironmentObject var storageManager: StorageManager
    @EnvironmentObject var photoManager: PhotoManager
    @EnvironmentObject var securityManager: SecurityManager
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardViewModel)
                .tabItem {
                    Label("Dashboard", systemImage: "house.fill")
                }
                .tag(0)
            
            StorageView()
                .tabItem {
                    Label("Storage", systemImage: "internaldrive.fill")
                }
                .tag(1)
            
            PhotoCleanerView()
                .tabItem {
                    Label("Photos", systemImage: "photo.stack.fill")
                }
                .tag(2)
            
            SecurityView()
                .tabItem {
                    Label("Security", systemImage: "lock.shield.fill")
                }
                .tag(3)
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(4)
        }
        .accentColor(.blue)
        .onAppear {
            Task {
                await storageManager.analyzeStorage()
                dashboardViewModel.updateStats(
                    storage: storageManager.storageAnalysis,
                    photoAnalysis: photoManager.analysisResult
                )
            }
        }
        .onChange(of: storageManager.storageAnalysis) { _ in
            dashboardViewModel.updateStats(
                storage: storageManager.storageAnalysis,
                photoAnalysis: photoManager.analysisResult
            )
        }
        .onChange(of: photoManager.analysisResult) { _ in
            dashboardViewModel.updateStats(
                storage: storageManager.storageAnalysis,
                photoAnalysis: photoManager.analysisResult
            )
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(StorageManager())
            .environmentObject(PhotoManager())
            .environmentObject(SecurityManager())
            .preferredColorScheme(.dark)
    }
}
