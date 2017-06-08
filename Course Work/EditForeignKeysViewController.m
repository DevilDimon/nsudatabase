//
//  EditForeignKeysViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "EditForeignKeysViewController.h"
#import "NSString+Oracle.h"

@interface EditForeignKeysViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) IBOutlet NSTableView *tableView;
@property (nonatomic) IBOutlet NSTextField *constraintTextField;
@property (nonatomic) IBOutlet NSTextField *nameTextField;
@property (nonatomic) IBOutlet NSComboBox *tableComboBox;
@property (nonatomic) IBOutlet NSComboBox *columnComboBox;
@property (nonatomic) IBOutlet NSComboBox *foreignColumnComboBox;

@property (nonatomic) ForeignKey *foreignKey;
@property (nonatomic) NSInteger cur;

@end


@implementation EditForeignKeysViewController

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    [self refresh];
}

- (void)refresh
{
    [self.table refreshForeignKeys];
    [self refreshTables];
    [self refreshColumns];
    [self refreshConstraintText];
    [self.tableView reloadData];
}

- (void)refreshTables
{
    OCI_Statement *st = OCI_StatementCreate(self.table.conn);
    OCI_ExecuteStmt(st, "SELECT table_name FROM user_tables");
    
    NSMutableArray *tableNames = [NSMutableArray array];
    OCI_Resultset *rs = OCI_GetResultset(st);
    while (OCI_FetchNext(rs)) {
        NSString *table = [NSString stringWithOtext:OCI_GetString(rs, 1)];
        [tableNames addObject:table];
    }
    
    [self.tableComboBox removeAllItems];
    [self.tableComboBox addItemsWithObjectValues:tableNames];
}

- (void)refreshColumns
{
    [self.columnComboBox removeAllItems];
    for (NSString *column in self.table.columns) {
        [self.columnComboBox addItemWithObjectValue:column];
    }
}

- (void)refreshForeignColumns
{
    [self.foreignColumnComboBox removeAllItems];
    Table *foreignTable = [[Table alloc] initWithName:self.foreignKey.tableName
        connection:self.table.conn resultSet:NULL];
    [foreignTable refresh];
    for (NSString *column in foreignTable.columns) {
        [self.foreignColumnComboBox addItemWithObjectValue:column];
    }
    
}

- (void)refreshConstraintText
{
    if (!self.foreignKey) {
        self.constraintTextField.stringValue = @"None";
        return;
    }
    
    NSMutableString *string = [NSMutableString string];
    for (NSString *column in self.foreignKey.columns) {
        [string appendFormat:@"%@, ", column];
    }
    
    if (self.foreignKey.columns.count > 0) {
        [string deleteCharactersInRange:NSMakeRange(string.length - 2, 2)];
    }
    [string appendFormat:@" REF. %@(", self.foreignKey.tableName ?: @"None"];
    
    for (NSString *column in self.foreignKey.foreignFields) {
        [string appendFormat:@"%@, ", column];
    }
    if (self.foreignKey.foreignFields.count > 0) {
        [string deleteCharactersInRange:NSMakeRange(string.length - 2, 2)];
    }
    
    [string appendString:@")"];
    
    self.constraintTextField.stringValue = [string copy];
}

- (IBAction)onNameEdited:(id)sender
{
    if (!self.foreignKey) {
        self.foreignKey = [[ForeignKey alloc] init];
    }
    [self refreshConstraintText];
}

- (IBAction)onTableChanged:(NSComboBox *)sender
{
    if (!self.foreignKey) {
        return;
    }
    
    NSString *tableName = sender.stringValue;
    self.foreignKey.tableName = tableName;
    [self.foreignKey.foreignFields removeAllObjects];
    [self.foreignKey.columns removeAllObjects];
    self.cur = 0;
    [self refreshForeignColumns];
    [self refreshConstraintText];
}

- (IBAction)onColumnChanged:(NSComboBox *)sender
{
    if (!self.foreignKey) {
        return;
    }
    
    self.foreignKey.columns[self.cur] = sender.stringValue;
    [self refreshConstraintText];
    
}

- (IBAction)onForeignColumnChanged:(NSComboBox *)sender
{
    if (!self.foreignKey) {
        return;
    }
    
    self.foreignKey.foreignFields[self.cur] = sender.stringValue;
    [self refreshConstraintText];
}

- (IBAction)onNext:(id)sender
{
    if (!self.foreignKey || self.foreignKey.columns.count < self.cur ||
        self.foreignKey.foreignFields.count < self.cur) {
        return;
    }
    
    self.cur++;
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.table.foreignKeys.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([tableColumn.identifier isEqualToString:@"ConstraintColumn"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"ConstraintCell" owner:self];
        cell.textField.stringValue = [self.table.foreignKeys keyAtIndex:row];
        return cell;
    }
    if ([tableColumn.identifier isEqualToString:@"TableColumn"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"TableCell" owner:self];
        cell.textField.stringValue = self.table.foreignKeys[row].tableName;
        return cell;
    }
    if ([tableColumn.identifier isEqualToString:@"ColumnsColumn"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"ColumnsCell" owner:self];
        NSMutableString *columns = [NSMutableString string];
        for (NSString *column in self.table.foreignKeys[row].columns) {
            [columns appendFormat:@"%@, ", column];
        }
        
        [columns deleteCharactersInRange:NSMakeRange(columns.length - 2, 2)];
        cell.textField.stringValue = columns;
        return cell;
    }
    if ([tableColumn.identifier isEqualToString:@"ForeignColumn"]) {
        NSTableCellView *cell = [tableView makeViewWithIdentifier:@"ForeignCell" owner:self];
        NSMutableString *columns = [NSMutableString string];
        for (NSString *column in self.table.foreignKeys[row].foreignFields) {
            [columns appendFormat:@"%@, ", column];
        }
        
        [columns deleteCharactersInRange:NSMakeRange(columns.length - 2, 2)];
        cell.textField.stringValue = columns;
        return cell;
    }
    
    return nil;
}

- (IBAction)onAddConstraint:(id)sender
{
    if (!self.foreignKey || self.foreignKey.columns.count < self.cur ||
        self.foreignKey.foreignFields.count < self.cur) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    if ([self.table makeForeignKey:self.nameTextField.stringValue foreignKey:self.foreignKey]) {
        self.foreignKey = nil;
        self.cur = 0;
        [self refresh];
    }
    
    [self.view.window endSheet:progressWC.window];
}

- (IBAction)onRemoveConstraint:(id)sender
{
    if (self.tableView.selectedRow < 0) {
        return;
    }
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    
    NSString *constraint = [self.table.foreignKeys keyAtIndex:self.tableView.selectedRow];
    
    [self.table removeConstraint:constraint];
    
    [self refresh];
    
    [self.view.window endSheet:progressWC.window];
}

@end
