//
//  CADDrawingDocument.swift
//  LibreCAD_MacOS
//
//  Основной документ CAD системы с управлением сущностями, слоями и операциями
//

import Foundation
import Combine
import CoreGraphics

/// Класс документа чертежа
class CADDrawingDocument: ObservableObject {
    // MARK: - Published свойства
    
    @Published var entities: [CADEntityBase] = []
    @Published var layers: [CADLayer] = []
    @Published var selectedEntityIDs: Set<UUID> = []
    @Published var currentTool: CADToolType = .select
    @Published var currentLayerID: UUID = UUID()
    @Published var zoomLevel: Double = 1.0
    @Published var panOffset: CADPoint = .zero
    @Published var gridSettings: GridSettings = .default
    @Published var snapSettings: SnapSettings = .default
    @Published var displaySettings: DisplaySettings = .default
    @Published var undoStack: [CADCommand] = []
    @Published var redoStack: [CADCommand] = []
    @Published var filePath: URL?
    @Published var isModified: Bool = false
    @Published var fileName: String = "Без названия"
    
    // MARK: - Вычисляемые свойства
    
    var currentLayer: CADLayer? {
        layers.first { $0.id == currentLayerID }
    }
    
    var selectedEntities: [CADEntityBase] {
        entities.filter { selectedEntityIDs.contains($0.id) }
    }
    
    var visibleEntities: [CADEntityBase] {
        let visibleLayerIDs = layers.filter { $0.isVisible }.map { $0.id }
        return entities.filter { visibleLayerIDs.contains($0.layerID) }
    }
    
    var bounds: SelectionBounds {
        guard !entities.isEmpty else {
            return SelectionBounds(minX: -100, minY: -100, maxX: 100, maxY: 100)
        }
        
        var minX = Double.greatestFiniteMagnitude
        var minY = Double.greatestFiniteMagnitude
        var maxX = -Double.greatestFiniteMagnitude
        var maxY = -Double.greatestFiniteMagnitude
        
        for entity in entities {
            minX = min(minX, entity.bounds.minX)
            minY = min(minY, entity.bounds.minY)
            maxX = max(maxX, entity.bounds.maxX)
            maxY = max(maxY, entity.bounds.maxY)
        }
        
        // Добавляем отступы
        let padding = max((maxX - minX) * 0.1, 10.0)
        return SelectionBounds(
            minX: minX - padding,
            minY: minY - padding,
            maxX: maxX + padding,
            maxY: maxY + padding
        )
    }
    
    // MARK: - Инициализация
    
    init() {
        // Создаем слой по умолчанию
        let defaultLayer = CADLayer(name: "0", color: CADColor.black)
        layers.append(defaultLayer)
        currentLayerID = defaultLayer.id
    }
    
    // MARK: - Операции с сущностями
    
    func addEntity(_ entity: CADEntityBase) {
        entities.append(entity)
        isModified = true
        objectWillChange.send()
    }
    
    func removeEntity(id: UUID) {
        entities.removeAll { $0.id == id }
        selectedEntityIDs.remove(id)
        isModified = true
        objectWillChange.send()
    }
    
    func updateEntity(_ entity: CADEntityBase) {
        if let index = entities.firstIndex(where: { $0.id == entity.id }) {
            entities[index] = entity
            isModified = true
            objectWillChange.send()
        }
    }
    
    func clearAll() {
        entities.removeAll()
        selectedEntityIDs.removeAll()
        isModified = false
        objectWillChange.send()
    }
    
    // MARK: - Выделение
    
    func selectEntity(id: UUID, addToSelection: Bool = false) {
        if addToSelection {
            selectedEntityIDs.insert(id)
        } else {
            selectedEntityIDs = [id]
        }
        objectWillChange.send()
    }
    
    func deselectAll() {
        selectedEntityIDs.removeAll()
        objectWillChange.send()
    }
    
    func selectInRect(_ rect: SelectionBounds) {
        selectedEntityIDs.removeAll()
        for entity in visibleEntities {
            if rect.intersects(entity.bounds) {
                selectedEntityIDs.insert(entity.id)
            }
        }
        objectWillChange.send()
    }
    
    func entityAt(point: CADPoint, tolerance: Double = 5.0) -> CADEntityBase? {
        for entity in visibleEntities.reversed() {
            if entity.contains(point: point, tolerance: tolerance) {
                return entity
            }
        }
        return nil
    }
    
    func entitiesAt(point: CADPoint, tolerance: Double = 5.0) -> [CADEntityBase] {
        return visibleEntities.filter { $0.contains(point: point, tolerance: tolerance) }
    }
    
    // MARK: - Геометрические операции
    
    func moveSelected(by offset: CADPoint) {
        guard !selectedEntityIDs.isEmpty else { return }
        
        let command = MoveCommand(document: self, offset: offset)
        executeCommand(command)
    }
    
    func rotateSelected(around center: CADPoint, by angle: Double) {
        guard !selectedEntityIDs.isEmpty else { return }
        
        let command = RotateCommand(document: self, center: center, angle: angle)
        executeCommand(command)
    }
    
    func scaleSelected(around center: CADPoint, by factor: Double) {
        guard !selectedEntityIDs.isEmpty else { return }
        
        let command = ScaleCommand(document: self, center: center, factor: factor)
        executeCommand(command)
    }
    
    func mirrorSelected(about point: CADPoint) {
        guard !selectedEntityIDs.isEmpty else { return }
        
        let command = MirrorCommand(document: self, point: point)
        executeCommand(command)
    }
    
    func deleteSelected() {
        guard !selectedEntityIDs.isEmpty else { return }
        
        let command = DeleteCommand(document: self, entityIDs: Array(selectedEntityIDs))
        executeCommand(command)
    }
    
    func copySelected() {
        // Копирование в буфер обмена будет реализовано отдельно
    }
    
    // MARK: - Undo/Redo
    
    func executeCommand(_ command: CADCommand) {
        command.execute()
        undoStack.append(command)
        redoStack.removeAll()
        isModified = true
        objectWillChange.send()
    }
    
    func undo() {
        guard let command = undoStack.popLast() else { return }
        command.undo()
        redoStack.append(command)
        isModified = true
        objectWillChange.send()
    }
    
    func redo() {
        guard let command = redoStack.popLast() else { return }
        command.redo()
        undoStack.append(command)
        isModified = true
        objectWillChange.send()
    }
    
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    
    // MARK: - Слои
    
    func addLayer(name: String, color: CADColor = .black) -> CADLayer {
        let layer = CADLayer(name: name, color: color)
        layers.append(layer)
        isModified = true
        objectWillChange.send()
        return layer
    }
    
    func removeLayer(id: UUID) {
        guard id != currentLayerID && layers.count > 1 else { return }
        layers.removeAll { $0.id == id }
        // Перемещаем сущности удаленного слоя на слой по умолчанию
        let defaultLayerID = layers.first?.id ?? currentLayerID
        for i in entities.indices {
            if entities[i].layerID == id {
                entities[i].layerID = defaultLayerID
            }
        }
        isModified = true
        objectWillChange.send()
    }
    
    func toggleLayerVisibility(id: UUID) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].isVisible.toggle()
            isModified = true
            objectWillChange.send()
        }
    }
    
    func setLayerLock(id: UUID, locked: Bool) {
        if let index = layers.firstIndex(where: { $0.id == id }) {
            layers[index].isLocked = locked
            isModified = true
            objectWillChange.send()
        }
    }
    
    // MARK: - Навигация
    
    func zoomToFit() {
        // Будет реализовано в View
        zoomLevel = 1.0
        panOffset = .zero
        objectWillChange.send()
    }
    
    func zoomIn() {
        zoomLevel = min(zoomLevel * 1.2, 100.0)
        objectWillChange.send()
    }
    
    func zoomOut() {
        zoomLevel = max(zoomLevel / 1.2, 0.01)
        objectWillChange.send()
    }
    
    func pan(by offset: CADPoint) {
        panOffset = panOffset + offset
        objectWillChange.send()
    }
    
    // MARK: - Привязки
    
    func snapPoint(_ point: CADPoint) -> CADPoint {
        guard snapSettings.enabled else { return point }
        
        var snappedPoint = point
        var minDistance = snapSettings.apertureSize
        var foundSnap = false
        
        // Привязка к сетке
        if snapSettings.modes.contains(.grid) && gridSettings.snapToGrid {
            let snappedX = round(point.x / gridSettings.spacingX) * gridSettings.spacingX
            let snappedY = round(point.y / gridSettings.spacingY) * gridSettings.spacingY
            snappedPoint = CADPoint(x: snappedX, y: snappedY)
            foundSnap = true
        }
        
        // Привязка к точкам сущностей
        if snapSettings.modes.contains(.endpoint) || 
           snapSettings.modes.contains(.midpoint) ||
           snapSettings.modes.contains(.center) {
            
            for entity in visibleEntities {
                // Конечные точки для линий и полилиний
                if let line = entity as? CADLine {
                    checkSnap(to: line.startPoint, from: point, minDistance: &minDistance, snappedPoint: &snappedPoint, found: &foundSnap)
                    checkSnap(to: line.endPoint, from: point, minDistance: &minDistance, snappedPoint: &snappedPoint, found: &foundSnap)
                }
                
                // Центр для кругов и дуг
                if let circle = entity as? CADCircle {
                    checkSnap(to: circle.center, from: point, minDistance: &minDistance, snappedPoint: &snappedPoint, found: &foundSnap)
                }
                
                if let arc = entity as? CADArc {
                    checkSnap(to: arc.center, from: point, minDistance: &minDistance, snappedPoint: &snappedPoint, found: &foundSnap)
                }
                
                // Точки полилинии
                if let polyline = entity as? CADPolyline {
                    for p in polyline.points {
                        checkSnap(to: p, from: point, minDistance: &minDistance, snappedPoint: &snappedPoint, found: &foundSnap)
                    }
                }
            }
        }
        
        return foundSnap ? snappedPoint : point
    }
    
    private func checkSnap(to targetPoint: CADPoint, from point: CADPoint, 
                          minDistance: inout Double, snappedPoint: inout CADPoint, found: inout Bool) {
        let distance = point.distance(to: targetPoint)
        if distance < minDistance {
            minDistance = distance
            snappedPoint = targetPoint
            found = true
        }
    }
}

// MARK: - Команды для Undo/Redo

/// Команда перемещения
class MoveCommand: CADCommand {
    var description: String { "Переместить" }
    
    private weak var document: CADDrawingDocument?
    private let entityIDs: [UUID]
    private let offset: CADPoint
    private var originalStates: [UUID: CADEntityBase] = [:]
    
    init(document: CADDrawingDocument, offset: CADPoint) {
        self.document = document
        self.entityIDs = Array(document.selectedEntityIDs)
        self.offset = offset
        
        // Сохраняем оригинальные состояния
        for entity in document.entities where entityIDs.contains(entity.id) {
            originalStates[entity.id] = entity.moved(by: CADPoint(x: 0, y: 0))
        }
    }
    
    func execute() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if entityIDs.contains(doc.entities[i].id) {
                if let line = doc.entities[i] as? CADLine {
                    doc.entities[i] = line.moved(by: offset)
                } else if let circle = doc.entities[i] as? CADCircle {
                    doc.entities[i] = circle.moved(by: offset)
                } else if let arc = doc.entities[i] as? CADArc {
                    doc.entities[i] = arc.moved(by: offset)
                } else if let rect = doc.entities[i] as? CADRectangle {
                    doc.entities[i] = rect.moved(by: offset)
                } else if let text = doc.entities[i] as? CADText {
                    doc.entities[i] = text.moved(by: offset)
                } else if let polyline = doc.entities[i] as? CADPolyline {
                    doc.entities[i] = polyline.moved(by: offset)
                }
            }
        }
        doc.objectWillChange.send()
    }
    
    func undo() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if let original = originalStates[doc.entities[i].id] {
                doc.entities[i] = original
            }
        }
        doc.objectWillChange.send()
    }
    
    func redo() {
        execute()
    }
}

/// Команда вращения
class RotateCommand: CADCommand {
    var description: String { "Повернуть" }
    
    private weak var document: CADDrawingDocument?
    private let entityIDs: [UUID]
    private let center: CADPoint
    private let angle: Double
    private var originalStates: [UUID: CADEntityBase] = [:]
    
    init(document: CADDrawingDocument, center: CADPoint, angle: Double) {
        self.document = document
        self.entityIDs = Array(document.selectedEntityIDs)
        self.center = center
        self.angle = angle
        
        for entity in document.entities where entityIDs.contains(entity.id) {
            originalStates[entity.id] = entity.rotated(around: CADPoint(x: 0, y: 0), by: 0)
        }
    }
    
    func execute() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if entityIDs.contains(doc.entities[i].id) {
                if let line = doc.entities[i] as? CADLine {
                    doc.entities[i] = line.rotated(around: center, by: angle)
                } else if let circle = doc.entities[i] as? CADCircle {
                    doc.entities[i] = circle.rotated(around: center, by: angle)
                } else if let arc = doc.entities[i] as? CADArc {
                    doc.entities[i] = arc.rotated(around: center, by: angle)
                } else if let rect = doc.entities[i] as? CADRectangle {
                    doc.entities[i] = rect.rotated(around: center, by: angle)
                } else if let text = doc.entities[i] as? CADText {
                    doc.entities[i] = text.rotated(around: center, by: angle)
                } else if let polyline = doc.entities[i] as? CADPolyline {
                    doc.entities[i] = polyline.rotated(around: center, by: angle)
                }
            }
        }
        doc.objectWillChange.send()
    }
    
    func undo() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if let original = originalStates[doc.entities[i].id] {
                doc.entities[i] = original
            }
        }
        doc.objectWillChange.send()
    }
    
    func redo() {
        execute()
    }
}

/// Команда масштабирования
class ScaleCommand: CADCommand {
    var description: String { "Масштабировать" }
    
    private weak var document: CADDrawingDocument?
    private let entityIDs: [UUID]
    private let center: CADPoint
    private let factor: Double
    private var originalStates: [UUID: CADEntityBase] = [:]
    
    init(document: CADDrawingDocument, center: CADPoint, factor: Double) {
        self.document = document
        self.entityIDs = Array(document.selectedEntityIDs)
        self.center = center
        self.factor = factor
        
        for entity in document.entities where entityIDs.contains(entity.id) {
            originalStates[entity.id] = entity.scaled(around: CADPoint(x: 0, y: 0), by: 1.0)
        }
    }
    
    func execute() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if entityIDs.contains(doc.entities[i].id) {
                if let line = doc.entities[i] as? CADLine {
                    doc.entities[i] = line.scaled(around: center, by: factor)
                } else if let circle = doc.entities[i] as? CADCircle {
                    doc.entities[i] = circle.scaled(around: center, by: factor)
                } else if let arc = doc.entities[i] as? CADArc {
                    doc.entities[i] = arc.scaled(around: center, by: factor)
                } else if let rect = doc.entities[i] as? CADRectangle {
                    doc.entities[i] = rect.scaled(around: center, by: factor)
                } else if let text = doc.entities[i] as? CADText {
                    doc.entities[i] = text.scaled(around: center, by: factor)
                } else if let polyline = doc.entities[i] as? CADPolyline {
                    doc.entities[i] = polyline.scaled(around: center, by: factor)
                }
            }
        }
        doc.objectWillChange.send()
    }
    
    func undo() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if let original = originalStates[doc.entities[i].id] {
                doc.entities[i] = original
            }
        }
        doc.objectWillChange.send()
    }
    
    func redo() {
        execute()
    }
}

/// Команда отражения
class MirrorCommand: CADCommand {
    var description: String { "Отразить" }
    
    private weak var document: CADDrawingDocument?
    private let entityIDs: [UUID]
    private let point: CADPoint
    private var originalStates: [UUID: CADEntityBase] = [:]
    
    init(document: CADDrawingDocument, point: CADPoint) {
        self.document = document
        self.entityIDs = Array(document.selectedEntityIDs)
        self.point = point
        
        for entity in document.entities where entityIDs.contains(entity.id) {
            originalStates[entity.id] = entity.mirrored(about: CADPoint(x: 0, y: 0))
        }
    }
    
    func execute() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if entityIDs.contains(doc.entities[i].id) {
                if let line = doc.entities[i] as? CADLine {
                    doc.entities[i] = line.mirrored(about: point)
                } else if let circle = doc.entities[i] as? CADCircle {
                    doc.entities[i] = circle.mirrored(about: point)
                } else if let arc = doc.entities[i] as? CADArc {
                    doc.entities[i] = arc.mirrored(about: point)
                } else if let rect = doc.entities[i] as? CADRectangle {
                    doc.entities[i] = rect.mirrored(about: point)
                } else if let text = doc.entities[i] as? CADText {
                    doc.entities[i] = text.mirrored(about: point)
                } else if let polyline = doc.entities[i] as? CADPolyline {
                    doc.entities[i] = polyline.mirrored(about: point)
                }
            }
        }
        doc.objectWillChange.send()
    }
    
    func undo() {
        guard let doc = document else { return }
        for i in doc.entities.indices {
            if let original = originalStates[doc.entities[i].id] {
                doc.entities[i] = original
            }
        }
        doc.objectWillChange.send()
    }
    
    func redo() {
        execute()
    }
}

/// Команда удаления
class DeleteCommand: CADCommand {
    var description: String { "Удалить" }
    
    private weak var document: CADDrawingDocument?
    private let entityIDs: [UUID]
    private var deletedEntities: [CADEntityBase] = []
    
    init(document: CADDrawingDocument, entityIDs: [UUID]) {
        self.document = document
        self.entityIDs = entityIDs
        
        // Сохраняем удаляемые сущности
        for entity in document.entities where entityIDs.contains(entity.id) {
            deletedEntities.append(entity)
        }
    }
    
    func execute() {
        guard let doc = document else { return }
        doc.entities.removeAll { entityIDs.contains($0.id) }
        doc.selectedEntityIDs.subtract(entityIDs)
        doc.objectWillChange.send()
    }
    
    func undo() {
        guard let doc = document else { return }
        for entity in deletedEntities {
            doc.entities.append(entity)
        }
        doc.objectWillChange.send()
    }
    
    func redo() {
        execute()
    }
}
