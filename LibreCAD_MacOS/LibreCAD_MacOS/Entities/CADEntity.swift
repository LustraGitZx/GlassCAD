//
//  CADEntity.swift
//  LibreCAD_MacOS
//
//  Базовый класс и реализации сущностей CAD
//

import Foundation
import CoreGraphics

// MARK: - Базовый протокол сущности

/// Протокол для всех CAD сущностей
protocol CADEntityProtocol: Codable, Identifiable, Hashable {
    var id: UUID { get set }
    var layerID: UUID { get set }
    var entityType: EntityType { get }
    var bounds: SelectionBounds { get }
    var color: CADColor? { get set }
    var lineWidth: Double { get set }
    var lineType: CADLineType { get set }
    
    // Геометрические операции
    func moved(by offset: CADPoint) -> Self
    func rotated(around center: CADPoint, by angle: Double) -> Self
    func scaled(around center: CADPoint, by factor: Double) -> Self
    func mirrored(about point: CADPoint) -> Self
    
    // Проверки
    func contains(point: CADPoint, tolerance: Double) -> Bool
    func distance(to point: CADPoint) -> Double
    func nearestPoint(to point: CADPoint) -> CADPoint?
    
    // Рендеринг
    func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings)
}

// MARK: - Базовая реализация сущности

/// Базовый класс для всех сущностей
class CADEntityBase: Codable, Identifiable, Hashable {
    var id: UUID
    var layerID: UUID
    var entityType: EntityType
    var color: CADColor?
    var lineWidth: Double
    var lineType: CADLineType
    var createdAt: Date
    var modifiedAt: Date
    
    init(id: UUID = UUID(), layerID: UUID, entityType: EntityType, 
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.id = id
        self.layerID = layerID
        self.entityType = entityType
        self.color = color
        self.lineWidth = lineWidth
        self.lineType = lineType
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
    
    static func == (lhs: CADEntityBase, rhs: CADEntityBase) -> Bool {
        return lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    var bounds: SelectionBounds {
        fatalError("Must be implemented by subclass")
    }
    
    func moved(by offset: CADPoint) -> CADEntityBase {
        fatalError("Must be implemented by subclass")
    }
    
    func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        fatalError("Must be implemented by subclass")
    }
    
    func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        fatalError("Must be implemented by subclass")
    }
    
    func mirrored(about point: CADPoint) -> CADEntityBase {
        fatalError("Must be implemented by subclass")
    }
    
    func contains(point: CADPoint, tolerance: Double) -> Bool {
        fatalError("Must be implemented by subclass")
    }
    
    func distance(to point: CADPoint) -> Double {
        fatalError("Must be implemented by subclass")
    }
    
    func nearestPoint(to point: CADPoint) -> CADPoint? {
        fatalError("Must be implemented by subclass")
    }
    
    func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        fatalError("Must be implemented by subclass")
    }
}

// MARK: - Линия

class CADLine: CADEntityBase {
    var startPoint: CADPoint
    var endPoint: CADPoint
    
    override var entityType: EntityType { .line }
    
    override var bounds: SelectionBounds {
        let minX = min(startPoint.x, endPoint.x)
        let minY = min(startPoint.y, endPoint.y)
        let maxX = max(startPoint.x, endPoint.x)
        let maxY = max(startPoint.y, endPoint.y)
        return SelectionBounds(minX: minX, minY: minY, maxX: maxX, maxY: maxY)
    }
    
    init(id: UUID = UUID(), layerID: UUID, startPoint: CADPoint, endPoint: CADPoint,
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        super.init(id: id, layerID: layerID, entityType: .line, color: color, lineWidth: lineWidth, lineType: lineType)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startPoint = try container.decode(CADPoint.self, forKey: .startPoint)
        endPoint = try container.decode(CADPoint.self, forKey: .endPoint)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startPoint, forKey: .startPoint)
        try container.encode(endPoint, forKey: .endPoint)
    }
    
    private enum CodingKeys: String, CodingKey {
        case startPoint, endPoint
    }
    
    override func moved(by offset: CADPoint) -> CADEntityBase {
        let newEntity = CADLine(layerID: layerID, startPoint: startPoint + offset, endPoint: endPoint + offset)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        let newEntity = CADLine(layerID: layerID, 
                               startPoint: startPoint.rotated(around: center, by: angle),
                               endPoint: endPoint.rotated(around: center, by: angle))
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        let newEntity = CADLine(layerID: layerID,
                               startPoint: startPoint.scaled(around: center, by: factor),
                               endPoint: endPoint.scaled(around: center, by: factor))
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth * factor
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func mirrored(about point: CADPoint) -> CADEntityBase {
        let newEntity = CADLine(layerID: layerID,
                               startPoint: CADPoint(x: 2 * point.x - startPoint.x, y: 2 * point.y - startPoint.y),
                               endPoint: CADPoint(x: 2 * point.x - endPoint.x, y: 2 * point.y - endPoint.y))
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func contains(point: CADPoint, tolerance: Double) -> Bool {
        return distance(to: point) <= tolerance
    }
    
    override func distance(to point: CADPoint) -> Double {
        let lineLengthSq = pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2)
        
        if lineLengthSq == 0 {
            return point.distance(to: startPoint)
        }
        
        var t = ((point.x - startPoint.x) * (endPoint.x - startPoint.x) +
                 (point.y - startPoint.y) * (endPoint.y - startPoint.y)) / lineLengthSq
        
        t = max(0, min(1, t))
        
        let projection = CADPoint(
            x: startPoint.x + t * (endPoint.x - startPoint.x),
            y: startPoint.y + t * (endPoint.y - startPoint.y)
        )
        
        return point.distance(to: projection)
    }
    
    override func nearestPoint(to point: CADPoint) -> CADPoint? {
        let lineLengthSq = pow(endPoint.x - startPoint.x, 2) + pow(endPoint.y - startPoint.y, 2)
        
        if lineLengthSq == 0 {
            return startPoint
        }
        
        var t = ((point.x - startPoint.x) * (endPoint.x - startPoint.x) +
                 (point.y - startPoint.y) * (endPoint.y - startPoint.y)) / lineLengthSq
        
        t = max(0, min(1, t))
        
        return CADPoint(
            x: startPoint.x + t * (endPoint.x - startPoint.x),
            y: startPoint.y + t * (endPoint.y - startPoint.y)
        )
    }
    
    override func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        context.saveGState()
        context.setLineWidth(CGFloat(lineWidth))
        context.setStrokeColor((color ?? CADColor.black).nsColor.cgColor)
        
        if lineType != .continuous {
            context.setLineDash(phase: 0, lengths: lineType.pattern.map { CGFloat($0) })
        }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: startPoint.x, y: startPoint.y), transform: transform)
        path.addLine(to: CGPoint(x: endPoint.x, y: endPoint.y), transform: transform)
        
        context.addPath(path)
        context.strokePath()
        context.restoreGState()
    }
}

// MARK: - Круг

class CADCircle: CADEntityBase {
    var center: CADPoint
    var radius: Double
    
    override var entityType: EntityType { .circle }
    
    override var bounds: SelectionBounds {
        return SelectionBounds(
            minX: center.x - radius,
            minY: center.y - radius,
            maxX: center.x + radius,
            maxY: center.y + radius
        )
    }
    
    init(id: UUID = UUID(), layerID: UUID, center: CADPoint, radius: Double,
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.center = center
        self.radius = radius
        super.init(id: id, layerID: layerID, entityType: .circle, color: color, lineWidth: lineWidth, lineType: lineType)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(CADPoint.self, forKey: .center)
        radius = try container.decode(Double.self, forKey: .radius)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(radius, forKey: .radius)
    }
    
    private enum CodingKeys: String, CodingKey {
        case center, radius
    }
    
    override func moved(by offset: CADPoint) -> CADEntityBase {
        let newEntity = CADCircle(layerID: layerID, center: center + offset, radius: radius)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        let newEntity = CADCircle(layerID: layerID, 
                                 center: self.center.rotated(around: center, by: angle),
                                 radius: radius)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        let newEntity = CADCircle(layerID: layerID,
                                 center: self.center.scaled(around: center, by: factor),
                                 radius: radius * factor)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth * factor
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func mirrored(about point: CADPoint) -> CADEntityBase {
        let newCenter = CADPoint(x: 2 * point.x - center.x, y: 2 * point.y - center.y)
        let newEntity = CADCircle(layerID: layerID, center: newCenter, radius: radius)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func contains(point: CADPoint, tolerance: Double) -> Bool {
        return abs(point.distance(to: center) - radius) <= tolerance
    }
    
    override func distance(to point: CADPoint) -> Double {
        return abs(point.distance(to: center) - radius)
    }
    
    override func nearestPoint(to point: CADPoint) -> CADPoint? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance == 0 {
            return CADPoint(x: center.x + radius, y: center.y)
        }
        
        return CADPoint(
            x: center.x + (dx / distance) * radius,
            y: center.y + (dy / distance) * radius
        )
    }
    
    override func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        context.saveGState()
        context.setLineWidth(CGFloat(lineWidth))
        context.setStrokeColor((color ?? CADColor.black).nsColor.cgColor)
        
        if lineType != .continuous {
            context.setLineDash(phase: 0, lengths: lineType.pattern.map { CGFloat($0) })
        }
        
        let cgRect = CGRect(
            x: center.x - radius,
            y: center.y - radius,
            width: 2 * radius,
            height: 2 * radius
        )
        
        if let ellipsePath = CGPath(ellipseIn: cgRect, transform: transform) {
            context.addPath(ellipsePath)
            context.strokePath()
        }
        
        context.restoreGState()
    }
}

// MARK: - Дуга

class CADArc: CADEntityBase {
    var center: CADPoint
    var radius: Double
    var startAngle: Double  // в градусах
    var endAngle: Double    // в градусах
    
    override var entityType: EntityType { .arc }
    
    override var bounds: SelectionBounds {
        // Упрощенный расчет границ
        let startX = center.x + radius * cos(startAngle * .pi / 180.0)
        let startY = center.y + radius * sin(startAngle * .pi / 180.0)
        let endX = center.x + radius * cos(endAngle * .pi / 180.0)
        let endY = center.y + radius * sin(endAngle * .pi / 180.0)
        
        return SelectionBounds(
            minX: min(center.x - radius, min(startX, endX)),
            minY: min(center.y - radius, min(startY, endY)),
            maxX: max(center.x + radius, max(startX, endX)),
            maxY: max(center.y + radius, max(startY, endY))
        )
    }
    
    init(id: UUID = UUID(), layerID: UUID, center: CADPoint, radius: Double,
         startAngle: Double, endAngle: Double,
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.center = center
        self.radius = radius
        self.startAngle = startAngle.truncatingRemainder(dividingBy: 360)
        self.endAngle = endAngle.truncatingRemainder(dividingBy: 360)
        super.init(id: id, layerID: layerID, entityType: .arc, color: color, lineWidth: lineWidth, lineType: lineType)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        center = try container.decode(CADPoint.self, forKey: .center)
        radius = try container.decode(Double.self, forKey: .radius)
        startAngle = try container.decode(Double.self, forKey: .startAngle)
        endAngle = try container.decode(Double.self, forKey: .endAngle)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(center, forKey: .center)
        try container.encode(radius, forKey: .radius)
        try container.encode(startAngle, forKey: .startAngle)
        try container.encode(endAngle, forKey: .endAngle)
    }
    
    private enum CodingKeys: String, CodingKey {
        case center, radius, startAngle, endAngle
    }
    
    override func moved(by offset: CADPoint) -> CADEntityBase {
        let newEntity = CADArc(layerID: layerID, center: center + offset, radius: radius,
                              startAngle: startAngle, endAngle: endAngle)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        let newEntity = CADArc(layerID: layerID,
                              center: self.center.rotated(around: center, by: angle),
                              radius: radius,
                              startAngle: startAngle + angle,
                              endAngle: endAngle + angle)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        let newEntity = CADArc(layerID: layerID,
                              center: self.center.scaled(around: center, by: factor),
                              radius: radius * factor,
                              startAngle: startAngle,
                              endAngle: endAngle)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth * factor
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func mirrored(about point: CADPoint) -> CADEntityBase {
        let newCenter = CADPoint(x: 2 * point.x - center.x, y: 2 * point.y - center.y)
        let newEntity = CADArc(layerID: layerID, center: newCenter, radius: radius,
                              startAngle: -startAngle, endAngle: -endAngle)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func contains(point: CADPoint, tolerance: Double) -> Bool {
        return abs(distance(to: point)) <= tolerance
    }
    
    override func distance(to point: CADPoint) -> Double {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        let radialDistance = abs(distance - radius)
        
        // Проверяем угол
        var angle = atan2(dy, dx) * 180.0 / .pi
        if angle < 0 { angle += 360 }
        
        // Нормализуем углы дуги
        var start = startAngle.truncatingRemainder(dividingBy: 360)
        var end = endAngle.truncatingRemainder(dividingBy: 360)
        if start < 0 { start += 360 }
        if end < 0 { end += 360 }
        
        // Проверяем, находится ли точка в пределах дуги
        let isInArc: Bool
        if start < end {
            isInArc = angle >= start && angle <= end
        } else {
            isInArc = angle >= start || angle <= end
        }
        
        if isInArc {
            return radialDistance
        } else {
            // Возвращаем расстояние до ближайшего конца дуги
            let startPoint = CADPoint(
                x: center.x + radius * cos(startAngle * .pi / 180.0),
                y: center.y + radius * sin(startAngle * .pi / 180.0)
            )
            let endPoint = CADPoint(
                x: center.x + radius * cos(endAngle * .pi / 180.0),
                y: center.y + radius * sin(endAngle * .pi / 180.0)
            )
            return min(point.distance(to: startPoint), point.distance(to: endPoint))
        }
    }
    
    override func nearestPoint(to point: CADPoint) -> CADPoint? {
        let dx = point.x - center.x
        let dy = point.y - center.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance == 0 {
            return CADPoint(x: center.x + radius, y: center.y)
        }
        
        var angle = atan2(dy, dx) * 180.0 / .pi
        if angle < 0 { angle += 360 }
        
        // Нормализуем углы дуги
        var start = startAngle.truncatingRemainder(dividingBy: 360)
        var end = endAngle.truncatingRemainder(dividingBy: 360)
        if start < 0 { start += 360 }
        if end < 0 { end += 360 }
        
        // Проверяем, находится ли проекция в пределах дуги
        let isInArc: Bool
        if start < end {
            isInArc = angle >= start && angle <= end
        } else {
            isInArc = angle >= start || angle <= end
        }
        
        if isInArc {
            return CADPoint(
                x: center.x + (dx / distance) * radius,
                y: center.y + (dy / distance) * radius
            )
        } else {
            // Возвращаем ближайший конец дуги
            let startPoint = CADPoint(
                x: center.x + radius * cos(startAngle * .pi / 180.0),
                y: center.y + radius * sin(startAngle * .pi / 180.0)
            )
            let endPoint = CADPoint(
                x: center.x + radius * cos(endAngle * .pi / 180.0),
                y: center.y + radius * sin(endAngle * .pi / 180.0)
            )
            return point.distance(to: startPoint) < point.distance(to: endPoint) ? startPoint : endPoint
        }
    }
    
    override func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        context.saveGState()
        context.setLineWidth(CGFloat(lineWidth))
        context.setStrokeColor((color ?? CADColor.black).nsColor.cgColor)
        
        if lineType != .continuous {
            context.setLineDash(phase: 0, lengths: lineType.pattern.map { CGFloat($0) })
        }
        
        let startRad = startAngle * .pi / 180.0
        let endRad = endAngle * .pi / 180.0
        
        context.beginPath()
        context.arc(center: CGPoint(x: center.x, y: center.y),
                   radius: CGFloat(radius),
                   startAngle: CGFloat(startRad),
                   endAngle: CGFloat(endRad),
                   clockwise: false,
                   transform: transform)
        context.strokePath()
        
        context.restoreGState()
    }
}

// MARK: - Прямоугольник

class CADRectangle: CADEntityBase {
    var origin: CADPoint
    var width: Double
    var height: Double
    
    override var entityType: EntityType { .rectangle }
    
    override var bounds: SelectionBounds {
        return SelectionBounds(
            minX: origin.x,
            minY: origin.y,
            maxX: origin.x + width,
            maxY: origin.y + height
        )
    }
    
    init(id: UUID = UUID(), layerID: UUID, origin: CADPoint, width: Double, height: Double,
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.origin = origin
        self.width = width
        self.height = height
        super.init(id: id, layerID: layerID, entityType: .rectangle, color: color, lineWidth: lineWidth, lineType: lineType)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        origin = try container.decode(CADPoint.self, forKey: .origin)
        width = try container.decode(Double.self, forKey: .width)
        height = try container.decode(Double.self, forKey: .height)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(origin, forKey: .origin)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
    }
    
    private enum CodingKeys: String, CodingKey {
        case origin, width, height
    }
    
    override func moved(by offset: CADPoint) -> CADEntityBase {
        let newEntity = CADRectangle(layerID: layerID, origin: origin + offset, width: width, height: height)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        // Для простоты поворачиваем только позицию, не сам прямоугольник
        let newOrigin = origin.rotated(around: center, by: angle)
        let newEntity = CADRectangle(layerID: layerID, origin: newOrigin, width: width, height: height)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        let newEntity = CADRectangle(layerID: layerID,
                                    origin: origin.scaled(around: center, by: factor),
                                    width: width * factor,
                                    height: height * factor)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth * factor
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func mirrored(about point: CADPoint) -> CADEntityBase {
        let newOrigin = CADPoint(x: 2 * point.x - origin.x, y: 2 * point.y - origin.y)
        let newEntity = CADRectangle(layerID: layerID, origin: newOrigin, width: width, height: height)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func contains(point: CADPoint, tolerance: Double) -> Bool {
        // Проверяем, находится ли точка на границе прямоугольника
        let left = distanceToLine(p1: origin, p2: CADPoint(x: origin.x + width, y: origin.y), point: point)
        let right = distanceToLine(p1: CADPoint(x: origin.x + width, y: origin.y), 
                                   p2: CADPoint(x: origin.x + width, y: origin.y + height), point: point)
        let top = distanceToLine(p1: CADPoint(x: origin.x + width, y: origin.y + height),
                                p2: CADPoint(x: origin.x, y: origin.y + height), point: point)
        let bottom = distanceToLine(p1: CADPoint(x: origin.x, y: origin.y + height),
                                   p2: origin, point: point)
        
        return min(left, right, top, bottom) <= tolerance
    }
    
    private func distanceToLine(p1: CADPoint, p2: CADPoint, point: CADPoint) -> Double {
        let A = point.x - p1.x
        let B = point.y - p1.y
        let C = p2.x - p1.x
        let D = p2.y - p1.y
        
        let dot = A * C + B * D
        let lenSq = C * C + D * D
        var param = -1.0
        
        if lenSq != 0 {
            param = dot / lenSq
        }
        
        let xx: Double
        let yy: Double
        
        if param < 0 {
            xx = p1.x
            yy = p1.y
        } else if param > 1 {
            xx = p2.x
            yy = p2.y
        } else {
            xx = p1.x + param * C
            yy = p1.y + param * D
        }
        
        let dx = point.x - xx
        let dy = point.y - yy
        return sqrt(dx * dx + dy * dy)
    }
    
    override func distance(to point: CADPoint) -> Double {
        return contains(point: point, tolerance: 0) ? 0 : distanceToBoundary(point)
    }
    
    private func distanceToBoundary(_ point: CADPoint) -> Double {
        let distances = [
            distanceToLine(p1: origin, p2: CADPoint(x: origin.x + width, y: origin.y), point: point),
            distanceToLine(p1: CADPoint(x: origin.x + width, y: origin.y),
                          p2: CADPoint(x: origin.x + width, y: origin.y + height), point: point),
            distanceToLine(p1: CADPoint(x: origin.x + width, y: origin.y + height),
                          p2: CADPoint(x: origin.x, y: origin.y + height), point: point),
            distanceToLine(p1: CADPoint(x: origin.x, y: origin.y + height), p2: origin, point: point)
        ]
        return distances.min() ?? 0
    }
    
    override func nearestPoint(to point: CADPoint) -> CADPoint? {
        // Находим ближайшую точку на границе прямоугольника
        let clampedX = max(origin.x, min(point.x, origin.x + width))
        let clampedY = max(origin.y, min(point.y, origin.y + height))
        
        // Проверяем, внутри ли прямоугольника
        if point.x >= origin.x && point.x <= origin.x + width &&
           point.y >= origin.y && point.y <= origin.y + height {
            // Точка внутри, возвращаем ближайшую границу
            let distLeft = abs(point.x - origin.x)
            let distRight = abs(point.x - (origin.x + width))
            let distTop = abs(point.y - (origin.y + height))
            let distBottom = abs(point.y - origin.y)
            
            let minDist = min(distLeft, distRight, distTop, distBottom)
            
            if minDist == distLeft {
                return CADPoint(x: origin.x, y: clampedY)
            } else if minDist == distRight {
                return CADPoint(x: origin.x + width, y: clampedY)
            } else if minDist == distTop {
                return CADPoint(x: clampedX, y: origin.y + height)
            } else {
                return CADPoint(x: clampedX, y: origin.y)
            }
        }
        
        // Точка снаружи
        return CADPoint(x: clampedX, y: clampedY)
    }
    
    override func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        context.saveGState()
        context.setLineWidth(CGFloat(lineWidth))
        context.setStrokeColor((color ?? CADColor.black).nsColor.cgColor)
        
        if lineType != .continuous {
            context.setLineDash(phase: 0, lengths: lineType.pattern.map { CGFloat($0) })
        }
        
        let rect = CGRect(x: origin.x, y: origin.y, width: width, height: height)
        
        if let rectPath = CGPath(rect: rect, transform: transform) {
            context.addPath(rectPath)
            context.strokePath()
        }
        
        context.restoreGState()
    }
}

// MARK: - Текст

class CADText: CADEntityBase {
    var position: CADPoint
    var text: String
    var font: CADFont
    var rotation: Double
    
    override var entityType: EntityType { .text }
    
    override var bounds: SelectionBounds {
        // Приблизительный расчет границ текста
        let charWidth = font.size * 0.6
        let textWidth = Double(text.count) * charWidth
        let textHeight = font.size
        
        return SelectionBounds(
            minX: position.x,
            minY: position.y - textHeight,
            maxX: position.x + textWidth,
            maxY: position.y
        )
    }
    
    init(id: UUID = UUID(), layerID: UUID, position: CADPoint, text: String,
         font: CADFont = .default, rotation: Double = 0,
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.position = position
        self.text = text
        self.font = font
        self.rotation = rotation
        super.init(id: id, layerID: layerID, entityType: .text, color: color, lineWidth: lineWidth, lineType: lineType)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        position = try container.decode(CADPoint.self, forKey: .position)
        text = try container.decode(String.self, forKey: .text)
        font = try container.decode(CADFont.self, forKey: .font)
        rotation = try container.decode(Double.self, forKey: .rotation)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(position, forKey: .position)
        try container.encode(text, forKey: .text)
        try container.encode(font, forKey: .font)
        try container.encode(rotation, forKey: .rotation)
    }
    
    private enum CodingKeys: String, CodingKey {
        case position, text, font, rotation
    }
    
    override func moved(by offset: CADPoint) -> CADEntityBase {
        let newEntity = CADText(layerID: layerID, position: position + offset, text: text,
                               font: font, rotation: rotation)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        let newEntity = CADText(layerID: layerID,
                               position: position.rotated(around: center, by: angle),
                               text: text,
                               font: font,
                               rotation: rotation + angle)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        let newEntity = CADText(layerID: layerID,
                               position: position.scaled(around: center, by: factor),
                               text: text,
                               font: CADFont(name: font.name, size: font.size * factor, bold: font.bold, italic: font.italic),
                               rotation: rotation)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth * factor
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func mirrored(about point: CADPoint) -> CADEntityBase {
        let newPosition = CADPoint(x: 2 * point.x - position.x, y: 2 * point.y - position.y)
        let newEntity = CADText(layerID: layerID, position: newPosition, text: text,
                               font: font, rotation: -rotation)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func contains(point: CADPoint, tolerance: Double) -> Bool {
        return distance(to: point) <= tolerance
    }
    
    override func distance(to point: CADPoint) -> Double {
        return point.distance(to: position)
    }
    
    override func nearestPoint(to point: CADPoint) -> CADPoint? {
        return position
    }
    
    override func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        context.saveGState()
        context.setFillColor((color ?? CADColor.black).nsColor.cgColor)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: font.name, size: CGFloat(font.size)) ?? NSFont.systemFont(ofSize: CGFloat(font.size)),
            .foregroundColor: (color ?? CADColor.black).nsColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        
        context.textMatrix = transform
        context.textPosition = CGPoint(x: position.x, y: position.y)
        
        #if os(macOS)
        attributedString.draw(at: CGPoint(x: position.x, y: position.y))
        #endif
        
        context.restoreGState()
    }
}

// MARK: - Полилиния

class CADPolyline: CADEntityBase {
    var points: [CADPoint]
    var isClosed: Bool
    
    override var entityType: EntityType { .polyline }
    
    override var bounds: SelectionBounds {
        guard !points.isEmpty else {
            return SelectionBounds()
        }
        return SelectionBounds(points: points)
    }
    
    init(id: UUID = UUID(), layerID: UUID, points: [CADPoint], isClosed: Bool = false,
         color: CADColor? = nil, lineWidth: Double = 1.0, lineType: CADLineType = .continuous) {
        self.points = points
        self.isClosed = isClosed
        super.init(id: id, layerID: layerID, entityType: .polyline, color: color, lineWidth: lineWidth, lineType: lineType)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        points = try container.decode([CADPoint].self, forKey: .points)
        isClosed = try container.decode(Bool.self, forKey: .isClosed)
        try super.init(from: decoder)
    }
    
    override func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(points, forKey: .points)
        try container.encode(isClosed, forKey: .isClosed)
    }
    
    private enum CodingKeys: String, CodingKey {
        case points, isClosed
    }
    
    override func moved(by offset: CADPoint) -> CADEntityBase {
        let newPoints = points.map { $0 + offset }
        let newEntity = CADPolyline(layerID: layerID, points: newPoints, isClosed: isClosed)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func rotated(around center: CADPoint, by angle: Double) -> CADEntityBase {
        let newPoints = points.map { $0.rotated(around: center, by: angle) }
        let newEntity = CADPolyline(layerID: layerID, points: newPoints, isClosed: isClosed)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func scaled(around center: CADPoint, by factor: Double) -> CADEntityBase {
        let newPoints = points.map { $0.scaled(around: center, by: factor) }
        let newEntity = CADPolyline(layerID: layerID, points: newPoints, isClosed: isClosed)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth * factor
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func mirrored(about point: CADPoint) -> CADEntityBase {
        let newPoints = points.map { CADPoint(x: 2 * point.x - $0.x, y: 2 * point.y - $0.y) }
        let newEntity = CADPolyline(layerID: layerID, points: newPoints, isClosed: isClosed)
        newEntity.id = id
        newEntity.color = color
        newEntity.lineWidth = lineWidth
        newEntity.lineType = lineType
        return newEntity
    }
    
    override func contains(point: CADPoint, tolerance: Double) -> Bool {
        return distance(to: point) <= tolerance
    }
    
    override func distance(to point: CADPoint) -> Double {
        guard points.count >= 2 else {
            return points.first?.distance(to: point) ?? Double.greatestFiniteMagnitude
        }
        
        var minDistance = Double.greatestFiniteMagnitude
        
        for i in 0..<points.count - 1 {
            let line = CADLine(layerID: layerID, startPoint: points[i], endPoint: points[i + 1])
            minDistance = min(minDistance, line.distance(to: point))
        }
        
        if isClosed {
            let line = CADLine(layerID: layerID, startPoint: points.last!, endPoint: points.first!)
            minDistance = min(minDistance, line.distance(to: point))
        }
        
        return minDistance
    }
    
    override func nearestPoint(to point: CADPoint) -> CADPoint? {
        guard points.count >= 2 else {
            return points.first
        }
        
        var minDistance = Double.greatestFiniteMagnitude
        var nearestPoint: CADPoint?
        
        for i in 0..<points.count - 1 {
            let line = CADLine(layerID: layerID, startPoint: points[i], endPoint: points[i + 1])
            if let np = line.nearestPoint(to: point) {
                let dist = point.distance(to: np)
                if dist < minDistance {
                    minDistance = dist
                    nearestPoint = np
                }
            }
        }
        
        if isClosed {
            let line = CADLine(layerID: layerID, startPoint: points.last!, endPoint: points.first!)
            if let np = line.nearestPoint(to: point) {
                let dist = point.distance(to: np)
                if dist < minDistance {
                    nearestPoint = np
                }
            }
        }
        
        return nearestPoint
    }
    
    override func draw(in context: CGContext, transform: CGAffineTransform, displaySettings: DisplaySettings) {
        guard points.count >= 2 else { return }
        
        context.saveGState()
        context.setLineWidth(CGFloat(lineWidth))
        context.setStrokeColor((color ?? CADColor.black).nsColor.cgColor)
        context.setLineJoin(.round)
        context.setLineCap(.round)
        
        if lineType != .continuous {
            context.setLineDash(phase: 0, lengths: lineType.pattern.map { CGFloat($0) })
        }
        
        let path = CGMutablePath()
        path.move(to: CGPoint(x: points[0].x, y: points[0].y), transform: transform)
        
        for i in 1..<points.count {
            path.addLine(to: CGPoint(x: points[i].x, y: points[i].y), transform: transform)
        }
        
        if isClosed {
            path.closeSubpath()
        }
        
        context.addPath(path)
        context.strokePath()
        
        context.restoreGState()
    }
}
