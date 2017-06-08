//
//  ForeignKey.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "ForeignKey.h"

@implementation ForeignKey

- (instancetype)init
{
    self = [super init];
    if (self) {
        _columns = [NSMutableArray array];
        _foreignFields = [NSMutableArray array];
    }
    return self;
}

@end
