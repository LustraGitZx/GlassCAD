//
//  CADTypes.swift
//  LibreCAD_MacOS
//
//  Основные типы и структуры данных для CAD системы
//

import Foundation
import CoreGraphics
import AppKit

// MARK: - Базовые типы

/// Точка в 2D пространстве
struct CADPoint: Codable, Equatable, Hashable {
    var x: Double
    var y: Double
    
    static let zero = CADPoint(x: 0, y: 0)
    
    init(x: Double = 0, y: Double = 0) {
        self.x = x
        self.y = y
    }
    
    init(CGPoint: CGPoint) {
        self.x = CGPoint.x
        self.y = CGPoint.y
    }
    
    var cgPoint: CGPoint {
        return CGPoint(x: x, y: y)
    }
    
    // Векторные операции
    static func + (lhs: CADPoint, rhs: CADPoint) -> CADPoint {
        return CADPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func - (lhs: CADPoint, rhs: CADPoint) -> CADPoint {
        return CADPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    
    static func * (lhs: CADPoint, scalar: Double) -> CADPoint {
        return CADPoint(x: lhs.x * scalar, y: lhs.y * scalar)
    }
    
    func distance(to point: CADPoint) -> Double {
        let dx = x - point.x
        let dy = y - point.y
        return sqrt(dx * dx + dy * dy)
    }
    
    func rotated(around center: CADPoint, by angle: Double) -> CADPoint {
        let rad = angle * .pi / 180.0
        let cosA = cos(rad)
        let sinA = sin(rad)
        
        let translatedX = x - center.x
        let translatedY = y - center.y
        
        let rotatedX = translatedX * cosA - translatedY * sinA
        let rotatedY = translatedX * sinA + translatedY * cosA
        
        return CADPoint(x: rotatedX + center.x, y: rotatedY + center.y)
    }
    
    func scaled(around center: CADPoint, by factor: Double) -> CADPoint {
        let dx = x - center.x
        let dy = y - center.y
        return CADPoint(x: center.x + dx * factor, y: center.y + dy * factor)
    }
}

/// Угол в градусах
struct CADAngle: Codable, Equatable {
    var degrees: Double
    
    var radians: Double {
        get { degrees * .pi / 180.0 }
        set { degrees = newValue * 180.0 / .pi }
    }
    
    init(degrees: Double = 0) {
        self.degrees = degrees.truncatingRemainder(dividingBy: 360)
    }
    
    init(radians: Double) {
        self.degrees = radians * 180.0 / .pi
    }
}

/// Цвет в формате RGBA
struct CADColor: Codable, Equatable, Hashable {
    var red: Double
    var green: Double
    var blue: Double
    var alpha: Double
    
    static let black = CADColor(red: 0, green: 0, blue: 0, alpha: 1)
    static let white = CADColor(red: 1, green: 1, blue: 1, alpha: 1)
    static let red = CADColor(red: 1, green: 0, blue: 0, alpha: 1)
    static let green = CADColor(red: 0, green: 1, blue: 0, alpha: 1)
    static let blue = CADColor(red: 0, green: 0, blue: 1, alpha: 1)
    static let yellow = CADColor(red: 1, green: 1, blue: 0, alpha: 1)
    static let cyan = CADColor(red: 0, green: 1, blue: 1, alpha: 1)
    static let magenta = CADColor(red: 1, green: 0, blue: 1, alpha: 1)
    static let gray = CADColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
    static let clear = CADColor(red: 0, green: 0, blue: 0, alpha: 0)
    
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
        self.alpha = min(max(alpha, 0), 1)
    }
    
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        self.red = Double((rgb & 0xFF0000) >> 16) / 255.0
        self.green = Double((rgb & 0x00FF00) >> 8) / 255.0
        self.blue = Double(rgb & 0x0000FF) / 255.0
        self.alpha = 1.0
    }
    
    var nsColor: NSColor {
        return NSColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    
    #if canImport(UIKit)
    var uiColor: UIColor {
        return UIColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(alpha))
    }
    #endif
}

/// Типы линий
enum CADLineType: String, Codable, CaseIterable {
    case continuous = "Continuous"
    case dashed = "Dashed"
    case dotted = "Dotted"
    case dashDot = "DashDot"
    case dashDotDot = "DashDotDot"
    case center = "Center"
    case hidden = "Hidden"
    
    var pattern: [Double] {
        switch self {
        case .continuous: return []
        case .dashed: return [5.0, 3.0]
        case .dotted: return [1.0, 3.0]
        case .dashDot: return [5.0, 3.0, 1.0, 3.0]
        case .dashDotDot: return [5.0, 3.0, 1.0, 3.0, 1.0, 3.0]
        case .center: return [10.0, 3.0, 2.0, 3.0]
        case .hidden: return [5.0, 2.0]
        }
    }
}

/// Типы шрифтов
struct CADFont: Codable, Equatable {
    var name: String
    var size: Double
    var bold: Bool
    var italic: Bool
    
    static let `default` = CADFont(name: "SF Pro Text", size: 12, bold: false, italic: false)
    
    init(name: String = "SF Pro Text", size: Double = 12, bold: Bool = false, italic: Bool = false) {
        self.name = name
        self.size = size
        self.bold = bold
        self.italic = italic
    }
}

// MARK: - Перечисления

/// Типы сущностей
enum EntityType: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case line = "Line"
    case circle = "Circle"
    case arc = "Arc"
    case ellipse = "Ellipse"
    case polyline = "Polyline"
    case spline = "Spline"
    case text = "Text"
    case dimension = "Dimension"
    case hatch = "Hatch"
    case point = "Point"
    case rectangle = "Rectangle"
    case polygon = "Polygon"
    case image = "Image"
}

/// Режимы привязки
enum SnapMode: String, Codable, CaseIterable {
    case none = "None"
    case endpoint = "Endpoint"
    case midpoint = "Midpoint"
    case center = "Center"
    case intersection = "Intersection"
    case perpendicular = "Perpendicular"
    case tangent = "Tangent"
    case quadrant = "Quadrant"
    case nearest = "Nearest"
    case grid = "Grid"
    
    var icon: String {
        switch self {
        case .none: return "slash.circle"
        case .endpoint: return "circle.fill"
        case .midpoint: return "square.fill"
        case .center: return "target"
        case .intersection: return "xmark.circle.fill"
        case .perpendicular: return "angle"
        case .tangent: return "circle.dashed"
        case .quadrant: return "circle.grid.cross"
        case .nearest: return "dot.radiowaves.left.and.right"
        case .grid: return "grid"
        }
    }
}

/// Режимы ортогональности
enum OrthoMode: String, Codable, CaseIterable {
    case off = "Off"
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case both = "Both"
}

/// Типы размерных линий
enum DimensionType: String, Codable, CaseIterable {
    case linear = "Linear"
    case aligned = "Aligned"
    case angular = "Angular"
    case radial = "Radial"
    case diameter = "Diameter"
    case arcLength = "ArcLength"
}

/// Стили заполнения
enum HatchPattern: String, Codable, CaseIterable {
    case solid = "Solid"
    case horizontal = "Horizontal"
    case vertical = "Vertical"
    case cross = "Cross"
    case diagonalCross = "DiagonalCross"
    case diagonalUp = "DiagonalUp"
    case diagonalDown = "DiagonalDown"
    case brick = "Brick"
    case circle = "Circle"
    case hexagon = "Hexagon"
    
    var spacing: Double {
        switch self {
        case .solid: return 0
        default: return 10.0
        }
    }
}

// MARK: - Структуры выделения

/// Результат выделения
struct SelectionResult {
    var entityID: UUID
    var distance: Double
    var point: CADPoint?
    
    init(entityID: UUID, distance: Double, point: CADPoint? = nil) {
        self.entityID = entityID
        self.distance = distance
        self.point = point
    }
}

/// Границы выделения
struct SelectionBounds {
    var minX: Double
    var minY: Double
    var maxX: Double
    var maxY: Double
    
    var width: Double { maxX - minX }
    var height: Double { maxY - minY }
    var center: CADPoint { CADPoint(x: (minX + maxX) / 2, y: (minY + maxY) / 2) }
    
    init(minX: Double = 0, minY: Double = 0, maxX: Double = 0, maxY: Double = 0) {
        self.minX = minX
        self.minY = minY
        self.maxX = maxX
        self.maxY = maxY
    }
    
    init(points: [CADPoint]) {
        if points.isEmpty {
            self.init()
            return
        }
        
        minX = points.map { $0.x }.min() ?? 0
        minY = points.map { $0.y }.min() ?? 0
        maxX = points.map { $0.x }.max() ?? 0
        maxY = points.map { $0.y }.max() ?? 0
    }
    
    func contains(_ point: CADPoint) -> Bool {
        return point.x >= minX && point.x <= maxX &&
               point.y >= minY && point.y <= maxY
    }
    
    func intersects(_ other: SelectionBounds) -> Bool {
        return !(other.minX > maxX || other.maxX < minX ||
                 other.minY > maxY || other.maxY < minY)
    }
}

// MARK: - Настройки документа

/// Настройки сетки
struct GridSettings: Codable, Equatable {
    var enabled: Bool
    var spacingX: Double
    var spacingY: Double
    var subdivisions: Int
    var color: CADColor
    var snapToGrid: Bool
    
    static let `default` = GridSettings(
        enabled: true,
        spacingX: 10.0,
        spacingY: 10.0,
        subdivisions: 5,
        color: CADColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 0.5),
        snapToGrid: false
    )
}

/// Настройки привязок
struct SnapSettings: Codable, Equatable {
    var enabled: Bool
    var modes: Set<SnapMode>
    var apertureSize: Double
    
    static let `default` = SnapSettings(
        enabled: true,
        modes: [.endpoint, .midpoint, .center, .intersection],
        apertureSize: 10.0
    )
}

/// Настройки отображения
struct DisplaySettings: Codable, Equatable {
    var showGrid: Bool
    var showSnapPoints: Bool
    var showSelectionBounds: Bool
    var showCoordinates: Bool
    var antiAliasing: Bool
    var lineWidth: Double
    
    static let `default` = DisplaySettings(
        showGrid: true,
        showSnapPoints: true,
        showSelectionBounds: true,
        showCoordinates: true,
        antiAliasing: true,
        lineWidth: 1.0
    )
}

// MARK: - Протоколы

/// Протокол для Undo/Redo операций
protocol CADCommand: AnyObject {
    var description: String { get }
    func execute()
    func undo()
    func redo()
}

/// Протокол для экспортеров
protocol CADExporter {
    var fileExtension: String { get }
    var mimeType: String { get }
    func export(document: CADDrawingDocument) throws -> Data
}

/// Протокол для импортеров
protocol CADImporter {
    var supportedExtensions: [String] { get }
    func importFileData(data: Data) throws -> CADDrawingDocument
}
