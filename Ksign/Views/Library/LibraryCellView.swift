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
            // 1. زر التحديد في وضع التعديل (Edit Mode)
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
            
            // 2. أيقونة التطبيق
            FRAppIconView(app: app, size: 54)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
            
            // 3. معلومات التطبيق (الاسم، الإصدار، حالة الشهادة)
            VStack(alignment: .leading, spacing: 4) {
                Text(app.name ?? .localized("Unknown"))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                Text(_desc)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // كبسولة حالة الشهادة (تظهر أسفل الاسم إذا كان التطبيق موقّع)
                if !isEditing, app.isSigned, let certInfo = certInfo {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                        Text(certInfo.formatted)
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundColor(certInfo.color)
                    .padding(.top, 1)
                }
            }
            
            Spacer(minLength: 8)
            
            // 4. الأزرار الجانبية الأنيقة (تظهر فقط إذا لم نكن في وضع التعديل)
            if !isEditing {
                HStack(spacing: 8) {
                    
                    // زر التوقيع/التثبيت (Pill Button - يشبه App Store)
                    Button {
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                        
                        if app.isSigned {
                            selectedInstallAppPresenting = AnyApp(base: app)
                        } else {
                            selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
                        }
                    } label: {
                        Text(app.isSigned ? "تثبيت" : "توقيع")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            // لون أزرق للتثبيت، وأخضر للتوقيع
                            .background(app.isSigned ? Color.blue : Color(red: 0.1, green: 0.75, blue: 0.4))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.borderless)
                    
                    // زر القائمة المنسدلة (ثلاث نقاط)
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
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.secondary)
                            .frame(width: 30, height: 30)
                            .background(Color.secondary.opacity(0.15))
                            .clipShape(Circle())
                    }
                }
            }
        }
        .padding(12)
        // خلفية الكارت أنيقة وخفيفة
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 5, x: 0, y: 2)
        // تأثير الضغط
        .scaleEffect(_isSelected ? 0.96 : 1.0)
        .onTapGesture {
            if isEditing { _toggleSelection() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
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
