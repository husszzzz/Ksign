//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//  Modified for Hassany Store
//

import SwiftUI
import NimbleViews

// MARK: - View
struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    // متغير للتحكم في ظهور رسالة "حول المتجر"
    @State private var showAboutMessage = false
    
    private var selectedCertificate: CertificatePair? {
        guard
            _storedSelectedCert >= 0,
            _storedSelectedCert < _certificates.count
        else {
            return nil
        }
        return _certificates[_storedSelectedCert]
    }
    
    // MARK: Body
    var body: some View {
        NBNavigationView(.localized("Settings")) {
            Form {
                
                // 1. بانر الصور المتحرك (بديل التبرعات)
                Section {
                    StoreBannerView()
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // 2. قسم حول وقناة التليجرام
                _feedback()
                
                // 3. المظهر (تم حذف أيقونة التطبيق حسب الطلب)
                Section {
                    NavigationLink(destination: AppearanceView()) {
                        Label(.localized("Appearance"), systemImage: "paintbrush")
                    }
                }
                
                NBSection(.localized("Certificates")) {
                    
                    if let cert = selectedCertificate {
                        CertificatesCellView(cert: cert)
                    } else {
                        Text(.localized("No Certificate"))
                            .font(.footnote)
                            .foregroundColor(.disabled())
                    }
                    NavigationLink(destination: CertificatesView()) {
                        Label(.localized("Certificates"), systemImage: "signature")
                    }
                 
                } footer: {
                    Text(.localized("Add and manage certificates used for signing applications."))
                }
                
                NBSection(.localized("Features")) {
                    NavigationLink(destination: LogsView(manager: LogsManager.shared)) {
                        Label(.localized("Logs"), systemImage: "apple.terminal")
                    }
                    NavigationLink(destination: AppFeaturesView()) {
                        Label(.localized("App Features"), systemImage: "sparkles")
                    }
                    NavigationLink(destination: ConfigurationView()) {
                        Label(.localized("Signing Options"), systemImage: "gear")
                    }
                    NavigationLink(destination: ArchiveView()) {
                        Label(.localized("Archive & Extraction"), systemImage: "archivebox")
                    }
                    NavigationLink(destination: InstallationView()) {
                        Label(.localized("Installation"), systemImage: "server.rack")
                    }
                }
                
                _directories()
                
                Section {
                    NavigationLink(destination: ResetView()) {
                        Label(.localized("Reset"), systemImage: "trash")
                    }
                } footer: {
                    Text("Reset the applications sources, certificates, apps, and general contents.")
                }

            }
        }
    }
}

// MARK: - View extension
extension SettingsView {
    @ViewBuilder
    private func _feedback() -> some View {
        Section {
            // زر "حول المتجر" لفتح النافذة المنبثقة
            Button(action: {
                showAboutMessage.toggle()
            }) {
                HStack {
                    Label("حول المتجر", systemImage: "info.circle")
                    Spacer()
                }
            }
            .sheet(isPresented: $showAboutMessage) {
                StoreAboutMessageView()
            }
            
            // زر قناة التليجرام الخاص بالمتجر
            Button("قناة التليجرام", systemImage: "paperplane.circle") {
                UIApplication.open("https://t.me/hassanyIPA")
            }
        } header: {
            Text("حول")
        }
    }
    
    @ViewBuilder
    private func _directories() -> some View {
        NBSection(.localized("Misc")) {
            Button(.localized("Open Documents"), systemImage: "folder") {
                UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!.absoluteString) // تعديل طفيف لضمان عمل الرابط
            }
            Button(.localized("Open Archives"), systemImage: "folder") {
                UIApplication.open(FileManager.default.archives.toSharedDocumentsURL()!.absoluteString)
            }
        } footer: {
            Text(.localized("All of Ksign files except certificates are contained in the documents directory, here are some quick links to these."))
        }
    }
}

// MARK: - إضافات متجر بلس الخاصة (Hassany Store)

// 1. واجهة البانر المتحرك
struct StoreBannerView: View {
    @State private var currentIndex = 0
    // مؤقت لتغيير الصورة كل 4 ثواني
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        TabView(selection: $currentIndex) {
            
            // الصورة الأولى (عرض فقط)
            AsyncImage(url: URL(string: "https://up6.cc/2026/07/178299404288331.png")) { phase in
                if let image = phase.image {
                    image.resizable().scaledToFill()
                } else {
                    Color.gray.opacity(0.1)
                }
            }
            .tag(0)
            
            // الصورة الثانية (الدعم الفني قابلة للضغط)
            Button(action: {
                UIApplication.open("https://t.me/OM_G9")
            }) {
                AsyncImage(url: URL(string: "https://up6.cc/2026/07/178299412751421.png")) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFill()
                    } else {
                        Color.gray.opacity(0.1)
                    }
                }
            }
            .buttonStyle(PlainButtonStyle())
            .tag(1)
            
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .frame(height: 160)
        .cornerRadius(12)
        .padding(.horizontal)
        .onReceive(timer) { _ in
            withAnimation {
                currentIndex = currentIndex == 0 ? 1 : 0
            }
        }
    }
}

// 2. رسالة "حول المتجر" المنبثقة
struct StoreAboutMessageView: View {
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .trailing, spacing: 18) {
                    
                    Text("مرحبًا بك في متجر بلس، وجهتك للحصول على أفضل تطبيقات وألعاب iPhone المعدلة بأحدث الإصدارات.")
                        .font(.body)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(5)
                    
                    Text("يعمل المطور الحسني على توفير تطبيقات موثوقة يتم تحديثها باستمرار، مع الاهتمام بالجودة وسهولة الاستخدام، لتجربة تحميل سلسة وآمنة.")
                        .font(.body)
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(5)
                    
                    Divider()
                        .padding(.vertical, 5)
                    
                    Text("مميزات متجر بلس:")
                        .font(.headline)
                        .bold()
                        .foregroundColor(.blue)
                    
                    VStack(alignment: .trailing, spacing: 12) {
                        BulletPointRow(text: "أكثر من آلاف التطبيقات والألعاب.")
                        BulletPointRow(text: "تحديثات مستمرة لأحدث الإصدارات.")
                        BulletPointRow(text: "واجهة سريعة وسهلة الاستخدام.")
                        BulletPointRow(text: "روابط تحميل مباشرة.")
                        BulletPointRow(text: "دعم فني عبر تيليجرام.")
                        BulletPointRow(text: "تحسينات مستمرة وإضافة تطبيقات جديدة بشكل دوري.")
                    }
                    
                    Spacer()
                }
                .padding(20)
                // إجبار التنسيق من اليمين لليسار لضمان ظهور النص العربي بشكل مثالي
                .environment(\.layoutDirection, .rightToLeft)
            }
            .navigationTitle("حول المتجر")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("إغلاق") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.headline)
                }
            }
        }
    }
    
    // دالة مساعدة لتصميم شكل النقاط (Bullet Points)
    private func BulletPointRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(text)
                .multilineTextAlignment(.trailing)
            Text("•")
                .foregroundColor(.blue)
                .font(.title2)
        }
    }
}
