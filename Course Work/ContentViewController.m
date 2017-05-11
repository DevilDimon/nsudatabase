//
//  ContentViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "ContentViewController.h"
#import "Table.h"

@interface ContentViewController ()

@property (nonatomic) Table *table;

@end


@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"DidLoad");
}

- (void)setTableName:(NSString *)tableName
{
    _tableName = tableName;
    _table = [[Table alloc] initWithName:_tableName connection:self.conn sql:nil];
    [_table refresh];
    NSLog(@"Refreshed");
}

@end
