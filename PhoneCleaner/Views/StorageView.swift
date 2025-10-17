import SwiftUI

struct StorageView: View {
    @EnvironmentObject var storageManager: StorageManager
    @State private var selectedCategory: StorageCategory?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if let analysis = storageManager.storageAnalysis {
                        StorageOverviewCard(analysis: analysis)
                            .padding(.horizontal)
                        
                        StorageBreakdownChart(items: analysis.items, selectedCategory: $selectedCategory)
                            .padding(.horizontal)
                        
                        CategoryList(items: analysis.items)
                            .padding(.horizontal)
                    } else if storageManager.isAnalyzing {
                        ProgressView("Analyzing storage...")
                            .padding()
                    } else {
                        Button {
                            Task {
                                await storageManager.analyzeStorage()
                            }
                        } label: {
                            Label("Analyze Storage", systemImage: "chart.pie.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(15)
                        }
                        .padding()
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Storage")
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await storageManager.analyzeStorage()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
    }
}

struct StorageOverviewCard: View {
    let analysis: StorageAnalysis
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Storage Overview")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(analysis.formattedUsedSpace) of \(analysis.formattedTotalSpace) used")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    ForEach(analysis.items) { item in
                        Rectangle()
                            .fill(categoryColor(item.category))
                            .frame(width: geometry.size.width * CGFloat(item.percentage / 100))
                    }
                }
                .frame(height: 30)
                .cornerRadius(15)
            }
            .frame(height: 30)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Used")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(analysis.formattedUsedSpace)
                        .font(.headline)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Available")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(analysis.formattedFreeSpace)
                        .font(.headline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func categoryColor(_ category: StorageCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

struct StorageBreakdownChart: View {
    let items: [StorageItem]
    @Binding var selectedCategory: StorageCategory?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown by Category")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: item.category.iconName)
                            .foregroundColor(categoryColor(item.category))
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.category.rawValue)
                                .font(.subheadline)
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(height: 6)
                                        .cornerRadius(3)
                                    
                                    Rectangle()
                                        .fill(categoryColor(item.category))
                                        .frame(width: geometry.size.width * CGFloat(item.percentage / 100), height: 6)
                                        .cornerRadius(3)
                                }
                            }
                            .frame(height: 6)
                        }
                        
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(item.formattedSize)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                            
                            Text("\(Int(item.percentage))%")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(20)
    }
    
    private func categoryColor(_ category: StorageCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

struct CategoryList: View {
    let items: [StorageItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Storage Details")
                .font(.title3)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(items) { item in
                    CategoryRow(item: item)
                }
            }
        }
    }
}

struct CategoryRow: View {
    let item: StorageItem
    
    var body: some View {
        HStack {
            Image(systemName: item.category.iconName)
                .font(.title2)
                .foregroundColor(categoryColor(item.category))
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.category.rawValue)
                    .font(.headline)
                
                Text("\(Int(item.percentage))% of total storage")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            Text(item.formattedSize)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(15)
    }
    
    private func categoryColor(_ category: StorageCategory) -> Color {
        switch category.color {
        case "blue": return .blue
        case "purple": return .purple
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        default: return .gray
        }
    }
}

struct StorageView_Previews: PreviewProvider {
    static var previews: some View {
        StorageView()
            .environmentObject(StorageManager())
            .preferredColorScheme(.dark)
    }
}
