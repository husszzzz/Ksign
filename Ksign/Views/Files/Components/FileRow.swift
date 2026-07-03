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
            // ... (نفس تصميمك الأصلي للـ HStack)
            Text(file.name).font(.body)
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { showingConfirmationDialog = true }
        .confirmationDialog(file.name, isPresented: $showingConfirmationDialog, titleVisibility: .visible) {
            fileConfirmationDialogButtons()
        }
    }
    
    @ViewBuilder
    private func fileConfirmationDialogButtons() -> some View {
        // 🟢 الزر الأخضر
        if let ext = file.fileExtension?.lowercased(), ext == "ipa" {
            Button {
                NotificationCenter.default.post(name: NSNotification.Name("ksign.openSigningView"), object: file)
            } label: {
                HStack { Text("توقيع وتثبيت"); Image(systemName: "signature") }
            }
            .tint(.green)
        }
        
        // باقي الأزرار الأصلية
        if !file.isDirectory {
             Button { quickLookFileURL = file.url } label: { Label("Preview", systemImage: "eye") }
        }
        // ... (أضف باقي الأزرار الخاصة بك هنا)
    }
}
