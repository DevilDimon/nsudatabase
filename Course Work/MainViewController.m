//
//  ViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 01/04/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@property (nonatomic) IBOutlet NSTextField *testLabel;

@end


@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    
    self.testLabel.stringValue = [NSString stringWithFormat:@"%s, %s, %s",
                                  OCI_GetDatabase(self.connection), OCI_GetUserName(self.connection),
                                  OCI_GetPassword(self.connection)];
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
    
}


@end
