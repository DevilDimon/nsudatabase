//
//  ContentViewController.h
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ocilib.h"

@interface ContentViewController : NSViewController

@property (nonatomic, assign) OCI_Connection *conn;
@property (nonatomic, copy) NSString *tableName;

- (IBAction)onRefreshPressed:(id)sender;

@end
