//  CADLayer.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class CADEntity;

@interface CADLayer : NSObject

@property (nonatomic, copy) NSString *name;
@property (nonatomic, strong) NSColor *color;
@property (nonatomic, assign) BOOL isVisible;
@property (nonatomic, assign) BOOL isLocked;
@property (nonatomic, assign) CGFloat lineWidth;
@property (nonatomic, strong) NSMutableArray<CADLayer *> *entities;

- (instancetype)initWithName:(NSString *)name;
- (void)addEntity:(CADEntity *)entity;
- (void)removeEntity:(CADEntity *)entity;
- (void)clear;

@end
