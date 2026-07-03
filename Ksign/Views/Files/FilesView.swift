import SwiftUI
import UniformTypeIdentifiers
import QuickLook
import NimbleViews

struct FilesView: View {
    let directoryURL: URL?
    let isRootView: Bool
    @Namespace private var _namespace
    @StateObject private var viewModel: FilesViewModel
    @StateObject private var downloadManager = DownloadManager.shared
    @State private var searchText = ""
    @AppStorage("Feather.useLastExportLocation") private var _useLastExportLocation: Bool = false
    @State private var plistFileURL: URL?
    @State private var hexEditorFileURL: URL?
    @State private var textEditorFileURL: URL?
    @State private var quickLookFileURL: URL?
    @State private var moveSingleFile: FileItem?
    @State private var shareItems: [Any] = []
    @State private var navigateToDirectoryURL: URL?
    @State private var _appToSign: FileItem? // المتغير الجديد لربط التوقيع

    init() { self.directoryURL = nil; self.isRootView = true; self._viewModel = StateObject(wrappedValue: FilesViewModel()) }
    init(directoryURL: URL) { self.directoryURL = directoryURL; self.isRootView = false; self._viewModel = StateObject(wrappedValue: FilesViewModel(directory: directoryURL)) }
    
    private var filteredFiles: [FileItem] {
        searchText.isEmpty ? viewModel.files : viewModel.files.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        Group {
            if isRootView { NavigationStack { filesBrowserContent }.accentColor(.accentColor) } else { filesBrowserContent }
        }
        .onAppear { viewModel.loadFiles() }
        // استقبال الإشارة لفتح التوقيع
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ksign.openSigningView"))) { notification in
            if let file = notification.object as? FileItem { _appToSign = file }
        }
        .fullScreenCover(item: $_appToSign) { file in SigningView(app: AnyApp(base: file), signAndInstall: true) }
        .onDisappear { if !isRootView { NotificationCenter.default.removeObserver(self) } }
    }
    
    private var filesBrowserContent: some View {
        ZStack {
            List {
                ForEach(filteredFiles) { file in
                    FileRow(
                        file: file, isSelected: viewModel.selectedItems.contains(file), viewModel: viewModel,
                        plistFileURL: $plistFileURL, hexEditorFileURL: $hexEditorFileURL, textEditorFileURL: $textEditorFileURL,
                        quickLookFileURL: $quickLookFileURL, shareItems: $shareItems, moveFileItem: $moveSingleFile,
                        onExtractArchive: extractArchive, onPackageApp: packageAppAsIPA, onImportIpa: importIpaToLibrary, onNavigateToDirectory: navigateToDirectory
                    )
                    .swipeActions(edge: .trailing) { FileUIHelpers.swipeActions(for: file, viewModel: viewModel) }
                }
            }
            .listStyle(.plain)
            .navigationTitle(directoryURL?.lastPathComponent ?? viewModel.currentDirectory.lastPathComponent)
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) { addButton; editButton }
            }
            .fullScreenCover(item: $plistFileURL) { fileURL in PlistEditorView(fileURL: fileURL) }
            .fullScreenCover(item: $hexEditorFileURL) { fileURL in HexEditorView(fileURL: fileURL) }
            .fullScreenCover(item: $textEditorFileURL) { fileURL in TextEditorView(fileURL: fileURL) }
            .fullScreenCover(item: $quickLookFileURL) { fileURL in QuickLookPreview(fileURL: fileURL) }
        }
    }

    private var addButton: some View {
        Menu {
            Button { viewModel.showingImporter = true } label: { Label("Import", systemImage: "doc.badge.plus") }
            Button { viewModel.createNewFolder(name: "New Folder") } label: { Label("Folder", systemImage: "folder.badge.plus") }
        } label: { Image(systemName: "plus") }
    }
    
    private var editButton: some View {
        Button { withAnimation { viewModel.isEditMode = viewModel.isEditMode == .active ? .inactive : .active } } label: { Text(viewModel.isEditMode == .active ? "Done" : "Edit") }
    }
    
    private func navigateToDirectory(_ url: URL) { navigateToDirectoryURL = url }
    private func extractArchive(_ file: FileItem) { ExtractionService.extractArchive(file, to: viewModel.currentDirectory) { _ in viewModel.loadFiles() } }
    private func packageAppAsIPA(_ file: FileItem) { ExtractionService.packageAppAsIPA(file, to: viewModel.currentDirectory) { _ in viewModel.loadFiles() } }
    private func importIpaToLibrary(_ file: FileItem) { /* نفس كودك الأصلي */ }
}
