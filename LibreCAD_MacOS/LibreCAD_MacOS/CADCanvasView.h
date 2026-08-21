//  CADCanvasView.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CADToolType) {
    kCADToolSelect = 0,
    kCADToolLine,
    kCADToolCircle,
    kCADToolRectangle,
    kCADToolArc,
    kCADToolText,
    kCADToolDimension,
    kCADToolMove,
    kCADToolCopy,
    kCADToolRotate,
    kCADToolScale,
    kCADToolTrim,
    kCADToolExtend,
    kCADToolOffset,
    kCADToolMirror,
    kCADToolArray,
    kCADToolFillet,
    kCADToolChamfer
};

@class CADEntity;
@class CADLayer;

@interface CADCanvasView : NSView

@property (nonatomic, assign) CADToolType currentTool;
@property (nonatomic, strong) NSMutableArray<CADLayer *> *layers;
@property (nonatomic, strong) CADLayer *currentLayer;
@property (nonatomic, assign) CGFloat zoomLevel;
@property (nonatomic, assign) NSPoint panOffset;

- (void)newDocument;
- (void)openFile:(NSURL *)url;
- (void)saveDocument;
- (void)setCurrentTool:(CADToolType)tool;
- (void)undo;
- (void)redo;
- (void)zoomIn;
- (void)zoomOut;
- (void)zoomExtents;
- (void)panBy:(NSPoint)delta;

@end
