import SwiftUI

struct SecurityView: View {
    @EnvironmentObject var securityManager: SecurityManager
    @State private var selectedFiles: [URL] = []
    @State private var showFilePicker = false
    @State private var showShredConfirmation = false
    @State private var shredPasses = 7
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    SecurityHeaderCard()
                        .padding(.horizontal)
                    
                    FileShredderSection(
                        selectedFiles: $selectedFiles,
                        showFilePicker: $showFilePicker,
                        showShredConfirmation: $showShredConfirmation,
                        shredPasses: $shredPasses
                    )
                    .padding(.horizontal)
                    
                    EncryptionSection()
                        .padding(.horizontal)
                    
                    VPNSection()
                        .padding(.horizontal)
                    
                    PrivacyTipsSection()
                        .padding(.horizontal)
                }
                .padding(.top)
            }
            .navigationTitle("Security")
            .background(Color.black.ignoresSafeArea())
            .alert("Secure Delete", isPresented: $showShredConfirmation) {
                Button("Cancel", role: .cancel) {
                    selectedFiles.removeAll()
                }
                Button("Delete", role: .destructive) {
                    Task {
                        for file in selectedFiles {
                            try? await securityManager.securelyDeleteFile(at: file, passes: shredPasses)
                        }
                        selectedFiles.removeAll()
                    }
                }
            } message: {
                Text("This will permanently delete \(selectedFiles.count) file(s) using \(shredPasses)-pass overwriting. This action cannot be undone.")
            }
        }
    }
}

struct SecurityHeaderCard: View {
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "shield.checkered")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Advanced Security")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Protect your privacy with military-grade security features")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct FileShredderSection: View {
    @EnvironmentObject var securityManager: SecurityManager
    @Binding var selectedFiles: [URL]
    @Binding var showFilePicker: Bool
    @Binding var showShredConfirmation: Bool
    @Binding var shredPasses: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "shredder")
                    .foregroundColor(.red)
                Text("Secure File Shredder")
                    .font(.headline)
            }
            
            Text("Permanently delete files using military-grade \(shredPasses)-pass overwriting to prevent recovery.")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(spacing: 12) {
                HStack {
                    Text("Overwrite Passes")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Picker("Passes", selection: $shredPasses) {
                        Text("3 (Fast)").tag(3)
                        Text("7 (Standard)").tag(7)
                        Text("35 (Maximum)").tag(35)
                    }
                    .pickerStyle(.menu)
                }
                
                Button {
                    showFilePicker = true
                } label: {
                    Label("Select Files to Shred", systemImage: "doc.badge.plus")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(10)
                }
                
                if !selectedFiles.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(selectedFiles.count) file(s) selected")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Button {
                            showShredConfirmation = true
                        } label: {
                            Text("Shred Selected Files")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(10)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct EncryptionSection: View {
    @EnvironmentObject var securityManager: SecurityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                Text("Data Encryption")
                    .font(.headline)
            }
            
            Text("All app data is encrypted using AES-256 encryption for maximum security.")
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Encryption Status")
                        .font(.subheadline)
                    Text("Active")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                Image(systemName: "checkmark.shield.fill")
                    .font(.title)
                    .foregroundColor(.green)
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct VPNSection: View {
    @EnvironmentObject var securityManager: SecurityManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "network.badge.shield.half.filled")
                    .foregroundColor(.blue)
                Text("VPN Protection")
                    .font(.headline)
            }
            
            Text("Secure your internet connection and protect your IP address with built-in VPN capabilities.")
                .font(.caption)
                .foregroundColor(.gray)
            
            Toggle(isOn: $securityManager.isVPNEnabled) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("VPN Status")
                        .font(.subheadline)
                    Text(securityManager.isVPNEnabled ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(securityManager.isVPNEnabled ? .green : .gray)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
            
            if securityManager.isVPNEnabled {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Your connection is secure")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct PrivacyTipsSection: View {
    let tips = [
        SecurityTip(icon: "eye.slash.fill", title: "Regular Cleanup", description: "Delete sensitive files regularly to minimize data exposure"),
        SecurityTip(icon: "lock.rotation", title: "Strong Passwords", description: "Use complex passwords and change them periodically"),
        SecurityTip(icon: "wifi.slash", title: "Public Networks", description: "Enable VPN when using public Wi-Fi networks"),
        SecurityTip(icon: "shippingbox.fill", title: "Before Selling", description: "Use secure shredder before selling or recycling your device")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Privacy Tips")
                .font(.headline)
            
            ForEach(tips) { tip in
                HStack(spacing: 12) {
                    Image(systemName: tip.icon)
                        .foregroundColor(.blue)
                        .frame(width: 30)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(tip.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text(tip.description)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
}

struct SecurityTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
}

struct SecurityView_Previews: PreviewProvider {
    static var previews: some View {
        SecurityView()
            .environmentObject(SecurityManager())
            .preferredColorScheme(.dark)
    }
}
