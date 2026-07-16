import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

enum TabEnum: String, CaseIterable, Hashable {
    case home         
    case library      
    case appstore     
    case settings     
    
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
        case .home:         return "house.fill"
        case .library:      return "signature" // أيقونة القلم والدائرة
        case .appstore:     return "square.stack.3d.up.fill"
        case .settings:     return "slider.horizontal.3"
        case .files:        return "folder.fill"
        case .sources:      return "globe.desk"
        case .certificates: return "person.text.rectangle"
        }
    }
    
    @ViewBuilder
    static func view(for tab: TabEnum) -> some View {
        switch tab {
        // 🚀 الحل هنا: شلنا التمرير ورجعناه يستدعي الشاشة طبيعي
        case .home: HomeView() 
        case .library: LibraryView() 
        case .appstore: AppstoreView()
        case .settings: SettingsView()
        case .files: FilesView()
        case .sources: SourcesView()
        case .certificates: NBNavigationView(.localized("Certificates")) { CertificatesView() }
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .home,      
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
