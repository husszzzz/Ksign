//
//  AppstoreView.swift
//  Feather (Modified for Hassany Store - Categories & Sorting Newest to Oldest)
//

import SwiftUI
import AltSourceKit
import CoreData

// MARK: - مسار التطبيق في المتجر
struct AppstoreAppRoute: Identifiable, Hashable {
    let source: ASRepository
    let app: ASRepository.App
    let id: String = UUID().uuidString
}

struct AppstoreView: View {
    @StateObject private var viewModel = SourcesViewModel()
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    @State private var searchText = ""
    @State private var selectedCategory = 0 // 0: جميع التطبيقات, 1: المميزة
    @State private var isRefreshing = false
    
    // 1. جميع التطبيقات (من كل المصادر) معكوسة لتظهر من الأحدث للأقدم
    private var allApps: [AppstoreAppRoute] {
        var all: [AppstoreAppRoute] = []
        for source in _allSources {
            if let repo = viewModel.sources[source] {
                for app in repo.apps {
                    all.append(AppstoreAppRoute(source: repo, app: app))
                }
            }
        }
        return all.reversed() // 🚀 من الأحدث للأقدم
    }
    
    // 2. التطبيقات المميزة (من ملف الجيسون الخاص بيك فقط)
    private var featuredApps: [AppstoreAppRoute] {
        var featured: [AppstoreAppRoute] = []
        for source in _allSources {
            if let repo = viewModel.sources[source] {
                // 🚀 الفلترة هنا تعتمد على اسم ومعرف السورس اللي سويناه بلوحة التحكم
                if repo.name == "Hassany Store Apps" || repo.identifier == "com.hassanystore.source" || repo.identifier == "com.hassanystore.apps" {
                    for app in repo.apps {
                        featured.append(AppstoreAppRoute(source: repo, app: app))
                    }
                }
            }
        }
        return featured.reversed() // 🚀 من الأحدث للأقدم
    }
    
    // 3. التطبيقات المعروضة حالياً (حسب القسم المختار والبحث)
    private var displayedApps: [AppstoreAppRoute] {
        let sourceApps = (selectedCategory == 0) ? allApps : featuredApps
        if searchText.isEmpty {
            return sourceApps
        } else {
            return sourceApps.filter { $0.app.name?.localizedCaseInsensitiveContains(searchText) == true }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 20) {
                        
                        // 1. شريط البحث
                        HStack {
                            Image(systemName: "magnifyingglass").foregroundColor(.gray)
                            TextField("بحث عن تطبيق...", text: $searchText)
                                .foregroundColor(.white)
                        }
                        .padding(12)
                        .background(Color(white: 0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        
                        // 2. أقسام المتجر (شريط التنقل) 🚀
                        Picker("التصنيفات", selection: $selectedCategory) {
                            Text("جميع التطبيقات").tag(0)
                            Text("تطبيقاتنا المميزة").tag(1)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 20)
                        
                        // 3. زر تحديث المتجر (نفس تصميمك)
                        Button(action: {
                            refreshStore()
                        }) {
                            HStack {
                                Image(systemName: "chevron.left").foregroundColor(.gray.opacity(0.6))
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text("تحديث المتجر").font(.system(size: 18, weight: .bold)).foregroundColor(.white)
                                    Text("اضغط لتحديث التطبيقات وإضافة الجديد").font(.system(size: 13, weight: .medium)).foregroundColor(.gray)
                                }
                                if isRefreshing {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .purple))
                                        .padding(.leading, 10)
                                } else {
                                    Image(systemName: "arrow.triangle.2.circlepath").font(.system(size: 24)).foregroundColor(.purple)
                                        .padding(.leading, 10)
                                }
                            }
                            .padding(20)
                            .background(Color(white: 0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.purple.opacity(0.3), lineWidth: 1))
                            .padding(.horizontal, 20)
                        }
                        .buttonStyle(.plain)
                        
                        // 4. عداد التطبيقات (نفس تصميمك)
                        HStack {
                            Spacer()
                            Text("عدد التطبيقات المتاحة: \(displayedApps.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(Color(red: 0.8, green: 0.4, blue: 1.0))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.purple.opacity(0.2))
                                .clipShape(Capsule())
                        }
                        .padding(.horizontal, 20)
                        
                        // 5. شبكة التطبيقات المعروضة
                        if displayedApps.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "square.stack.3d.up.slash").font(.system(size: 50)).foregroundColor(.gray.opacity(0.5))
                                Text(selectedCategory == 1 ? "لا توجد تطبيقات مميزة حالياً" : "لا توجد تطبيقات")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .padding(.top, 50)
                        } else {
                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 15), GridItem(.flexible(), spacing: 15)], spacing: 20) {
                                ForEach(displayedApps, id: \.id) { route in
                                    NavigationLink(destination: SourceAppsDetailView(source: route.source, app: route.app)) {
                                        StoreAppCard(app: route.app)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
            .navigationTitle("App Store")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        // إجراء إضافي يمكن استخدامه لاحقاً
                    }) {
                        Image(systemName: "arrow.up.arrow.down.circle").foregroundColor(.purple)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchSources(_allSources, refresh: false)
                }
            }
        }
    }
    
    private func refreshStore() {
        guard !isRefreshing else { return }
        isRefreshing = true
        Task {
            await viewModel.fetchSources(_allSources, refresh: true)
            await MainActor.run {
                isRefreshing = false
            }
        }
    }
}

// MARK: - كارت التطبيق في المتجر
struct StoreAppCard: View {
    let app: ASRepository.App
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: app.iconURL) { phase in
                if let image = phase.image {
                    image.resizable().aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Image(systemName: "app.dashed").resizable().foregroundColor(.gray)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 80, height: 80)
            .clipShape(RoundedRectangle(cornerRadius: 18))
            
            VStack(spacing: 4) {
                Text(app.name ?? "تطبيق")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text("v\(app.version ?? "1.0")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            
            Text("تثبيت")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(LinearGradient(colors: [.purple, Color(red: 0.4, green: 0, blue: 0.8)], startPoint: .leading, endPoint: .trailing))
                .clipShape(Capsule())
        }
        .padding(16)
        .background(Color(white: 0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}
