import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

enum TabEnum: String, CaseIterable, Hashable {
    case home         // 1. الرئيسية
    case library      // 2. التوقيع
    case appstore     // 3. متجر التطبيقات
    case settings     // 4. الإعدادات
    
    // الأقسام الإضافية
    case files
    case sources
    case certificates
    
    var title: String {
        switch self {
        case .home:         return "الرئيسية"
        case .library:      return "التوقيع"
        case .appstore:     return "متجر التطبيقات" 
        case .settings:     return "الإعدادات"
        case .files:        return .localized("Files")
        case .sources:      return .localized("Sources")
        case .certificates: return .localized("Certificates")
        }
    }
    
    var icon: String {
        switch self {
        // أيقونات عصرية وفخمة (Apple SF Symbols الحديثة)
        case .home:         return "house.fill"                  // بيت عصري وممتلئ
        case .library:      return "seal.fill"                   // أيقونة ختم التوثيق (تليق بالتوقيع)
        case .appstore:     return "square.stack.3d.up.fill"     // أيقونة 3D فخمة للمتجر
        case .settings:     return "slider.horizontal.3"         // أيقونة سلايدر احترافية للإعدادات
        case .files:        return "folder.fill"
        case .sources:      return "globe.desk"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home: HomeView() 
        case .library: LibraryView() 
        case .appstore: AppstoreView()
        case .settings: SettingsView()
        case .files: FilesView()
        case .sources: SourcesView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    // ترتيب الأزرار بالشريط السفلي
    static var defaultTabs: [TabEnum] {
        return [
            .home,      // تفتح الرئيسية أولاً
            .library,
            .appstore,
            .settings
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates,
            .files,
            .sources
        ]
    }
}
