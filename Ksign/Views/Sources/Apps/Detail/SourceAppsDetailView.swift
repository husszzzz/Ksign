//
//  SourceAppsDetailView.swift
//  Feather
//
//  Created by samsam on 7/25/25.
//  Modified for Hassany Store (VIP Glassmorphism & Hidden Source)
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
    @State var cancellable: AnyCancellable? // Combine
    @State private var _isScreenshotPreviewPresented: Bool = false
    @State private var _selectedScreenshotIndex: Int = 0
    
    var currentDownload: Download? {
        downloadManager.getDownload(by: app.currentUniqueId)
    }
    
    var source: ASRepository
    var app: ASRepository.App
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            
            // 1. الهيدر الفخم (أيقونة + معلومات أساسية + زر تثبيت)
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 16) {
                    // أيقونة التطبيق
                    if let iconURL = app.iconURL {
                        LazyImage(url: iconURL) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 100, height: 100)
                                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                            } else {
                                standardIcon
                            }
                        }
                    } else {
                        standardIcon
                    }

                    // اسم التطبيق والوصف المختصر
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.currentName)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)
                        
                        Text(app.currentDescription ?? .localized("An awesome application"))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(2)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.top, 16)
                
                // زر التثبيت الكبير (Gradient)
                HStack {
                    DownloadButtonView(app: app)
                        .frame(maxWidth: .infinity)
                        .font(.headline)
                        .padding(.vertical, 4)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color(red: 0.4, green: 0.1, blue: 0.7)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Capsule())
                        .shadow(color: .purple.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal)
                
                // كبسولات المعلومات (الحجم والإصدار)
                _infoPills(app: app)
                    .padding(.horizontal)
            }
            .padding(.bottom, 10)
            
            VStack(spacing: 16) {
                // 2. لقطات الشاشة (Screenshots)
                if let screenshotURLs = app.screenshotURLs {
                    _glassSection(title: .localized("Screenshots")) {
                        _screenshots(screenshotURLs: screenshotURLs)
                    }
                }
                
                // 3. ما الجديد (What's New)
                if let currentVer = app.currentVersion, let whatsNewDesc = app.currentAppVersion?.localizedDescription {
                    _glassSection(title: .localized("What's New")) {
                        VStack(alignment: .leading, spacing: 12) {
                            AppVersionInfo(
                                version: currentVer,
                                date: app.currentDate?.date,
                                description: whatsNewDesc
                            )
                            if let versions = app.versions {
                                NavigationLink(destination: VersionHistoryView(app: app, versions: versions).navigationTitle(.localized("Version History")).navigationBarTitleDisplayMode(.large)) {
                                    Text(.localized("Version History"))
                                        .font(.subheadline.bold())
                                        .foregroundColor(.purple)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                }
                
                // 4. الوصف (Description)
                if let appDesc = app.localizedDescription {
                    _glassSection(title: .localized("Description")) {
                        ExpandableText(text: appDesc, lineLimit: 4)
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                
                // 5. المعلومات (Information) - تم إخفاء المصدر 🚫
                _glassSection(title: .localized("Information")) {
                    VStack(spacing: 12) {
                        // 🚫 تم حذف حقل "المصدر" (Source) من هنا
                        
                        if let developer = app.developer, !developer.isEmpty {
                            _infoRow(title: .localized("Developer"), value: developer)
                        }
                        if let size = app.size {
                            _infoRow(title: .localized("Size"), value: size.formattedByteCount)
                        }
                        if let category = app.category, !category.isEmpty {
                            _infoRow(title: .localized("Category"), value: category.capitalized)
                        }
                        if let version = app.currentVersion, !version.isEmpty {
                            _infoRow(title: .localized("Version"), value: version)
                        }
                        if let date = app.currentDate?.date {
                            _infoRow(title: .localized("Updated"), value: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none))
                        }
                        if let bundleId = app.id {
                            _infoRow(title: .localized("Identifier"), value: bundleId)
                        }
                    }
                }
                
                // 6. الصلاحيات (Permissions)
                if let appPermissions = app.appPermissions {
                    _glassSection(title: .localized("Permissions")) {
                        VStack(alignment: .leading, spacing: 12) {
                            if let entitlements = appPermissions.entitlements {
                                NBTitleWithSubtitleView(
                                    title: .localized("Entitlements"),
                                    subtitle: entitlements.map(\.name).joined(separator: "\n")
                                )
                            }
                            if let privacyItems = appPermissions.privacy {
                                ForEach(privacyItems, id: \.self) { item in
                                    NBTitleWithSubtitleView(
                                        title: item.name,
                                        subtitle: item.usageDescription
                                    )
                                }
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 30)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all)) // خلفية سوداء لبروز التصميم الزجاجي
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            NBToolbarButton(systemImage: "square.and.arrow.up", placement: .topBarTrailing) {
                let sharedString = """
                \(app.currentName) - v\(app.currentVersion ?? "1.0")
                \(app.currentDescription ?? "")
                ---
                Shared via Hassany Store
                """
                UIActivityViewController.show(activityItems: [sharedString])
            }
        }
        .fullScreenCover(isPresented: $_isScreenshotPreviewPresented) {
            if let screenshotURLs = app.screenshotURLs {
                ScreenshotPreviewView(
                    screenshotURLs: screenshotURLs,
                    initialIndex: _selectedScreenshotIndex
                )
            }
        }
    }
    
    var standardIcon: some View {
        Image(systemName: "app.fill")
            .resizable()
            .frame(width: 100, height: 100)
            .foregroundColor(.purple.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}

// MARK: - Extension: UI Components (Glassmorphism)
extension SourceAppsDetailView {
    
    // تصميم الأقسام كـ "بطاقات زجاجية" (Glass Sections)
    @ViewBuilder
    private func _glassSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 4)
            
            content()
                .padding(16)
                .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.white.opacity(0.1), lineWidth: 1))
        }
    }
    
    @ViewBuilder
    private func _infoPills(app: ASRepository.App) -> some View {
        let pillItems = _buildPills(from: app)
        HStack(spacing: 12) {
            ForEach(pillItems.indices, id: \.hashValue) { index in
                let pill = pillItems[index]
                HStack(spacing: 6) {
                    Image(systemName: pill.icon)
                        .font(.system(size: 14, weight: .semibold))
                    Text(pill.title)
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(pill.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(pill.color.opacity(0.15))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private func _buildPills(from app: ASRepository.App) -> [NBPillItem] {
        var pills: [NBPillItem] = []
        if let version = app.currentVersion {
            pills.append(NBPillItem(title: version, icon: "tag.fill", color: .purple))
        }
        if let size = app.size {
            pills.append(NBPillItem(title: size.formattedByteCount, icon: "externaldrive.fill", color: .gray))
        }
        return pills
    }
    
    @ViewBuilder
    private func _infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
                .font(.system(size: 15, weight: .medium))
            Spacer()
            Text(value)
                .foregroundColor(.white)
                .font(.system(size: 15, weight: .semibold))
        }
        Divider().background(Color.white.opacity(0.1))
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
                                .frame(height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .onTapGesture {
                                    _selectedScreenshotIndex = index
                                    _isScreenshotPreviewPresented = true
                                }
                        }
                    }
                }
            }
        }
        .padding(.horizontal, -16) // لتمديد السكرول لحواف الشاشة
    }
}
