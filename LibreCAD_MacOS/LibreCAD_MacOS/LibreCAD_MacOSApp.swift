//
//  LibreCAD_MacOSApp.swift
//  LibreCAD_MacOS
//
//  Точка входа приложения
//

import SwiftUI

@main
struct LibreCAD_MacOSApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 600)
        }
        .windowStyle(.automatic)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Новый") {
                    NotificationCenter.default.post(name: .newDocument, object: nil)
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Открыть...") {
                    NotificationCenter.default.post(name: .openDocument, object: nil)
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Divider()
                
                Button("Сохранить") {
                    NotificationCenter.default.post(name: .saveDocument, object: nil)
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Сохранить как...") {
                    NotificationCenter.default.post(name: .saveDocumentAs, object: nil)
                }
                .keyboardShortcut("s", modifiers: [.command, .shift])
            }
            
            CommandGroup(after: .undoRedo) {
                Divider()
                
                Button("Вырезать") {
                    // Вырезать выделенное
                }
                .keyboardShortcut("x", modifiers: .command)
                
                Button("Копировать") {
                    // Копировать выделенное
                }
                .keyboardShortcut("c", modifiers: .command)
                
                Button("Вставить") {
                    // Вставить из буфера
                }
                .keyboardShortcut("v", modifiers: .command)
            }
            
            CommandMenu("Инструменты") {
                Button("Линия") {
                    NotificationCenter.default.post(name: .selectTool, object: CADToolType.line)
                }
                .keyboardShortcut("l", modifiers: .command)
                
                Button("Круг") {
                    NotificationCenter.default.post(name: .selectTool, object: CADToolType.circle)
                }
                .keyboardShortcut("i", modifiers: .command)
                
                Button("Прямоугольник") {
                    NotificationCenter.default.post(name: .selectTool, object: CADToolType.rectangle)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Выделение") {
                    NotificationCenter.default.post(name: .selectTool, object: CADToolType.select)
                }
                .keyboardShortcut("v", modifiers: [.command, .shift])
                
                Button("Панорамирование") {
                    NotificationCenter.default.post(name: .selectTool, object: CADToolType.pan)
                }
                .keyboardShortcut("h", modifiers: .command)
            }
            
            CommandMenu("Вид") {
                Button("Показать все") {
                    NotificationCenter.default.post(name: .zoomToFit, object: nil)
                }
                .keyboardShortcut("0", modifiers: .command)
                
                Button("Увеличить") {
                    NotificationCenter.default.post(name: .zoomIn, object: nil)
                }
                .keyboardShortcut("+", modifiers: .command)
                
                Button("Уменьшить") {
                    NotificationCenter.default.post(name: .zoomOut, object: nil)
                }
                .keyboardShortcut("-", modifiers: .command)
                
                Divider()
                
                Button("Сетка") {
                    NotificationCenter.default.post(name: .toggleGrid, object: nil)
                }
                .keyboardShortcut("g", modifiers: .command)
            }
            
            CommandGroup(replacing: .help) {
                Button("О программе LibreCAD") {
                    NSApplication.shared.orderFrontStandardAboutPanel(nil)
                }
            }
        }
        
        Settings {
            SettingsView()
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let newDocument = Notification.Name("newDocument")
    static let openDocument = Notification.Name("openDocument")
    static let saveDocument = Notification.Name("saveDocument")
    static let saveDocumentAs = Notification.Name("saveDocumentAs")
    static let selectTool = Notification.Name("selectTool")
    static let zoomToFit = Notification.Name("zoomToFit")
    static let zoomIn = Notification.Name("zoomIn")
    static let zoomOut = Notification.Name("zoomOut")
    static let toggleGrid = Notification.Name("toggleGrid")
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Настройка приложения после запуска
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        // Сохранение настроек перед закрытием
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @AppStorage("gridSpacing") private var gridSpacing: Double = 10.0
    @AppStorage("snapEnabled") private var snapEnabled: Bool = true
    @AppStorage("antiAliasing") private var antiAliasing: Bool = true
    
    var body: some View {
        TabView {
            Form {
                Section("Сетка") {
                    TextField("Шаг сетки:", value: $gridSpacing, format: .number)
                    Toggle("Привязка к сетке", isOn: .constant(true))
                }
                
                Section("Отображение") {
                    Toggle("Сглаживание", isOn: $antiAliasing)
                    Toggle("Показывать координаты", isOn: .constant(true))
                }
            }
            .padding(20)
            .tabItem {
                Label("Основные", systemImage: "gear")
            }
            
            Form {
                Section("Горячие клавиши") {
                    LabeledContent("Новый документ") { Text("⌘N") }
                    LabeledContent("Открыть") { Text("⌘O") }
                    LabeledContent("Сохранить") { Text("⌘S") }
                    LabeledContent("Отменить") { Text("⌘Z") }
                    LabeledContent("Повторить") { Text("⇧⌘Z") }
                }
            }
            .padding(20)
            .tabItem {
                Label("Клавиши", systemImage: "keyboard")
            }
        }
        .frame(width: 450, height: 300)
    }
}
