//
//  InstallPreview.swift
//  Feather
//
//  Created by samara on 22.04.2025.
//  Modified for Hassany Store Theme (Premium Glass & Animated Progress Ring)
//

import SwiftUI
import NimbleViews
import IDeviceSwift
import OSLog

// MARK: - View
struct InstallPreviewView: View {
    @Environment(\.dismiss) var dismiss
    
    // Sharing
    @AppStorage("Feather.useShareSheetForArchiving") private var _useShareSheet: Bool = false
    
    // Methods
    @AppStorage("Feather.installationMethod") private var _installationMethod: Int = 0
    @AppStorage("Feather.serverMethod") private var _serverMethod: Int = 0
    @State private var _isWebviewPresenting = false
    @State private var progressTask: Task<Void, Never>?
    
    var app: AppInfoPresentable
    @StateObject var viewModel: InstallerStatusViewModel
    @StateObject var installer: ServerInstaller
    @State var isSharing: Bool

    // متغير للتحكم بدوران حلقة التحميل
    @State private var isRotating = false

    init(app: AppInfoPresentable, isSharing: Bool = false) {
        self.app = app
        self.isSharing = isSharing
        let method = UserDefaults.standard.integer(forKey: "Feather.installationMethod")
        let viewModel = InstallerStatusViewModel(isIdevice: method == 1)
        self._viewModel = StateObject(wrappedValue: viewModel)
        self._installer = StateObject(wrappedValue: try! ServerInstaller(app: app, viewModel: viewModel))
    }
    
    // MARK: Body
    var body: some View {
        VStack(spacing: 25) {
            
            // ==========================================
            // 1. أيقونة التطبيق مع حلقة التحميل الدائرية
            // ==========================================
            ZStack {
                // تأثير الإشعاع الخلفي (Glow)
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)
                
                // أيقونة التطبيق المستهدف الفخمة
                FRAppIconView(app: app, size: 85)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                
                // حلقة التحميل الدائرية (Progress Ring)
                Circle()
                    .trim(from: 0, to: viewModel.installProgress > 0 ? CGFloat(viewModel.installProgress) : (isRotating ? 0.8 : 0.05))
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue, Color.purple]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .frame(width: 115, height: 115)
                    .rotationEffect(.degrees(isRotating ? 360 : 0))
            }
            .padding(.top, 20)
            
            // ==========================================
            // 2. حالة التحميل والنصوص (متحركة)
            // ==========================================
            VStack(spacing: 8) {
                Text(app.name ?? "جاري التجهيز...")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                HStack(spacing: 6) {
                    Image(systemName: viewModel.statusImage)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.purple)
                        .symbolEffect(.pulse, options: .repeating, isActive: viewModel.installProgress < 1.0)
                    
                    Text(viewModel.statusLabel)
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(
            // خلفية زجاجية داكنة فخمة (Dark Glass)
            ZStack {
                Color.black.opacity(0.85)
                RadialGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.15), .clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: 200
                )
            }
        )
        .cornerRadius(30) // حواف دائرية قوية
        .overlay(
            RoundedRectangle(cornerRadius: 30)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1.5) // إطار بنفسجي خفيف
        )
        .padding() // مسافة عن حواف الشاشة
        .sheet(isPresented: $_isWebviewPresenting) {
            SafariRepresentableView(url: installer.pageEndpoint).ignoresSafeArea()
        }
        .onReceive(viewModel.$status) { newStatus in
            if case .ready = newStatus {
                if _serverMethod == 0 {
                    UIApplication.shared.open(URL(string: installer.iTunesLink)!)
                } else if _serverMethod == 1 {
                    _isWebviewPresenting = true
                }
            }
            
            if case .installing = newStatus {
                if progressTask == nil {
                    progressTask = startInstallProgressPolling(
                        bundleID: app.identifier!,
                        viewModel: viewModel
                    )
                }
            }
            
            if case .sendingPayload = newStatus, _serverMethod == 1 {
                _isWebviewPresenting = false
            }
            
            switch newStatus {
            case .completed, .broken(_):
                progressTask?.cancel()
                progressTask = nil
                BackgroundAudioManager.shared.stop()
                withAnimation { isRotating = false }
            default:
                break
            }
        }
        .onAppear {
            _install()
            BackgroundAudioManager.shared.start()
            // تشغيل دوران حلقة التحميل بشكل مستمر
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                isRotating = true
            }
        }
        .onDisappear {
            progressTask?.cancel()
            progressTask = nil
            BackgroundAudioManager.shared.stop()
        }
    }
    
    private func _install() {
        guard isSharing || app.identifier != Bundle.main.bundleIdentifier! || _installationMethod == 1 else {
            UIAlertController.showAlertWithOk(
                title: .localized("Install"),
                message: .localized("You cannot update ‘%@‘ with itself, please use an alternative tool to update it.", arguments: Bundle.main.name)
            )
            return
        }

        Task.detached {
            do {
                let handler = await ArchiveHandler(app: app, viewModel: viewModel)
                try await handler.move()
                
                let packageUrl = try await handler.archive()
                
                if await !isSharing {
                    if await _installationMethod == 0 {
                        await MainActor.run {
                            installer.packageUrl = packageUrl
                            viewModel.status = .ready
                        }
                        
                        if case .installing = await viewModel.status {
                            let task = await startInstallProgressPolling(
                                bundleID: app.identifier!,
                                viewModel: viewModel
                            )

                            await MainActor.run {
                                progressTask = task
                            }
                        }
                    }
                    else if await _installationMethod == 1 {
                        let handler = await InstallationProxy(viewModel: viewModel)
                        try await handler.install(at: packageUrl, suspend: app.identifier == Bundle.main.bundleIdentifier!)
                    }
                } else {
                    let package = try await handler.moveToArchive(packageUrl, shouldOpen: !_useShareSheet)
                    
                    if await !_useShareSheet {
                        await MainActor.run {
                            dismiss()
                        }
                    } else {
                        if let package {
                            await MainActor.run {
                                dismiss()
                                UIActivityViewController.show(activityItems: [package])
                            }
                        }
                    }
                }
            } catch {
                await progressTask?.cancel()
                await MainActor.run {
                    UIAlertController.showAlertWithOk(
                        title: .localized("Install"),
                        message: error.localizedDescription,
                        action: {
                            HeartbeatManager.shared.start(true)
                            dismiss()
                        }
                    )
                }
            }
        }
    }
    
    private func startInstallProgressPolling(
            bundleID: String,
            viewModel: InstallerStatusViewModel
        ) -> Task<Void, Never> {

            Task.detached(priority: .background) {
                var hasStarted = false

                while !Task.isCancelled {
                    let rawProgress = await UIApplication.installProgress(for: bundleID) ?? 0.0

                    if rawProgress > 0 {
                        hasStarted = true
                    }

                    let progress = await hasStarted
                        ? _normalizeInstallProgress(rawProgress)
                        : 0.0

                    Logger.misc.info("Install progress for \(bundleID): \(progress) - \(rawProgress) - \(viewModel.installProgress)")

                    await MainActor.run {
                        viewModel.installProgress = progress
                    }

                    if hasStarted && rawProgress == 0 {
                        await MainActor.run {
                            viewModel.installProgress = 1.0
                            viewModel.status = .completed(.success(()))
                        }
                        break
                    }

                    try? await Task.sleep(nanoseconds: 1_000_000) // 1 ms
                }
            }
        }

        private func _normalizeInstallProgress(_ rawProgress: Double) -> Double {
            min(1.0, max(0.0, (rawProgress - 0.6) / 0.3))
        }
}
