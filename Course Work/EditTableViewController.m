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
#import "EditForeignKeysViewController.h"

@interface EditTableViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) IBOutlet NSTableView *constraintsTableView;
@property (nonatomic) IBOutlet NSTextField *nameTextField;
@property (nonatomic) IBOutlet NSTableView *uniqueTableView;
@property (nonatomic) IBOutlet NSTextField *primaryKeyTextField;
@property (nonatomic) IBOutlet NSTextField *primaryKeyColumnsTextField;

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
        [self.table refresh];
        [self.table refreshConstraints];
        self.nameTextField.stringValue = self.table.name;
        self.primaryKeyTextField.stringValue = self.table.primaryKeyConstraintName ?: @"None";
        
        NSMutableString *primaryKeyColumns = [NSMutableString stringWithString:@"Columns: "];
        for (NSString *column in self.table.primaryKeyColumns) {
            [primaryKeyColumns appendFormat:@"%@, ", column];
        }
        if (self.table.primaryKeyConstraintName) {
            [primaryKeyColumns deleteCharactersInRange:NSMakeRange(primaryKeyColumns.length - 2, 2)];
        }
        self.primaryKeyColumnsTextField.stringValue = [primaryKeyColumns copy];
        
        [self.constraintsTableView reloadData];
        [self.uniqueTableView reloadData];
        
        return;
    }
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == self.constraintsTableView) {
        return self.table.columns.count;
    }
    if (tableView == self.uniqueTableView) {
        return self.table.uniqueColumns.count;
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
    }
    if (tableView == self.uniqueTableView) {
        if ([tableColumn.identifier isEqualToString:@"UniqueColumn"]) {
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"UniqueCell" owner:self];
            cell.textField.stringValue = [self.table.uniqueColumns keyAtIndex:row];
            return cell;
        }
        if ([tableColumn.identifier isEqualToString:@"ParticipatingColumn"]) {
            NSTableCellView *cell = [tableView makeViewWithIdentifier:@"ParticipatingCell" owner:self];
            NSMutableString *columns = [NSMutableString string];
            for (NSString *column in self.table.uniqueColumns[row]) {
                [columns appendFormat:@"%@, ", column];
            }
            
            [columns deleteCharactersInRange:NSMakeRange(columns.length - 2, 2)];
            cell.textField.stringValue = columns;
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

- (IBAction)onAddAttribute:(id)sender
{
    if (!self.table) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    [self.table addAttribute];
    [self refresh];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onRemoveAttribute:(id)sender
{
    if (!self.table) {
        return;
    }
    
    if (self.constraintsTableView.selectedRowIndexes.count <= 0) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSMutableArray *names = [NSMutableArray array];
    [self.constraintsTableView.selectedRowIndexes
     enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
         NSString *name = [self.table.columns keyAtIndex:index];
         [names addObject:name];
    }];
    
    for (NSString *name in names) {
        [self.table removeAttribute:name];
    }
    
    [self refresh];
    
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

- (IBAction)onMakeUnique:(id)sender
{
    if (self.constraintsTableView.selectedRowIndexes.count <= 0) {
        return;
    }
    
    if (!self.table) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSMutableArray *names = [NSMutableArray array];
    [self.constraintsTableView.selectedRowIndexes
     enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
         NSString *name = [self.table.columns keyAtIndex:index];
         [names addObject:name];
     }];
    
    [self.table makeUnique:names];
    
    [self refresh];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onRemoveUniqueConstraint:(id)sender
{
    if (self.uniqueTableView.selectedRowIndexes.count <= 0) {
        return;
    }
    
    if (!self.table) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSMutableArray *names = [NSMutableArray array];
    [self.uniqueTableView.selectedRowIndexes
     enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
         NSString *name = [self.table.uniqueColumns keyAtIndex:index];
         [names addObject:name];
     }];
    
    
    for (NSString *constraint in names) {
        [self.table removeConstraint:constraint];
    }
    
    [self refresh];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onMakePrimaryKey:(id)sender
{
    if (self.constraintsTableView.selectedRowIndexes.count <= 0) {
        return;
    }
    
    if (!self.table) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSMutableArray *names = [NSMutableArray array];
    [self.constraintsTableView.selectedRowIndexes
     enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
         NSString *name = [self.table.columns keyAtIndex:index];
         [names addObject:name];
     }];
    
    [self.table makePrimaryKey:names];
    
    [self refresh];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onRemovePrimaryKey:(id)sender
{
    if (!self.table) {
        return;
    }
    
    if (!self.table.primaryKeyConstraintName) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    [self.table removeConstraint:self.table.primaryKeyConstraintName];
    
    [self refresh];
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onEditForeignKeys:(id)sender
{
    if (!self.table) {
        return;
    }
    
    EditForeignKeysViewController *vc = [[NSStoryboard storyboardWithName:@"Main"
        bundle:[NSBundle mainBundle]]
        instantiateControllerWithIdentifier:@"EditForeignKeysViewController"];
    vc.table = self.table;
    
    [self presentViewControllerAsModalWindow:vc];
}

@end
