//
//  CADLayer.swift
//  LibreCAD_MacOS
//
//  Класс слоя для организации сущностей
//

import Foundation

/// Класс слоя
class CADLayer: Codable, Identifiable, Equatable, ObservableObject {
    var id: UUID
    @Published var name: String
    @Published var color: CADColor
    @Published var lineWidth: Double
    @Published var lineType: CADLineType
    @Published var isVisible: Bool
    @Published var isLocked: Bool
    @Published var opacity: Double
    
    init(id: UUID = UUID(), name: String, color: CADColor = .black, 
         lineWidth: Double = 1.0, lineType: CADLineType = .continuous,
         isVisible: Bool = true, isLocked: Bool = false, opacity: Double = 1.0) {
        self.id = id
        self.name = name
        self.color = color
        self.lineWidth = lineWidth
        self.lineType = lineType
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.opacity = opacity
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, color, lineWidth, lineType, isVisible, isLocked, opacity
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        color = try container.decode(CADColor.self, forKey: .color)
        lineWidth = try container.decode(Double.self, forKey: .lineWidth)
        lineType = try container.decode(CADLineType.self, forKey: .lineType)
        isVisible = try container.decode(Bool.self, forKey: .isVisible)
        isLocked = try container.decode(Bool.self, forKey: .isLocked)
        opacity = try container.decode(Double.self, forKey: .opacity)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(color, forKey: .color)
        try container.encode(lineWidth, forKey: .lineWidth)
        try container.encode(lineType, forKey: .lineType)
        try container.encode(isVisible, forKey: .isVisible)
        try container.encode(isLocked, forKey: .isLocked)
        try container.encode(opacity, forKey: .opacity)
    }
    
    static func == (lhs: CADLayer, rhs: CADLayer) -> Bool {
        return lhs.id == rhs.id
    }
}
