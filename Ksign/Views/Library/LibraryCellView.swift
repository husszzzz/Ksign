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
    
    private var _isSelected: Bool {
        selectedApps.contains(app.uuid ?? "")
    }
    
    // MARK: Body
    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        HStack(spacing: 12) {
            // زر التحديد في وضع التعديل (Edit Mode)
            if isEditing {
                Button {
                    _toggleSelection()
                } label: {
                    Image(systemName: _isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(_isSelected ? .green : .secondary)
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .transition(.scale)
            }
            
            // بداية البطاقة الاحترافية (Pro Card)
            VStack(spacing: 16) {
                // القسم العلوي: الأيقونة والمعلومات
                HStack(alignment: .center, spacing: 14) {
                    FRAppIconView(app: app, size: 64)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: .black.opacity(0.3), radius: 5, x: 0, y: 3)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.white.opacity(0.1), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(app.name ?? .localized("Unknown"))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text(_desc)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.gray)
                            .lineLimit(1)
                        
                        // حالة الشهادة
                        if !isEditing, app.isSigned, let certInfo = certInfo {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 11))
                                Text(certInfo.formatted)
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(certInfo.color)
                        }
                    }
                    Spacer()
                }
                
                // القسم السفلي: الأزرار (يظهر فقط إذا لم نكن في وضع التعديل)
                if !isEditing {
                    HStack(spacing: 12) {
                        // الزر الرئيسي (توقيع وتثبيت)
                        Button {
                            let impact = UIImpactFeedbackGenerator(style: .medium)
                            impact.impactOccurred()
                            
                            if app.isSigned {
                                selectedInstallAppPresenting = AnyApp(base: app)
                            } else {
                                selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: app.isSigned ? "arrow.down.app.fill" : "signature")
                                    .font(.system(size: 16, weight: .bold))
                                Text(app.isSigned ? "تثبيت التطبيق" : "توقيع وتثبيت")
                                    .font(.system(size: 16, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            // تدرج لوني احترافي جداً
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: app.isSigned ? [Color.blue, Color(red: 0.2, green: 0.6, blue: 1.0)] : [Color(red: 0.1, green: 0.7, blue: 0.3), Color(red: 0.1, green: 0.55, blue: 0.3)]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .buttonStyle(.borderless)
                        
                        // زر الخيارات (Menu) الأنيق
                        Menu {
                            Section {
                                if app.isSigned {
                                    if let id = app.identifier {
                                        Button { UIApplication.openApp(with: id) } label: {
                                            Label("فتح التطبيق", systemImage: "app.badge.checkmark")
                                        }
                                    }
                                    Button { selectedSigningAppPresenting = AnyApp(base: app) } label: {
                                        Label("إعادة توقيع", systemImage: "signature")
                                    }
                                } else {
                                    Button { selectedSigningAppPresenting = AnyApp(base: app) } label: {
                                        Label("توقيع يدوي", systemImage: "signature")
                                    }
                                }
                                
                                Button { selectedInstallAppPresenting = AnyApp(base: app, archive: true) } label: {
                                    Label("تصدير (IPA)", systemImage: "square.and.arrow.up")
                                }
                            }
                            
                            Section {
                                Button { selectedAppDylibsPresenting = AnyApp(base: app) } label: {
                                    Label("إظهار المكتبات (Dylibs)", systemImage: "building.columns")
                                }
                                
                                Button { selectedInfoAppPresenting = AnyApp(base: app) } label: {
                                    Label("معلومات مفصلة", systemImage: "info.circle")
                                }
                            }
                            
                            Section {
                                Button(role: .destructive) { Storage.shared.deleteApp(for: app) } label: {
                                    Label("حذف التطبيق", systemImage: "trash")
                                }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                                // قياس الزر يتناسب مع زر التوقيع
                                .frame(width: 52, height: 52)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
            }
            .padding(16)
            // خلفية الكارت الفخمة
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(UIColor.secondarySystemGroupedBackground))
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
            )
            // إطار خفيف جداً يبرز الكارت
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .scaleEffect(_isSelected ? 0.96 : 1.0)
            .onTapGesture {
                if isEditing { _toggleSelection() }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
    }
    
    // MARK: - الدوال المساعدة
    private var _desc: String {
        if let version = app.version, let id = app.identifier {
            return "v\(version) • \(id)"
        } else {
            return .localized("Unknown")
        }
    }
    
    private func _toggleSelection() {
        guard let uuid = app.uuid else { return }
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7, blendDuration: 0)) {
            if _isSelected {
                selectedApps.remove(uuid)
            } else {
                selectedApps.insert(uuid)
            }
        }
    }
}
