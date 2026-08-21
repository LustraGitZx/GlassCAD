//
//  CADTools.swift
//  LibreCAD_MacOS
//
//  Инструменты для рисования и редактирования
//

import Foundation
import CoreGraphics

/// Типы инструментов
enum CADToolType: String, CaseIterable, Identifiable {
    case select = "select"
    case pan = "pan"
    case line = "line"
    case rectangle = "rectangle"
    case circle = "circle"
    case arc = "arc"
    case text = "text"
    case polyline = "polyline"
    case move = "move"
    case copy = "copy"
    case rotate = "rotate"
    case scale = "scale"
    case mirror = "mirror"
    case trim = "trim"
    case offset = "offset"
    case dimension = "dimension"
    case hatch = "hatch"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .select: return "arrow.up.left.and.arrow.down.right"
        case .pan: return "hand.raised"
        case .line: return "line"
        case .rectangle: return "rectangle"
        case .circle: return "circle"
        case .arc: return "circle.lefthalf.filled"
        case .text: return "textformat"
        case .polyline: return "pencil"
        case .move: return "arrow.3.trianglepath"
        case .copy: return "doc.on.doc"
        case .rotate: return "arrow.2.squarepath"
        case .scale: return "arrow.up.left.and.arrow.down.right.rectangle"
        case .mirror: return "flipphone"
        case .trim: return "scissors"
        case .offset: return "square.split.2x1"
        case .dimension: return "ruler"
        case .hatch: return "grid"
        }
    }
    
    var displayName: String {
        switch self {
        case .select: return "Выделение"
        case .pan: return "Панорамирование"
        case .line: return "Линия"
        case .rectangle: return "Прямоугольник"
        case .circle: return "Круг"
        case .arc: return "Дуга"
        case .text: return "Текст"
        case .polyline: return "Полилиния"
        case .move: return "Переместить"
        case .copy: return "Копировать"
        case .rotate: return "Повернуть"
        case .scale: return "Масштаб"
        case .mirror: return "Отразить"
        case .trim: return "Обрезать"
        case .offset: return "Подобие"
        case .dimension: return "Размер"
        case .hatch: return "Штриховка"
        }
    }
}

/// Состояние инструмента рисования
class CADToolState: ObservableObject {
    @Published var isActive: Bool = false
    @Published var startPoint: CADPoint?
    @Published var endPoint: CADPoint?
    @Published var points: [CADPoint] = []
    @Published var previewEntity: CADEntityBase?
    
    func reset() {
        isActive = false
        startPoint = nil
        endPoint = nil
        points.removeAll()
        previewEntity = nil
    }
}

/// Менеджер инструментов
class CADToolManager: ObservableObject {
    @Published var currentTool: CADToolType = .select
    @Published var toolStates: [CADToolType: CADToolState] = [:]
    
    // Настройки инструментов
    @Published var lineWidth: Double = 1.0
    @Published var lineColor: CADColor = .black
    @Published var lineType: CADLineType = .continuous
    
    init() {
        // Инициализируем состояния для всех инструментов
        for tool in CADToolType.allCases {
            toolStates[tool] = CADToolState()
        }
    }
    
    var currentState: CADToolState? {
        toolStates[currentTool]
    }
    
    func activateTool(_ tool: CADToolType) {
        // Деактивируем текущий инструмент
        currentState?.reset()
        currentTool = tool
        currentState?.isActive = true
    }
    
    func startDrawing(at point: CADPoint) {
        currentState?.startPoint = point
        currentState?.isActive = true
        
        if currentTool == .polyline {
            currentState?.points = [point]
        }
    }
    
    func updateDrawing(to point: CADPoint) {
        guard let state = currentState, let start = state.startPoint else { return }
        
        state.endPoint = point
        
        // Создаем предварительный просмотр
        switch currentTool {
        case .line:
            state.previewEntity = CADLine(layerID: UUID(), startPoint: start, endPoint: point)
        case .rectangle:
            let width = point.x - start.x
            let height = point.y - start.y
            state.previewEntity = CADRectangle(layerID: UUID(), origin: start, width: abs(width), height: abs(height))
        case .circle:
            let radius = start.distance(to: point)
            state.previewEntity = CADCircle(layerID: UUID(), center: start, radius: radius)
        case .polyline:
            state.points.append(point)
            state.previewEntity = CADPolyline(layerID: UUID(), points: state.points, isClosed: false)
        default:
            break
        }
    }
    
    func finishDrawing() -> CADEntityBase? {
        guard let state = currentState, let start = state.startPoint else { return nil }
        
        var entity: CADEntityBase?
        
        switch currentTool {
        case .line:
            if let end = state.endPoint {
                entity = CADLine(layerID: UUID(), startPoint: start, endPoint: end)
            }
        case .rectangle:
            if let end = state.endPoint {
                let width = end.x - start.x
                let height = end.y - start.y
                entity = CADRectangle(layerID: UUID(), origin: start, width: abs(width), height: abs(height))
            }
        case .circle:
            if let end = state.endPoint {
                let radius = start.distance(to: end)
                entity = CADCircle(layerID: UUID(), center: start, radius: radius)
            }
        case .polyline:
            if state.points.count >= 2 {
                entity = CADPolyline(layerID: UUID(), points: state.points, isClosed: false)
            }
        default:
            break
        }
        
        state.reset()
        return entity
    }
    
    func cancelDrawing() {
        currentState?.reset()
    }
}
