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

@interface ContentViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) Table *table;
@property (nonatomic) NSTableView *tableView;

@property (nonatomic) NSTableColumn *currentColumn;

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
    NSTableCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    cell.textField.stringValue = self.table.rows[row][[self.table.columns indexOfKey:tableColumn.title]];
    
    return cell;
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
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Table Refresh Error";
        alert.informativeText = [self errorString];
        [alert runModal];
        
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    
    NSTableView *tableView = [[NSTableView alloc] init];
    
    NSMenu *menu = [[NSMenu alloc] initWithTitle:@"Row Actions"];
    [menu addItemWithTitle:@"Delete Row" action:@selector(deleteRow) keyEquivalent:@""];
    tableView.menu = menu;
    
    tableView.usesAlternatingRowBackgroundColors = YES;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask | NSTableViewSolidVerticalGridLineMask;
    NSNib *textNib = [[NSNib alloc] initWithNibNamed:@"TextCellView" bundle:[NSBundle mainBundle]];
    NSNib *dateNib = [[NSNib alloc] initWithNibNamed:@"DateCellView" bundle:[NSBundle mainBundle]];
    [tableView registerNib:textNib forIdentifier:@"Text"];
    [tableView registerNib:dateNib forIdentifier:@"Date"];
    
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
    
    if (![self.table deleteRow:row]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Table Refresh Error";
        alert.informativeText = [self errorString];
        [alert runModal];
        
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    [self.tableView removeRowsAtIndexes:[NSIndexSet indexSetWithIndex:row]
        withAnimation:NSTableViewAnimationEffectFade];
    
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
    
    if (![self.table updateRow:row columnName:self.tableView.tableColumns[column].title
            newValue:textField.stringValue]) {
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Table Update Error";
        alert.informativeText = [self errorString];
        [alert runModal];
    }
    
    [self.tableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
        columnIndexes:[NSIndexSet indexSetWithIndex:column]];
    
    [self.view.window endSheet:progressWC.window];
}

@end
