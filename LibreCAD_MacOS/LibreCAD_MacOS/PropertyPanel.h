//  PropertyPanel.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PropertyPanel : NSView

@property (nonatomic, strong) NSTableView *propertiesTable;
@property (nonatomic, strong) NSArrayController *propertiesController;

@end
