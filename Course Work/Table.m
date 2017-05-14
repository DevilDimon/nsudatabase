//
//  Table.m
//  Course Work
//
//  Created by Dmitriy Serov on 11/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "Table.h"
#import <OrderedDictionary.h>
#import "NSString+Oracle.h"

@implementation Table

- (instancetype)initWithName:(NSString *)name connection:(OCI_Connection *)conn sql:(NSString *)sql
{
    self = [super init];
    if (self) {
        _name = name;
        _conn = conn;
        _sql = sql;
    }
    
    return self;
}

- (BOOL)refresh
{
    if (self.sql) {
        return YES;
    }
    
    OCI_TypeInfo *info = OCI_TypeInfoGet(self.conn, [self.name otext], OCI_TIF_TABLE);
    if (!info) {
        return NO;
    }
    
    int n = OCI_TypeInfoGetColumnCount(info);
    
    MutableOrderedDictionary *newColumns = [MutableOrderedDictionary dictionary];
    for (int i = 1; i <= n; i++) {
        OCI_Column *column = OCI_TypeInfoGetColumn(info, i);
        NSString *columnName = [NSString stringWithOtext:OCI_ColumnGetName(column)];
        NSString *columnType = [NSString stringWithOtext:OCI_ColumnGetSQLType(column)];
        if ([self isTypeSupported:columnType]) {
            newColumns[columnName] = columnType;
        }
    }
    
    self.columns = [newColumns copy];
    OCI_TypeInfoFree(info);
    
    self.rows = [NSMutableArray array];
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmtFmt(st, "SELECT * FROM %m", [self.name otext]) != TRUE) {
        OCI_StatementFree(st);
        return NO;
    }
    OCI_Resultset *rs = OCI_GetResultset(st);
    
    self.rows = [NSMutableArray array];
    while (OCI_FetchNext(rs)) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:self.columns.count];
        for (NSString *column in self.columns) {
            [row addObject:[NSString stringWithOtext:OCI_GetString2(rs, [column otext])]];
        }
        [self.rows addObject:[row copy]];
    }
    
    return YES;
}

- (BOOL)isTypeSupported:(NSString *)type
{
    static NSArray *supportedTypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        supportedTypes = @[@"NUMBER", @"VARCHAR2", @"DATE"];
    });
    
    return [supportedTypes containsObject:type];
}

@end
