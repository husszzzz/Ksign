//
//  SourceAppsView.swift
//  Feather
//
//  Created by samara on 1.05.2025.
//  Modified for Hassany Store (Grid UI)
//

import SwiftUI
import AltSourceKit
import NimbleViews
import UIKit

// MARK: - Extension: View (Enil)
extension SourceAppsView {
    enum SortOption: String, CaseIterable {
        case `default` = "default"
        case name
        case date
        
        var displayName: String {
            switch self {
            case .default:  .localized("Default")
            case .name:     .localized("Name")
            case .date:     .localized("Date")
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
    
    @State var isLoading = true
    @State var hasLoadedOnce = false
    @State private var _searchText = ""
    var fromAppStore: Bool = false
    
    private var _navigationTitle: String {
        if fromAppStore {
            return .localized("App Store")
        } else if object.count == 1 {
            return object[0].name ?? .localized("Unknown")
        } else {
            return .localized("%lld Sources", arguments: object.count)
        }
    }
    
    var object: [AltSource]
    @ObservedObject var viewModel: SourcesViewModel
    @State private var _sources: [ASRepository]?
    
    @FetchRequest(
        entity: AltSource.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \AltSource.name, ascending: true)],
        animation: .snappy
    ) private var _allSources: FetchedResults<AltSource>
    
    // فلترة التطبيقات للبحث والشبكة (Grid) - تم التعديل هنا للتعامل مع الـ Optional
    private var _filteredApps: [SourceAppRoute] {
        guard let sources = _sources else { return [] }
        var all = [SourceAppRoute]()
        for source in sources {
            for app in source.apps {
                all.append(SourceAppRoute(source: source, app: app))
            }
        }
        
        if !_searchText.isEmpty {
            all = all.filter { ($0.app.name ?? "").localizedCaseInsensitiveContains(_searchText) }
        }
        return all
    }
    
    // MARK: Body
    var body: some View {
        ZStack {
            if let _sources, !_sources.isEmpty {
                // التصميم الجديد: نظام الكارتات (Grid)
                ScrollView {
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
                    .padding(16)
                }
            } else {
                if #available(iOS 17, *) {
                    ContentUnavailableView {
                        ProgressView()
                        Label(.localized("Fetching..."), systemImage: "")
                    } description: {
                        Text(.localized("Stuck? Check if you have any sources added."))
                    }
                }
                else { ProgressView() }
            }
        }
        .navigationTitle(_navigationTitle)
        .searchable(text: $_searchText, placement: .platform())
        .toolbarTitleMenu {
            if let _sources, _sources.count == 1 {
                if let url = _sources[0].website {
                    Button(.localized("Visit Website"), systemImage: "globe") {
                        UIApplication.open(url)
                    }
                }
                if let url = _sources[0].patreonURL {
                    Button(.localized("Visit Patreon"), systemImage: "dollarsign.circle") {
                        UIApplication.open(url)
                    }
                }
            }
            Divider()
            Button(.localized("Copy"), systemImage: "doc.on.doc") {
                UIPasteboard.general.string = object.map {
                    $0.sourceURL!.absoluteString
                }.joined(separator: "\n")
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }
        }
        .toolbar {
            if fromAppStore {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        SourcesView()
                    } label: {
                        Text(.localized("Sources"))
                    }
                }
            }
            
            NBToolbarButton(
                systemImage: "arrow.trianglehead.2.counterclockwise.rotate.90",
                style: .icon,
                placement: .topBarTrailing
            ) {
                Task {
                    await viewModel.fetchSources(_allSources, refresh: true)
                }
            }
            
            NBToolbarMenu(
                systemImage: "line.3.horizontal.decrease",
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

// MARK: - Extension: View (Sort)
extension SourceAppsView {
    @ViewBuilder
    private func _sortActions() -> some View {
        Section(.localized("Filter by")) {
            ForEach(SortOption.allCases, id: \.displayName) { opt in
                _sortButton(for: opt)
            }
        }
    }
    
    private func _sortButton(for option: SortOption) -> some View {
        Button {
            if _sortOption == option {
                _sortAscending.toggle()
            } else {
                _sortOption = option
                _sortAscending = true
            }
        } label: {
            HStack {
                Text(option.displayName)
                Spacer()
                if _sortOption == option {
                    Image(systemName: _sortAscending ? "chevron.up" : "chevron.down")
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

// MARK: - التصميم الجديد: كارت التطبيق
struct AppCardView: View {
    let route: SourceAppsView.SourceAppRoute
    
    var body: some View {
        VStack(spacing: 12) {
            // صورة التطبيق
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
            
            // اسم التطبيق والإصدار - تم التعديل هنا للتعامل مع الـ Optional
            VStack(spacing: 4) {
                Text(route.app.name ?? "Unknown App")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                Text("v\(route.app.version)")
                    .font(.system(size: 12, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.secondary)
            }
            
            // زر التثبيت
            Text("تثبيت")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.accentColor) // يأخذ اللون الأساسي لمتجرك
                .clipShape(Capsule())
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}
