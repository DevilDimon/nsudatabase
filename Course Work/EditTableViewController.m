//
//  EditTableViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 08/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "EditTableViewController.h"
#import "NSString+Oracle.h"
#import "TypeCellView.h"
#import "CheckCellView.h"

@interface EditTableViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) IBOutlet NSTableView *constraintsTableView;
@property (nonatomic) IBOutlet NSTextField *nameTextField;

@end

@implementation EditTableViewController

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self refresh];
    
}

- (void)refresh
{
    if (self.table) {
        
        self.nameTextField.stringValue = self.table.name;
        [self.constraintsTableView reloadData];
        
        return;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.constraintsTableView) {
        return self.table.columns.count;
    }
    
    return 0;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == self.constraintsTableView) {
        if ([tableColumn.identifier isEqualToString:@"AttributeColumn"]) {
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"AttributeCell" owner:self];
            cell.textField.stringValue = [self.table.columns keyAtIndex:row];
            return cell;
        }
        if ([tableColumn.identifier isEqualToString:@"TypeColumn"]) {
            TypeCellView *cell = [tableView makeViewWithIdentifier:@"TypeCell" owner:self];
            [cell.popupButton selectItemWithTitle:self.table.columns[row]];
            return cell;
        }
        if ([tableColumn.identifier isEqualToString:@"NotNullColumn"]) {
            CheckCellView *cell = [tableView makeViewWithIdentifier:@"NotNullCell" owner:self];
            if (![self.table.nullableColumns containsObject:[self.table.columns keyAtIndex:row]]) {
                cell.checkbox.state = NSOnState;
            }
            else {
                cell.checkbox.state = NSOffState;
            }
            return cell;
        }
        if ([tableColumn.identifier isEqualToString:@"UniqueColumn"]) {
            CheckCellView *cell = [tableView makeViewWithIdentifier:@"UniqueCell" owner:self];
            cell.checkbox.state = NSOffState;
            return cell;
        }
        if ([tableColumn.identifier isEqualToString:@"PrimaryKeyColumn"]) {
            CheckCellView *cell = [tableView makeViewWithIdentifier:@"PrimaryKeyCell" owner:self];
            cell.checkbox.state = NSOffState;
            return cell;
        }
    }
    
    
    return nil;
}

- (IBAction)onNameChanged:(NSTextField *)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    if (self.table) {
        if ([sender.stringValue isEqualToString:self.table.name]) {
            [self.view.window endSheet:progressWC.window];
            return;
        }
        if (![self.table alterName:sender.stringValue]) {
            self.nameTextField.stringValue = self.table.name;
        }
    }
    else {
        OCI_Statement *st = OCI_StatementCreate(self.conn);
        NSString *sql = [NSString stringWithFormat:@"CREATE TABLE %@ (idd NUMBER)", sender.stringValue];
        if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
            [self.view.window endSheet:progressWC.window];
            return;
        }
        
        OCI_StatementFree(st);
        self.table = [[Table alloc] initWithName:sender.stringValue connection:self.conn resultSet:NULL];
        [self.table refresh];
        [self refresh];
    }
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onAttributeNameChanged:(NSTextField *)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    
    NSInteger row = [self.constraintsTableView rowForView:sender];
    NSString *name = [self.table.columns keyAtIndex:row];
    
    [self.table alterAttributeName:name newName:sender.stringValue];
    
    [self.constraintsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
        columnIndexes:[NSIndexSet indexSetWithIndex:0]];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onAttributeTypeChanged:(NSPopUpButton *)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSInteger row = [self.constraintsTableView rowForView:sender];
    NSString *name = [self.table.columns keyAtIndex:row];
    
    [self.table alterAttributeType:name newType:sender.selectedItem.title];
    
    [self.constraintsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
        columnIndexes:[NSIndexSet indexSetWithIndex:1]];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onAttributeNullabilityChanged:(NSPopUpButton *)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSInteger row = [self.constraintsTableView rowForView:sender];
    NSString *name = [self.table.columns keyAtIndex:row];
    
    [self.table alterAttributeNullability:name nullability:sender.state == NSOffState];
    
    [self.constraintsTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row]
        columnIndexes:[NSIndexSet indexSetWithIndex:2]];
    
    [self.view.window endSheet:progressWC.window];
}

@end
