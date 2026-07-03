import SwiftUI
import UniformTypeIdentifiers

struct SigningView: View {
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
                                // محتوى التطبيقات غير الموقعة
                            }
                            .listStyle(.plain)
                        }
                    } else {
                        if signedApps.isEmpty {
                            emptyStateView
                        } else {
                            List {
                                // محتوى التطبيقات الموقعة
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
    
    // تصميم الواجهة في حال عدم وجود تطبيقات (نسخة طبق الأصل من صورتك)
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
            
            // زر الاستيراد الأخضر (شفاف مع حدود خضراء)
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
            Spacer() // لرفع المحتوى قليلاً للأعلى ليتوسط الشاشة بشكل مثالي
        }
    }
}

// كود مساعد جاهز لفتح تطبيق "الملفات" (Files) بالايفون بدون أي أخطاء برمجية
struct DocumentPickerView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.item], asCopy: true)
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}
}
