//
//  SourceAppsView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//  Modified for Hassany Store (Custom Filter UI, Correct Sorting)
//

import SwiftUI
import AltSourceKit
import NimbleViews
import UIKit

// MARK: - Extension: View (Sort)
extension SourceAppsView {
    enum SortOption: String, CaseIterable {
        case `default` = "default"
        case name
        case date
        
        var displayName: String {
            switch self {
            case .default: return .localized("Default")
            case .name:    return .localized("Name")
            case .date:    return .localized("Date")
            }
        }
    }
}

// MARK: - View
struct SourceAppsView: View {
    @AppStorage("Feather.sortOptionRawValue") private var _sortOptionRawValue: String = SortOption.default.rawValue
    @AppStorage("Feather.sortAscending") private var _sortAscending: Bool = true
    
    @State private var _sortOption: SortOption = .default
    @State private var _selectedRoute: SourceAppRoute?
    @State private var isRefreshing = false
    
    // 🚀 متغير للتحكم بأقسام المتجر
    @State private var selectedCategory = 0 // 0: جميع التطبيقات, 1: مميزة
    
    @State var isLoading = true
    @State var hasLoadedOnce = false
    @State private var _searchText = ""
    var fromAppStore: Bool = false
    
    private var _navigationTitle: String {
        return "App Store"
    }
    
    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    @State private var _sources: [ASRepository]?
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    // 🚀 الفلترة والتقسيم
    private var _filteredApps: [SourceAppRoute] {
        guard let sources = _sources else { return [] }
        var all: [SourceAppRoute] = []
        
        for source in sources {
            // فلتر "تطبيقاتنا المميزة"
            if selectedCategory == 1 {
                // يعتمد على وجود كلمة Hassany في اسم السورس لتجنب أخطاء المسافات
                if let sourceName = source.name, sourceName.localizedCaseInsensitiveContains("Hassany") {
                    for app in source.apps {
                        all.append(SourceAppRoute(source: source, app: app))
                    }
                }
            } else {
                // فلتر "جميع التطبيقات" (يعرض الكل)
                for app in source.apps {
                    all.append(SourceAppRoute(source: source, app: app))
                }
            }
        }
        
        // ❌ شلنا الـ reversed() حتى يقرا من السورس مباشرة (واللي هو مرتب من الأحدث للأقدم أصلاً)
        
        let currentSearch = _searchText.lowercased()
        if !currentSearch.isEmpty {
            all = all.filter { route in
                let appName = route.app.name ?? ""
                return appName.lowercased().contains(currentSearch)
            }
        }
        
        let sortOpt = _sortOption
        let asc = _sortAscending
        
        if sortOpt == .name {
            all.sort { a, b in
                let nameA = a.app.name ?? ""
                let nameB = b.app.name ?? ""
                return asc ? (nameA < nameB) : (nameA > nameB)
            }
        }
        
        return all
    }
    
    var body: some View {
        ZStack {
            if let sources = _sources, !sources.isEmpty {
                ScrollView {
                    VStack(spacing: 16) {
                        
                        // 🚀 1. شريط التنقل الجديد (تصميم احترافي فخم)
                        HStack(spacing: 0) {
                            FilterTabButton(title: "جميع التطبيقات", isSelected: selectedCategory == 0) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedCategory = 0 }
                            }
                            FilterTabButton(title: "تطبيقاتنا المميزة", isSelected: selectedCategory == 1) {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selectedCategory = 1 }
                            }
                        }
                        .padding(4)
                        .background(Color(white: 0.1))
                        .clipShape(Capsule())
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                        
                        // 2. زر التحديث الفخم
                        _refreshBanner()
                        
                        // 3. عداد التطبيقات
                        HStack {
                            Text("عدد التطبيقات المتاحة: \(_filteredApps.count)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.purple)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(Color.purple.opacity(0.15))
                                .clipShape(Capsule())
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        
                        // 4. شبكة التطبيقات أو رسالة فارغة
                        if _filteredApps.isEmpty {
                            VStack(spacing: 15) {
                                Image(systemName: "square.stack.3d.up.slash")
                                    .font(.system(size: 50))
                                    .foregroundColor(.gray.opacity(0.5))
                                Text(selectedCategory == 1 ? "لا توجد تطبيقات مميزة حالياً" : "لا توجد تطبيقات")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16, weight: .medium))
                            }
                            .padding(.top, 60)
                        } else {
                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 16)], spacing: 16) {
                                ForEach(_filteredApps, id: \.id) { route in
                                    Button(action: {
                                        self._selectedRoute = route
                                    }) {
                                        AppCardView(route: route)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 20)
                        }
                    }
                }
            } else {
                if #available(iOS 17, *) {
                    ContentUnavailableView {
                        ProgressView()
                        Label(.localized("Fetching..."), systemImage: "")
                    } description: {
                        Text("جاري تحميل تطبيقات المتجر...")
                    }
                } else {
                    ProgressView()
                }
            }
        }
        .navigationTitle(_navigationTitle)
        .searchable(text: $_searchText, placement: .platform())
        .toolbar {
            NBToolbarMenu(
                systemImage: "arrow.up.arrow.down.circle",
                style: .icon,
                placement: .topBarTrailing
            ) {
                _sortActions()
            }
        }
        .onAppear {
            if !hasLoadedOnce, viewModel.isFinished {
                _load()
                hasLoadedOnce = true
            }
            _sortOption = SortOption(rawValue: _sortOptionRawValue) ?? .default
        }
        .onChange(of: viewModel.isFinished) { _ in
            _load()
        }
        .onChange(of: _sortOption) { newValue in
            _sortOptionRawValue = newValue.rawValue
        }
        .navigationDestinationIfAvailable(item: $_selectedRoute) { route in
            SourceAppsDetailView(source: route.source, app: route.app)
        }
    }
    
    private func _load() {
        isLoading = true
        Task {
            let loadedSources = object.compactMap { viewModel.sources[$0] }
            _sources = loadedSources
            withAnimation(.easeIn(duration: 0.2)) {
                isLoading = false
            }
        }
    }
    
    struct SourceAppRoute: Identifiable, Hashable {
        let source: ASRepository
        let app: ASRepository.App
        let id: String = UUID().uuidString
    }
}

// 🚀 زر الفلتر الجديد المخصص (تصميم فخم)
struct FilterTabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(isSelected ? .white : .gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? LinearGradient(colors: [.purple, Color(red: 0.4, green: 0, blue: 0.8)], startPoint: .leading, endPoint: .trailing) : LinearGradient(colors: [.clear, .clear], startPoint: .leading, endPoint: .trailing))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

extension SourceAppsView {
    @ViewBuilder
    private func _refreshBanner() -> some View {
        Button(action: {
            isRefreshing = true
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.impactOccurred()
            Task {
                await viewModel.fetchSources(_allSources, refresh: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    isRefreshing = false
                }
            }
        }) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.purple)
                    .rotationEffect(.degrees(isRefreshing ? 360 : 0))
                    .animation(isRefreshing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("تحديث المتجر")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    Text("اضغط لتحديث التطبيقات وإضافة الجديد")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.gray.opacity(0.5))
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.8))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.2), lineWidth: 1))
            .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func _sortActions() -> some View {
        Section("ترتيب حسب") {
            ForEach(SortOption.allCases, id: \.displayName) { opt in
                Button {
                    if _sortOption == opt {
                        _sortAscending.toggle()
                    } else {
                        _sortOption = opt
                        _sortAscending = true
                    }
                } label: {
                    HStack {
                        Text(opt.displayName)
                        Spacer()
                        if _sortOption == opt {
                            Image(systemName: _sortAscending ? "chevron.up" : "chevron.down")
                        }
                    }
                }
            }
        }
    }
}

extension View {
    @ViewBuilder
    func navigationDestinationIfAvailable<Item: Identifiable & Hashable, Destination: View>(
        item: Binding<Item?>,
        @ViewBuilder destination: @escaping (Item) -> Destination
    ) -> some View {
        if #available(iOS 17, *) {
            self.navigationDestination(item: item, destination: destination)
        } else {
            self
        }
    }
}

struct AppCardView: View {
    let route: SourceAppsView.SourceAppRoute
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: route.app.iconURL) { phase in
                if let image = phase.image {
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else if phase.error != nil {
                    Image(systemName: "app.dashed")
                        .resizable()
                        .foregroundColor(.gray)
                } else {
                    ProgressView()
                }
            }
            .frame(width: 75, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            VStack(spacing: 4) {
                Text(route.app.name ?? "Unknown App")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("v\(route.app.version ?? "1.0")")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            
            Text("تثبيت")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.purple, Color(red: 0.4, green: 0.1, blue: 0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Capsule())
                .shadow(color: .purple.opacity(0.3), radius: 3, x: 0, y: 2)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.8))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.purple.opacity(0.1), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
