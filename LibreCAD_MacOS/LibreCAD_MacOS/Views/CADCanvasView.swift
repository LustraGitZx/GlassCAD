//
//  CADCanvasView.swift
//  LibreCAD_MacOS
//
//  Холст для черчения с поддержкой рендеринга и взаимодействия
//

import SwiftUI
import CoreGraphics
import AppKit

struct CADCanvasView: View {
    @ObservedObject var document: CADDrawingDocument
    @ObservedObject var toolManager: CADToolManager
    
    @State private var isDragging = false
    @State private var lastMousePosition: CADPoint = .zero
    @State private var rubberBandRect: SelectionBounds?
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Фон с эффектом жидкого стекла
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                    .edgesIgnoringSafeArea(.all)
                
                // Сетка
                if document.displaySettings.showGrid && document.gridSettings.enabled {
                    GridView(settings: document.gridSettings, 
                            zoomLevel: document.zoomLevel,
                            panOffset: document.panOffset)
                }
                
                // Холст для рисования
                CanvasRenderer(document: document, toolManager: toolManager)
                    .gesture(dragGesture(in: geometry.size))
                    .contextMenu {
                        contextMenu
                    }
                
                // Индикатор привязки
                if let snapPoint = toolManager.currentState?.startPoint, document.snapSettings.enabled {
                    SnapIndicator(point: snapPoint)
                }
                
                // Координаты курсора
                if document.displaySettings.showCoordinates {
                    CoordinateDisplay(position: lastMousePosition)
                        .position(x: geometry.size.width - 120, y: geometry.size.height - 30)
                }
            }
        }
        .onHover { hovering in
            if !hovering {
                NSCursor.arrow.pop()
            }
        }
    }
    
    private func dragGesture(in size: CGSize) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let currentPoint = screenToCAD(value.location, in: size)
                
                switch toolManager.currentTool {
                case .pan:
                    let delta = CADPoint(x: value.translation.width, y: -value.translation.height)
                    document.pan(by: delta)
                    
                case .select:
                    if isDragging {
                        rubberBandRect = SelectionBounds(
                            minX: min(lastMousePosition.x, currentPoint.x),
                            minY: min(lastMousePosition.y, currentPoint.y),
                            maxX: max(lastMousePosition.x, currentPoint.x),
                            maxY: max(lastMousePosition.y, currentPoint.y)
                        )
                    }
                    
                default:
                    if toolManager.currentState?.isActive == true {
                        let snappedPoint = document.snapPoint(currentPoint)
                        toolManager.updateDrawing(to: snappedPoint)
                    }
                }
                
                lastMousePosition = currentPoint
            }
            .onEnded { value in
                let currentPoint = screenToCAD(value.location, in: size)
                let snappedPoint = document.snapPoint(currentPoint)
                
                switch toolManager.currentTool {
                case .select:
                    if let rect = rubberBandRect {
                        document.selectInRect(rect)
                        rubberBandRect = nil
                    } else {
                        if let entity = document.entityAt(point: currentPoint) {
                            document.selectEntity(id: entity.id, addToSelection: NSEvent.modifierFlags.contains(.shift))
                        } else {
                            document.deselectAll()
                        }
                    }
                    
                case .line, .rectangle, .circle, .polyline:
                    if toolManager.currentState?.startPoint == nil {
                        toolManager.startDrawing(at: snappedPoint)
                    } else {
                        if let entity = toolManager.finishDrawing() {
                            entity.layerID = document.currentLayerID
                            document.addEntity(entity)
                        }
                    }
                    
                default:
                    break
                }
                
                isDragging = false
            }
    }
    
    private var contextMenu: some View {
        Group {
            Button("Отменить") {
                document.undo()
            }
            .disabled(!document.canUndo)
            
            Button("Повторить") {
                document.redo()
            }
            .disabled(!document.canRedo)
            
            Divider()
            
            Button("Выделить все") {
                // Выделение всех сущностей
            }
            
            Button("Снять выделение") {
                document.deselectAll()
            }
            
            Divider()
            
            Button("Удалить") {
                document.deleteSelected()
            }
            .disabled(document.selectedEntityIDs.isEmpty)
            
            Divider()
            
            Menu("Трансформация") {
                Button("Переместить") {
                    // Режим перемещения
                }
                
                Button("Повернуть") {
                    // Режим вращения
                }
                
                Button("Масштабировать") {
                    // Режим масштабирования
                }
                
                Button("Отразить") {
                    // Режим отражения
                }
            }
            
            Divider()
            
            Menu("Привязки") {
                ForEach(SnapMode.allCases, id: \.self) { mode in
                    Toggle(mode.rawValue, isOn: Binding(
                        get: { document.snapSettings.modes.contains(mode) },
                        set: { isEnabled in
                            if isEnabled {
                                document.snapSettings.modes.insert(mode)
                            } else {
                                document.snapSettings.modes.remove(mode)
                            }
                        }
                    ))
                }
            }
            
            Divider()
            
            Toggle("Сетка", isOn: $document.gridSettings.enabled)
            Toggle("Привязка к сетке", isOn: $document.gridSettings.snapToGrid)
        }
    }
    
    private func screenToCAD(_ point: CGPoint, in size: CGSize) -> CADPoint {
        let centerX = size.width / 2
        let centerY = size.height / 2
        
        return CADPoint(
            x: (point.x - centerX + document.panOffset.x) / document.zoomLevel,
            y: -(point.y - centerY + document.panOffset.y) / document.zoomLevel
        )
    }
}

// MARK: - Canvas Renderer

struct CanvasRenderer: NSViewRepresentable {
    @ObservedObject var document: CADDrawingDocument
    @ObservedObject var toolManager: CADToolManager
    
    func makeNSView(context: Context) -> CanvasView {
        let view = CanvasView()
        view.document = document
        view.toolManager = toolManager
        return view
    }
    
    func updateNSView(_ nsView: CanvasView, context: Context) {
        nsView.document = document
        nsView.toolManager = toolManager
        nsView.setNeedsDisplay(nsView.bounds)
    }
}

class CanvasView: NSView {
    var document: CADDrawingDocument?
    var toolManager: CADToolManager?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.white.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        guard let doc = document else { return }
        
        // Clear background
        context.setFillColor(NSColor.white.cgColor)
        context.fill(dirtyRect)
        
        // Draw grid
        drawGrid(in: context, bounds: dirtyRect, document: doc)
        
        // Draw entities
        for entity in doc.entities {
            if let layer = doc.layers.first(where: { $0.id == entity.layerID }), layer.isVisible {
                entity.draw(in: context, transform: CGAffineTransform.identity, displaySettings: doc.displaySettings)
            }
        }
        
        // Draw selection
        for entityId in doc.selectedEntityIds {
            if let entity = doc.entities.first(where: { $0.id == entityId }) {
                context.saveGState()
                context.setStrokeColor(NSColor.systemBlue.cgColor)
                context.setLineWidth(2.0)
                context.setLineDash(phase: 0, lengths: [5.0, 3.0])
                // Draw bounding box
                if let bounds = entity.bounds {
                    let rect = CGRect(x: bounds.minX, y: bounds.minY, width: bounds.maxX - bounds.minX, height: bounds.maxY - bounds.minY)
                    context.stroke(rect)
                }
                context.restoreGState()
            }
        }
    }
    
    private func drawGrid(in context: CGContext, bounds: NSRect, document: CADDrawingDocument) {
        let settings = document.gridSettings
        let zoomLevel = document.zoomLevel
        let panOffset = document.panOffset
        
        let centerX = bounds.width / 2
        let centerY = bounds.height / 2
        
        let spacingX = settings.spacingX * zoomLevel
        let spacingY = settings.spacingY * zoomLevel
        
        context.saveGState()
        context.setStrokeColor(NSColor.lightGray.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)
        
        // Vertical lines
        var x = centerX + panOffset.x.truncatingRemainder(dividingBy: spacingX)
        while x < bounds.width {
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: bounds.height))
            x += spacingX
        }
        
        // Horizontal lines
        var y = centerY + panOffset.y.truncatingRemainder(dividingBy: spacingY)
        while y < bounds.height {
            context.move(to: CGPoint(x: 0, y: y))
            context.addLine(to: CGPoint(x: bounds.width, y: y))
            y += spacingY
        }
        
        context.strokePath()
        context.restoreGState()
    }
}

// MARK: - Grid View

struct GridView: View {
    let settings: GridSettings
    let zoomLevel: Double
    let panOffset: CADPoint
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let centerX = geometry.size.width / 2
                let centerY = geometry.size.height / 2
                
                let spacingX = settings.spacingX * zoomLevel
                let spacingY = settings.spacingY * zoomLevel
                
                // Вертикальные линии
                var x = centerX + panOffset.x.truncatingRemainder(dividingBy: spacingX)
                while x < geometry.size.width {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    x += spacingX
                }
                
                x = centerX + panOffset.x.truncatingRemainder(dividingBy: spacingX)
                while x > 0 {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geometry.size.height))
                    x -= spacingX
                }
                
                // Горизонтальные линии
                var y = centerY + panOffset.y.truncatingRemainder(dividingBy: spacingY)
                while y < geometry.size.height {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y += spacingY
                }
                
                y = centerY + panOffset.y.truncatingRemainder(dividingBy: spacingY)
                while y > 0 {
                    path.move(to: CGPoint(x: 0, y: y))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: y))
                    y -= spacingY
                }
            }
            .stroke(settings.color.nsColor, lineWidth: 0.5)
        }
    }
}

// MARK: - Snap Indicator

struct SnapIndicator: View {
    let point: CADPoint
    
    var body: some View {
        Circle()
            .stroke(Color.blue, lineWidth: 2)
            .frame(width: 10, height: 10)
    }
}

// MARK: - Coordinate Display

struct CoordinateDisplay: View {
    let position: CADPoint
    
    var body: some View {
        Text(String(format: "X: %.2f\nY: %.2f", position.x, position.y))
            .font(.caption.monospaced())
            .foregroundColor(.secondary)
            .padding(8)
            .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
            .cornerRadius(8)
    }
}

// MARK: - Visual Effect View

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }
    
    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
