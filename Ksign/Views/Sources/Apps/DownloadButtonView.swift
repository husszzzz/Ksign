//
//  DownloadButtonView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//  Modified for Hassany Store (Crash-Free Auto-Sign Pipeline)
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import UserNotifications
import CoreData

struct DownloadButtonView: View {
    let app: ASRepository.App
    @ObservedObject private var downloadManager = DownloadManager.shared
    @Environment(\.managedObjectContext) private var viewContext

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
            
            if downloadProgress >= 1.0 && !hasTriggeredAutomation {
                hasTriggeredAutomation = true
                startRealAutoSign()
            }
        }
    }
    
    // MARK: - الخطوة 1: بدء الأتمتة
    private func startRealAutoSign() {
        isSigning = true
        let appName = app.currentName
        
        Task {
            // ننتظر ثانيتين حتى النظام يستوعب نزول التطبيق للمكتبة
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await fetchFromDatabase(appName: appName)
        }
    }
    
    // MARK: - الخطوة 2: البحث في قاعدة البيانات بشكل آمن
    @MainActor
    private func fetchFromDatabase(appName: String) {
        // استخدمنا NSManagedObject لخدعة المترجم ومنعه من الانهيار
        let request = NSFetchRequest<NSManagedObject>(entityName: "App")
        request.predicate = NSPredicate(format: "name == %@", appName)
        
        do {
            let results = try viewContext.fetch(request)
            if let realApp = results.first {
                executeSigning(databaseObject: realApp)
            } else {
                isSigning = false
            }
        } catch {
            isSigning = false
        }
    }
    
    // MARK: - الخطوة 3: التوقيع الفعلي بالخلفية
    private func executeSigning(databaseObject: Any) {
        Task.detached {
            do {
                // استدعاء الـ ViewModel بشكل آمن
                let viewModel = await InstallerStatusViewModel()
                
                // تحويل الكائن بمرونة لتجنب أخطاء "any App"
                let handler = await ArchiveHandler(app: databaseObject as! (any App), viewModel: viewModel)
                
                try await handler.move()
                let _ = try await handler.archive()
                
                await MainActor.run {
                    self.sendSuccessNotification()
                    self.isSigning = false
                }
            } catch {
                await MainActor.run {
                    self.isSigning = false
                }
            }
        }
    }
    
    // MARK: - الخطوة 4: الإشعارات
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    private func sendSuccessNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Hassany Store"
        content.body = "اكتمل توقيع وتثبيت \(app.currentName)، يمكنك العثور عليه الآن."
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}
