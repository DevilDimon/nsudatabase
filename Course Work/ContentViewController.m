//
//  ContentViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "ContentViewController.h"

@interface ContentViewController ()


@end

@implementation ContentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSLog(@"DidLoad");
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    NSLog(@"WillAppear");
}

- (void)setTableName:(NSString *)tableName
{
    _tableName = tableName;
    NSLog(@"Table name: %@", self.tableName);
}

@end
