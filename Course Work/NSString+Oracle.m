//
//  NSString+Oracle.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "NSString+Oracle.h"

@implementation NSString (Oracle)

+ (NSString *)stringWithOtext:(const otext *)string
{
    return [NSString stringWithCString:string encoding:NSUTF8StringEncoding];
}

@end
