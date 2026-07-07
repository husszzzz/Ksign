//
//  FeatherApp.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//  Modified for Hassany Store Theme (Global Auto-Sign Observer)
//

import SwiftUI
import Nuke
import OSLog
import IDeviceSwift

@main
struct FeatherApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let heartbeat = HeartbeatManager.shared
    @StateObject var downloadManager = DownloadManager.shared
    @StateObject var accentColorManager = AccentColorManager.shared
    @StateObject var extractManager = ExtractManager.shared
    @StateObject var logsManager = LogsManager.shared
    let storage = Storage.shared

    // ==========================================
    // 🎨 محرك الثيم الشامل لمتجر Hassany Store
    // ==========================================
    init() {
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundColor = UIColor(white: 0.05, alpha: 0.9)
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().tintColor = UIColor.systemPurple

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithTransparentBackground()
        tabAppearance.backgroundColor = UIColor(white: 0.05, alpha: 0.95)
        tabAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterialDark)
        
        UITabBar.appearance().standardAppearance = tabAppearance
        if #available(iOS 15.0, *) {
            UITabBar.appearance().scrollEdgeAppearance = tabAppearance
        }
        UITabBar.appearance().tintColor = UIColor.systemPurple
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
        
        UIView.appearance().tintColor = UIColor.systemPurple
    }

    var body: some Scene {
        WindowGroup {
            VStack {
                ExtractHeaderView(extractManager: extractManager)
                    .transition(.move(edge: .top).combined(with: .opacity))
                DownloadHeaderView(downloadManager: downloadManager)
                    .transition(.move(edge: .top).combined(with: .opacity))
                VariedTabbarView()
                    .environment(\.managedObjectContext, storage.context)
                    .onOpenURL(perform: _handleURL)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            .preferredColorScheme(.dark)
            .tint(.purple)
            .animation(.smooth, value: downloadManager.manualDownloads.description)
            .animation(.smooth, value: extractManager.extractItems.description)
            .onReceive(accentColorManager.objectWillChange) { _ in
                UIView.appearance().tintColor = UIColor.systemPurple
            }
            // ==========================================
            // 🚀 الحارس المخفي: نظام التوقيع والتثبيت الآلي
            // ==========================================
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("HassanyStoreAutoSignRequest"))) { notification in
                guard let ipaPathURL = notification.object as? URL else { return }
                
                print("🚀 الحارس المخفي استلم الطلب! جاري التوقيع للتطبيق: \(ipaPathURL.lastPathComponent)")
                
                Task.detached {
                    do {
                        // 1. قراءة بيانات الـ IPA المكتمل وتجهيزه للمحرك
                        let fileManager = FileManager.default
                        guard fileManager.fileExists(atPath: ipaPathURL.path) else { return }
                        
                        // تجهيز كائن وهمي للتطبيق حتى يدخل بالمحرك
                        let fakeApp = try await App(context: Storage.shared.context)
                        fakeApp.uuid = UUID().uuidString
                        fakeApp.name = ipaPathURL.lastPathComponent.replacingOccurrences(of: ".ipa", with: "")
                        
                        // 2. تشغيل محرك التوقيع بالخلفية
                        let viewModel = InstallerStatusViewModel() // هذا ضروري بدون await
                        let handler = ArchiveHandler(app: fakeApp, viewModel: viewModel)
                        
                        try await handler.move()
                        
                        // 3. التوقيع ثم إطلاق رسالة التثبيت الرسمية (install)
                        let signedApp = try await handler.archive()
                        
                        await MainActor.run {
                            print("✅ التوقيع اكتمل بنجاح، رسالة التثبيت ستظهر الآن!")
                            // ملاحظة: handler.archive() في Ksign عادةً تتكفل بإظهار الرسالة
                            // إذا احتاجت تفعيل يدوي نرسل إشارة لفتح شاشة التثبيت:
                            NotificationCenter.default.post(name: NSNotification.Name("feather.installApp"), object: nil)
                        }
                    } catch {
                        print("❌ فشل التوقيع المخفي: \(error.localizedDescription)")
                    }
                }
            }
            // ==========================================
            .onAppear {
                UIView.appearance().tintColor = UIColor.systemPurple
                if logsManager.isCapturing { logsManager.startCapture() }
            }
        }
    }
    
    private func _handleURL(_ url: URL) {
        if url.scheme == "ksign" {
            if let fullPath = url.validatedScheme(after: "/source/") {
                FR.handleSource(fullPath) { }
            }
            
            if
                let fullPath = url.validatedScheme(after: "/install/"),
                let downloadURL = URL(string: fullPath)
            {
                _ = DownloadManager.shared.startDownload(from: downloadURL, id: "FeatherManualDownload_\(UUID().uuidString)")
            }
        } else {
            if url.pathExtension == "ipa" || url.pathExtension == "tipa" {
                if FileManager.default.isFileFromFileProvider(at: url) {
                    guard url.startAccessingSecurityScopedResource() else { return }
                    FR.handlePackageFile(url) { _ in }
                } else {
                    FR.handlePackageFile(url) { _ in }
                }
                
                return
            }
            
            if url.pathExtension == "ksign" {
                UIAlertController.showAlertWithOk(title: .localized("Error"), message: .localized("Ksign certificate file (.ksign) is now unsupported from v1.5.1, please refer to use .p12 and .mobileprovision instead."))
            }
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        
        _createPipeline()
        _createSourcesDirectory()
        if !UserDefaults.standard.bool(forKey: "hasInitializedBuiltInSources") {
            _initializeBuiltInSources()
            UserDefaults.standard.set(true, forKey: "hasInitializedBuiltInSources")
        }
        
        _clean()
        
        _copyServerCertificates()
        _addDefaultCertificates()

#if SERVER
        _downloadSSLCertificates()
#endif
        return true
    }
    
    private func _initializeBuiltInSources() { 
        Storage.shared.addBuiltInSources()
    }
    
    private func _createPipeline() {
        DataLoader.sharedUrlCache.diskCapacity = 0
        
        let pipeline = ImagePipeline {
            let dataLoader: DataLoader = {
                let config = URLSessionConfiguration.default
                config.urlCache = nil
                return DataLoader(configuration: config)
            }()
            let dataCache = try? DataCache(name: "thewonderofyou.Feather.datacache")
            let imageCache = Nuke.ImageCache()
            dataCache?.sizeLimit = 500 * 1024 * 1024
            imageCache.costLimit = 100 * 1024 * 1024
            $0.dataCache = dataCache
            $0.imageCache = imageCache
            $0.dataLoader = dataLoader
            $0.dataCachePolicy = .automatic
            $0.isStoringPreviewsInMemoryCache = false
        }
        
        ImagePipeline.shared = pipeline
    }
    
    private func _createSourcesDirectory() {
        let fileManager = FileManager.default
        let appDirectory = URL.documentsDirectory.appendingPathComponent("App")
        try? fileManager.createDirectoryIfNeeded(at: appDirectory)
        
        let directories = ["Signed", "Unsigned", "Archives", "Server", "Tweaks"].map {
            appDirectory.appendingPathComponent($0)
        }
        
        for url in directories {
            try? fileManager.createDirectoryIfNeeded(at: url)
        }
    }
    
    private func _clean() {
        let fileManager = FileManager.default
        let tmpDirectory = fileManager.temporaryDirectory
        
        if let files = try? fileManager.contentsOfDirectory(atPath: tmpDirectory.path()) {
            for file in files {
                try? fileManager.removeItem(atPath: tmpDirectory.appendingPathComponent(file).path())
            }
        }
    }
    
    private func _copyServerCertificates() {
        let fileManager = FileManager.default
        let serverDirectory = URL.documentsDirectory.appendingPathComponent("App/Server")
        
        try? fileManager.createDirectoryIfNeeded(at: serverDirectory)
        
        let filesToCopy = ["server.crt", "server.pem", "commonName.txt"]
        
        for fileName in filesToCopy {
            guard let bundleURL = Bundle.main.url(forResource: fileName.components(separatedBy: ".").first!, withExtension: fileName.components(separatedBy: ".").last!) else {
                continue
            }
            
            let destinationURL = serverDirectory.appendingPathComponent(fileName)
            try? fileManager.removeItem(at: destinationURL)
            
            do {
                try fileManager.copyItem(at: bundleURL, to: destinationURL)
            } catch {
                print("Error copying \(fileName): \(error)")
            }
        }
    }
    
    private func _addDefaultCertificates() {
        guard
            UserDefaults.standard.bool(forKey: "feather.didImportDefaultCertificates") == false,
            let signingAssetsURL = Bundle.main.url(forResource: "signing-assets", withExtension: nil)
        else {
            return
        }
        
        do {
            let folderContents = try FileManager.default.contentsOfDirectory(
                at: signingAssetsURL,
                includingPropertiesForKeys: nil,
                options: .skipsHiddenFiles
            )
            
            for folderURL in folderContents {
                guard folderURL.hasDirectoryPath else { continue }
                
                let certName = folderURL.lastPathComponent
                let p12Url = folderURL.appendingPathComponent("cert.p12")
                let provisionUrl = folderURL.appendingPathComponent("cert.mobileprovision")
                let passwordUrl = folderURL.appendingPathComponent("cert.txt")
                
                guard
                    FileManager.default.fileExists(atPath: p12Url.path),
                    FileManager.default.fileExists(atPath: provisionUrl.path),
                    FileManager.default.fileExists(atPath: passwordUrl.path)
                else {
                    continue
                }
                
                let password = try String(contentsOf: passwordUrl, encoding: .utf8)
                
                FR.handleCertificateFiles(
                    p12URL: p12Url,
                    provisionURL: provisionUrl,
                    p12Password: password,
                    certificateName: certName,
                ) { _ in }
            }
            UserDefaults.standard.set(true, forKey: "feather.didImportDefaultCertificates")
        } catch {
            Logger.misc.error("Failed to list signing-assets: \(error)")
        }
    }

#if SERVER
    private func _downloadSSLCertificates() {
        let serverURL = "https://backloop.dev/pack.json"
        
        FR.downloadSSLCertificates(from: serverURL) { success in
            if success {
                print("SSL certificates downloaded successfully")
            } else {
                print("Failed to download SSL certificates")
            }
        }
    }
#endif
}
