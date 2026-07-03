import SwiftUI
import UniformTypeIdentifiers
import NimbleViews

struct SigningView: View {
    @State private var signingState = 0 // 0: لم يتم التوقيع, 1: موقعة
    @State private var searchText = ""
    @State private var showingImporter = false
    
    // فرضاً عندك قائمة تطبيقات
    @State private var signedApps: [String] = [] 
    @State private var unsignedApps: [String] = [] 

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // شريط التبويب (لم يتم التوقيع / موقعة)
                Picker("", selection: $signingState) {
                    Text("لم يتم التوقيع").tag(0)
                    Text("موقعة").tag(1)
                }
                .pickerStyle(.segmented)
                .padding()

                // المحتوى بناءً على الحالة
                if signingState == 0 {
                    if unsignedApps.isEmpty {
                        emptyStateView
                    } else {
                        List { /* قائمة غير الموقع */ }
                    }
                } else {
                    if signedApps.isEmpty {
                        emptyStateView
                    } else {
                        List { /* قائمة الموقع */ }
                    }
                }
            }
            .navigationTitle("التوقيع")
            .searchable(text: $searchText, prompt: "ابحث في التطبيقات...")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { /* Action for Link button */ } label: { Image(systemName: "link") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showingImporter = true } label: { Image(systemName: "folder.badge.plus") }
                }
            }
            .sheet(isPresented: $showingImporter) {
                FileImporterRepresentableView(
                    allowedContentTypes: [UTType.item],
                    allowsMultipleSelection: true,
                    onDocumentsPicked: { urls in
                        // هنا تضع منطق استيراد الملفات
                    }
                )
            }
        }
    }

    // واجهة الحالة الفارغة
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "signature")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("لا توجد تطبيقات")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("ابدأ باستيراد ملف IPA لتتمكن من توقيعه وتثبيته.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button {
                showingImporter = true
            } label: {
                Text("استيراد من الملفات")
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 30)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.green, lineWidth: 1)
                    )
            }
            Spacer()
        }
    }
}
