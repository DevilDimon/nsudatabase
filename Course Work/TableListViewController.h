//
//  TableListViewController.h
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ocilib.h"
#import "ContentViewController.h"

@interface TableListViewController : NSViewController

@property (nonatomic, assign) OCI_Connection *conn;
@property (nonatomic) ContentViewController *contentVC;

@end
