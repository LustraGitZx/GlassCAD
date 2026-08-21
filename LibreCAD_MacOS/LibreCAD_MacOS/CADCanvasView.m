//  CADCanvasView.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "CADCanvasView.h"
#import "CADEntity.h"
#import "CADLayer.h"

@interface CADCanvasView () {
    NSMutableArray *entities;
    NSMutableArray *undoStack;
    NSMutableArray *redoStack;
    NSPoint lastMouseLocation;
    BOOL isDragging;
    NSTrackingArea *trackingArea;
}
@property (nonatomic, strong) CAShapeLayer *gridLayer;
@property (nonatomic, strong) CAShapeLayer *entitiesLayer;
@property (nonatomic, strong) CAShapeLayer *selectionLayer;
@property (nonatomic, strong) NSTimer *renderTimer;
@end

@implementation CADCanvasView

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupView];
    }
    return self;
}

- (void)setupView {
    self.wantsLayer = YES;
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
    
    // Modern macOS appearance with liquid glass effect
    self.layer.backgroundColor = [NSColor whiteColor].CGColor;
    self.layer.cornerRadius = 0;
    
    // Enable layer blending for smooth rendering
    self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;
    
    // Initialize arrays
    entities = [[NSMutableArray alloc] init];
    undoStack = [[NSMutableArray alloc] init];
    redoStack = [[NSMutableArray alloc] init];
    layers = [[NSMutableArray alloc] init];
    
    // Create default layer
    CADLayer *defaultLayer = [[CADLayer alloc] initWithName:@"0"];
    [layers addObject:defaultLayer];
    self.currentLayer = defaultLayer;
    
    // Setup properties
    self.zoomLevel = 1.0;
    self.panOffset = NSMakePoint(0, 0);
    self.currentTool = kCADToolSelect;
    
    isDragging = NO;
    
    // Setup grid layer
    self.gridLayer = [CAShapeLayer layer];
    self.gridLayer.frame = self.bounds;
    self.gridLayer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
    [self.layer addSublayer:self.gridLayer];
    
    // Setup entities layer
    self.entitiesLayer = [CAShapeLayer layer];
    self.entitiesLayer.frame = self.bounds;
    self.entitiesLayer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
    [self.layer addSublayer:self.entitiesLayer];
    
    // Setup selection layer
    self.selectionLayer = [CAShapeLayer layer];
    self.selectionLayer.frame = self.bounds;
    self.selectionLayer.contentsScale = [NSScreen mainScreen].backingScaleFactor;
    [self.layer addSublayer:self.selectionLayer];
    
    // Draw initial grid
    [self drawGrid];
}

- (void)updateTrackingAreas {
    [super updateTrackingAreas];
    
    if (trackingArea) {
        [self removeTrackingArea:trackingArea];
        trackingArea = nil;
    }
    
    NSTrackingAreaOptions options = NSTrackingMouseMoved | 
                                     NSTrackingActiveInKeyWindow |
                                     NSTrackingInVisibleRect;
    
    trackingArea = [[NSTrackingArea alloc] initWithRect:self.bounds
                                                options:options
                                                  owner:self
                                               userInfo:nil];
    [self addTrackingArea:trackingArea];
}

- (void)mouseDown:(NSEvent *)event {
    lastMouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    isDragging = YES;
    
    if (self.currentTool == kCADToolSelect) {
        [self handleSelectionAtPoint:lastMouseLocation];
    } else {
        [self startDrawingAtPoint:lastMouseLocation];
    }
}

- (void)mouseDragged:(NSEvent *)event {
    if (!isDragging) return;
    
    NSPoint currentPoint = [self convertPoint:[event locationInWindow] fromView:nil];
    NSPoint delta = NSMakePoint(currentPoint.x - lastMouseLocation.x,
                                currentPoint.y - lastMouseLocation.y);
    
    if ([event modifierFlags] & NSEventModifierFlagShift) {
        // Pan operation
        [self panBy:delta];
    } else {
        // Drawing operation
        [self continueDrawingAtPoint:currentPoint];
    }
    
    lastMouseLocation = currentPoint;
}

- (void)mouseUp:(NSEvent *)event {
    isDragging = NO;
    [self finishDrawing];
}

- (void)scrollWheel:(NSEvent *)event {
    CGFloat delta = [event scrollingDeltaY];
    if (delta > 0) {
        [self zoomIn];
    } else {
        [self zoomOut];
    }
}

- (void)drawGrid {
    UIBezierPath *gridPath = [UIBezierPath bezierPath];
    CGFloat gridSize = 20.0 * self.zoomLevel;
    CGFloat majorGridSize = gridSize * 5;
    
    // Light gray color for grid
    UIColor *gridColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0];
    UIColor *majorGridColor = [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1.0];
    
    NSInteger countX = ceil(self.bounds.size.width / gridSize);
    NSInteger countY = ceil(self.bounds.size.height / gridSize);
    
    // Draw minor grid lines
    [gridColor setStroke];
    gridPath.lineWidth = 0.5;
    
    for (NSInteger i = -countX; i <= countX; i++) {
        CGFloat x = self.bounds.size.width / 2 + self.panOffset.x + (i * gridSize);
        [gridPath moveToPoint:CGPointMake(x, 0)];
        [gridPath addLineToPoint:CGPointMake(x, self.bounds.size.height)];
    }
    
    for (NSInteger i = -countY; i <= countY; i++) {
        CGFloat y = self.bounds.size.height / 2 + self.panOffset.y + (i * gridSize);
        [gridPath moveToPoint:CGPointMake(0, y)];
        [gridPath addLineToPoint:CGPointMake(self.bounds.size.width, y)];
    }
    
    [gridPath stroke];
    
    // Draw major grid lines
    UIBezierPath *majorGridPath = [UIBezierPath bezierPath];
    [majorGridColor setStroke];
    majorGridPath.lineWidth = 1.0;
    
    for (NSInteger i = -countX / 5; i <= countX / 5; i++) {
        CGFloat x = self.bounds.size.width / 2 + self.panOffset.x + (i * majorGridSize);
        [majorGridPath moveToPoint:CGPointMake(x, 0)];
        [majorGridPath addLineToPoint:CGPointMake(x, self.bounds.size.height)];
    }
    
    for (NSInteger i = -countY / 5; i <= countY / 5; i++) {
        CGFloat y = self.bounds.size.height / 2 + self.panOffset.y + (i * majorGridSize);
        [majorGridPath moveToPoint:CGPointMake(0, y)];
        [majorGridPath addLineToPoint:CGPointMake(self.bounds.size.width, y)];
    }
    
    [majorGridPath stroke];
    
    self.gridLayer.path = gridPath.CGPath;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Core drawing happens in layers for performance
    [self drawGrid];
    [self renderEntities];
}

- (void)renderEntities {
    CGMutablePathRef entitiesPath = CGPathCreateMutable();
    
    for (CADEntity *entity in entities) {
        if (entity.isVisible) {
            CGPathAddPath(entitiesPath, NULL, entity.path.CGPath);
        }
    }
    
    self.entitiesLayer.path = entitiesPath;
    CGPathRelease(entitiesPath);
}

#pragma mark - Drawing Operations

- (void)startDrawingAtPoint:(NSPoint)point {
    // Implement based on current tool
    switch (self.currentTool) {
        case kCADToolLine:
            [self startLineAtPoint:point];
            break;
        case kCADToolCircle:
            [self startCircleAtPoint:point];
            break;
        case kCADToolRectangle:
            [self startRectangleAtPoint:point];
            break;
        case kCADToolArc:
            [self startArcAtPoint:point];
            break;
        default:
            break;
    }
}

- (void)continueDrawingAtPoint:(NSPoint)point {
    switch (self.currentTool) {
        case kCADToolLine:
            [self updateLineToPoint:point];
            break;
        case kCADToolCircle:
            [self updateCircleToPoint:point];
            break;
        case kCADToolRectangle:
            [self updateRectangleToPoint:point];
            break;
        case kCADToolArc:
            [self updateArcToPoint:point];
            break;
        default:
            break;
    }
}

- (void)finishDrawing {
    // Finalize the current drawing operation
    [self commitCurrentEntity];
}

- (void)startLineAtPoint:(NSPoint)point {
    // Create new line entity
    CADEntity *line = [[CADEntity alloc] initLineFromPoint:point toPoint:point];
    line.layer = self.currentLayer;
    [self.currentLayer addEntity:line];
}

- (void)updateLineToPoint:(NSPoint)point {
    // Update current line endpoint
    if (self.currentLayer.entities.count > 0) {
        CADEntity *currentEntity = self.currentLayer.entities.lastObject;
        if (currentEntity.type == kCADEntityLine) {
            currentEntity.endPoint = point;
            [self renderEntities];
        }
    }
}

- (void)startCircleAtPoint:(NSPoint)point {
    // Create new circle entity
    CADEntity *circle = [[CADEntity alloc] initCircleWithCenter:point radius:0];
    circle.layer = self.currentLayer;
    [self.currentLayer addEntity:circle];
}

- (void)updateCircleToPoint:(NSPoint)point {
    // Update circle radius
    if (self.currentLayer.entities.count > 0) {
        CADEntity *currentEntity = self.currentLayer.entities.lastObject;
        if (currentEntity.type == kCADEntityCircle) {
            CGFloat dx = point.x - currentEntity.centerPoint.x;
            CGFloat dy = point.y - currentEntity.centerPoint.y;
            currentEntity.radius = sqrt(dx * dx + dy * dy);
            [self renderEntities];
        }
    }
}

- (void)startRectangleAtPoint:(NSPoint)point {
    // Create new rectangle entity
    CADEntity *rect = [[CADEntity alloc] initRectangleWithOrigin:point size:NSZeroSize];
    rect.layer = self.currentLayer;
    [self.currentLayer addEntity:rect];
}

- (void)updateRectangleToPoint:(NSPoint)point {
    // Update rectangle size
    if (self.currentLayer.entities.count > 0) {
        CADEntity *currentEntity = self.currentLayer.entities.lastObject;
        if (currentEntity.type == kCADEntityRectangle) {
            currentEntity.size = NSMakeSize(point.x - currentEntity.originPoint.x,
                                           point.y - currentEntity.originPoint.y);
            [self renderEntities];
        }
    }
}

- (void)startArcAtPoint:(NSPoint)point {
    // Create new arc entity
    CADEntity *arc = [[CADEntity alloc] initArcWithCenter:point radius:0 startAngle:0 endAngle:0];
    arc.layer = self.currentLayer;
    [self.currentLayer addEntity:arc];
}

- (void)updateArcToPoint:(NSPoint)point {
    // Update arc parameters
    if (self.currentLayer.entities.count > 0) {
        CADEntity *currentEntity = self.currentLayer.entities.lastObject;
        if (currentEntity.type == kCADEntityArc) {
            CGFloat dx = point.x - currentEntity.centerPoint.x;
            CGFloat dy = point.y - currentEntity.centerPoint.y;
            currentEntity.radius = sqrt(dx * dx + dy * dy);
            currentEntity.endAngle = atan2(dy, dx);
            [self renderEntities];
        }
    }
}

- (void)commitCurrentEntity {
    // Push to undo stack
    if (undoStack.count > 50) {
        [undoStack removeObjectAtIndex:0];
    }
    [undoStack addObject:[self.currentLayer.entities lastObject]];
    [redoStack removeAllObjects];
}

#pragma mark - Tool Actions

- (void)newDocument {
    [entities removeAllObjects];
    [undoStack removeAllObjects];
    [redoStack removeAllObjects];
    
    // Clear all layers except default
    CADLayer *defaultLayer = [[CADLayer alloc] initWithName:@"0"];
    [layers removeAllObjects];
    [layers addObject:defaultLayer];
    self.currentLayer = defaultLayer;
    
    self.zoomLevel = 1.0;
    self.panOffset = NSMakePoint(0, 0);
    
    [self renderEntities];
    [self drawGrid];
}

- (void)openFile:(NSURL *)url {
    // TODO: Implement DXF file loading
    NSLog(@"Opening file: %@", url);
}

- (void)saveDocument {
    // TODO: Implement DXF file saving
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    savePanel.allowedContentTypes = @[@"org.librecad.dxf"];
    savePanel.nameFieldStringValue = @"drawing.dxf";
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            NSLog(@"Saving to: %@", savePanel.URL);
        }
    }];
}

- (void)setCurrentTool:(CADToolType)tool {
    self.currentTool = tool;
}

- (void)undo {
    if (undoStack.count > 0) {
        CADEntity *entity = [undoStack lastObject];
        [undoStack removeLastObject];
        [redoStack addObject:entity];
        [entity removeFromLayer];
        [self renderEntities];
    }
}

- (void)redo {
    if (redoStack.count > 0) {
        CADEntity *entity = [redoStack lastObject];
        [redoStack removeLastObject];
        [undoStack addObject:entity];
        [entity.layer addEntity:entity];
        [self renderEntities];
    }
}

- (void)zoomIn {
    self.zoomLevel *= 1.2;
    [self drawGrid];
    [self renderEntities];
}

- (void)zoomOut {
    self.zoomLevel /= 1.2;
    [self drawGrid];
    [self renderEntities];
}

- (void)zoomExtents {
    // Calculate extents of all entities and fit to view
    self.zoomLevel = 1.0;
    self.panOffset = NSMakePoint(0, 0);
    [self drawGrid];
    [self renderEntities];
}

- (void)panBy:(NSPoint)delta {
    self.panOffset = NSMakePoint(self.panOffset.x + delta.x,
                                 self.panOffset.y + delta.y);
    [self drawGrid];
    [self renderEntities];
}

- (void)handleSelectionAtPoint:(NSPoint)point {
    // Find and select entity at point
    for (CADEntity *entity in entities) {
        if ([entity containsPoint:point]) {
            entity.selected = !entity.selected;
            [self renderEntities];
            break;
        }
    }
}

@end
