//
//  LibraryAppIconView.swift
//  Feather
//
//  Created by samara on 11.04.2025.
//

import SwiftUI
import NimbleExtensions
import NimbleViews

// MARK: - View
struct LibraryCellView: View {
    @AppStorage("Feather.libraryCellAppearance") private var _libraryCellAppearance: Int = 0
    @Environment(\.editMode) private var editMode
    
    var certInfo: Date.ExpirationInfo? {
        Storage.shared.getCertificate(from: app)?.expiration?.expirationInfo()
    }
    
    var app: AppInfoPresentable
    @Binding var selectedInfoAppPresenting: AnyApp?
    @Binding var selectedSigningAppPresenting: AnyApp?
    @Binding var selectedInstallAppPresenting: AnyApp?
    @Binding var selectedAppDylibsPresenting: AnyApp?
    @Binding var selectedApps: Set<String>
    
    // متغير الحركة (التنفس)
    @State private var isAnimating = false
    
    private var _isSelected: Bool {
        selectedApps.contains(app.uuid ?? "")
    }
    
    // MARK: Body
    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        HStack(spacing: 12) {
            // زر التحديد في وضع التعديل
            if isEditing {
                Button {
                    _toggleSelection()
                } label: {
                    Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(_isSelected ? .green : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
            }
            
            // بداية البطاقة (Card)
            VStack(spacing: 16) {
                // الجزء العلوي: الأيقونة، الاسم، الإصدار، وحالة الشهادة
                HStack(alignment: .center, spacing: 12) {
                    FRAppIconView(app: app, size: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(app.name ?? .localized("Unknown"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(_desc)
                            .font(.caption)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // كبسولة حالة الشهادة (تظهر فقط إذا كان التطبيق موقع)
                        if !isEditing, app.isSigned, let certInfo = certInfo {
                            HStack(spacing: 4) {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 10))
                                Text(certInfo.formatted)
                                    .font(.system(size: 10, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(certInfo.color)
                            .clipShape(Capsule())
                            .padding(.top, 2)
                        }
                    }
                    Spacer()
                }
                
                // الجزء السفلي: الأزرار (تظهر فقط إذا لم نكن في وضع التعديل)
                if !isEditing {
                    HStack(spacing: 12) {
                        
                        // 1. الزر الأخضر (توقيع وتثبيت / أو تثبيت)
                        Button {
                            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                            impactFeedback.impactOccurred()
                            
                            if app.isSigned {
                                selectedInstallAppPresenting = AnyApp(base: app)
                            } else {
                                selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
                            }
                        } label: {
                            Text(app.isSigned ? "تثبيت" : "توقيع وتثبيت")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color(red: 0.1, green: 0.75, blue: 0.4)) // أخضر احترافي
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.borderless)
                        
                        // 2. الزر الرصاصي (القائمة العصرية - Menu)
                        Menu {
                            if app.isSigned {
                                if let id = app.identifier {
                                    Button { UIApplication.openApp(with: id) } label: {
                                        Label("فتح", systemImage: "app.badge.checkmark")
                                    }
                                }
                                Button { selectedSigningAppPresenting = AnyApp(base: app) } label: {
                                    Label("إعادة توقيع", systemImage: "signature")
                                }
                            } else {
                                Button { selectedSigningAppPresenting = AnyApp(base: app) } label: {
                                    Label("توقيع", systemImage: "signature")
                                }
                            }
                            
                            Button { selectedInstallAppPresenting = AnyApp(base: app, archive: true) } label: {
                                Label("تصدير", systemImage: "square.and.arrow.up")
                            }
                            
                            Button { selectedAppDylibsPresenting = AnyApp(base: app) } label: {
                                Label("إظهار المكتبات", systemImage: "building.columns")
                            }
                            
                            Button { selectedInfoAppPresenting = AnyApp(base: app) } label: {
                                Label("عرض المعلومات", systemImage: "info.circle")
                            }
                            
                            // زر الحذف باللون الأحمر التلقائي
                            Button(role: .destructive) { Storage.shared.deleteApp(for: app) } label: {
                                Label("حذف", systemImage: "trash")
                            }
                        } label: {
                            Text("خيارات أخرى")
                                .font(.subheadline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.15)) // رصاصي شفاف
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.8)) // لون البطاقة
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
            // تأثير النبض (التنفس)
            .scaleEffect(_isSelected ? 0.95 : (isAnimating ? 1.015 : 1.0))
            .onTapGesture {
                if isEditing { _toggleSelection() }
            }
            .onAppear {
                // تشغيل الأنيميشن بشكل مستمر وهادئ
                withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                    isAnimating = true
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        // إخفاء فواصل القائمة التقليدية والخلفية المزعجة
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - الدوال المساعدة
    private var _desc: String {
        if let version = app.version, let id = app.identifier {
            return "\(version) • \(id)"
        } else {
            return .localized("Unknown")
        }
    }
    
    private func _toggleSelection() {
        guard let uuid = app.uuid else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8, blendDuration: 0)) {
            if _isSelected {
                selectedApps.remove(uuid)
            } else {
                selectedApps.insert(uuid)
            }
        }
    }
}
