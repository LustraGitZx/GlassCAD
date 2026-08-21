//  LayerPanel.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "LayerPanel.h"

@interface LayerPanel () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) NSVisualEffectView *visualEffect;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSToolbar *layerToolbar;
@property (nonatomic, strong) NSMutableArray *layers;
@end

@implementation LayerPanel

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
    _visualEffect = [[NSVisualEffectView alloc] initWithFrame:self.bounds];
    _visualEffect.material = NSVisualEffectMaterialSidebar;
    _visualEffect.blendingMode = NSVisualEffectBlendingModeBehindWindow;
    _visualEffect.state = NSVisualEffectStateActive;
    _visualEffect.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self addSubview:_visualEffect positioned:NSWindowBelow relativeTo:nil];
    
    // Initialize layers array
    _layers = [[NSMutableArray alloc] init];
    
    // Create toolbar for layer operations
    [self createToolbar];
    
    // Create scroll view for table
    CGFloat toolbarHeight = 30;
    _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, frameRect.size.width - 20, frameRect.size.height - toolbarHeight - 20)];
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.borderType = NSNoBorder;
    _scrollView.drawsBackground = NO;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Create table view
    NSTableViewStyle tableStyle = NSTableViewStyleInset;
    _layerTable = [[NSTableView alloc] initWithFrame:NSZeroRect style:tableStyle];
    _layerTable.dataSource = self;
    _layerTable.delegate = self;
    _layerTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    _layerTable.gridStyleMask = NSTableViewSolidVerticalGridLineMask;
    _layerTable.rowSizeStyle = NSTableViewRowSizeStyleSmall;
    _layerTable.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
    _layerTable.allowsMultipleSelection = NO;
    
    // Add columns
    NSTableColumn *visibilityColumn = [[NSTableColumn alloc] initWithIdentifier:@"Visibility"];
    visibilityColumn.title = @"";
    visibilityColumn.minWidth = 30;
    visibilityColumn.maxWidth = 30;
    [_layerTable addTableColumn:visibilityColumn];
    
    NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
    nameColumn.title = @"Layer Name";
    nameColumn.minWidth = 150;
    nameColumn.maxWidth = 300;
    [_layerTable addTableColumn:nameColumn];
    
    NSTableColumn *colorColumn = [[NSTableColumn alloc] initWithIdentifier:@"Color"];
    colorColumn.title = @"Color";
    colorColumn.minWidth = 80;
    colorColumn.maxWidth = 100;
    [_layerTable addTableColumn:colorColumn];
    
    [_scrollView setDocumentView:_layerTable];
    [self addSubview:_scrollView];
    
    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.topAnchor constant:toolbarHeight + 10],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10]
    ]];
    
    // Add default layer
    [self addLayerWithName:@"0"];
}

- (void)createToolbar {
    _layerToolbar = [[NSToolbar alloc] initWithIdentifier:@"LayerToolbar"];
    _layerToolbar.displayMode = NSToolbarDisplayModeIconOnly;
    _layerToolbar.showsBaselineSeparator = NO;
    _layerToolbar.delegate = self;
    
    // Create toolbar view manually
    NSView *toolbarView = [[NSView alloc] initWithFrame:NSMakeRect(10, self.bounds.size.height - 40, self.bounds.size.width - 20, 30)];
    toolbarView.autoresizingMask = NSViewWidthSizable;
    
    // Add layer buttons
    NSButton *newLayerButton = [self createToolbarButtonWithTitle:@"+" action:@selector(addLayer:)];
    newLayerButton.frame = NSMakeRect(0, 5, 30, 25);
    [toolbarView addSubview:newLayerButton];
    
    NSButton *deleteLayerButton = [self createToolbarButtonWithTitle:@"-" action:@selector(deleteLayer:)];
    deleteLayerButton.frame = NSMakeRect(35, 5, 30, 25);
    [toolbarView addSubview:deleteLayerButton];
    
    NSButton *editLayerButton = [self createToolbarButtonWithTitle:@"✏️" action:@selector(editLayer:)];
    editLayerButton.frame = NSMakeRect(70, 5, 30, 25);
    [toolbarView addSubview:editLayerButton];
    
    [self addSubview:toolbarView];
}

- (NSButton *)createToolbarButtonWithTitle:(NSString *)title action:(SEL)action {
    NSButton *button = [[NSButton alloc] init];
    button.title = title;
    button.target = self;
    button.action = action;
    button.bezelStyle = NSBezelStyleRounded;
    button.wantsLayer = YES;
    button.layer.cornerRadius = 4.0;
    button.translatesAutoresizingMaskIntoConstraints = NO;
    return button;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _layers.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
        cell.identifier = tableColumn.identifier;
        
        if ([tableColumn.identifier isEqualToString:@"Visibility"]) {
            NSButton *checkBox = [[NSButton alloc] init];
            checkBox.buttonType = NSSwitchButton;
            checkBox.target = self;
            checkBox.action = @selector(visibilityChanged:);
            checkBox.tag = row;
            checkBox.translatesAutoresizingMaskIntoConstraints = NO;
            [cell addSubview:checkBox];
            
            [NSLayoutConstraint activateConstraints:@[
                [checkBox.centerXAnchor constraintEqualToAnchor:cell.centerXAnchor],
                [checkBox.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
                [checkBox.widthAnchor constraintEqualToConstant:20],
                [checkBox.heightAnchor constraintEqualToConstant:20]
            ]];
        } else {
            NSTextField *textField = [[NSTextField alloc] init];
            textField.bezeled = NO;
            textField.drawsBackground = NO;
            textField.editable = NO;
            textField.selectable = YES;
            textField.translatesAutoresizingMaskIntoConstraints = NO;
            [cell addSubview:textField];
            
            [NSLayoutConstraint activateConstraints:@[
                [textField.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:2],
                [textField.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-2],
                [textField.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
                [textField.heightAnchor constraintEqualToConstant:17]
            ]];
            
            cell.textField = textField;
        }
    }
    
    NSDictionary *layer = _layers[row];
    
    if ([tableColumn.identifier isEqualToString:@"Visibility"]) {
        NSButton *checkBox = [cell.subviews.firstObject isKindOfClass:[NSButton class]] ? cell.subviews.firstObject : nil;
        if (checkBox) {
            checkBox.tag = row;
            checkBox.integerValue = [layer[@"visible"] boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
        }
    } else if ([tableColumn.identifier isEqualToString:@"Name"]) {
        cell.stringValue = layer[@"name"];
    } else if ([tableColumn.identifier isEqualToString:@"Color"]) {
        cell.stringValue = layer[@"color"];
    }
    
    return cell;
}

- (void)addLayer:(id)sender {
    NSString *layerName = [NSString stringWithFormat:@"Layer%ld", (long)_layers.count];
    [self addLayerWithName:layerName];
}

- (void)addLayerWithName:(NSString *)name {
    NSDictionary *layer = @{
        @"name": name,
        @"visible": @YES,
        @"locked": @NO,
        @"color": @"ByLayer"
    };
    [_layers addObject:layer];
    [_layerTable reloadData];
}

- (void)deleteLayer:(id)sender {
    NSInteger selectedRow = _layerTable.selectedRow;
    if (selectedRow >= 0 && selectedRow < _layers.count) {
        [_layers removeObjectAtIndex:selectedRow];
        [_layerTable reloadData];
    }
}

- (void)editLayer:(id)sender {
    NSInteger selectedRow = _layerTable.selectedRow;
    if (selectedRow >= 0 && selectedRow < _layers.count) {
        // TODO: Show layer properties dialog
        NSLog(@"Edit layer: %@", _layers[selectedRow]);
    }
}

- (void)visibilityChanged:(NSButton *)sender {
    NSInteger row = sender.tag;
    if (row >= 0 && row < _layers.count) {
        NSMutableDictionary *layer = [_layers[row] mutableCopy];
        layer[@"visible"] = @(sender.integerValue == NSControlStateValueOn);
        [_layers replaceObjectAtIndex:row withObject:layer];
        
        // Post notification for canvas update
        [[NSNotificationCenter defaultCenter] postNotificationName:@"LayerVisibilityChangedNotification"
                                                            object:self
                                                          userInfo:@{@"layerIndex": @(row)}];
    }
}

- (void)refreshLayers {
    [_layerTable reloadData];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
    [super resizeSubviewsWithOldSize:oldBoundsSize];
    
    // Update visual effect view frame
    _visualEffect.frame = self.bounds;
}

@end
