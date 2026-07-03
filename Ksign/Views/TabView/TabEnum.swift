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
    case signing
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
        case .appstore:     return "متجر التطبيقات" // التعديل الأول: تغيير الاسم
        case .signing:      return "التوقيع"        // التعديل الثاني: إضافة التوقيع
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
        case .signing:      return "signature" // أيقونة التوقيع الجديدة
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
        case .signing: SigningMainView() // مربوطة بالواجهة الجديدة المدمجة
        }
    }
    
    // هذا الجزء هو اللي يتحكم بالترتيب والأقسام المعروضة بالشريط السفلي
    static var defaultTabs: [TabEnum] {
        return [
            .appstore,  // 1. متجر التطبيقات (يفتح المتجر عليه مباشرة)
            .signing,   // 2. التوقيع (القسم الجديد اللي راح يدمج الملفات والموقع)
            .settings   // 3. الإعدادات
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}

// MARK: - واجهة التوقيع المدمجة (الخطوة الثانية)
struct SigningMainView: View {
    // حالة المتغير لمعرفة أي قسم مختار (0 = الملفات، 1 = موقع)
    @State private var selectedTab = 0
    
    var body: some View {
        VStack(spacing: 0) {
            // شريط التبديل (Segmented Control) اللي يصير فوق
            VStack {
                Picker("القسم", selection: $selectedTab) {
                    Text("الملفات").tag(0)
                    Text("موقع").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 10)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .zIndex(1)
            
            // عرض الواجهات بناءً على الاختيار (بدون تأثير سحب حتى لا يتعارض مع حذف الملفات)
            if selectedTab == 0 {
                FilesView() // واجهة استيراد الملفات
            } else {
                LibraryView() // واجهة التطبيقات الموقعة
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
    }
}
