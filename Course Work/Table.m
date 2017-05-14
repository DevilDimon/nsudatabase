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


@interface Table ()

@end

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
    
    NSMutableArray *newRows = [NSMutableArray array];
    while (OCI_FetchNext(rs)) {
        NSMutableArray *row = [NSMutableArray arrayWithCapacity:self.columns.count];
        for (NSString *column in self.columns) {
            [row addObject:[NSString stringWithOtext:OCI_GetString2(rs, [column otext])]];
        }
        [newRows addObject:[row copy]];
    }
    
    self.rows = [newRows mutableCopy];
    
    return YES;
}

- (BOOL)deleteRow:(NSInteger)row
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE ", self.name];
    for (NSString *columnName in self.columns) {
        NSString *value = self.rows[row][[self.columns indexOfKey:columnName]];
        [sql appendFormat:@"%@ = %@ AND ", columnName,
         [self formatForWhereClause:value type:self.columns[columnName]]];
    }
    
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 5, 5)];
    
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        OCI_StatementFree(st);
        return NO;
    }
    OCI_StatementFree(st);
    OCI_Commit(self.conn);
    
    [self.rows removeObjectAtIndex:row];
    
    return YES;
}

- (NSString *)formatForWhereClause:(NSString *)string type:(NSString *)type
{
    if ([type isEqualToString:@"NUMBER"]) {
        return string;
    }
    if ([type isEqualToString:@"VARCHAR2"]) {
        return [NSString stringWithFormat:@"'%@'", string];
    }
    if ([type isEqualToString:@"DATE"]) {
        return [NSString stringWithFormat:@"TO_DATE('%@')", string];
    }
    
    return nil;
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
