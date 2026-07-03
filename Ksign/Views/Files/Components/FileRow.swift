import SwiftUI

struct FileRow: View {
    let file: FileItem
    let isSelected: Bool
    @ObservedObject var viewModel: FilesViewModel
    @Binding var plistFileURL: URL?
    @Binding var hexEditorFileURL: URL?
    @Binding var quickLookFileURL: URL?
    @Binding var textEditorFileURL: URL?
    @Binding var shareItems: [Any]
    @Binding var moveFileItem: FileItem?
    
    let onExtractArchive: (FileItem) -> Void
    let onPackageApp: (FileItem) -> Void
    let onImportIpa: (FileItem) -> Void
    let onNavigateToDirectory: ((URL) -> Void)?
    
    @State private var showingConfirmationDialog = false
    
    var body: some View {
        HStack(spacing: 12) {
            Group {
                if file.isDirectory {
                    if file.isAppDirectory { Image(systemName: "app.badge").foregroundColor(.accentColor) } else { Image(systemName: "folder").foregroundColor(.accentColor) }
                } else if file.isImageFile { ImageRow(file: file) } else if file.isArchive { Image(systemName: "doc.zipper").foregroundColor(.accentColor) }
                else if file.isPlistFile { Image(systemName: "list.bullet").foregroundColor(.accentColor) }
                else if file.isP12Certificate { Image(systemName: "key").foregroundColor(.accentColor) }
                else if file.isKsignFile { Image(systemName: "questionmark").foregroundColor(.accentColor) }
                else { Image(systemName: "doc").foregroundColor(.accentColor) }
            }
            .font(.title2).frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(file.name).font(.body).lineLimit(1)
                HStack(spacing: 4) {
                    if !file.isDirectory { Text(file.formattedSize).font(.caption).foregroundColor(.secondary) }
                    if let date = file.creationDate {
                        if !file.isDirectory { Text("•").font(.caption).foregroundColor(.secondary) }
                        Text(date, style: .date).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            Spacer()
            if viewModel.isEditMode == .inactive {
                if file.isDirectory { Image(systemName: "chevron.right").foregroundColor(.secondary).font(.system(size: 12)) }
            } else {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle").foregroundColor(isSelected ? .accentColor : .secondary).font(.system(size: 22))
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .onTapGesture {
            if viewModel.isEditMode == .active {
                if viewModel.selectedItems.contains(file) { viewModel.selectedItems.remove(file) } else { viewModel.selectedItems.insert(file) }
            } else if file.isDirectory { onNavigateToDirectory?(file.url) } else { showingConfirmationDialog = true }
        }
        .confirmationDialog(file.name, isPresented: $showingConfirmationDialog, titleVisibility: .visible) {
            fileConfirmationDialogButtons()
        }
        .contextMenu { fileConfirmationDialogButtons() }
    }
    
    @ViewBuilder
    private func fileConfirmationDialogButtons() -> some View {
        // 🟢 الزر الأخضر الجديد
        if let ext = file.fileExtension?.lowercased(), ext == "ipa" {
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("ksign.openSigningView"), object: file)
            } label: {
                HStack { Text("توقيع وتثبيت"); Image(systemName: "signature") }
            }
            .tint(.green)
        }
        
        if !file.isDirectory { Button { quickLookFileURL = file.url } label: { Label("Preview", systemImage: "eye") } }
        if file.isTextFile { Button { textEditorFileURL = file.url } label: { Label("Text Editor", systemImage: "doc.plaintext") } }
        if file.isPlistFile { Button { plistFileURL = file.url } label: { Label("Plist Editor", systemImage: "list.bullet") } }
        if !file.isDirectory { Button { hexEditorFileURL = file.url } label: { Label("Hex Editor", systemImage: "doc.text") } }
        if file.isP12Certificate { Button { viewModel.importCertificate(file) } label: { Label("Import Certificate", systemImage: "key") } }
        if file.isKsignFile { Button { UIAlertController.showAlertWithOk(title: "?", message: "Ksign certificate file (.ksign) is now unsupported.") } label: { Label("Import Certificate", systemImage: "questionmark") } }
        if let ext = file.fileExtension?.lowercased(), ext == "app" { Button { onPackageApp(file) } label: { Label("Package as IPA", systemImage: "doc.zipper") } }
        if file.isArchive { Button { onExtractArchive(file) } label: { Label("Extract", systemImage: "doc.zipper") } }
        Button { moveFileItem = file } label: { Label("Move", systemImage: "folder") }
        Button {
            UIAlertController.showAlertWithTextBox(title: "Rename", message: "Enter new name", textFieldPlaceholder: "File name", textFieldText: file.name, submit: "Rename", cancel: "Cancel") { name in viewModel.renameFile(newName: name, item: file) }
        } label: { Label("Rename", systemImage: "pencil") }
        Button { shareItems = [file.url]; UIActivityViewController.show(activityItems: shareItems) } label: { Label("Share", systemImage: "square.and.arrow.up") }
        Button(role: .destructive) { viewModel.deleteFile(file) } label: { Label("Delete", systemImage: "trash") }
    }
}
