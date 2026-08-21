//  CADEntity.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, CADEntityType) {
    kCADEntityLine,
    kCADEntityCircle,
    kCADEntityArc,
    kCADEntityRectangle,
    kCADEntityPolyline,
    kCADEntityText,
    kCADEntityDimension,
    kCADEntityPoint,
    kCADEntitySpline,
    kCADEntityEllipse,
    kCADEntityHatch
};

@class CADLayer;

@interface CADEntity : NSObject

@property (nonatomic, assign) CADEntityType type;
@property (nonatomic, strong) CADLayer *layer;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL selected;
@property (nonatomic, strong) UIBezierPath *path;

// Line properties
@property (nonatomic, assign) NSPoint startPoint;
@property (nonatomic, assign) NSPoint endPoint;

// Circle/Arc properties
@property (nonatomic, assign) NSPoint centerPoint;
@property (nonatomic, assign) CGFloat radius;
@property (nonatomic, assign) CGFloat startAngle;
@property (nonatomic, assign) CGFloat endAngle;

// Rectangle properties
@property (nonatomic, assign) NSPoint originPoint;
@property (nonatomic, assign) NSSize size;

// Text properties
@property (nonatomic, strong) NSString *text;
@property (nonatomic, strong) NSFont *font;

// Initialization methods
- (instancetype)initLineFromPoint:(NSPoint)start toPoint:(NSPoint)end;
- (instancetype)initCircleWithCenter:(NSPoint)center radius:(CGFloat)radius;
- (instancetype)initArcWithCenter:(NSPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle;
- (instancetype)initRectangleWithOrigin:(NSPoint)origin size:(NSSize)size;

// Layer management
- (void)removeFromLayer;

// Hit testing
- (BOOL)containsPoint:(NSPoint)point;

@end
