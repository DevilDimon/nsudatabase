//
//  ContentViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "ContentViewController.h"
#import "Table.h"
#import "NSViewController+ErrorString.h"
#import "DateCellView.h"
#import "NullTextPopover.h"
#import "NullDatePopover.h"

@interface ContentViewController () <NSTableViewDelegate, NSTableViewDataSource, NSPopoverDelegate>

@property (nonatomic) Table *table;
@property (nonatomic) NSTableView *tableView;

@property (nonatomic) NSPopover *nullPopover;

@end


@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)setTableName:(NSString *)tableName
{
    _tableName = tableName;

    [self onRefreshPressed:nil];
}

- (NSString *)identifierForType:(NSString *)type
{
    if ([type isEqualToString:@"NUMBER"] || [type isEqualToString:@"VARCHAR2"]) {
        return @"Text";
    } else if([type isEqualToString:@"DATE"]) {
        return @"Date";
    }
    
    return nil;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id obj = self.table.rows[row][[self.table.columns indexOfKey:tableColumn.title]];
    if (obj == [NSNull null]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Null" owner:self];
        cell.textField.stringValue = @"<null>";
        
        return cell;
    }
    if ([tableColumn.identifier isEqualToString:@"Date"]) {
        DateCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        cell.datePicker.dateValue = obj;
        
        return cell;
    }
    else {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Text" owner:self];
        cell.textField.stringValue = obj;
    
        return cell;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.table.rows.count;
}

- (IBAction)onRefreshPressed:(id)sender
{
    self.table = [[Table alloc] initWithName:self.tableName connection:self.conn sql:nil];
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    if (![self.table refresh]) {
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    
    NSTableView *tableView = [[NSTableView alloc] init];
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Row Actions"];
    [menu addItemWithTitle:@"Add Row" action:@selector(addNewRow) keyEquivalent:@""];
    [menu addItemWithTitle:@"Delete Row" action:@selector(deleteRow) keyEquivalent:@""];
    [menu addItemWithTitle:@"Set as NULL" action:@selector(nullify) keyEquivalent:@""];
    tableView.menu = menu;
    
    tableView.usesAlternatingRowBackgroundColors = YES;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask |
        NSTableViewSolidVerticalGridLineMask;
    tableView.target = self;
    tableView.doubleAction = @selector(onDoubleClick);
    NSNib *textNib = [[NSNib alloc] initWithNibNamed:@"TextCellView" bundle:[NSBundle mainBundle]];
    NSNib *dateNib = [[NSNib alloc] initWithNibNamed:@"DateCellView" bundle:[NSBundle mainBundle]];
    NSNib *nullNib = [[NSNib alloc] initWithNibNamed:@"NullCellView" bundle:[NSBundle mainBundle]];
    [tableView registerNib:textNib forIdentifier:@"Text"];
    [tableView registerNib:dateNib forIdentifier:@"Date"];
    [tableView registerNib:nullNib forIdentifier:@"Null"];
    
    for (NSString *columnName in self.table.columns) {
        NSString *identifier = [self identifierForType:self.table.columns[columnName]];
        if (!identifier) {
            continue;
        }
        
        NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:identifier];
//        column.headerCell.title = columnName;
        column.title = columnName;
        
        [tableView addTableColumn:column];
    }
    
    [self.tableView.enclosingScrollView removeFromSuperview];
    
    self.tableView = tableView;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
    
    //    self.view.translatesAutoresizingMaskIntoConstraints = NO;
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    scrollView.documentView = self.tableView;
    scrollView.hasVerticalScroller = YES;
    [self.view addSubview:scrollView];
    [self.view addConstraints:@[
        [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeTop multiplier:1.0 constant:0],
        [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeBottom multiplier:1.0 constant:0],
        [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeLeading multiplier:1.0 constant:0],
        [NSLayoutConstraint constraintWithItem:self.view attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:scrollView attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:0]
    ]];
    
    [self.view.window endSheet:progressWC.window];
}

- (void)addNewRow
{
    
}

- (void)deleteRow
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSInteger row = self.tableView.clickedRow;
    if (row < 0) {
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    [self.table deleteRow:row];
    
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
        withAnimation:NSTableViewAnimationEffectFade];
    
    [self.view.window endSheet:progressWC.window];
    
}

- (void)nullify
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    if (row < 0 || column < 0) {
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    [self.table updateRow:row columnName:self.tableView.tableColumns[column].title newValue:[NSNull null]];
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
        columnIndexes:[NSIndexSet indexSetWithIndex:column]];
    
    [self.view.window endSheet:progressWC.window];

}

- (IBAction)onTextEdited:(id)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main"
        bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    if (row < 0 || column < 0) {
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    NSTextField *textField = (NSTextField *)sender;
    
    [self.table updateRow:row columnName:self.tableView.tableColumns[column].title
                      newValue:textField.stringValue];
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
        columnIndexes:[NSIndexSet indexSetWithIndex:column]];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onDateChanged:(id)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main"
        bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSInteger row = [self.tableView rowForView:sender];
    NSInteger column = [self.tableView columnForView:sender];
    if (row < 0 || column < 0) {
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    NSDatePicker *datePicker = (NSDatePicker *)sender;
    
    [self.table updateRow:row columnName:self.tableView.tableColumns[column].title
                      newValue:datePicker.dateValue];
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                              columnIndexes:[NSIndexSet indexSetWithIndex:column]];
    
    [self.view.window endSheet:progressWC.window];
    
}

- (void)onDoubleClick
{
    NSInteger row = self.tableView.clickedRow;
    NSInteger column = self.tableView.clickedColumn;
    
    if (row < 0 || column < 0) {
        return;
    }
    
    NSInteger realColumn = [self.table.columns
                            indexOfKey:self.tableView.tableColumns[column].title];
    
    if (self.table.rows[row][realColumn] != [NSNull null]) {
        
        return;
    }
    
    NSString *type = self.table.columns[self.tableView.tableColumns[column].title];

    self.nullPopover = [[NSPopover alloc] init];
    self.nullPopover.behavior = NSPopoverBehaviorTransient;
    self.nullPopover.delegate = self;
    
    if ([type isEqualToString:@"NUMBER"] || [type isEqualToString:@"VARCHAR2"]) {
        NullTextPopover *vc = [[NSStoryboard storyboardWithName:@"Main"
            bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"NullTextPopover"];
        vc.row = row;
        vc.column = column;
        self.nullPopover.contentViewController = vc;
    }
    if ([type isEqualToString:@"DATE"]) {
        NullDatePopover *vc = [[NSStoryboard storyboardWithName:@"Main"
            bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"NullDatePopover"];
        vc.row = row;
        vc.column = column;
        self.nullPopover.contentViewController = vc;
    }
    
    [self.nullPopover showRelativeToRect:[self.tableView frameOfCellAtColumn:column row:row]
        ofView:self.tableView preferredEdge:NSRectEdgeMinX];
    
}

- (void)popoverWillClose:(NSNotification *)notification
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main"
        bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    id<CellRelated> vc = (id<CellRelated>)self.nullPopover.contentViewController;
    
    NSInteger row = vc.row;
    NSInteger column = vc.column;
    
    NSString *type = self.table.columns[self.tableView.tableColumns[column].title];
    
    if ([type isEqualToString:@"NUMBER"] || [type isEqualToString:@"VARCHAR2"]) {
        NSTextField *textField = [(NullTextPopover *)self.nullPopover.contentViewController textField];
        [self.table updateRow:row columnName:self.tableView.tableColumns[column].title
                          newValue:textField.stringValue];
    }
    if ([type isEqualToString:@"DATE"]) {
        NSDatePicker *datePicker = [(NullDatePopover *)self.nullPopover.contentViewController datePicker];
        [self.table updateRow:row columnName:self.tableView.tableColumns[column].title
                     newValue:datePicker.dateValue];
    }
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
                              columnIndexes:[NSIndexSet indexSetWithIndex:column]];
    
    [self.view.window endSheet:progressWC.window];

}

@end
