//
//  EditTableViewController.h
//  Course Work
//
//  Created by Dmitriy Serov on 08/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Table.h"
#import "ocilib.h"

@interface EditTableViewController : NSViewController

@property (nonatomic) Table *table;
@property (nonatomic) OCI_Connection *conn;

@end
