//
//  NSString+Oracle.h
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ocilib.h"

@interface NSString (Oracle)

+ (NSString *)stringWithOtext:(const otext *)string;

@end
