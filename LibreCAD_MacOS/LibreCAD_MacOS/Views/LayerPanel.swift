//
//  LayerPanel.swift
//  LibreCAD_MacOS
//
//  Нижняя панель управления слоями с эффектом жидкого стекла
//

import SwiftUI

struct LayerPanel: View {
    @ObservedObject var document: CADDrawingDocument
    
    @State private var showingNewLayer = false
    @State private var newLayerName = ""
    @State private var newLayerColor = CADColor.black
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Заголовок
            HStack {
                Text("Слои")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingNewLayer = true }) {
                    Image(systemName: "plus")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
                .help("Добавить слой")
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            
            Divider()
            
            // Список слоев
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(document.layers) { layer in
                        LayerCell(layer: layer, 
                                 isSelected: layer.id == document.currentLayerID,
                                 onSelect: {
                            document.currentLayerID = layer.id
                        },
                                 onToggleVisibility: {
                            document.toggleLayerVisibility(id: layer.id)
                        },
                                 onDelete: {
                            document.removeLayer(id: layer.id)
                        })
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 50)
            
            Divider()
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
        .sheet(isPresented: $showingNewLayer) {
            NewLayerSheet(name: $newLayerName, 
                         color: Binding(
                            get: { Color(newLayerColor.nsColor) },
                            set { newLayerColor = CADColor(red: Double($0.components.red),
                                                           green: Double($0.components.green),
                                                           blue: Double($0.components.blue),
                                                           alpha: 1.0) }
                         ),
                         onCreate: {
                let layer = document.addLayer(name: newLayerName.isEmpty ? "Новый слой" : newLayerName, 
                                             color: newLayerColor)
                document.currentLayerID = layer.id
                newLayerName = ""
                showingNewLayer = false
            })
        }
    }
}

struct LayerCell: View {
    @ObservedObject var layer: CADLayer
    let isSelected: Bool
    let onSelect: () -> Void
    let onToggleVisibility: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Индикатор видимости
            Button(action: onToggleVisibility) {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash.fill")
                    .foregroundColor(layer.isVisible ? .accentColor : .secondary)
            }
            .buttonStyle(.plain)
            
            // Цвет слоя
            Circle()
                .fill(Color(layer.color.nsColor))
                .frame(width: 16, height: 16)
            
            // Имя слоя
            Text(layer.name)
                .font(.caption)
                .lineLimit(1)
            
            // Индикатор текущего слоя
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            // Кнопка удаления
            if !isSelected {
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(8)
        .onTapGesture {
            onSelect()
        }
        .frame(minWidth: 120)
    }
}

struct NewLayerSheet: View {
    @Binding var name: String
    @Binding var color: Color
    let onCreate: () -> Void
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Новый слой")
                .font(.title2)
                .fontWeight(.bold)
            
            TextField("Имя слоя", text: $name)
                .textFieldStyle(.roundedBorder)
            
            HStack {
                Text("Цвет:")
                ColorPicker("", selection: $color)
                    .labelsHidden()
            }
            
            HStack {
                Spacer()
                
                Button("Отмена") {
                    dismiss()
                }
                
                Button("Создать") {
                    onCreate()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .frame(width: 300)
    }
}

#Preview {
    LayerPanel(document: CADDrawingDocument())
        .frame(height: 100)
}
