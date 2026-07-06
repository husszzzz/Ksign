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
    
    // حالات الزر الجديدة للأتمتة
    @State private var isSigning: Bool = false
    @State private var hasTriggeredAutomation: Bool = false

    var body: some View {
        ZStack {
            if isSigning {
                // 1. حالة التوقيع التلقائي (بعد اكتمال التحميل)
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
                .background(Color.orange) // لون مميز لعملية التوقيع
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
                        // تصفير الحالات عند بدء تحميل جديد
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
            requestNotificationPermission() // طلب صلاحية الإشعارات
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
            
            // الأتمتة: عندما يكتمل التحميل ننتقل للتوقيع تلقائياً
            if downloadProgress >= 1.0 && !hasTriggeredAutomation {
                hasTriggeredAutomation = true
                startAutoSignAndInstallPipeline()
            }
        }
    }
    
    // MARK: - Automation Pipeline
    private func startAutoSignAndInstallPipeline() {
        isSigning = true // تغيير شكل الزر
        
        // هنا يجب استدعاء كود التوقيع الفعلي الخاص بمشروعك.
        // محاكاة مؤقتة لعملية التوقيع (3 ثواني) لغرض التجربة:
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            
            // 1. إرسال الإشعار
            sendSuccessNotification()
            
            // 2. فتح نافذة التثبيت (يجب ربطها بكود التثبيت الفعلي)
            // InstallManager.shared.install(app: app)
            
            // إنهاء حالة التوقيع
            isSigning = false
        }
    }
    
    // MARK: - Notifications System
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("تمت الموافقة على الإشعارات")
            }
        }
    }
    
    private func sendSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Hassany Store"
        let appName = app.currentName
        content.body = "اكتمل توقيع وتثبيت \(appName)، يمكن العثور عليه في الشاشة الرئيسية."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
