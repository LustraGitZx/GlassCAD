//
//  ContentView.swift
//  LibreCAD_MacOS
//
//  Главный экран приложения с современным интерфейсом macOS
//

import SwiftUI
import AppKit

struct ContentView: View {
    @StateObject private var document = CADDrawingDocument()
    @StateObject private var toolManager = CADToolManager()
    @StateObject private var fileIO = CADFileIOWrapper()
    
    @State private var showingNewDocument = false
    @State private var showingOpenPanel = false
    @State private var showingSavePanel = false
    @State private var showingExportPanel = false
    @State private var showingAbout = false
    @State private var exportFormat: CADFileIO.FileFormat = .json
    
    @Environment(\.undoManager) var undoManager
    
    var body: some View {
        GeometryReader { geometry in
            HSplitView {
                // Левая панель инструментов
                ToolboxPanel(toolManager: toolManager, document: document)
                    .frame(width: 80)
                
                // Центральная область
                VStack(spacing: 0) {
                    // Холст для черчения
                    CADCanvasView(document: document, toolManager: toolManager)
                        .background(Color(NSColor.textBackgroundColor))
                    
                    // Нижняя панель слоев
                    LayerPanel(document: document)
                        .frame(height: 150)
                }
                
                // Правая панель свойств
                PropertyPanel(document: document, toolManager: toolManager)
                    .frame(width: 250)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showingNewDocument = true }) {
                    Image(systemName: "doc.badge.plus")
                }
                .help("Новый документ")
                
                Button(action: { showingOpenPanel = true }) {
                    Image(systemName: "folder.open")
                }
                .help("Открыть")
                
                Button(action: { showingSavePanel = true }) {
                    Image(systemName: "square.and.arrow.down")
                }
                .help("Сохранить")
                
                Divider()
                
                Button(action: { document.undo() }) {
                    Image(systemName: "arrow.uturn.backward")
                }
                .disabled(!document.canUndo)
                .help("Отменить (⌘Z)")
                
                Button(action: { document.redo() }) {
                    Image(systemName: "arrow.uturn.forward")
                }
                .disabled(!document.canRedo)
                .help("Повторить (⇧⌘Z)")
                
                Divider()
                
                Button(action: { document.zoomIn() }) {
                    Image(systemName: "plus.magnifyingglass")
                }
                .help("Увеличить")
                
                Button(action: { document.zoomOut() }) {
                    Image(systemName: "minus.magnifyingglass")
                }
                .help("Уменьшить")
                
                Button(action: { document.zoomToFit() }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                }
                .help("Показать все")
                
                Divider()
                
                Menu {
                    ForEach(CADFileIO.FileFormat.allCases, id: \.self) { format in
                        Button(format.rawValue) {
                            exportFormat = format
                            showingExportPanel = true
                        }
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .help("Экспорт")
                
                Button(action: { showingAbout = true }) {
                    Image(systemName: "info.circle")
                }
                .help("О программе")
            }
        }
        .fileDialogImportAction(importFiles)
        .fileDialogExportAction(exportFiles)
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
        .alert("Новый документ", isPresented: $showingNewDocument) {
            Button("Создать", role: .destructive) {
                document.clearAll()
                document.fileName = "Без названия"
            }
            Button("Отмена", role: .cancel) {}
        } message: {
            Text("Все несохраненные изменения будут потеряны.")
        }
    }
    
    private func importFiles() {
        if let url = fileIO.showOpenPanel() {
            do {
                let newDoc = try fileIO.importFile(from: url)
                document.entities = newDoc.entities
                document.layers = newDoc.layers
                document.fileName = url.deletingPathExtension().lastPathComponent
                document.filePath = url
            } catch {
                showError("Ошибка импорта: \(error.localizedDescription)")
            }
        }
    }
    
    private func exportFiles() {
        if let url = fileIO.showSavePanel(suggestedName: document.fileName, format: exportFormat) {
            do {
                try fileIO.export(document: document, to: url, format: exportFormat)
            } catch {
                showError("Ошибка экспорта: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveFile() {
        if let url = fileIO.showSavePanel(suggestedName: document.fileName, format: .json) {
            do {
                try fileIO.export(document: document, to: url, format: .json)
                document.filePath = url
                document.fileName = url.deletingPathExtension().lastPathComponent
                document.isModified = false
            } catch {
                showError("Ошибка сохранения: \(error.localizedDescription)")
            }
        }
    }
    
    private func showError(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Ошибка"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.runModal()
    }
}

// MARK: - Wrapper для FileIO

class CADFileIOWrapper: ObservableObject {
    private let fileIO = CADFileIO()
    
    func export(document: CADDrawingDocument, to url: URL, format: CADFileIO.FileFormat) throws {
        try fileIO.export(document: document, to: url, format: format)
    }
    
    func importFile(from url: URL) throws -> CADDrawingDocument {
        return try fileIO.importFile(from: url)
    }
    
    func showOpenPanel() -> URL? {
        return fileIO.showOpenPanel()
    }
    
    func showSavePanel(suggestedName: String, format: CADFileIO.FileFormat) -> URL? {
        return fileIO.showSavePanel(suggestedName: suggestedName, format: format)
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "pencil.and.ruler")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("LibreCAD macOS")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Версия 1.0")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Современное CAD приложение\nдля macOS с интерфейсом в стиле Liquid Glass")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("© 2024 LibreCAD Project")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(40)
        .frame(width: 400)
    }
}

#Preview {
    ContentView()
}
