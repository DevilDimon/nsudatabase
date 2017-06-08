//
//  ReportViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 08/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "ReportViewController.h"
#import "DateCellView.h"

@interface ReportViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) NSTableView *tableView;

@end

@implementation ReportViewController

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    if (![self.table refresh]) {
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    NSTableView *tableView = [[NSTableView alloc] init];
    
    tableView.usesAlternatingRowBackgroundColors = YES;
    tableView.gridStyleMask = NSTableViewSolidHorizontalGridLineMask |
    NSTableViewSolidVerticalGridLineMask;
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
        column.title = columnName;
        
        [tableView addTableColumn:column];
    }
    
    self.tableView = tableView;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
    
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

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.table.rows.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    id obj = self.table.rows[row][[self.table.columns indexOfKey:tableColumn.title]];
    if (obj == [NSNull null]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Null" owner:self];
        cell.textField.editable = NO;
        cell.textField.stringValue = @"<null>";
        
        return cell;
    }
    if ([tableColumn.identifier isEqualToString:@"Date"]) {
        DateCellView *cell = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
        cell.datePicker.enabled = NO;
        cell.datePicker.dateValue = obj;
        
        return cell;
    }
    else {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"Text" owner:self];
        cell.textField.editable = NO;
        cell.textField.stringValue = obj;
        
        return cell;
    }

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

@end
