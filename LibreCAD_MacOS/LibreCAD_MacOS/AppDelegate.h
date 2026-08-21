//  AppDelegate.h
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSWindow *window;
@property (strong, nonatomic) CADCanvasView *canvasView;
@property (strong, nonatomic) NSToolbar *toolbar;

@end
