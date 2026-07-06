//
//  DownloadButtonView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//  Modified for Hassany Store (One-Click Auto Sign & Install Pipeline)
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import UserNotifications // مكتبة الإشعارات

struct DownloadButtonView: View {
    let app: ASRepository.App
    @ObservedObject private var downloadManager = DownloadManager.shared

    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?
    
    // حالات الزر للأتمتة (التوقيع التلقائي)
    @State private var isSigning: Bool = false
    @State private var hasTriggeredAutomation: Bool = false

    var body: some View {
        ZStack {
            if isSigning {
                // 1. حالة التوقيع (بعد اكتمال التحميل)
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
                // 3. حالة الزر الافتراضية
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
            requestNotificationPermission() // طلب إذن الإشعارات من المستخدم
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
            
            // 🚀 الأتمتة: بمجرد أن يكتمل التحميل (1.0) نطلق عملية التوقيع تلقائياً
            if downloadProgress >= 1.0 && !hasTriggeredAutomation {
                hasTriggeredAutomation = true
                startAutoSignAndInstallPipeline()
            }
        }
    }
    
    // MARK: - Automation Pipeline (التوقيع والإشعار)
    private func startAutoSignAndInstallPipeline() {
        isSigning = true // تحويل الزر إلى "جاري التوقيع..."
        
        Task.detached {
            do {
                // 1. تجهيز المتطلبات بناءً على كود صورتك
                let installerViewModel = await InstallerStatusViewModel()
                
                // 2. تشغيل كود التوقيع (ArchiveHandler)
                // ⚠️ انتبه للملاحظة بالأسفل إذا ظهر لك خطأ هنا
                let handler = await ArchiveHandler(app: app as! any App, viewModel: installerViewModel)
                try await handler.move()
                let packageUrl = try await handler.archive()
                
                // 3. هنا يكتمل التوقيع ويصبح التطبيق جاهزاً للتثبيت
                
                // 4. إرسال الإشعار وتغيير حالة الزر بعد النجاح
                await MainActor.run {
                    sendSuccessNotification()
                    isSigning = false
                }
            } catch {
                await MainActor.run {
                    print("❌ فشل التوقيع: \(error)")
                    isSigning = false
                }
            }
        }
    }
    
    // MARK: - Notifications System (نظام الإشعارات)
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("✅ تمت الموافقة على الإشعارات")
            }
        }
    }
    
    private func sendSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Hassany Store"
        content.body = "اكتمل توقيع وتثبيت \(app.currentName)، يمكن العثور عليه في الشاشة الرئيسية."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
