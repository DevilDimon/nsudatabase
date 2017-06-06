//
//  MainWindowController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "MainWindowController.h"
#import "CodeViewController.h"
#import "MainViewController.h"

@interface MainWindowController ()

@end

@implementation MainWindowController

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.destinationController isKindOfClass:[CodeViewController class]]) {
        CodeViewController *codeVC = (CodeViewController *)segue.destinationController;
        codeVC.conn = ((MainViewController *)self.contentViewController).connection;
    }
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

@end
