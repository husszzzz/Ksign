//
//  SettingsView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//  Modified for Hassany Store
//

import SwiftUI
import NimbleViews

// MARK: - محرك إعدادات المتجر (سورس قياسي)
struct SettingsRemoteConfig: Codable {
    let settings_banners: [String]?
    let support_url: String?
    let channel_url: String?
}

class SettingsConfigManager: ObservableObject {
    @Published var settingsBanners: [String] = []
    @Published var supportURL: String = "https://t.me/OM_G9"
    @Published var channelURL: String = "https://t.me/hassanyIPA"
    
    // رابط السورس القياسي الخاص بك
    let sourceURL = "https://raw.githubusercontent.com/husszzzz/Ksign/refs/heads/main/banners.json"
    
    func fetchSettings() {
        guard let url = URL(string: sourceURL) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data {
                do {
                    let config = try JSONDecoder().decode(SettingsRemoteConfig.self, from: data)
                    DispatchQueue.main.async {
                        // تحديث البنرات إذا كانت موجودة بالرابط
                        if let fetchedBanners = config.settings_banners, !fetchedBanners.isEmpty {
                            self.settingsBanners = fetchedBanners
                        } else {
                            // صور احتياطية في حال خطأ بالسورس
                            self.settingsBanners = [
                                "https://up6.cc/2026/07/178299404288331.png",
                                "https://up6.cc/2026/07/178299412751421.png"
                            ]
                        }
                        
                        // تحديث الروابط
                        if let support = config.support_url { self.supportURL = support }
                        if let channel = config.channel_url { self.channelURL = channel }
                    }
                } catch {
                    print("فشل جلب إعدادات المتجر: \(error)")
                    // تحميل الصور الاحتياطية عند الفشل لتجنب الشاشة البيضاء
                    DispatchQueue.main.async {
                        if self.settingsBanners.isEmpty {
                            self.settingsBanners = [
                                "https://up6.cc/2026/07/178299404288331.png",
                                "https://up6.cc/2026/07/178299412751421.png"
                            ]
                        }
                    }
                }
            }
        }.resume()
    }
}

// MARK: - View
struct SettingsView: View {
    @AppStorage("feather.selectedCert") private var _storedSelectedCert: Int = 0
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var _certificates: FetchedResults<CertificatePair>
    
    // استدعاء محرك الإعدادات
    @StateObject private var configManager = SettingsConfigManager()
    
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
                
                // 1. بانر الصور المتحرك (مربوط بالسورس)
                Section {
                    StoreBannerView(manager: configManager)
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                // 2. قسم حول وقناة التليجرام
                _feedback()
                
                // 3. المظهر
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
        .onAppear {
            // جلب البيانات فور فتح صفحة الإعدادات
            configManager.fetchSettings()
        }
    }
}

// MARK: - View extension
extension SettingsView {
    @ViewBuilder
    private func _feedback() -> some View {
        Section {
            // زر "حول المتجر"
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
            
            // زر قناة التليجرام المربوط بالسورس القياسي
            Button("قناة التليجرام", systemImage: "paperplane.circle") {
                if let url = URL(string: configManager.channelURL) {
                    UIApplication.shared.open(url)
                }
            }
        } header: {
            Text("حول")
        }
    }
    
    @ViewBuilder
    private func _directories() -> some View {
        NBSection(.localized("Misc")) {
            Button(.localized("Open Documents"), systemImage: "folder") {
                UIApplication.open(URL.documentsDirectory.toSharedDocumentsURL()!.absoluteString)
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

// 1. واجهة البانر المتحرك السريعة
struct StoreBannerView: View {
    @ObservedObject var manager: SettingsConfigManager
    @State private var currentIndex = 0
    private let timer = Timer.publish(every: 4, on: .main, in: .common).autoconnect()
    
    var body: some View {
        if manager.settingsBanners.isEmpty {
            // شاشة تحميل أنيقة أثناء جلب الصور من السورس
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.15))
                .frame(height: 160)
                .padding(.horizontal)
                .overlay(ProgressView())
        } else {
            TabView(selection: $currentIndex) {
                ForEach(0..<manager.settingsBanners.count, id: \.self) { index in
                    
                    if index == 1 {
                        // الصورة الثانية (الدعم الفني) قابلة للضغط ومربوطة بالسورس
                        Button(action: {
                            if let url = URL(string: manager.supportURL) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            _asyncBannerImage(url: manager.settingsBanners[index])
                        }
                        .buttonStyle(PlainButtonStyle())
                        .tag(index)
                    } else {
                        // باقي الصور (عرض فقط)
                        _asyncBannerImage(url: manager.settingsBanners[index])
                            .tag(index)
                    }
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
            .frame(height: 160)
            .cornerRadius(12)
            .padding(.horizontal)
            .onReceive(timer) { _ in
                withAnimation {
                    if !manager.settingsBanners.isEmpty {
                        currentIndex = (currentIndex + 1) % manager.settingsBanners.count
                    }
                }
            }
        }
    }
    
    // تصميم الصورة مع مؤشر تحميل احترافي
    @ViewBuilder
    private func _asyncBannerImage(url: String) -> some View {
        AsyncImage(url: URL(string: url)) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else if phase.error != nil {
                Color.gray.opacity(0.1)
                    .overlay(Image(systemName: "photo").foregroundColor(.gray))
            } else {
                Color.gray.opacity(0.15)
                    .overlay(ProgressView())
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
