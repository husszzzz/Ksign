//
//  ContentView.swift
//  Feather
//
//  Created by samara on 10.04.2025.
//

import SwiftUI
import CoreData
import NimbleViews

// MARK: - View
struct LibraryView: View {
	@StateObject var downloadManager = DownloadManager.shared
	
	@State private var _selectedInfoAppPresenting: AnyApp?
	@State private var _selectedSigningAppPresenting: AnyApp?
	@State private var _selectedInstallAppPresenting: AnyApp?
	@State private var _selectedAppDylibsPresenting: AnyApp?
	@State private var _isBulkSigningPresenting = false
    @State private var _isBulkInstallingPresenting = false
	@State private var _isImportingPresenting = false
	@State private var _isDownloadingPresenting = false

	@State private var _alertDownloadString: String = "" // for _isDownloadingPresenting
	@State private var _searchText = ""
	@State private var _selectedTab: Int = 0 // 0 for Downloaded, 1 for Signed
	
	// MARK: Edit Mode
    @State private var _isEditMode: EditMode = .inactive
	@State private var _selectedApps: Set<String> = []
	
	@Namespace private var _namespace
	
	// horror
	private func filteredAndSortedApps<T>(from apps: FetchedResults<T>) -> [T] where T: NSManagedObject {
		apps.filter {
			_searchText.isEmpty ||
			(($0.value(forKey: "name") as? String)?.localizedCaseInsensitiveContains(_searchText) ?? false)
		}
	}
	
	private var _filteredSignedApps: [Signed] {
		filteredAndSortedApps(from: _signedApps)
	}
	
	private var _filteredImportedApps: [Imported] {
		filteredAndSortedApps(from: _importedApps)
	}
	
	// MARK: Fetch
	@FetchRequest(
		entity: Signed.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Signed.date, ascending: false)],
		animation: .snappy
	) private var _signedApps: FetchedResults<Signed>
	
	@FetchRequest(
		entity: Imported.entity(),
		sortDescriptors: [NSSortDescriptor(keyPath: \Imported.date, ascending: false)],
		animation: .snappy
	) private var _importedApps: FetchedResults<Imported>
	
	// MARK: Body
    var body: some View {
		NBNavigationView(.localized("Library")) {
			VStack(spacing: 0) {
				Picker("", selection: $_selectedTab) {
					Text(.localized("Downloaded Apps")).tag(0)
					Text(.localized("Signed Apps")).tag(1)
				}
				.pickerStyle(SegmentedPickerStyle())
				.padding(.horizontal)
				.padding(.vertical, 8)
				
				NBListAdaptable {
					if _selectedTab == 0 {
						NBSection(
							.localized("Downloaded Apps"),
							secondary: _filteredImportedApps.count.description
						) {
							ForEach(_filteredImportedApps, id: \.uuid) { app in
								LibraryCellView(
									app: app,
									selectedInfoAppPresenting: $_selectedInfoAppPresenting,
									selectedSigningAppPresenting: $_selectedSigningAppPresenting,
									selectedInstallAppPresenting: $_selectedInstallAppPresenting,
									selectedAppDylibsPresenting: $_selectedAppDylibsPresenting,
									selectedApps: $_selectedApps
								)
								.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
							}
						}
					} else {
						NBSection(
							.localized("Signed Apps"),
							secondary: _filteredSignedApps.count.description
						) {
							ForEach(_filteredSignedApps, id: \.uuid) { app in
								LibraryCellView(
									app: app,
									selectedInfoAppPresenting: $_selectedInfoAppPresenting,
									selectedSigningAppPresenting: $_selectedSigningAppPresenting,
									selectedInstallAppPresenting: $_selectedInstallAppPresenting,
									selectedAppDylibsPresenting: $_selectedAppDylibsPresenting,
									selectedApps: $_selectedApps
								)
								.compatMatchedTransitionSource(id: app.uuid ?? "", ns: _namespace)
							}
						}
					}
				}
			}
			.searchable(text: $_searchText, placement: .platform())
            .overlay {
                // التصميم مع اللون الأزرق الكلاسيكي
                if _filteredSignedApps.isEmpty && _filteredImportedApps.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "signature")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(.gray)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.gray)
                                    .offset(x: 25, y: 15)
                            )
                            .padding(.bottom, 8)
                        
                        Text(.localized("No Apps"))
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(.localized("Get started by importing your first IPA file."))
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                        
                        Button {
                            _isImportingPresenting = true
                        } label: {
                            Text(.localized("Import from Files"))
                                .font(.headline)
                                .foregroundColor(.blue) // اللون الأزرق الكلاسيكي
                                .padding(.horizontal, 24)
                                .padding(.vertical, 12)
                                .background(Color.blue.opacity(0.15)) // خلفية زرقاء شفافة
                                .clipShape(Capsule())
                        }
                        .padding(.top, 10)
                    }
                }
            }
			.toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                if _isEditMode.isEditing {
					ToolbarItemGroup(placement: .topBarTrailing) {
                        if _selectedTab == 0 {
                            Button {
                                _isBulkSigningPresenting = true
                            } label: {
                                NBButton(.localized("Sign"), systemImage: "signature", style: .icon)
                            }
                            .disabled(_selectedApps.isEmpty)
                        } else {
                            Button {
                                _isBulkInstallingPresenting = true
                            } label: {
                                NBButton(.localized("Install"), systemImage: "square.and.arrow.down")
                            }
                            .disabled(_selectedApps.isEmpty)
                        }
						Button {
							_bulkDeleteSelectedApps()
						} label: {
							NBButton(.localized("Delete"), systemImage: "trash", style: .icon)
						}
						.disabled(_selectedApps.isEmpty)
					}
				} else {
                    // الأزرار العلوية الجديدة (مربوطة بشكل مباشر وصحيح)
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        Button {
                            _isDownloadingPresenting = true
                        } label: {
                            Image(systemName: "link")
                                .font(.system(size: 16, weight: .medium))
                        }
                        
                        Button {
                            _isImportingPresenting = true
                        } label: {
                            Image(systemName: "folder.badge.plus")
                                .font(.system(size: 16, weight: .medium))
                        }
                    }
				}
			}
            .environment(\.editMode, $_isEditMode)
			.sheet(item: $_selectedInfoAppPresenting) { app in
				LibraryInfoView(app: app.base)
			}
			.sheet(item: $_selectedInstallAppPresenting) { app in
				InstallPreviewView(app: app.base, isSharing: app.archive)
					.presentationDetents([.height(200)])
					.presentationDragIndicator(.visible)			}
			.fullScreenCover(item: $_selectedSigningAppPresenting) { app in
				SigningView(app: app.base, signAndInstall: app.signAndInstall)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.fullScreenCover(item: $_selectedAppDylibsPresenting) { app in
                DylibsView(app: app.base)
					.compatNavigationTransition(id: app.base.uuid ?? "", ns: _namespace)
			}
			.fullScreenCover(isPresented: $_isBulkSigningPresenting) {
				BulkSigningView(apps: _selectedApps.compactMap { id in
					(_importedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
					?? (_signedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
				})
				.compatNavigationTransition(id: _selectedApps.joined(separator: ","), ns: _namespace)
				.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ksign.bulkSigningFinished"))) { notification in
					_selectedTab = 1
				}
			}
            .sheet(isPresented: $_isBulkInstallingPresenting) {
                BulkInstallPreviewView(apps: _selectedApps.compactMap { id in
                    (_importedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
                    ?? (_signedApps.first(where: { $0.uuid == id }) as AppInfoPresentable?)
                })
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
            }
            // نافذة استيراد الملفات (معالجة الملفات)
			.sheet(isPresented: $_isImportingPresenting) {
				FileImporterRepresentableView(
					allowedContentTypes:  [.ipa, .tipa],
					allowsMultipleSelection: true,
					onDocumentsPicked: { urls in
						guard !urls.isEmpty else { return }
						
						for ipas in urls {
							let id = "FeatherManualDownload_\(UUID().uuidString)"
							let dl = downloadManager.startArchive(from: ipas, id: id)
							downloadManager.handlePachageFile(url: ipas, dl: dl) { err in
								if let error = err {
									UIAlertController.showAlertWithOk(title: "Error", message: .localized("Whoops!, something went wrong when extracting the file. \nMaybe try switching the extraction library in the settings?"))
								}
							}
						}
					}
				)
			}
            // نافذة التحميل من رابط (مربوطة بزر الرابط العلوي)
			.alert(.localized("Import from URL"), isPresented: $_isDownloadingPresenting) {
				TextField(.localized("URL"), text: $_alertDownloadString)
				Button(.localized("Cancel"), role: .cancel) {
					_alertDownloadString = ""
				}
				Button(.localized("OK")) {
					if let url = URL(string: _alertDownloadString), !_alertDownloadString.isEmpty {
						_ = downloadManager.startDownload(from: url, id: "FeatherManualDownload_\(UUID().uuidString)")
					}
                    _alertDownloadString = ""
				}
			}
			.onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("feather.installApp"))) { notification in
                if let app = _signedApps.first {
                    _selectedInstallAppPresenting = AnyApp(base: app)
				}
			}
        }
        .onChange(of: _isEditMode) { state in
            if !state.isEditing {
                DispatchQueue.main.asyncAfter(deadline: .now()) {
                    withAnimation{
                        _selectedApps.removeAll()
                    }
                }
            }
        }
    }
}

// MARK: - Extension: View (Edit Mode Functions)
extension LibraryView {
	private func _bulkDeleteSelectedApps() {
		let appsToDelete = _selectedApps
		
		withAnimation(.easeInOut(duration: 0.5)) {
			for appUUID in appsToDelete {
				if let signedApp = _signedApps.first(where: { $0.uuid == appUUID }) {
					Storage.shared.deleteApp(for: signedApp)
				} else if let importedApp = _importedApps.first(where: { $0.uuid == appUUID }) {
					Storage.shared.deleteApp(for: importedApp)
				}
			}
		}
		
		DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
			_selectedApps.removeAll()
		}
	}
}
