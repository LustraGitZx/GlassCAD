//  AppDelegate.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "AppDelegate.h"
#import "CADCanvasView.h"
#import "ToolboxPanel.h"
#import "LayerPanel.h"
#import "PropertyPanel.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Create main window with modern macOS style
    NSRect contentRect = NSMakeRect(100, 100, 1400, 900);
    
    self.window = [[NSWindow alloc] initWithContentRect:contentRect
                                              styleMask:NSWindowStyleMaskTitled |
                                                        NSWindowStyleMaskClosable |
                                                        NSWindowStyleMaskMiniaturizable |
                                                        NSWindowStyleMaskResizable |
                                                        NSWindowStyleMaskFullSizeContentView
                                        backing:NSBackingStoreBuffered
                                          defer:NO];
    
    self.window.title = @"LibreCAD";
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.movableByWindowBackground = YES;
    
    // Enable vibrant appearance for liquid glass effect
    self.window.appearance = [NSAppearance appearanceNamed:NSAppearanceNameVibrantLight];
    self.window.backgroundColor = [NSColor clearColor];
    
    // Create toolbar
    [self setupToolbar];
    self.window.toolbar = self.toolbar;
    
    // Create split view for panels and canvas
    [self setupInterface];
    
    [self.window makeKeyAndOrderFront:nil];
}

- (void)setupToolbar {
    self.toolbar = [[NSToolbar alloc] initWithIdentifier:@"MainToolbar"];
    self.toolbar.delegate = self;
    self.toolbar.displayMode = NSToolbarDisplayModeIconAndLabel;
    self.toolbar.showsBaselineSeparator = NO;
}

- (void)setupInterface {
    // Create main horizontal split view
    NSSplitView *mainSplitView = [[NSSplitView alloc] initWithFrame:self.window.contentView.bounds];
    mainSplitView.dividerStyle = NSSplitViewDividerStyleThin;
    mainSplitView.autosaveName = @"MainSplitView";
    
    // Left toolbox panel
    ToolboxPanel *toolboxPanel = [[ToolboxPanel alloc] initWithFrame:NSMakeRect(0, 0, 80, 600)];
    NSSplitViewItem *leftItem = [[NSSplitViewItem alloc] initWithView:toolboxPanel];
    leftItem.canCollapse = NO;
    leftItem.minimumThickness = 80;
    leftItem.maximumThickness = 120;
    [mainSplitView addArrangedSubview:toolboxPanel];
    
    // Center canvas area
    NSView *centerContainer = [[NSView alloc] initWithFrame:NSZeroRect];
    centerContainer.wantsLayer = YES;
    
    // Create CAD canvas view
    self.canvasView = [[CADCanvasView alloc] initWithFrame:centerContainer.bounds];
    self.canvasView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [centerContainer addSubview:self.canvasView];
    
    NSSplitViewItem *centerItem = [[NSSplitViewItem alloc] initWithView:centerContainer];
    centerItem.canCollapse = NO;
    [mainSplitView addArrangedSubview:centerContainer];
    
    // Right property panel
    PropertyPanel *propertyPanel = [[PropertyPanel alloc] initWithFrame:NSMakeRect(0, 0, 250, 600)];
    NSSplitViewItem *rightItem = [[NSSplitViewItem alloc] initWithView:propertyPanel];
    rightItem.canCollapse = YES;
    rightItem.minimumThickness = 200;
    rightItem.maximumThickness = 350;
    [mainSplitView addArrangedSubview:propertyPanel];
    
    // Add bottom layer panel
    LayerPanel *layerPanel = [[LayerPanel alloc] initWithFrame:NSMakeRect(0, 0, 800, 200)];
    NSSplitViewItem *bottomItem = [[NSSplitViewItem alloc] initWithView:layerPanel];
    bottomItem.canCollapse = YES;
    bottomItem.minimumThickness = 150;
    bottomItem.maximumThickness = 300;
    
    // Create vertical split for bottom panel
    NSSplitView *verticalSplit = [[NSSplitView alloc] initWithFrame:self.window.contentView.bounds];
    verticalSplit.orientation = NSVerticalUserInterfaceLayoutOrientation;
    [verticalSplit addArrangedSubview:mainSplitView];
    [verticalSplit addArrangedSubview:layerPanel];
    
    verticalSplit.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.window.contentView addSubview:verticalSplit];
}

#pragma mark - NSToolbarDelegate

- (NSArray<NSToolbarItemIdentifier> *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar {
    return @[
        NSToolbarSpaceItemIdentifier,
        @"NewFile",
        @"OpenFile",
        @"SaveFile",
        NSToolbarFlexibleSpaceItemIdentifier,
        @"SelectTool",
        @"LineTool",
        @"CircleTool",
        @"RectangleTool",
        @"ArcTool",
        @"TextTool",
        @"DimensionTool",
        NSToolbarFlexibleSpaceItemIdentifier,
        @"Undo",
        @"Redo",
        NSToolbarSpaceItemIdentifier
    ];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSToolbarItemIdentifier)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
    
    if ([itemIdentifier isEqualToString:@"NewFile"]) {
        item.label = @"New";
        item.image = [NSImage imageNamed:NSImageNameAddTemplate];
        item.action = @selector(newFile:);
    } else if ([itemIdentifier isEqualToString:@"OpenFile"]) {
        item.label = @"Open";
        item.image = [NSImage imageNamed:NSImageNameQuickLookTemplate];
        item.action = @selector(openFile:);
    } else if ([itemIdentifier isEqualToString:@"SaveFile"]) {
        item.label = @"Save";
        item.image = [NSImage imageNamed:NSImageNameSaveTemplate];
        item.action = @selector(saveFile:);
    } else if ([itemIdentifier isEqualToString:@"SelectTool"]) {
        item.label = @"Select";
        item.image = [NSImage imageNamed:NSImageNameTouchBarCursorPointer];
        item.action = @selector(selectTool:);
        item.tag = 1;
    } else if ([itemIdentifier isEqualToString:@"LineTool"]) {
        item.label = @"Line";
        item.image = [NSImage imageNamed:NSImageNameTouchBarRecordStartTemplate];
        item.action = @selector(lineTool:);
        item.tag = 2;
    } else if ([itemIdentifier isEqualToString:@"CircleTool"]) {
        item.label = @"Circle";
        item.image = [NSImage imageNamed:NSImageNameTouchBarRecordStartTemplate];
        item.action = @selector(circleTool:);
        item.tag = 3;
    } else if ([itemIdentifier isEqualToString:@"RectangleTool"]) {
        item.label = @"Rectangle";
        item.image = [NSImage imageNamed:NSImageNameTouchBarRecordStartTemplate];
        item.action = @selector(rectangleTool:);
        item.tag = 4;
    } else if ([itemIdentifier isEqualToString:@"ArcTool"]) {
        item.label = @"Arc";
        item.image = [NSImage imageNamed:NSImageNameTouchBarRecordStartTemplate];
        item.action = @selector(arcTool:);
        item.tag = 5;
    } else if ([itemIdentifier isEqualToString:@"TextTool"]) {
        item.label = @"Text";
        item.image = [NSImage imageNamed:NSImageNameTouchBarTextFont];
        item.action = @selector(textTool:);
        item.tag = 6;
    } else if ([itemIdentifier isEqualToString:@"DimensionTool"]) {
        item.label = @"Dimension";
        item.image = [NSImage imageNamed:NSImageNameTouchBarColorPickerSwatch];
        item.action = @selector(dimensionTool:);
        item.tag = 7;
    } else if ([itemIdentifier isEqualToString:@"Undo"]) {
        item.label = @"Undo";
        item.image = [NSImage imageNamed:NSImageNameUndoTemplate];
        item.action = @selector(undo:);
    } else if ([itemIdentifier isEqualToString:@"Redo"]) {
        item.label = @"Redo";
        item.image = [NSImage imageNamed:NSImageNameRedoTemplate];
        item.action = @selector(redo:);
    }
    
    return item;
}

#pragma mark - Actions

- (void)newFile:(id)sender {
    [self.canvasView newDocument];
}

- (void)openFile:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    openPanel.allowedContentTypes = @[@"org.librecad.dxf"];
    openPanel.beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSModalResponseOK) {
            [self.canvasView openFile:openPanel.URL];
        }
    }];
}

- (void)saveFile:(id)sender {
    [self.canvasView saveDocument];
}

- (void)selectTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolSelect];
}

- (void)lineTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolLine];
}

- (void)circleTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolCircle];
}

- (void)rectangleTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolRectangle];
}

- (void)arcTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolArc];
}

- (void)textTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolText];
}

- (void)dimensionTool:(id)sender {
    [self.canvasView setCurrentTool:kCADToolDimension];
}

- (void)undo:(id)sender {
    [self.canvasView undo];
}

- (void)redo:(id)sender {
    [self.canvasView redo];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
