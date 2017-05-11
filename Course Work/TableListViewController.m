//
//  TableListViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "TableListViewController.h"
#import "ContentViewController.h"
#import "ocilib.h"
#import "NSString+Oracle.h"
#import "NSViewController+ErrorString.h"

@interface TableListViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) IBOutlet NSTableView *tableView;
@property (nonatomic) IBOutlet NSView *containerView;

@property (nonatomic) NSMutableArray<NSString *> *tableNames;

@end

@implementation TableListViewController

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    if (!self.tableNames) {
        [self onRefreshPressed:nil];
    }
}

- (BOOL)refresh
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmt(st, "SELECT table_name FROM user_tables") != TRUE) {
        OCI_StatementFree(st);
        return NO;
    }
    
    self.tableNames = [NSMutableArray array];
    OCI_Resultset *rs = OCI_GetResultset(st);
    while (OCI_FetchNext(rs)) {
        NSString *table = [NSString stringWithOtext:OCI_GetString(rs, 1)];
        [self.tableNames addObject:table];
    }
    
    return YES;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.tableNames.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn
    row:(NSInteger)row
{
    NSString *tableName = self.tableNames[row];
    NSTableCellView *cell = [self.tableView makeViewWithIdentifier:@"TableName" owner:self];
    cell.textField.stringValue = tableName;
    
    return cell;
}

- (IBAction)onRefreshPressed:(id)sender
{
    self.tableNames = [NSMutableArray array];
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    
    
    if (![self refresh]) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Table Refresh Error";
        alert.informativeText = [self errorString];
        [alert runModal];
        
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    [self.tableView reloadData];
    [self.tableView scrollRowToVisible:0];
    
    [self.view.window endSheet:progressWC.window];
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    self.contentVC.tableName = self.tableNames[self.tableView.selectedRow];
}


@end
