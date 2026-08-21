//
//  ToolboxPanel.swift
//  LibreCAD_MacOS
//
//  Левая панель инструментов с эффектом жидкого стекла
//

import SwiftUI

struct ToolboxPanel: View {
    @ObservedObject var toolManager: CADToolManager
    @ObservedObject var document: CADDrawingDocument
    
    let columns = [GridItem(.fixed(60))]
    
    var body: some View {
        VStack(spacing: 8) {
            // Заголовок
            Text("Инструменты")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            Divider()
            
            // Сетка инструментов
            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(CADToolType.allCases) { tool in
                        ToolButton(tool: tool, 
                                  isSelected: toolManager.currentTool == tool,
                                  action: {
                            toolManager.activateTool(tool)
                            document.currentTool = tool
                        })
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Настройки линий
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                
                Text("Свойства")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                
                // Толщина линии
                HStack {
                    Image(systemName: "line.3.horizontal")
                        .font(.caption)
                    TextField("", value: $toolManager.lineWidth, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                }
                
                // Тип линии
                Menu {
                    ForEach(CADLineType.allCases, id: \.self) { lineType in
                        Button(lineType.rawValue) {
                            toolManager.lineType = lineType
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "line.3.horizontal.decrease")
                            .font(.caption)
                        Text(toolManager.lineType.rawValue)
                            .font(.caption)
                            .lineLimit(1)
                    }
                }
                .buttonStyle(.bordered)
                
                // Цвет линии
                ColorPicker("Цвет", selection: Binding(
                    get: { Color(toolManager.lineColor.nsColor) },
                    set { toolManager.lineColor = CADColor(red: Double($0.components.red),
                                                           green: Double($0.components.green),
                                                           blue: Double($0.components.blue),
                                                           alpha: Double($0.components.alpha)) }
                ))
                .labelsHidden()
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(VisualEffectView(material: .sidebar, blendingMode: .behindWindow))
    }
}

struct ToolButton: View {
    let tool: CADToolType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: tool.icon)
                    .font(.system(size: 20))
                Text(tool.displayName)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(width: 60, height: 60)
            .background(isSelected ? Color.accentColor.opacity(0.3) : Color.clear)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .help(tool.displayName)
    }
}

#Preview {
    ToolboxPanel(toolManager: CADToolManager(), document: CADDrawingDocument())
        .frame(width: 80)
}
