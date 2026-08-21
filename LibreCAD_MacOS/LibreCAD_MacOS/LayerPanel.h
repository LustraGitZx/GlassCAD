//  LayerPanel.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface LayerPanel : NSView

@property (nonatomic, strong) NSTableView *layerTable;
@property (nonatomic, strong) NSArrayController *layerController;

- (void)refreshLayers;

@end
