//  CADLayer.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "CADLayer.h"
#import "CADEntity.h"

@implementation CADLayer

- (instancetype)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
        _name = [name copy];
        _isVisible = YES;
        _isLocked = NO;
        _lineWidth = 1.0;
        _color = [NSColor blackColor];
        _entities = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addEntity:(CADEntity *)entity {
    if (!_isLocked && _isVisible) {
        entity.layer = self;
        [_entities addObject:entity];
    }
}

- (void)removeEntity:(CADEntity *)entity {
    [_entities removeObject:entity];
}

- (void)clear {
    [_entities removeAllObjects];
}

@end
