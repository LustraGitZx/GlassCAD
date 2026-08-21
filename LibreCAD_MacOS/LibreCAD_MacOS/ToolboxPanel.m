//  ToolboxPanel.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "ToolboxPanel.h"

@interface ToolboxPanel () <NSStackViewDelegate>
@property (nonatomic, strong) NSArray *toolIcons;
@property (nonatomic, strong) NSArray *toolNames;
@end

@implementation ToolboxPanel

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupPanel];
    }
    return self;
}

- (void)setupPanel {
    // Modern macOS vibrant appearance for liquid glass effect
    self.wantsLayer = YES;
    self.layer.backgroundColor = [[NSColor colorWithWhite:1.0 alpha:0.3] CGColor];
    self.layer.cornerRadius = 8.0;
    
    // Enable backdrop blur for liquid glass effect
    NSVisualEffectView *visualEffect = [[NSVisualEffectView alloc] initWithFrame:self.bounds];
    visualEffect.material = NSVisualEffectMaterialSidebar;
    visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    visualEffect.state = NSVisualEffectStateActive;
    visualEffect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:visualEffect positioned:NSWindowBelow relativeTo:nil];
    
    // Tool icons and names
    _toolIcons = @[
        @"Select",
        @"Line",
        @"Circle",
        @"Rectangle",
        @"Arc",
        @"Text",
        @"Dimension",
        @"Move",
        @"Copy",
        @"Rotate",
        @"Scale",
        @"Trim",
        @"Offset",
        @"Mirror"
    ];
    
    _toolNames = @[
        @"Select",
        @"Line",
        @"Circle",
        @"Rectangle",
        @"Arc",
        @"Text",
        @"Dimension",
        @"Move",
        @"Copy",
        @"Rotate",
        @"Scale",
        @"Trim",
        @"Offset",
        @"Mirror"
    ];
    
    // Create stack view for tool buttons
    _toolButtons = [[NSStackView alloc] initWithFrame:NSMakeRect(10, 10, frameRect.size.width - 20, frameRect.size.height - 20)];
    _toolButtons.orientation = NSUserInterfaceLayoutOrientationVertical;
    _toolButtons.spacing = 4.0;
    _toolButtons.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self addSubview:_toolButtons];
    
    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        [_toolButtons.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
        [_toolButtons.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        [_toolButtons.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [_toolButtons.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10]
    ]];
    
    // Create tool buttons
    [self createToolButtons];
    
    _selectedToolIndex = 0;
}

- (void)createToolButtons {
    for (NSInteger i = 0; i < _toolIcons.count; i++) {
        NSButton *button = [self createToolButtonWithTitle:_toolNames[i] index:i];
        [_toolButtons addArrangedSubview:button];
    }
}

- (NSButton *)createToolButtonWithTitle:(NSString *)title index:(NSInteger)index {
    NSButton *button = [[NSButton alloc] init];
    button.title = title;
    button.tag = index;
    button.target = self;
    button.action = @selector(toolButtonClicked:);
    button.bezelStyle = NSBezelStyleRounded;
    
    // Modern button styling
    button.wantsLayer = YES;
    button.layer.cornerRadius = 6.0;
    button.contentTintColor = [NSColor labelColor];
    
    // Set initial state
    if (index == 0) {
        button.state = NSControlStateValueOn;
        button.layer.backgroundColor = [[NSColor systemBlueColor] CGColor];
    } else {
        button.state = NSControlStateValueOff;
        button.layer.backgroundColor = [[NSColor clearColor] CGColor];
    }
    
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button.heightAnchor constraintEqualToConstant:32].active = YES;
    
    return button;
}

- (void)toolButtonClicked:(NSButton *)sender {
    [self selectTool:sender.tag];
}

- (void)selectTool:(NSInteger)index {
    _selectedToolIndex = index;
    
    // Update button states
    for (NSInteger i = 0; i < _toolButtons.arrangedSubviews.count; i++) {
        NSView *view = _toolButtons.arrangedSubviews[i];
        if ([view isKindOfClass:[NSButton class]]) {
            NSButton *button = (NSButton *)view;
            if (i == index) {
                button.state = NSControlStateValueOn;
                button.layer.backgroundColor = [[NSColor systemBlueColor] CGColor];
            } else {
                button.state = NSControlStateValueOff;
                button.layer.backgroundColor = [[NSColor clearColor] CGColor];
            }
        }
    }
    
    // Notify delegate or post notification
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ToolChangedNotification"
                                                        object:self
                                                      userInfo:@{@"toolIndex": @(index)}];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
    [super resizeSubviewsWithOldSize:oldBoundsSize];
    
    // Update visual effect view frame
    for (NSView *subview in self.subviews) {
        if ([subview isKindOfClass:[NSVisualEffectView class]]) {
            subview.frame = self.bounds;
        }
    }
}

@end
