//  ToolboxPanel.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ToolboxPanel : NSView

@property (nonatomic, strong) NSStackView *toolButtons;
@property (nonatomic, assign) NSInteger selectedToolIndex;

- (void)selectTool:(NSInteger)index;

@end
