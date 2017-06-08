//
//  NullTextPopover.h
//  Course Work
//
//  Created by Dmitriy Serov on 08/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "CellRelated.h"

@interface NullTextPopover : NSViewController <CellRelated>

@property (nonatomic) IBOutlet NSTextField *textField;

@end
