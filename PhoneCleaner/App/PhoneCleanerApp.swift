import SwiftUI

@main
struct APEXiPhoneCleanerPROApp: App {
    @StateObject private var storageManager = StorageManager()
    @StateObject private var photoManager = PhotoManager()
    @StateObject private var securityManager = SecurityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(storageManager)
                .environmentObject(photoManager)
                .environmentObject(securityManager)
                .preferredColorScheme(.dark)
        }
    }
}
