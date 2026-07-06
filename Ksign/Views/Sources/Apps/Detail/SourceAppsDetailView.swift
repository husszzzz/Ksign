//
//  SourceAppsDetailView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//  Modified for Hassany Store (VIP Glassmorphism - Fixed Layout Overflow)
//

import SwiftUI
import Combine
import AltSourceKit
import NimbleViews
import NukeUI

// MARK: - SourceAppsDetailView
struct SourceAppsDetailView: View {
    @ObservedObject var downloadManager = DownloadManager.shared
    @State private var _downloadProgress: Double = 0
    @State var cancellable: AnyCancellable?
    @State private var _isScreenshotPreviewPresented: Bool = false
    @State private var _selectedScreenshotIndex: Int = 0
    
    var currentDownload: Download? {
        downloadManager.getDownload(by: app.currentUniqueId)
    }
    
    var source: ASRepository
    var app: ASRepository.App
    
    var body: some View {
        ZStack {
            // 1. الخلفية المغبشة (Blurred Background) الفخمة
            if let iconURL = app.iconURL {
                LazyImage(url: iconURL) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .edgesIgnoringSafeArea(.all)
                            .blur(radius: 50)
                            .opacity(0.4)
                    }
                }
            }
            Color.black.opacity(0.6).edgesIgnoringSafeArea(.all) // طبقة تعتيم فوق الغبش
            
            ScrollView(showsIndicators: false) {
                // وضعنا محتوى الشاشة بالكامل داخل إطار محدد العرض لمنع التمدد الخاطئ
                VStack(spacing: 24) {
                    
                    // 2. الهيدر (الأيقونة واسم التطبيق)
                    VStack(spacing: 16) {
                        if let iconURL = app.iconURL {
                            LazyImage(url: iconURL) { state in
                                if let image = state.image {
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 110, height: 110)
                                        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                                        .shadow(color: .black.opacity(0.4), radius: 15, x: 0, y: 8)
                                } else {
                                    standardIcon
                                }
                            }
                        } else {
                            standardIcon
                        }
                        
                        VStack(spacing: 6) {
                            Text(app.currentName)
                                .font(.system(size: 24, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 10)
                            
                            Text(app.developer ?? "Hassany Store")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 20)
                    
                    // 3. زر التثبيت العملاق (VIP Gradient - Fixed Padding)
                    DownloadButtonView(app: app)
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color(red: 0.4, green: 0.1, blue: 0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.horizontal, 30) // حماية الزر من الالتصاق بالحواف
                    
                    // 4. شريط الإحصائيات الأفقي
                    _horizontalStatsRow()
                        .padding(.horizontal, 16)
                    
                    Divider().background(Color.white.opacity(0.2)).padding(.horizontal, 20)
                    
                    // 5. لقطات الشاشة
                    if let screenshotURLs = app.screenshotURLs, !screenshotURLs.isEmpty {
                        _glassSection(title: .localized("Screenshots")) {
                            _screenshots(screenshotURLs: screenshotURLs)
                        }
                    }
                    
                    // 6. الوصف (Description)
                    if let appDesc = app.localizedDescription, !appDesc.isEmpty {
                        _glassSection(title: .localized("Description")) {
                            ExpandableText(text: appDesc, lineLimit: 5)
                                .font(.system(size: 15, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .lineSpacing(4)
                        }
                    }
                    
                    // 7. ما الجديد (What's New)
                    if let currentVer = app.currentVersion, let whatsNewDesc = app.currentAppVersion?.localizedDescription {
                        _glassSection(title: .localized("What's New")) {
                            VStack(alignment: .leading, spacing: 12) {
                                AppVersionInfo(
                                    version: currentVer,
                                    date: app.currentDate?.date,
                                    description: whatsNewDesc
                                )
                            }
                        }
                    }
                    
                    // 8. المعلومات الأساسية (بدون حقل المصدر)
                    _glassSection(title: .localized("Information")) {
                        VStack(spacing: 14) {
                            if let bundleId = app.id { _infoRow(title: .localized("Identifier"), value: bundleId) }
                            if let category = app.category, !category.isEmpty { _infoRow(title: .localized("Category"), value: category.capitalized) }
                            if let version = app.currentVersion, !version.isEmpty { _infoRow(title: .localized("Version"), value: version) }
                        }
                    }
                    
                }
                .padding(.bottom, 40)
                .frame(maxWidth: UIScreen.main.bounds.width) // قفل عرض الشاشة لمنع التمدد الخاطئ
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NBToolbarButton(systemImage: "square.and.arrow.up", placement: .topBarTrailing) {
                let sharedString = "\(app.currentName) - v\(app.currentVersion ?? "1.0")\nShared via Hassany Store"
                UIActivityViewController.show(activityItems: [sharedString])
            }
        }
        .fullScreenCover(isPresented: $_isScreenshotPreviewPresented) {
            if let screenshotURLs = app.screenshotURLs {
                ScreenshotPreviewView(screenshotURLs: screenshotURLs, initialIndex: _selectedScreenshotIndex)
            }
        }
    }
    
    var standardIcon: some View {
        Image(systemName: "app.fill")
            .resizable()
            .frame(width: 110, height: 110)
            .foregroundColor(.purple.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }
}

// MARK: - Extension: UI Components
extension SourceAppsDetailView {
    
    // شريط الإحصائيات الأفقي الجديد مع حماية حجم النص
    @ViewBuilder
    private func _horizontalStatsRow() -> some View {
        HStack(spacing: 0) {
            _statItem(title: "الإصدار", value: app.currentVersion ?? "1.0")
            Divider().frame(height: 30).background(Color.white.opacity(0.3))
            _statItem(title: "الحجم", value: app.size?.formattedByteCount ?? "N/A")
            Divider().frame(height: 30).background(Color.white.opacity(0.3))
            _statItem(title: "تاريخ التحديث", value: app.currentDate?.date != nil ? DateFormatter.localizedString(from: app.currentDate!.date, dateStyle: .short, timeStyle: .none) : "N/A")
        }
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    
    @ViewBuilder
    private func _statItem(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.gray)
                .lineLimit(1)
                .minimumScaleFactor(0.8) // تصغير النص بدل دفعه للخارج
            
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8) // تصغير النص بدل دفعه للخارج
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 4)
    }
    
    @ViewBuilder
    private func _glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            content()
                .padding(18)
                .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.08), lineWidth: 1))
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private func _infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 14, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
    }
    
    @ViewBuilder
    private func _screenshots(screenshotURLs: [URL]) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(screenshotURLs.indices, id: \.self) { index in
                    let url = screenshotURLs[index]
                    LazyImage(url: url) { state in
                        if let image = state.image {
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(height: 240)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                                .onTapGesture {
                                    _selectedScreenshotIndex = index
                                    _isScreenshotPreviewPresented = true
                                }
                        }
                    }
                }
            }
        }
    }
}
