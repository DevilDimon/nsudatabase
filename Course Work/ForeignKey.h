//
//  ForeignKey.h
//  Course Work
//
//  Created by Dmitriy Serov on 09/06/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ForeignKey : NSObject

@property (nonatomic) NSString *tableName;
@property (nonatomic) NSString *primaryKeyConstraint;
@property (nonatomic) NSMutableArray<NSString *> *columns;
@property (nonatomic) NSMutableArray<NSString *> *foreignFields;

@end
