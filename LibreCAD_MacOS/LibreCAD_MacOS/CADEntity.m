//  CADEntity.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "CADEntity.h"
#import "CADLayer.h"

@implementation CADEntity

- (instancetype)init {
    self = [super init];
    if (self) {
        _isVisible = YES;
        _selected = NO;
        _lineWidth = 1.0;
        _color = [NSColor blackColor];
    }
    return self;
}

- (instancetype)initLineFromPoint:(NSPoint)start toPoint:(NSPoint)end {
    self = [self init];
    if (self) {
        _type = kCADEntityLine;
        _startPoint = start;
        _endPoint = end;
        [self updatePath];
    }
    return self;
}

- (instancetype)initCircleWithCenter:(NSPoint)center radius:(CGFloat)radius {
    self = [self init];
    if (self) {
        _type = kCADEntityCircle;
        _centerPoint = center;
        _radius = radius;
        [self updatePath];
    }
    return self;
}

- (instancetype)initArcWithCenter:(NSPoint)center radius:(CGFloat)radius startAngle:(CGFloat)startAngle endAngle:(CGFloat)endAngle {
    self = [self init];
    if (self) {
        _type = kCADEntityArc;
        _centerPoint = center;
        _radius = radius;
        _startAngle = startAngle;
        _endAngle = endAngle;
        [self updatePath];
    }
    return self;
}

- (instancetype)initRectangleWithOrigin:(NSPoint)origin size:(NSSize)size {
    self = [self init];
    if (self) {
        _type = kCADEntityRectangle;
        _originPoint = origin;
        _size = size;
        [self updatePath];
    }
    return self;
}

- (void)updatePath {
    UIBezierPath *newPath = [UIBezierPath bezierPath];
    
    switch (_type) {
        case kCADEntityLine:
            [newPath moveToPoint:_startPoint];
            [newPath addLineToPoint:_endPoint];
            break;
            
        case kCADEntityCircle:
            [newPath appendPath:[UIBezierPath bezierPathWithOvalInRect:NSMakeRect(
                _centerPoint.x - _radius,
                _centerPoint.y - _radius,
                _radius * 2,
                _radius * 2
            )]];
            break;
            
        case kCADEntityArc:
            [newPath addArcWithCenter:_centerPoint
                               radius:_radius
                           startAngle:_startAngle
                             endAngle:_endAngle
                            clockwise:YES];
            break;
            
        case kCADEntityRectangle:
            [newPath appendPath:[UIBezierPath bezierPathWithRect:NSMakeRect(
                _originPoint.x,
                _originPoint.y,
                _size.width,
                _size.height
            )]];
            break;
            
        default:
            break;
    }
    
    _path = newPath;
}

- (void)removeFromLayer {
    if (_layer) {
        [_layer removeEntity:self];
        _layer = nil;
    }
}

- (BOOL)containsPoint:(NSPoint)point {
    if (!_path) return NO;
    return [_path containsPoint:point];
}

@end
