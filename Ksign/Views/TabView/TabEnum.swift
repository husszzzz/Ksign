import SwiftUI
import NimbleViews
import UniformTypeIdentifiers

enum TabEnum: String, CaseIterable, Hashable {
    case signing
    case files
    case sources
    case library
    case settings
    case certificates
    case appstore
    
    var title: String {
        switch self {
        case .files:        return .localized("Files")
        case .sources:      return .localized("Sources")
        case .library:      return .localized("Library")
        case .settings:     return .localized("Settings")
        case .certificates: return .localized("Certificates")
        case .appstore:     return "متجر التطبيقات" 
        case .signing:      return "التوقيع"        
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
        case .signing:      return "signature" 
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
        case .signing: SigningMainView() // هنا تم ربط واجهتك الجديدة
        }
    }
    
    static var defaultTabs: [TabEnum] {
        return [
            .appstore,  
            .signing,   
            .settings   
        ]
    }
    
    static var customizableTabs: [TabEnum] {
        return [
            .certificates
        ]
    }
}

// MARK: - واجهة التوقيع المدمجة التي قمت بتصميمها
struct SigningMainView: View {
    // 0: لم يتم التوقيع، 1: موقّعة
    @State private var selectedTab = 0 
    @State private var searchText = ""
    @State private var showingImporter = false
    @State private var isEditing = false
    
    // قوائم فارغة حالياً حتى تظهر واجهة "لا توجد تطبيقات" كما في صورتك تماماً
    @State private var unsignedApps: [String] = []
    @State private var signedApps: [String] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                // لون الخلفية الأسود المطابق لتصميم متجرك
                Color.black.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 0) {
                    // شريط التبويب (لم يتم التوقيع / موقّعة)
                    Picker("", selection: $selectedTab) {
                        Text("لم يتم التوقيع").tag(0)
                        Text("موقّعة").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    .padding(.bottom, 15)
                    
                    // محتوى الشاشة
                    if selectedTab == 0 {
                        if unsignedApps.isEmpty {
                            emptyStateView
                        } else {
                            List {
                                // هنا سيتم عرض التطبيقات غير الموقعة لاحقاً
                            }
                            .listStyle(.plain)
                        }
                    } else {
                        if signedApps.isEmpty {
                            emptyStateView
                        } else {
                            List {
                                // هنا سيتم عرض التطبيقات الموقعة لاحقاً
                            }
                            .listStyle(.plain)
                        }
                    }
                }
            }
            .navigationTitle("التوقيع")
            .searchable(text: $searchText, prompt: "ابحث في التطبيقات...")
            .toolbar {
                // الأزرار على اليسار (رابط + إضافة مجلد)
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button {
                        // إجراء زر الرابط (Link)
                    } label: {
                        Image(systemName: "link")
                            .foregroundColor(.white)
                    }
                    
                    Button {
                        showingImporter = true
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .foregroundColor(.white)
                    }
                }
                
                // الزر على اليمين (تعديل) باللون الأخضر
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isEditing.toggle()
                    } label: {
                        Text(isEditing ? "تم" : "تعديل")
                            .foregroundColor(.green) // لون أخضر مثل الصورة
                    }
                }
            }
            .sheet(isPresented: $showingImporter) {
                // استدعاء واجهة الملفات المدمجة بالأسفل
                DocumentPickerView()
            }
        }
        // إجبار الواجهة على الوضع الليلي لتطابق الصورة
        .preferredColorScheme(.dark) 
    }
    
    // تصميم الواجهة في حال عدم وجود تطبيقات
    private var emptyStateView: some View {
        VStack(spacing: 15) {
            Spacer()
            
            // أيقونة التوقيع
            Image(systemName: "signature")
                .font(.system(size: 65))
                .foregroundColor(.gray)
                .padding(.bottom, 5)
            
            // النصوص
            Text("لا توجد تطبيقات")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("ابدأ باستيراد ملف IPA لتتمكن من توقيعه وتثبيته.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 10)
            
            // زر الاستيراد الأخضر
            Button {
                showingImporter = true
            } label: {
                Text("استيراد من الملفات")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 24)
                    .overlay(
                        Capsule()
                            .stroke(Color.green, lineWidth: 1.5)
                    )
            }
            
            Spacer()
            Spacer() // لرفع المحتوى قليلاً للأعلى
        }
    }
}

// كود مساعد جاهز لفتح تطبيق "الملفات"
struct DocumentPickerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
