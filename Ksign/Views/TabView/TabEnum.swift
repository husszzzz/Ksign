import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

enum TabEnum: String, CaseIterable, Hashable {
    case home         // 1. ضفنا قسم الرئيسية
    case library      // 2. هذا هو قسم التوقيع الحقيقي (LibraryView)
    case appstore     // 3. متجر التطبيقات
    case settings     // 4. الإعدادات
    
    // الأقسام الإضافية
    case files
    case sources
    case certificates
    
    var title: String {
        switch self {
        case .home:         return "الرئيسية"
        case .library:      return "التوقيع" // غيرنا اسمه للتوقيع
        case .appstore:     return "متجر التطبيقات" 
        case .settings:     return .localized("Settings")
        case .files:        return .localized("Files")
        case .sources:      return .localized("Sources")
        case .certificates: return .localized("Certificates")
        }
    }
    
    var icon: String {
        switch self {
        case .home:         return "house.fill" // أيقونة البيت للرئيسية
        case .library:      return "signature"  // أيقونة التوقيع
        case .appstore:     return "plus.app.fill"
        case .settings:     return "gearshape.2"
        case .files:        return "folder.fill"
        case .sources:      return "globe.desk"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        case .home: HomeView() // استدعاء واجهة الرئيسية الجديدة اللي صممناها
        case .library: LibraryView() // استدعاء التوقيع الحقيقي (اللي برمجناه قبل شوية)
        case .appstore: AppstoreView()
        case .settings: SettingsView()
        case .files: FilesView()
        case .sources: SourcesView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    // ترتيب الأزرار بالشريط السفلي (من اليسار لليمين أو حسب لغة الجهاز)
    static var defaultTabs: [TabEnum] {
        return [
            .home,      // الرئيسية راح تكون أول وحدة تفتح
            .library,   // بعدها قسم التوقيع
            .appstore,  // بعدها المتجر
            .settings   // وأخيراً الإعدادات
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
