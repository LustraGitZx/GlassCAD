# LibreCAD for macOS - Modern Redesign

## Overview
This is a complete redesign of LibreCAD for macOS with a modern, clean interface following macOS design guidelines with liquid glass (vibrant) effects.

## Features

### Modern macOS Interface
- **Liquid Glass Effect**: Uses NSVisualEffectView with vibrant materials for panels
- **Clean Design**: Minimalist toolbar and panel design
- **Native Controls**: Standard macOS buttons, tables, and controls
- **Full-Screen Support**: Native macOS full-screen mode
- **Retina Display**: High-DPI support for crisp rendering

### 2D CAD Tools
- **Drawing Tools**: Line, Circle, Rectangle, Arc, Text
- **Modification Tools**: Move, Copy, Rotate, Scale, Trim, Offset, Mirror
- **Selection**: Point-and-click entity selection
- **Layers**: Full layer management with visibility controls
- **Properties**: Entity property inspection and editing

### Interface Components
1. **Main Toolbar**: File operations and tool selection
2. **Toolbox Panel** (Left): Quick access to drawing tools with vibrant background
3. **Canvas** (Center): Drawing area with grid and entity rendering
4. **Property Panel** (Right): Entity properties table
5. **Layer Panel** (Bottom): Layer management with add/delete/edit functions

## Project Structure

```
LibreCAD_MacOS/
├── LibreCAD_MacOS.xcodeproj/    # Xcode project file
└── LibreCAD_MacOS/              # Source code
    ├── main.m                   # Application entry point
    ├── AppDelegate.h/m          # Main application delegate
    ├── CADCanvasView.h/m        # Main drawing canvas
    ├── CADEntity.h/m            # Entity base class
    ├── CADLayer.h/m             # Layer management
    ├── ToolboxPanel.h/m         # Left tool panel
    ├── PropertyPanel.h/m        # Right property panel
    ├── LayerPanel.h/m           # Bottom layer panel
    └── Info.plist               # App configuration
```

## Requirements
- macOS 13.0 or later
- Xcode 15.0 or later
- Apple Silicon (M1/M2) or Intel Mac

## Building

1. Open `LibreCAD_MacOS.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build and Run (⌘R)

## Usage

### Drawing
1. Select a tool from the toolbar or toolbox panel
2. Click and drag on the canvas to draw
3. Use scroll wheel to zoom
4. Hold Shift + drag to pan

### Layers
1. Use + button to add new layer
2. Toggle visibility with checkbox
3. Select layer to make it current

### Properties
1. Select an entity on the canvas
2. View/edit properties in the right panel

## Design Philosophy

The interface follows these key principles:

1. **Clarity**: Clean, uncluttered interface with clear visual hierarchy
2. **Deference**: Content takes center stage, UI recedes
3. **Depth**: Layered interface with subtle shadows and blur effects
4. **Fluidity**: Smooth animations and transitions

## License

Based on LibreCAD original source code.
See original LICENSE file for details.

## Note

This is a native macOS rewrite focusing on modern UI/UX. The original LibreCAD Qt-based code remains available in the libreCAD_original directory for reference.
