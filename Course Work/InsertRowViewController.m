//
//  InsertRowViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 08/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "InsertRowViewController.h"
#import "ContentViewController.h"

@interface InsertRowViewController () <NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic) IBOutlet NSTableView *tableView;

@end


@implementation InsertRowViewController

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.table.columns.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn
                  row:(NSInteger)row
{
    if ([tableColumn.title isEqualToString:@"Attributes"]) {
        NSString *attribute = [self.table.columns keyAtIndex:row];
        NSTableCellView *cell = [self.tableView makeViewWithIdentifier:@"AttributeCell" owner:self];
        cell.textField.stringValue = attribute;
        return cell;
    }
    if ([tableColumn.title isEqualToString:@"Values"]) {
        NSTableCellView *cell = [self.tableView makeViewWithIdentifier:@"ValueCell" owner:self];
        return cell;
    }
    
    return nil;
    
}

- (IBAction)onOKPressed:(id)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    NSMutableArray *columns = [NSMutableArray array];
    NSMutableArray *vals = [NSMutableArray array];

    for (int i = 0; i < self.table.columns.count; i++) {
        [columns addObject:[(NSTableCellView *)[self.tableView viewAtColumn:0 row:i makeIfNecessary:NO]
                         textField].stringValue];
        [vals addObject:[(NSTableCellView *)[self.tableView viewAtColumn:1 row:i makeIfNecessary:NO]
            textField].stringValue];
    }
    
    if ([self.table insertRowWithColumns:columns values:vals]) {
        [self.view.window endSheet:progressWC.window];
        
        [self dismissController:nil];
        return;
    }
    
    [self.view.window endSheet:progressWC.window];
    
}

@end
