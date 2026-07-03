//
//  ContentView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//  Modified for Hassany Store - Signed Apps Only
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
    @StateObject var downloadManager = DownloadManager.shared
    
    @State private var _selectedInfoAppPresenting: AnyApp?
    @State private var _selectedSigningAppPresenting: AnyApp?
    @State private var _selectedInstallAppPresenting: AnyApp?
    @State private var _selectedAppDylibsPresenting: AnyApp?
    @State private var _isBulkInstallingPresenting = false
    
    @State private var _searchText = ""
    
    // MARK: Edit Mode
    @State private var _isEditMode: EditMode = .inactive
    @State private var _selectedApps: Set<String> = []
    
    @Namespace private var _namespace
    
    // فلترة التطبيقات حسب البحث
    private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
        apps.filter {
            _searchText.isEmpty ||
            (($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
        }
    }
    
    // سحب التطبيقات الموقعة فقط
    private var _filteredSignedApps: [Signed] {
        filteredAndSortedApps(from: _signedApps)
    }
    
    // MARK: Fetch
    @FetchRequest(
        entity: Signed.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
        animation: .snappy
    ) private var _signedApps: FetchedResults<Signed>
    
    @FetchRequest(
        entity: Imported.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
        animation: .snappy
    ) private var _importedApps: FetchedResults<Imported>
    
    // MARK: Body
    var body: some View {
        NBNavigationView("التطبيقات الموقعة") {
            VStack(spacing: 0) {
                NBListAdaptable {
                    NBSection(
                        "التطبيقات الموقعة",
                        secondary: _filteredSignedApps.count.description
                    ) {
                        ForEach(_filteredSignedApps, id: \.uuid) { app in
                            LibraryCellView(
                                app: app,
                                selectedInfoAppPresenting: $_selectedInfoAppPresenting,
                                selectedSigningAppPresenting: $_selectedSigningAppPresenting,
                                selectedInstallAppPresenting: $_selectedInstallAppPresenting,
                                selectedAppDylibsPresenting: $_selectedAppDylibsPresenting,
                                selectedApps: $_selectedApps
                            )
                            .compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
                        }
                    }
                }
            }
            .searchable(text: $_searchText, placement: .platform())
            .overlay {
                if _filteredSignedApps.isEmpty {
                    if #available(iOS 17, *) {
                        ContentUnavailableView {
                            Label("لا توجد تطبيقات", systemImage: "signature")
                        } description: {
                            Text("ستظهر هنا التطبيقات التي قمت بتوقيعها من قسم الملفات.")
                        }
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                if _isEditMode.isEditing {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            _isBulkInstallingPresenting = true
                        } label: {
                            NBButton(.localized("Install"), systemImage: "square.and.arrow.down")
                        }
                        .disabled(_selectedApps.isEmpty)
                        
                        Button {
                            _bulkDeleteSelectedApps()
                        } label: {
                            NBButton(.localized("Delete"), systemImage: "trash", style: .icon)
                        }
                        .disabled(_selectedApps.isEmpty)
                    }
                }
            }
            .environment(\.editMode, $_isEditMode)
            .sheet(item: $_selectedInfoAppPresenting) { app in
                LibraryInfoView(app: app.base)
            }
            .sheet(item: $_selectedInstallAppPresenting) { app in
                InstallPreviewView(app: app.base, isSharing: app.archive)
                    .presentationDetents([.height(200)])
                    .presentationDragIndicator(.visible)
            }
            .fullScreenCover(item: $_selectedSigningAppPresenting) { app in
                SigningView(app: app.base, signAndInstall: app.signAndInstall)
                    .compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
            }
            .fullScreenCover(item: $_selectedAppDylibsPresenting) { app in
                DylibsView(app: app.base)
                    .compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
            }
            .sheet(isPresented: $_isBulkInstallingPresenting) {
                BulkInstallPreviewView(apps: _selectedApps.compactMap { id in
                    (_signedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
                })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("feather.installApp"))) { notification in
                if let app = _signedApps.first {
                    _selectedInstallAppPresenting = AnyApp(base: app)
                }
            }
        }
        .onChange(of: _isEditMode) { state in
            if !state.isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation{
                        _selectedApps.removeAll()
                    }
                }
            }
        }
    }
}

// MARK: - Extension: View (Edit Mode Functions)
extension LibraryView {
    private func _bulkDeleteSelectedApps() {
        let appsToDelete = _selectedApps
        
        withAnimation(.easeInOut(duration: 0.5)) {
            for appUUID in appsToDelete {
                if let signedApp = _signedApps.first(where: { $0.uuid == appUUID }) {
                    Storage.shared.deleteApp(for: signedApp)
                } else if let importedApp = _importedApps.first(where: { $0.uuid == appUUID }) {
                    Storage.shared.deleteApp(for: importedApp)
                }
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            _selectedApps.removeAll()
        }
    }
}
