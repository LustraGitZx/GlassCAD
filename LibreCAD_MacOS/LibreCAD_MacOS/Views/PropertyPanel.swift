//
//  PropertyPanel.swift
//  LibreCAD_MacOS
//
//  Правая панель свойств с эффектом жидкого стекла
//

import SwiftUI

struct PropertyPanel: View {
    @ObservedObject var document: CADDrawingDocument
    @ObservedObject var toolManager: CADToolManager
    
    var selectedEntities: [CADEntityBase] {
        document.selectedEntities
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок
            HStack {
                Text("Свойства")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !selectedEntities.isEmpty {
                    Text("\(selectedEntities.count) выбр.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Информация о выделении
                    if !selectedEntities.isEmpty {
                        SelectionInfoSection(entities: selectedEntities)
                        
                        Divider()
                        
                        // Геометрические свойства
                        GeometrySection(entities: selectedEntities)
                        
                        Divider()
                        
                        // Свойства слоя
                        LayerPropertiesSection(document: document)
                        
                        Divider()
                        
                        // Операции трансформации
                        TransformSection(document: document)
                    } else {
                        // Нет выделения
                        VStack(spacing: 12) {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("Нет выделения")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Выберите объект на холсте\nдля просмотра свойств")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                    
                    // Общие настройки документа
                    Divider()
                    
                    DocumentSettingsSection(document: document)
                }
                .padding()
            }
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

// MARK: - Sections

struct SelectionInfoSection: View {
    let entities: [CADEntityBase]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Выделение")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            ForEach(entities.prefix(3)) { entity in
                HStack {
                    Image(systemName: iconForEntityType(entity.entityType))
                        .foregroundColor(.accentColor)
                    Text(entity.entityType.rawValue)
                        .font(.caption)
                    Spacer()
                    Text(String(entity.id.uuidString.prefix(8)))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            if entities.count > 3 {
                Text("и еще \(entities.count - 3)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func iconForEntityType(_ type: EntityType) -> String {
        switch type {
        case .line: return "line"
        case .circle: return "circle"
        case .arc: return "circle.lefthalf.filled"
        case .rectangle: return "rectangle"
        case .polyline: return "pencil"
        case .text: return "textformat"
        default: return "shape"
        }
    }
}

struct GeometrySection: View {
    let entities: [CADEntityBase]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Геометрия")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let firstEntity = entities.first {
                LabeledContent("Тип") {
                    Text(firstEntity.entityType.rawValue)
                }
                
                LabeledContent("Слой") {
                    Text("Слой \(firstEntity.layerID.uuidString.prefix(8))")
                }
                
                LabeledContent("Толщина") {
                    TextField("", value: Binding(
                        get: { firstEntity.lineWidth },
                        set: { /* Обновить толщину */ }
                    ), format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                }
            }
        }
    }
}

struct LayerPropertiesSection: View {
    @ObservedObject var document: CADDrawingDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Текущий слой")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            if let layer = document.currentLayer {
                LabeledContent("Имя") {
                    Text(layer.name)
                }
                
                LabeledContent("Цвет") {
                    Circle()
                        .fill(Color(layer.color.nsColor))
                        .frame(width: 20, height: 20)
                }
                
                Toggle("Видимый", isOn: Binding(
                    get: { layer.isVisible },
                    set: { document.toggleLayerVisibility(id: layer.id) }
                ))
                
                Toggle("Заблокирован", isOn: Binding(
                    get: { layer.isLocked },
                    set: { document.setLayerLock(id: layer.id, locked: $0) }
                ))
            }
        }
    }
}

struct TransformSection: View {
    @ObservedObject var document: CADDrawingDocument
    
    @State private var moveOffset: Double = 10
    @State private var rotateAngle: Double = 45
    @State private var scaleFactor: Double = 1.5
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Трансформация")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            HStack {
                Button("Переместить") {
                    document.moveSelected(by: CADPoint(x: moveOffset, y: moveOffset))
                }
                .disabled(document.selectedEntityIDs.isEmpty)
                
                TextField("Смещение", value: $moveOffset, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            
            HStack {
                Button("Повернуть") {
                    if let bounds = document.bounds.first {
                        document.rotateSelected(around: bounds.center, by: rotateAngle)
                    }
                }
                .disabled(document.selectedEntityIDs.isEmpty)
                
                TextField("Угол", value: $rotateAngle, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
            
            HStack {
                Button("Масштаб") {
                    if let bounds = document.bounds.first {
                        document.scaleSelected(around: bounds.center, by: scaleFactor)
                    }
                }
                .disabled(document.selectedEntityIDs.isEmpty)
                
                TextField("Фактор", value: $scaleFactor, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
        }
    }
}

struct DocumentSettingsSection: View {
    @ObservedObject var document: CADDrawingDocument
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Настройки")
                .font(.subheadline)
                .fontWeight(.semibold)
            
            Toggle("Показывать сетку", isOn: $document.gridSettings.enabled)
            Toggle("Привязка к сетке", isOn: $document.gridSettings.snapToGrid)
            Toggle("Показывать координаты", isOn: $document.displaySettings.showCoordinates)
            Toggle("Сглаживание", isOn: $document.displaySettings.antiAliasing)
            
            HStack {
                Text("Шаг сетки:")
                TextField("", value: $document.gridSettings.spacingX, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
            }
        }
    }
}

#Preview {
    PropertyPanel(document: CADDrawingDocument(), toolManager: CADToolManager())
        .frame(width: 250)
}
