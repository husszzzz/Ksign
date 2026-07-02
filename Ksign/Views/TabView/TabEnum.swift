//
//  TabEnum.swift
//  feather
//
//  Created by samara on 22.03.2025.
//  Modified for Hassany Store
//

import SwiftUI
import NimbleViews

enum TabEnum: String, CaseIterable, Hashable {
    case files
    case sources
    case library
    case settings
    case certificates
    case appstore
    
    // تم حذف قسم التنزيلات (downloader) من الجذور
    
    var title: String {
        switch self {
        case .files:        return .localized("Files")
        case .sources:      return .localized("Sources")
        case .library:      return .localized("Library")
        case .settings:     return .localized("Settings")
        case .certificates: return .localized("Certificates")
        case .appstore:     return .localized("App Store")
        }
    }
    
    var icon: String {
        switch self {
        case .files:        return "folder.fill"
        case .sources:      return "globe.desk"
        case .library:      return "square.grid.2x2"
        case .settings:     return "gearshape.2"
        case .certificates: return "person.text.rectangle"
        case .appstore:     return "plus.app.fill"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .files: FilesView()
        case .sources: SourcesView()
        case .library: LibraryView()
        case .settings: SettingsView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        case .appstore: AppstoreView()
        }
    }
    
    // هذا الجزء هو اللي يتحكم بالترتيب وأول قسم يفتح بالتطبيق
    static var defaultTabs: [TabEnum] {
        return [
            .appstore,  // 1. App Store (يفتح المتجر عليه مباشرة)
            .files,     // 2. الملفات
            .library,   // 3. المكتبة
            .settings   // 4. الإعدادات
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}
