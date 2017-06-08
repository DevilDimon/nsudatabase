//
//  EditForeignKeysViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "EditForeignKeysViewController.h"

@interface EditForeignKeysViewController () <NSTableViewDelegate, NSTableViewDataSource>

@property (nonatomic) IBOutlet NSTableView *tableView;

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
    [self.tableView reloadData];
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

@end
