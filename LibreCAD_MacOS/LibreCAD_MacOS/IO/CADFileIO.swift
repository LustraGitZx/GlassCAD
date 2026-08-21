//
//  CADFileIO.swift
//  LibreCAD_MacOS
//
//  Импорт и экспорт файлов в различных форматах
//

import Foundation
import AppKit
import UniformTypeIdentifiers

/// Менеджер импорта/экспорта файлов
class CADFileIO {
    
    // MARK: - Поддерживаемые форматы
    
    enum FileFormat: String, CaseIterable {
        case dxf = "DXF"
        case dwg = "DWG"
        case svg = "SVG"
        case pdf = "PDF"
        case png = "PNG"
        case json = "JSON (Native)"
        
        var extensions: [String] {
            switch self {
            case .dxf: return ["dxf", "DXF"]
            case .dwg: return ["dwg", "DWG"]
            case .svg: return ["svg", "SVG"]
            case .pdf: return ["pdf", "PDF"]
            case .png: return ["png", "PNG"]
            case .json: return ["json", "JSON", "cad"]
            }
        }
        
        var mimeType: String {
            switch self {
            case .dxf: return "application/dxf"
            case .dwg: return "application/dwg"
            case .svg: return "image/svg+xml"
            case .pdf: return "application/pdf"
            case .png: return "image/png"
            case .json: return "application/json"
            }
        }
    }
    
    // MARK: - Экспорт
    
    /// Экспорт документа в файл
    func export(document: CADDrawingDocument, to url: URL, format: FileFormat) throws {
        switch format {
        case .json:
            try exportToJSON(document: document, to: url)
        case .dxf:
            try exportToDXF(document: document, to: url)
        case .svg:
            try exportToSVG(document: document, to: url)
        case .pdf:
            try exportToPDF(document: document, to: url)
        case .png:
            try exportToPNG(document: document, to: url)
        case .dwg:
            throw CADError.unsupportedFormat("DWG export is not supported in this version")
        }
    }
    
    /// Экспорт в JSON (нативный формат)
    private func exportToJSON(document: CADDrawingDocument, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        // Создаем структуру для сохранения
        let fileData = CADFileData(
            fileName: document.fileName,
            entities: document.entities,
            layers: document.layers,
            gridSettings: document.gridSettings,
            snapSettings: document.snapSettings,
            displaySettings: document.displaySettings,
            version: "1.0"
        )
        
        let data = try encoder.encode(fileData)
        try data.write(to: url)
    }
    
    /// Экспорт в DXF
    private func exportToDXF(document: CADDrawingDocument, to url: URL) throws {
        var dxfContent = "0\nSECTION\n2\nHEADER\n9\n$ACADVER\n1\nAC1015\n0\nENDSEC\n"
        
        // Таблица слоев
        dxfContent += "0\nSECTION\n2\nTABLES\n0\nTABLE\n2\nLAYER\n"
        
        for layer in document.layers {
            dxfContent += "0\nLAYER\n2\n\(layer.name)\n70\n0\n62\n\(layer.color.toDXFColorCode())\n6\nCONTINUOUS\n"
        }
        
        dxfContent += "0\nENDTAB\n0\nENDSEC\n"
        
        // Сущности
        dxfContent += "0\nSECTION\n2\nENTITIES\n"
        
        for entity in document.entities {
            dxfContent += entity.toDXF()
        }
        
        dxfContent += "0\nENDSEC\n0\nEOF\n"
        
        try dxfContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Экспорт в SVG
    private func exportToSVG(document: CADDrawingDocument, to url: URL) throws {
        let bounds = document.bounds
        let width = bounds.maxX - bounds.minX
        let height = bounds.maxY - bounds.minY
        
        var svgContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg" 
             width="\(Int(width))" height="\(Int(height))" 
             viewBox="\(bounds.minX) \(bounds.minY) \(width) \(height)">
        
        """
        
        for entity in document.entities {
            svgContent += entity.toSVG(offset: CADPoint(x: -bounds.minX, y: -bounds.minY))
        }
        
        svgContent += "</svg>"
        
        try svgContent.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Экспорт в PDF
    private func exportToPDF(document: CADDrawingDocument, to url: URL) throws {
        let bounds = document.bounds
        let width = bounds.maxX - bounds.minX
        let height = bounds.maxY - bounds.minY
        
        let pageSize = NSSize(width: width + 100, height: height + 100)
        let pdfInfo: [String: Any] = [
            kCGPDFContextCreator as String: "LibreCAD macOS",
            kCGPDFContextTitle as String: document.fileName
        ]
        
        let pdfData = NSMutableData()
        
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData) else {
            throw CADError.exportFailed("Failed to create PDF consumer")
        }
        
        guard let context = CGContext(consumer: consumer, mediaBox: &CGRect(origin: .zero, size: pageSize), pdfInfo as CFDictionary) else {
            throw CADError.exportFailed("Failed to create PDF context")
        }
        
        context.beginPDFPage(nil)
        
        // Рисуем сущности
        let transform = CGAffineTransform(translationX: 50, y: 50)
        
        for entity in document.entities {
            entity.draw(in: context, transform: transform, displaySettings: document.displaySettings)
        }
        
        context.endPDFPage()
        context.closePDF()
        
        try pdfData.write(to: url)
    }
    
    /// Экспорт в PNG
    private func exportToPNG(document: CADDrawingDocument, to url: URL) throws {
        let bounds = document.bounds
        let width = Int(bounds.maxX - bounds.minX) + 200
        let height = Int(bounds.maxY - bounds.minY) + 200
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: nil,
                                     width: width,
                                     height: height,
                                     bitsPerComponent: 8,
                                     bytesPerRow: 0,
                                     space: colorSpace,
                                     bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw CADError.exportFailed("Failed to create image context")
        }
        
        // Белый фон
        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Рисуем сущности
        var transform = CGAffineTransform(translationX: 100 - bounds.minX, y: 100 + bounds.maxY)
        transform = transform.scaledBy(x: 1, y: -1)
        
        for entity in document.entities {
            entity.draw(in: context, transform: transform, displaySettings: document.displaySettings)
        }
        
        guard let cgImage = context.makeImage() else {
            throw CADError.exportFailed("Failed to create image")
        }
        
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw CADError.exportFailed("Failed to create PNG data")
        }
        
        try pngData.write(to: url)
    }
    
    // MARK: - Импорт
    
    /// Импорт документа из файла
    func importFile(from url: URL) throws -> CADDrawingDocument {
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "json", "cad":
            return try importFromJSON(from: url)
        case "dxf":
            return try importFromDXF(from: url)
        case "svg":
            return try importFromSVG(from: url)
        default:
            throw CADError.unsupportedFormat("Unsupported file format: \(ext)")
        }
    }
    
    /// Импорт из JSON
    private func importFromJSON(from url: URL) throws -> CADDrawingDocument {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        let fileData = try decoder.decode(CADFileData.self, from: data)
        
        let document = CADDrawingDocument()
        document.fileName = fileData.fileName
        document.entities = fileData.entities
        document.layers = fileData.layers
        document.gridSettings = fileData.gridSettings
        document.snapSettings = fileData.snapSettings
        document.displaySettings = fileData.displaySettings
        
        if let firstLayer = document.layers.first {
            document.currentLayerID = firstLayer.id
        }
        
        return document
    }
    
    /// Импорт из DXF (базовая поддержка)
    private func importFromDXF(from url: URL) throws -> CADDrawingDocument {
        let content = try String(contentsOf: url, encoding: .utf8)
        let document = CADDrawingDocument()
        
        // Парсинг DXF (упрощенная версия)
        let lines = content.components(separatedBy: "\n")
        var i = 0
        
        while i < lines.count {
            let code = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if code == "0" && i + 1 < lines.count {
                let entityType = lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines)
                
                switch entityType {
                case "LINE":
                    if let line = parseDXFLine(from: lines, startingAt: i) {
                        document.entities.append(line)
                    }
                case "CIRCLE":
                    if let circle = parseDXFCircle(from: lines, startingAt: i) {
                        document.entities.append(circle)
                    }
                case "ARC":
                    if let arc = parseDXFArc(from: lines, startingAt: i) {
                        document.entities.append(arc)
                    }
                default:
                    break
                }
            }
            
            i += 1
        }
        
        return document
    }
    
    /// Импорт из SVG (базовая поддержка)
    private func importFromSVG(from url: URL) throws -> CADDrawingDocument {
        // Базовая реализация импорта SVG
        return CADDrawingDocument()
    }
    
    // MARK: - Парсинг DXF
    
    private func parseDXFLine(from lines: [String], startingAt start: Int) -> CADLine? {
        // Упрощенный парсер линий DXF
        var startPoint = CADPoint.zero
        var endPoint = CADPoint.zero
        let layerID = UUID()
        
        var i = start
        while i < lines.count - 1 {
            let code = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if code == "0" && lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines) != "LINE" {
                break
            }
            
            if code == "10" && i + 2 < lines.count {
                startPoint.x = Double(lines[i + 2]) ?? 0
            } else if code == "20" && i + 2 < lines.count {
                startPoint.y = Double(lines[i + 2]) ?? 0
            } else if code == "11" && i + 2 < lines.count {
                endPoint.x = Double(lines[i + 2]) ?? 0
            } else if code == "21" && i + 2 < lines.count {
                endPoint.y = Double(lines[i + 2]) ?? 0
            } else if code == "8" && i + 2 < lines.count {
                // Имя слоя
            }
            
            i += 2
        }
        
        return CADLine(layerID: layerID, startPoint: startPoint, endPoint: endPoint)
    }
    
    private func parseDXFCircle(from lines: [String], startingAt start: Int) -> CADCircle? {
        var center = CADPoint.zero
        var radius: Double = 1.0
        let layerID = UUID()
        
        var i = start
        while i < lines.count - 1 {
            let code = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if code == "0" && lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines) != "CIRCLE" {
                break
            }
            
            if code == "10" && i + 2 < lines.count {
                center.x = Double(lines[i + 2]) ?? 0
            } else if code == "20" && i + 2 < lines.count {
                center.y = Double(lines[i + 2]) ?? 0
            } else if code == "40" && i + 2 < lines.count {
                radius = Double(lines[i + 2]) ?? 1.0
            }
            
            i += 2
        }
        
        return CADCircle(layerID: layerID, center: center, radius: radius)
    }
    
    private func parseDXFArc(from lines: [String], startingAt start: Int) -> CADArc? {
        var center = CADPoint.zero
        var radius: Double = 1.0
        var startAngle: Double = 0
        var endAngle: Double = 360
        let layerID = UUID()
        
        var i = start
        while i < lines.count - 1 {
            let code = lines[i].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if code == "0" && lines[i + 1].trimmingCharacters(in: .whitespacesAndNewlines) != "ARC" {
                break
            }
            
            if code == "10" && i + 2 < lines.count {
                center.x = Double(lines[i + 2]) ?? 0
            } else if code == "20" && i + 2 < lines.count {
                center.y = Double(lines[i + 2]) ?? 0
            } else if code == "40" && i + 2 < lines.count {
                radius = Double(lines[i + 2]) ?? 1.0
            } else if code == "50" && i + 2 < lines.count {
                startAngle = Double(lines[i + 2]) ?? 0
            } else if code == "51" && i + 2 < lines.count {
                endAngle = Double(lines[i + 2]) ?? 360
            }
            
            i += 2
        }
        
        return CADArc(layerID: layerID, center: center, radius: radius,
                     startAngle: startAngle, endAngle: endAngle)
    }
    
    // MARK: - Диалоги файлов
    
    func showOpenPanel() -> URL? {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        var fileTypes: [String] = []
        for format in FileFormat.allCases {
            fileTypes.append(contentsOf: format.extensions)
        }
        
        panel.allowedContentTypes = fileTypes.map { UTType(filenameExtension: $0) ?? .plainText }.compactMap { $0 }
        
        if panel.runModal() == .OK {
            return panel.url
        }
        
        return nil
    }
    
    func showSavePanel(suggestedName: String, format: FileFormat) -> URL? {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = suggestedName
        panel.allowedContentTypes = format.extensions.map { UTType(filenameExtension: $0) ?? .plainText }.compactMap { $0 }
        
        if panel.runModal() == .OK {
            return panel.url
        }
        
        return nil
    }
}

// MARK: - Структура файла

struct CADFileData: Codable {
    var fileName: String
    var entities: [CADEntityBase]
    var layers: [CADLayer]
    var gridSettings: GridSettings
    var snapSettings: SnapSettings
    var displaySettings: DisplaySettings
    var version: String
}

// MARK: - Расширения для экспорта

extension CADEntityBase {
    func toDXF() -> String {
        // Базовая реализация экспорта в DXF
        return ""
    }
    
    func toSVG(offset: CADPoint) -> String {
        // Базовая реализация экспорта в SVG
        return ""
    }
}

extension CADColor {
    func toDXFColorCode() -> Int {
        // Преобразование цвета в код цвета DXF (1-255)
        // Упрощенная реализация
        if self == .red { return 1 }
        if self == .yellow { return 2 }
        if self == .green { return 3 }
        if self == .cyan { return 4 }
        if self == .blue { return 5 }
        if self == .magenta { return 6 }
        if self == .black { return 7 }
        if self == .white { return 7 }
        return 7
    }
}

// MARK: - Ошибки

enum CADError: LocalizedError {
    case unsupportedFormat(String)
    case exportFailed(String)
    case importFailed(String)
    case fileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .unsupportedFormat(let msg):
            return "Неподдерживаемый формат: \(msg)"
        case .exportFailed(let msg):
            return "Ошибка экспорта: \(msg)"
        case .importFailed(let msg):
            return "Ошибка импорта: \(msg)"
        case .fileNotFound(let msg):
            return "Файл не найден: \(msg)"
        }
    }
}
