//
//  DownloadButtonView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//  Modified for Hassany Store (Crash-Free Auto-Sign Signal)
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import UserNotifications

struct DownloadButtonView: View {
    let app: ASRepository.App
    @ObservedObject private var downloadManager = DownloadManager.shared

    @State private var downloadProgress: Double = 0
    @State private var cancellable: AnyCancellable?
    @State private var isSigning: Bool = false
    @State private var hasTriggeredAutomation: Bool = false

    var body: some View {
        ZStack {
            if isSigning {
                HStack(spacing: 8) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                    Text("جاري التجهيز...")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange)
                .clipShape(Capsule())
                .shadow(color: .orange.opacity(0.4), radius: 4, x: 0, y: 2)
                
            } else if let currentDownload = downloadManager.getDownload(by: app.currentUniqueId) {
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
            
            // عند اكتمال التحميل نطلق الإشارة
            if downloadProgress >= 1.0 && !hasTriggeredAutomation {
                hasTriggeredAutomation = true
                triggerAutoInstallSignal()
            }
        }
    }
    
    // MARK: - إطلاق إشارة التوقيع المخفية
    private func triggerAutoInstallSignal() {
        isSigning = true
        let appName = app.currentName
        
        Task {
            // انتظار بسيط لترتيب الملفات
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                // إرسال إشارة مخفية لقسم التوقيع حتى يشتغل بالخلفية
                NotificationCenter.default.post(
                    name: NSNotification.Name("HassanyStoreAutoSignRequest"),
                    object: appName
                )
                
                sendSuccessNotification(appName: appName)
                isSigning = false
            }
        }
    }
    
    // MARK: - الإشعارات
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func sendSuccessNotification(appName: String) {
        let content = UNMutableNotificationContent()
        content.title = "Hassany Store"
        content.body = "اكتمل تحميل \(appName)، انتقل لقسم التوقيع لتثبيته بنقرة واحدة."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
