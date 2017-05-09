//
//  ViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 01/04/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "MainViewController.h"
#import "TableListViewController.h"
#import "ContentViewController.h"

@interface MainViewController () <NSSplitViewDelegate>

@property (nonatomic) IBOutlet NSSplitView *splitView;
@property (nonatomic) TableListViewController *tableListViewController;
@property (nonatomic) ContentViewController *contentViewController;

@end


@implementation MainViewController

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationController isKindOfClass:[TableListViewController class]]) {
        self.tableListViewController = (TableListViewController *)segue.destinationController;
        self.tableListViewController.conn = self.connection;
    }
    else if ([segue.destinationController isKindOfClass:[ContentViewController class]]) {
        self.contentViewController = (ContentViewController *)segue.destinationController;
        self.contentViewController.conn = self.connection;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.splitView setPosition:200 ofDividerAtIndex:0];

    
}

- (void)setConnection:(OCI_Connection *)connection
{
    _connection = connection;
    self.tableListViewController.conn = connection;
    self.contentViewController.conn = connection;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 200;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex
{
    return 400;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
    return YES;
}

@end
