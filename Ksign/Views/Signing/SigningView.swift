//
//  SigningView.swift
//  Feather
//
//  Created by samara on 14.04.2025.
//  Modified for Hassany Store Theme (Pro Glass, Pulse Animation & Duplication)
//

import SwiftUI
import PhotosUI
import NimbleViews

// MARK: - View
struct SigningView: View {
    @Environment(\.dismiss) var dismiss
    @Namespace var _namespace

    @StateObject private var _optionsManager = OptionsManager.shared
    
    @State private var _temporaryOptions: Options = OptionsManager.shared.options
    @State private var _temporaryCertificate: Int
    @State private var _isAltPickerPresenting = false
    @State private var _isFilePickerPresenting = false
    @State private var _isImagePickerPresenting = false
    @State private var _isLogsPresenting = false
    @State private var _isSigning = false
    @State private var _selectedPhoto: PhotosPickerItem? = nil
    @State var appIcon: UIImage?
    
    // متغيرات الأنيميشن وميزة التكرار الجديدة
    @State private var isPulsing = false
    @State private var duplicateCount = 0 // عداد التكرار
    @State private var originalBundleID: String = "" // لحفظ المعرف الأصلي
    
    var signAndInstall: Bool = false
    
    // MARK: Fetch
    @FetchRequest(
        entity: CertificatePair.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CertificatePair.date, ascending: false)],
        animation: .snappy
    ) private var certificates: FetchedResults<CertificatePair>
    
    private func _selectedCert() -> CertificatePair? {
        guard certificates.indices.contains(_temporaryCertificate) else { return nil }
        return certificates[_temporaryCertificate]
    }
    
    private func _getCertAppID() -> String? {
        guard
            let cert = _selectedCert(),
            let decoded = Storage.shared.getProvisionFileDecoded(for: cert),
            let entitlements = decoded.Entitlements,
            let appID = entitlements["application-identifier"]?.value as? String
        else {
            return nil
        }
        return appID.split(separator: ".").dropFirst().joined(separator: ".")
    }
    
    var app: AppInfoPresentable
    
    init(app: AppInfoPresentable, signAndInstall: Bool = false) {
        self.app = app
        self.signAndInstall = signAndInstall
        let storedCert = UserDefaults.standard.integer(forKey: "feather.selectedCert")
        __temporaryCertificate = State(initialValue: storedCert)
    }
        
    // MARK: Body
    var body: some View {
        NBNavigationView("إعدادات التوقيع", displayMode: .inline) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // 1. أيقونة التطبيق
                    _appIconHeader(for: app)
                    
                    // 2. حقول التخصيص + ميزة التكرار
                    _customizationOptions(for: app)
                    
                    // 3. الشهادة
                    _cert()
                    
                    // 4. الخصائص المتقدمة
                    _customizationProperties(for: app)
                    
                    Spacer(minLength: 100)
                }
                .padding(.vertical)
            }
            .background(Color.black.edgesIgnoringSafeArea(.all))
            .disabled(_isSigning)
            .overlay(
                VStack {
                    Spacer()
                    if _isSigning {
                        Button() {
                            _isLogsPresenting = true
                        } label: {
                            Text(.localized("Show Logs"))
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                .padding(.horizontal, 20)
                        }
                        .compatMatchedTransitionSource(id: "showLogs", ns: _namespace)
                    } else {
                        Button() {
                            _start()
                        } label: {
                            Text("بدء التوقيع")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 18)
                                .background(
                                    LinearGradient(
                                        gradient: Gradient(colors: [Color.purple, Color(red: 0.3, green: 0.0, blue: 0.6)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                .shadow(color: .purple.opacity(0.8), radius: isPulsing ? 20 : 8, x: 0, y: isPulsing ? 10 : 3)
                                .scaleEffect(isPulsing ? 1.03 : 0.98)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 10),
                alignment: .bottom
            )
            .toolbar {
                NBToolbarButton(role: .dismiss)
                NBToolbarButton(.localized("Reset"), style: .text, placement: .topBarTrailing) {
                    _temporaryOptions = OptionsManager.shared.options
                    appIcon = nil
                    duplicateCount = 0
                    _temporaryOptions.appIdentifier = originalBundleID
                }
            }
            .sheet(isPresented: $_isAltPickerPresenting) { SigningAlternativeIconView(app: app, appIcon: $appIcon, isModifing: .constant(true)) }
            .sheet(isPresented: $_isFilePickerPresenting) {
                FileImporterRepresentableView(allowedContentTypes:  [.image], onDocumentsPicked: { urls in
                    guard let selectedFileURL = urls.first else { return }
                    self.appIcon = UIImage.fromFile(selectedFileURL)?.resizeToSquare()
                })
            }
            .photosPicker(isPresented: $_isImagePickerPresenting, selection: $_selectedPhoto)
            .fullScreenCover(isPresented: $_isLogsPresenting ) {
                LogsView(manager: LogsManager.shared).compatNavigationTransition(id: "showLogs", ns: _namespace)
            }
            .onChange(of: _selectedPhoto) { newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let image = UIImage(data: data)?.resizeToSquare() {
                        appIcon = image
                    }
                }
            }
            .animation(.smooth, value: _isSigning)
        }
        .onAppear {
            originalBundleID = app.identifier ?? "" // حفظ المعرف الأصلي لأجل التكرار
            
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
            
            if _optionsManager.options.ppqProtection, let identifier = app.identifier, let cert = _selectedCert(), cert.ppQCheck {
                _temporaryOptions.appIdentifier = "\(identifier).\(_optionsManager.options.ppqString)"
            }
            if let currentBundleId = app.identifier, let newBundleId = _temporaryOptions.identifiers[currentBundleId] {
                _temporaryOptions.appIdentifier = newBundleId
            }
            if let currentName = app.name, let newName = _temporaryOptions.displayNames[currentName] {
                _temporaryOptions.appName = newName
            }
            if _optionsManager.options.prefix != nil || _optionsManager.options.suffix != nil {
                var name = app.name ?? ""
                if let dictName = _temporaryOptions.displayNames[name] { name = dictName }
                if let prefix = _optionsManager.options.prefix { name = prefix + name }
                if let suffix = _optionsManager.options.suffix { name = name + suffix }
                _temporaryOptions.appName = name
            }
        }
    }
}

// MARK: - Extension: View (Glassmorphism UI & Duplication)
extension SigningView {
    
    @ViewBuilder
    private func _appIconHeader(for app: AppInfoPresentable) -> some View {
        Menu {
            Button(.localized("Select Alternative Icon")) { _isAltPickerPresenting = true }
            Button(.localized("Choose from Files")) { _isFilePickerPresenting = true }
            Button(.localized("Choose from Photos")) { _isImagePickerPresenting = true }
        } label: {
            ZStack {
                Circle().fill(Color.purple.opacity(0.15)).frame(width: 100, height: 100).shadow(color: .purple.opacity(0.3), radius: 15)
                
                if let icon = appIcon {
                    Image(uiImage: icon).resizable().aspectRatio(contentMode: .fit).frame(width: 75, height: 75).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                } else {
                    FRAppIconView(app: app, size: 75).clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                Image(systemName: "pencil.circle.fill").font(.title2).foregroundColor(.purple).background(Circle().fill(Color.black)).offset(x: 35, y: 35)
            }
        }
        .padding(.top, 10)
    }

    @ViewBuilder
    private func _customizationOptions(for app: AppInfoPresentable) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("التخصيص")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                _glassCell(.localized("Name"), desc: _temporaryOptions.appName ?? app.name) {
                    SigningPropertiesView(title: .localized("Name"), initialValue: _temporaryOptions.appName ?? (app.name ?? ""), bindingValue: $_temporaryOptions.appName)
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                
                _glassCell(.localized("Identifier"), desc: _temporaryOptions.appIdentifier ?? app.identifier) {
                    SigningPropertiesView(title: .localized("Identifier"), initialValue: _temporaryOptions.appIdentifier ?? (app.identifier ?? ""), certAppId: _getCertAppID(), bindingValue: $_temporaryOptions.appIdentifier)
                }
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                
                _glassCell(.localized("Version"), desc: _temporaryOptions.appVersion ?? app.version) {
                    SigningPropertiesView(title: .localized("Version"), initialValue: _temporaryOptions.appVersion ?? (app.version ?? ""), bindingValue: $_temporaryOptions.appVersion)
                }
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                
                // إضافة ميزة التكرار هنا
                _duplicationCell()
            }
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 16)
        }
    }
    
    // تصميم ميزة "تكرار التطبيق" (App Duplication)
    @ViewBuilder
    private func _duplicationCell() -> some View {
        HStack {
            // أزرار التحكم بالعدد (+ و -)
            HStack(spacing: 12) {
                Button(action: {
                    if duplicateCount > 0 {
                        duplicateCount -= 1
                        _applyDuplication()
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(duplicateCount > 0 ? .white : .gray)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
                
                Text("\(duplicateCount)")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .frame(minWidth: 20)
                
                Button(action: {
                    duplicateCount += 1
                    _applyDuplication()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color(red: 0.1, green: 0.8, blue: 0.4))) // أخضر ساطع
                }
            }
            
            Spacer()
            
            // النصوص
            VStack(alignment: .trailing, spacing: 4) {
                Text("تكرار التطبيق")
                    .font(.headline)
                    .foregroundColor(.white)
                Text("إنشاء نسخة مستقلة بجانب الأساسية")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            // الأيقونة البرتقالية
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: "square.on.square.badge.plus")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
            .padding(.leading, 8)
        }
        .padding()
        .background(Color.black.opacity(0.2)) // تمييز قسم التكرار
    }
    
    // الدالة السحرية لتعديل المعرف (Bundle ID) لنسخ التطبيق
    private func _applyDuplication() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        if duplicateCount > 0 {
            // إضافة رقم التكرار لمعرف التطبيق حتى ينزل كنسخة جديدة
            _temporaryOptions.appIdentifier = "\(originalBundleID).copy\(duplicateCount)"
        } else {
            // إرجاع المعرف الأصلي إذا العداد صفر
            _temporaryOptions.appIdentifier = originalBundleID
        }
    }
    
    @ViewBuilder
    private func _cert() -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("الشهادة (التوقيع)")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)
            
            VStack {
                if let cert = _selectedCert() {
                    NavigationLink { CertificatesView(selectedCert: $_temporaryCertificate) } label: { CertificatesCellView(cert: cert).padding(8) }
                } else {
                    Text("لا توجد شهادة").foregroundColor(.gray).padding()
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func _customizationProperties(for app: AppInfoPresentable) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("متقدم")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding(.horizontal, 24)
            
            VStack(spacing: 0) {
                NavigationLink(String.localized("Properties")) {
                    Form { SigningOptionsView(options: $_temporaryOptions, temporaryOptions: _optionsManager.options) }.navigationTitle(.localized("Properties"))
                }
                .padding().frame(maxWidth: .infinity, alignment: .leading)
                
                Divider().background(Color.white.opacity(0.1)).padding(.leading, 16)
                
                DisclosureGroup("تعديل الإضافات (مكاتب وهاكات)") {
                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink(.localized("Existing Dylibs")) { SigningDylibView(app: app, options: $_temporaryOptions.optional()) }
                        NavigationLink(String.localized("Frameworks & PlugIns")) { SigningFrameworksView(app: app, options: $_temporaryOptions.optional()) }
                        #if NIGHTLY || DEBUG
                        NavigationLink(String.localized("Entitlements")) { SigningEntitlementsView(bindingValue: $_temporaryOptions.appEntitlementsFile) }
                        #endif
                        NavigationLink(String.localized("Tweaks")) { SigningTweaksView(options: $_temporaryOptions) }
                    }
                    .padding(.top, 12).padding(.bottom, 8).foregroundColor(.white)
                }
                .padding().accentColor(.purple)
            }
            .background(Color(UIColor.secondarySystemGroupedBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.15), lineWidth: 1))
            .padding(.horizontal, 16)
        }
    }
    
    @ViewBuilder
    private func _glassCell<V: View>(_ title: String, desc: String?, @ViewBuilder destination: () -> V) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Text(title).foregroundColor(.white)
                Spacer()
                Text(desc ?? .localized("Unknown")).foregroundColor(.gray).lineLimit(1).truncationMode(.tail).frame(maxWidth: 150, alignment: .trailing)
            }
            .padding().contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

extension SigningView {
    private func _start() {
        guard _selectedCert() != nil || _temporaryOptions.doAdhocSigning || _temporaryOptions.onlyModify else {
            UIAlertController.showAlertWithOk(title: .localized("No Certificate"), message: .localized("Please go to settings and import a valid certificate"), isCancel: true)
            return
        }

        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        _isLogsPresenting = _optionsManager.options.signingLogs
        _isSigning = true
#if DEBUG
        LogsManager.shared.startCapture()
#endif
        FR.signPackageFile(app, using: _temporaryOptions, icon: appIcon, certificate: _selectedCert()) { [self] error in
            if let error {
                let ok = UIAlertAction(title: .localized("Dismiss"), style: .cancel) { _ in dismiss() }
                UIAlertController.showAlert(title: .localized("Signing"), message: error.localizedDescription, actions: [ok])
            } else {
                if _temporaryOptions.removeApp && !app.isSigned { Storage.shared.deleteApp(for: app) }
                if signAndInstall {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                        NotificationCenter.default.post(name: NSNotification.Name("feather.installApp"), object: nil)
                    }
                }
                dismiss()
            }
        }
    }
}
