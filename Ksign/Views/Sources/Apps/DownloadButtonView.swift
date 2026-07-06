//
//  DownloadButtonView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//  Modified for Hassany Store (Real Auto-Sign & Install Pipeline)
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import UserNotifications
import CoreData // مكتبة قاعدة البيانات للبحث عن التطبيق بعد تحميله

struct DownloadButtonView: View {
    let app: ASRepository.App
    @ObservedObject private var downloadManager = DownloadManager.shared
    @Environment(\.managedObjectContext) private var viewContext // للوصول لمكتبة التطبيقات

    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?
    @State private var isSigning: Bool = false
    @State private var hasTriggeredAutomation: Bool = false

    var body: some View {
        ZStack {
            if isSigning {
                // 1. حالة التوقيع الفعلي
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("جاري التوقيع...")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .clipShape(Capsule())
                .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                
            } else if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
                // 2. حالة التحميل
                ZStack {
                    Circle()
                        .trim(from: 0, to: downloadProgress)
                        .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 32, height: 32)
                        .animation(.smooth, value: downloadProgress)

                    Image(systemName: "stop.fill")
                        .foregroundStyle(Color.accentColor)
                        .font(.system(size: 12))
                }
                .onTapGesture {
                    if downloadProgress <= 0.95 {
                        downloadManager.cancelDownload(currentDownload)
                    }
                }
                .compatTransition()
            } else {
                // 3. زر التثبيت
                Button {
                    if let url = app.currentDownloadUrl {
                        hasTriggeredAutomation = false
                        isSigning = false
                        _ = downloadManager.startDownload(from: url, id: app.currentUniqueId)
                    }
                } label: {
                    Text("تثبيت")
                        .lineLimit(1)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color(red: 0.4, green: 0.1, blue: 0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .buttonStyle(.borderless)
                .compatTransition()
            }
        }
        .onAppear {
            setupObserver()
            requestNotificationPermission()
        }
        .onDisappear { cancellable?.cancel() }
        .onChange(of: downloadManager.downloads.description) { _ in
            setupObserver()
        }
        .animation(.easeInOut(duration: 0.3), value: downloadManager.getDownload(by: app.currentUniqueId) != nil)
        .animation(.easeInOut, value: isSigning)
    }

    private func setupObserver() {
        cancellable?.cancel()
        guard let download = downloadManager.getDownload(by: app.currentUniqueId) else {
            downloadProgress = 0
            return
        }
        downloadProgress = download.overallProgress

        let publisher = Publishers.CombineLatest(
            download.$progress,
            download.$unpackageProgress
        )

        cancellable = publisher.sink { _, _ in
            downloadProgress = download.overallProgress
            
            // بمجرد أن يكتمل التحميل، نبدأ رحلة التوقيع الحقيقية
            if downloadProgress >= 1.0 && !hasTriggeredAutomation {
                hasTriggeredAutomation = true
                startRealAutoSign()
            }
        }
    }
    
    // MARK: - Real Auto-Sign Engine (محرك التوقيع الحقيقي)
    private func startRealAutoSign() {
        isSigning = true
        let appName = app.currentName
        
        Task {
            // 1. ننتظر ثانية ونص حتى نعطي مجال لنظام Feather يحفظ التطبيق في المكتبة (CoreData)
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                // 2. نبحث عن التطبيق اللي نزلناه هسه داخل المكتبة (عن طريق اسمه)
                let fetchRequest: NSFetchRequest<App> = App.fetchRequest()
                fetchRequest.predicate = NSPredicate(format: "name == %@", appName)
                
                do {
                    let downloadedApps = try viewContext.fetch(fetchRequest)
                    
                    // 3. إذا لكينا التطبيق بالمكتبة (نفس اللي طالع عندك بالصورة)
                    if let realAppToSign = downloadedApps.first {
                        
                        // 4. نشغل محرك التوقيع الحقيقي عليه
                        Task.detached {
                            do {
                                let viewModel = await InstallerStatusViewModel()
                                // تمرير التطبيق الحقيقي من قاعدة البيانات بدلاً من تطبيق المتجر
                                let handler = await ArchiveHandler(app: realAppToSign, viewModel: viewModel)
                                
                                try await handler.move()
                                let _ = try await handler.archive()
                                
                                // نجح التوقيع! نرسل إشعار
                                await MainActor.run {
                                    sendSuccessNotification(appName: appName)
                                    isSigning = false
                                }
                            } catch {
                                await MainActor.run {
                                    print("❌ فشل التوقيع الفعلي: \(error)")
                                    isSigning = false
                                }
                            }
                        }
                    } else {
                        // إذا التطبيق ما انحفظ بالمكتبة بعد
                        print("⚠️ لم يتم العثور على التطبيق في المكتبة للتوقيع")
                        isSigning = false
                    }
                } catch {
                    print("❌ خطأ في البحث عن التطبيق: \(error)")
                    isSigning = false
                }
            }
        }
    }
    
    // MARK: - Notifications System
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted { print("✅ تمت الموافقة على الإشعارات") }
        }
    }
    
    private func sendSuccessNotification(appName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hassany Store"
        content.body = "اكتمل توقيع وتثبيت \(appName)، يمكنك العثور عليه الآن."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
