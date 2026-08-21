//  PropertyPanel.m
//  LibreCAD_MacOS
//
//  Created by Developer on 2024.
//  Copyright © 2024 LibreCAD. All rights reserved.
//

#import "PropertyPanel.h"

@interface PropertyPanel () <NSTableViewDataSource, NSTableViewDelegate>
@property (nonatomic, strong) NSVisualEffectView *visualEffect;
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSArray *propertyNames;
@property (nonatomic, strong) NSMutableArray *propertyValues;
@end

@implementation PropertyPanel

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
    
    // Property names and values
    _propertyNames = @[
        @"Layer",
        @"Color",
        @"Line Type",
        @"Line Weight",
        @"X Coordinate",
        @"Y Coordinate",
        @"Length",
        @"Angle",
        @"Radius",
        @"Area"
    ];
    
    _propertyValues = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < _propertyNames.count; i++) {
        [_propertyValues addObject:@""];
    }
    
    // Create scroll view for table
    _scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(10, 10, frameRect.size.width - 20, frameRect.size.height - 20)];
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.autohidesScrollers = YES;
    _scrollView.borderType = NSNoBorder;
    _scrollView.drawsBackground = NO;
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Create table view
    NSTableViewStyle tableStyle = NSTableViewStyleInset;
    _propertiesTable = [[NSTableView alloc] initWithFrame:NSZeroRect style:tableStyle];
    _propertiesTable.dataSource = self;
    _propertiesTable.delegate = self;
    _propertiesTable.columnAutoresizingStyle = NSTableViewUniformColumnAutoresizingStyle;
    _propertiesTable.gridStyleMask = NSTableViewSolidVerticalGridLineMask;
    _propertiesTable.rowSizeStyle = NSTableViewRowSizeStyleMedium;
    _propertiesTable.selectionHighlightStyle = NSTableViewSelectionHighlightStyleSourceList;
    
    // Add columns
    NSTableColumn *nameColumn = [[NSTableColumn alloc] initWithIdentifier:@"Name"];
    nameColumn.title = @"Property";
    nameColumn.minWidth = 100;
    nameColumn.maxWidth = 150;
    [_propertiesTable addTableColumn:nameColumn];
    
    NSTableColumn *valueColumn = [[NSTableColumn alloc] initWithIdentifier:@"Value"];
    valueColumn.title = @"Value";
    valueColumn.minWidth = 100;
    valueColumn.maxWidth = 200;
    [_propertiesTable addTableColumn:valueColumn];
    
    [_scrollView setDocumentView:_propertiesTable];
    [self addSubview:_scrollView];
    
    // Add constraints
    [NSLayoutConstraint activateConstraints:@[
        [_scrollView.topAnchor constraintEqualToAnchor:self.topAnchor constant:10],
        [_scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-10],
        [_scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:10],
        [_scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-10]
    ]];
    
    // Listen for selection changes
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(selectionChanged:)
                                                 name:@"EntitySelectedNotification"
                                               object:nil];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _propertyNames.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSZeroRect];
        cell.identifier = tableColumn.identifier;
        
        NSTextField *textField = [[NSTextField alloc] init];
        textField.bezeled = NO;
        textField.drawsBackground = NO;
        textField.editable = ([tableColumn.identifier isEqualToString:@"Value"]);
        textField.selectable = YES;
        textField.translatesAutoresizingMaskIntoConstraints = NO;
        [cell addSubview:textField];
        
        [NSLayoutConstraint activateConstraints:@[
            [textField.leadingAnchor constraintEqualToAnchor:cell.leadingAnchor constant:2],
            [textField.trailingAnchor constraintEqualToAnchor:cell.trailingAnchor constant:-2],
            [textField.centerYAnchor constraintEqualToAnchor:cell.centerYAnchor],
            [textField.heightAnchor constraintEqualToConstant:17]
        ]];
        
        if ([tableColumn.identifier isEqualToString:@"Name"]) {
            cell.textField = textField;
        } else {
            cell.textField = textField;
        }
    }
    
    if ([tableColumn.identifier isEqualToString:@"Name"]) {
        cell.stringValue = _propertyNames[row];
    } else {
        cell.stringValue = _propertyValues[row];
    }
    
    return cell;
}

- (void)selectionChanged:(NSNotification *)notification {
    // Update property values based on selected entity
    NSDictionary *userInfo = notification.userInfo;
    // TODO: Populate property values from selected entity
    [_propertiesTable reloadData];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize {
    [super resizeSubviewsWithOldSize:oldBoundsSize];
    
    // Update visual effect view frame
    _visualEffect.frame = self.bounds;
}

@end
