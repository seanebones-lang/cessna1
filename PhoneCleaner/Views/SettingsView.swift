import SwiftUI

struct SettingsView: View {
    @State private var enableNotifications = true
    @State private var enableAutoClean = false
    @State private var enableDarkMode = true
    @State private var showAbout = false
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("APEX iPhone Cleaner PRO")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Version 1.0.0")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "iphone")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical)
                }
                
                Section(header: Text("General")) {
                    Toggle("Enable Notifications", isOn: $enableNotifications)
                    Toggle("Auto Clean", isOn: $enableAutoClean)
                    Toggle("Dark Mode", isOn: $enableDarkMode)
                }
                
                Section(header: Text("Cleaning")) {
                    NavigationLink(destination: CleaningPreferencesView()) {
                        Label("Cleaning Preferences", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink(destination: ScheduleView()) {
                        Label("Schedule Scans", systemImage: "calendar")
                    }
                }
                
                Section(header: Text("Privacy & Security")) {
                    Button {
                        showPrivacyPolicy = true
                    } label: {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: DataManagementView()) {
                        Label("Data Management", systemImage: "externaldrive.fill")
                    }
                }
                
                Section(header: Text("Support")) {
                    NavigationLink(destination: HelpView()) {
                        Label("Help & FAQ", systemImage: "questionmark.circle")
                    }
                    
                    Button {
                        showAbout = true
                    } label: {
                        Label("About", systemImage: "info.circle")
                            .foregroundColor(.primary)
                    }
                    
                    NavigationLink(destination: FeedbackView()) {
                        Label("Send Feedback", systemImage: "envelope")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        
                    } label: {
                        Label("Reset All Settings", systemImage: "arrow.counterclockwise")
                    }
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                PrivacyPolicyView()
            }
        }
    }
}

struct CleaningPreferencesView: View {
    @State private var scanPhotos = true
    @State private var scanVideos = true
    @State private var detectDuplicates = true
    @State private var detectBlurry = true
    @State private var minimumQualityThreshold = 0.3
    
    var body: some View {
        List {
            Section(header: Text("Scan Options")) {
                Toggle("Scan Photos", isOn: $scanPhotos)
                Toggle("Scan Videos", isOn: $scanVideos)
                Toggle("Detect Duplicates", isOn: $detectDuplicates)
                Toggle("Detect Blurry Photos", isOn: $detectBlurry)
            }
            
            Section(header: Text("Quality Settings")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Minimum Quality Threshold")
                        .font(.subheadline)
                    
                    Slider(value: $minimumQualityThreshold, in: 0...1)
                    
                    HStack {
                        Text("Low")
                            .font(.caption)
                            .foregroundColor(.gray)
                        Spacer()
                        Text("High")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Cleaning Preferences")
    }
}

struct ScheduleView: View {
    @State private var enableSchedule = false
    @State private var scheduleFrequency = "Weekly"
    
    let frequencies = ["Daily", "Weekly", "Monthly"]
    
    var body: some View {
        List {
            Section {
                Toggle("Enable Scheduled Scans", isOn: $enableSchedule)
            }
            
            if enableSchedule {
                Section(header: Text("Frequency")) {
                    Picker("Frequency", selection: $scheduleFrequency) {
                        ForEach(frequencies, id: \.self) { frequency in
                            Text(frequency).tag(frequency)
                        }
                    }
                    .pickerStyle(.inline)
                }
            }
        }
        .navigationTitle("Schedule Scans")
    }
}

struct DataManagementView: View {
    var body: some View {
        List {
            Section(header: Text("App Data")) {
                Button {
                    
                } label: {
                    Label("Clear App Cache", systemImage: "trash")
                        .foregroundColor(.orange)
                }
                
                Button(role: .destructive) {
                    
                } label: {
                    Label("Delete All App Data", systemImage: "trash.fill")
                }
            }
            
            Section(header: Text("Analytics")) {
                Text("APEX iPhone Cleaner PRO does not collect personal data. All scans and analyses are performed locally on your device.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle("Data Management")
    }
}

struct HelpView: View {
    let faqs = [
        FAQ(question: "How does duplicate detection work?", answer: "Our AI-powered algorithm analyzes photos using perceptual hashing to identify visually similar images with high accuracy."),
        FAQ(question: "Is my data safe?", answer: "Absolutely. All processing happens on your device. We don't upload or transmit any of your photos or data."),
        FAQ(question: "What is secure file shredding?", answer: "Secure shredding overwrites files multiple times with random data, making recovery impossible even with forensic tools."),
        FAQ(question: "Can I recover deleted photos?", answer: "Once photos are deleted through APEX iPhone Cleaner PRO, they are moved to the Photos app's Recently Deleted album where they can be recovered for 30 days."),
        FAQ(question: "How often should I clean my device?", answer: "We recommend scanning weekly for optimal storage management, or enable automatic scheduled scans.")
    ]
    
    var body: some View {
        List {
            Section(header: Text("Frequently Asked Questions")) {
                ForEach(faqs) { faq in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(faq.question)
                            .font(.headline)
                        
                        Text(faq.answer)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Help & FAQ")
    }
}

struct FAQ: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

struct FeedbackView: View {
    @State private var feedbackText = ""
    @State private var feedbackType = "General"
    
    let feedbackTypes = ["General", "Bug Report", "Feature Request", "Other"]
    
    var body: some View {
        List {
            Section(header: Text("Feedback Type")) {
                Picker("Type", selection: $feedbackType) {
                    ForEach(feedbackTypes, id: \.self) { type in
                        Text(type).tag(type)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            Section(header: Text("Your Feedback")) {
                TextEditor(text: $feedbackText)
                    .frame(minHeight: 150)
            }
            
            Section {
                Button {
                    
                } label: {
                    Text("Submit Feedback")
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.blue)
                }
            }
        }
        .navigationTitle("Send Feedback")
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Image(systemName: "iphone.badge.shield")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("APEX iPhone Cleaner PRO")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        AboutFeature(icon: "photo.stack", title: "AI-Powered", description: "Advanced algorithms for duplicate and quality detection")
                        AboutFeature(icon: "lock.shield", title: "Secure", description: "Military-grade encryption and secure deletion")
                        AboutFeature(icon: "speedometer", title: "Fast", description: "Optimized performance for quick scans")
                        AboutFeature(icon: "hand.raised", title: "Private", description: "All processing happens on your device")
                    }
                    .padding(.horizontal)
                    
                    Divider()
                        .padding(.horizontal)
                    
                    Text("© 2025 APEX iPhone Cleaner PRO\nAll rights reserved.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding(.top, 40)
            }
            .navigationTitle("About")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        
                    }
                }
            }
        }
    }
}

struct AboutFeature: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Privacy Policy")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Last updated: October 2025")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    privacySection(
                        title: "Data Collection",
                        content: "APEX iPhone Cleaner PRO does not collect, store, or transmit any personal data. All photo analysis and storage scans are performed locally on your device."
                    )
                    
                    privacySection(
                        title: "Photo Library Access",
                        content: "We request access to your photo library solely to identify duplicates and low-quality photos. Photos are analyzed on-device using AI algorithms and are never uploaded to external servers."
                    )
                    
                    privacySection(
                        title: "Storage Analysis",
                        content: "Storage analysis is performed using iOS system APIs. We only access directories and files that the app has permission to read, primarily within the app's sandbox."
                    )
                    
                    privacySection(
                        title: "Encryption",
                        content: "All app data is encrypted using AES-256 encryption. Encryption keys are stored securely in the iOS Keychain and never leave your device."
                    )
                    
                    privacySection(
                        title: "Third-Party Services",
                        content: "APEX iPhone Cleaner PRO does not integrate with any third-party analytics, advertising, or data collection services."
                    )
                    
                    privacySection(
                        title: "Data Deletion",
                        content: "When you delete photos or files through the app, they are permanently removed according to your device's standard deletion process. Secure shredding uses multi-pass overwriting for enhanced security."
                    )
                    
                    privacySection(
                        title: "Changes to This Policy",
                        content: "We may update this privacy policy from time to time. Any changes will be reflected in the app and on our website."
                    )
                    
                    privacySection(
                        title: "Contact Us",
                        content: "If you have questions about this privacy policy, please contact us through the app's feedback feature."
                    )
                }
                .padding()
            }
            .navigationTitle("Privacy Policy")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        
                    }
                }
            }
        }
    }
    
    func privacySection(title: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            
            Text(content)
                .font(.body)
                .foregroundColor(.gray)
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .preferredColorScheme(.dark)
    }
}
