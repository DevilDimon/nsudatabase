//
//  Table.h
//  Course Work
//
//  Created by Dmitriy Serov on 11/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ocilib.h"

@interface Table : NSObject

@property (nonatomic) OCI_Connection *conn;
@property (nonatomic) NSString *name;
@property (nonatomic) NSString *sql;
@property (nonatomic) NSArray<NSDictionary<NSString *, NSValue *> *> *columns;
@property (nonatomic) NSMutableArray<NSArray *> *rows;

- (instancetype)initWithName:(NSString *)name connection:(OCI_Connection *)conn sql:(NSString *)sql;
- (BOOL)refresh;

@end
