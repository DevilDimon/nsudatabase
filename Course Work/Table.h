//
//  Table.h
//  Course Work
//
//  Created by Dmitriy Serov on 11/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ocilib.h"
#import <OrderedDictionary.h>

@interface Table : NSObject

@property (nonatomic) OCI_Connection *conn;
@property (nonatomic) NSString *name;
@property (nonatomic) OCI_Resultset *rs;
@property (nonatomic) OrderedDictionary<NSString *, NSString *> *columns;
@property (nonatomic) NSMutableArray<NSMutableArray *> *rows;
@property (nonatomic) NSMutableArray<NSString *> *nullableColumns;

@property (nonatomic) OrderedDictionary<NSString *, NSArray<NSString *> *> *uniqueColumns;

- (instancetype)initWithName:(NSString *)name connection:(OCI_Connection *)conn
    resultSet:(OCI_Resultset *)rs;
- (BOOL)refresh;
- (BOOL)deleteRow:(NSInteger)row;
- (BOOL)updateRow:(NSInteger)row columnName:(NSString *)column newValue:(id)value;
- (BOOL)insertRowWithColumns:(NSArray *)columns values:(NSArray *)values;

- (BOOL)alterName:(NSString *)name;
- (BOOL)alterAttributeName:(NSString *)attribute newName:(NSString *)newName;
- (BOOL)alterAttributeType:(NSString *)attribute newType:(NSString *)type;
- (BOOL)alterAttributeNullability:(NSString *)attribute nullability:(BOOL)nullability;
- (BOOL)addAttribute;
- (BOOL)removeAttribute:(NSString *)attribute;

- (BOOL)refreshConstraints;
- (BOOL)makeUnique:(NSArray<NSString *> *)attributes;
- (BOOL)removeConstraint:(NSString *)constraint;

@end
