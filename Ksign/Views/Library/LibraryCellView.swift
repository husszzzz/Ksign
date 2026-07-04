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
    
    // متغيرات التحكم بالانقلاب ثلاثي الأبعاد
    @State private var isFlipped = false
    @State private var degrees: Double = 0
    
    private var _isSelected: Bool {
        selectedApps.contains(app.uuid ?? "")
    }
    
    // MARK: Body
    var body: some View {
        let isEditing = editMode?.wrappedValue == .active
        
        ZStack {
            // وجه الكارت الأمامي (معلومات التطبيق)
            VStack(spacing: 12) {
                FRAppIconView(app: app, size: 70)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 3)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.1), lineWidth: 1))
                
                VStack(spacing: 4) {
                    Text(app.name ?? .localized("Unknown"))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                    
                    Text(app.version ?? "")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
                
                if app.isSigned, let certInfo = certInfo {
                    Text("موقّع ✅")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(certInfo.color)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(certInfo.color.opacity(0.15))
                        .clipShape(Capsule())
                } else {
                    Text("غير موقّع ⚠️")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.06), lineWidth: 1))
            .opacity(isFlipped ? 0.0 : 1.0) // إخفاء الوجه عند الانقلاب
            
            // ظهر الكارت الخلفي (لوحة خيارات التحكم)
            VStack(spacing: 10) {
                // الزر الرئيسي الكبير (توقيع وتثبيت / تثبيت)
                Button {
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    if app.isSigned {
                        selectedInstallAppPresenting = AnyApp(base: app)
                    } else {
                        selectedSigningAppPresenting = AnyApp(base: app, signAndInstall: true)
                    }
                } label: {
                    Text(app.isSigned ? "تثبيت" : "توقيع وتثبيت")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: app.isSigned ? [Color.blue, Color(red: 0.2, green: 0.6, blue: 1.0)] : [Color(red: 0.1, green: 0.7, blue: 0.3), Color(red: 0.1, green: 0.55, blue: 0.3)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.borderless)
                
                // خيارات شبكية مصغرة لباقي العمليات
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    Button {
                        selectedSigningAppPresenting = AnyApp(base: app)
                    } label: {
                        _miniOptionButton(title: "توقيع", icon: "signature", color: .blue)
                    }
                    
                    Button {
                        selectedInstallAppPresenting = AnyApp(base: app, archive: true)
                    } label: {
                        _miniOptionButton(title: "تصدير", icon: "square.and.arrow.up", color: .purple)
                    }
                    
                    Button {
                        selectedAppDylibsPresenting = AnyApp(base: app)
                    } label: {
                        _miniOptionButton(title: "مكتبات", icon: "building.columns", color: .cyan)
                    }
                    
                    Button {
                        Storage.shared.deleteApp(for: app)
                    } label: {
                        _miniOptionButton(title: "حذف", icon: "trash", color: .red)
                    }
                }
                .buttonStyle(.borderless)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 170)
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.95))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
            .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0)) // قلب العناصر بالخلف لتظهر صحيحة
            .opacity(isFlipped ? 1.0 : 0.0) // إظهار الظهر فقط عند الانقلاب
        }
        // تأثيرات الدوران 3D على الكارت بالكامل
        .rotation3DEffect(.degrees(degrees), axis: (x: 0, y: 1, z: 0))
        .contentShape(Rectangle())
        .onTapGesture {
            if isEditing {
                _toggleSelection()
            } else {
                // أنيميشن الانقلاب ثلاثي الأبعاد
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0)) {
                    self.degrees += 180
                    self.isFlipped.toggle()
                }
            }
        }
        .scaleEffect(_isSelected ? 0.95 : 1.0)
    }
    
    // ويدجت صغير للأزرار بالخلف
    @ViewBuilder
    private func _miniOptionButton(title: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 8))
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
