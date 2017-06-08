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
            if (OCI_IsNull2(rs, [column otext])) {
                [row addObject:[NSNull null]];
                continue;
            }
            if ([self.columns[column] isEqualToString:@"DATE"]) {
                OCI_Date *date = OCI_GetDate2(rs, [column otext]);
                time_t pt;
                OCI_DateToCTime(date, NULL, &pt);
                NSDate *nsdate = [NSDate dateWithTimeIntervalSince1970:pt];
                [row addObject:nsdate];
            }
            else {
                [row addObject:[NSString stringWithOtext:OCI_GetString2(rs, [column otext])]];
            }
        }
        [newRows addObject:row];
    }
    
    self.rows = [newRows mutableCopy];
    
    return YES;
}

- (BOOL)deleteRow:(NSInteger)row
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"DELETE FROM %@ WHERE ", self.name];
    for (NSString *columnName in self.columns) {
        id value = self.rows[row][[self.columns indexOfKey:columnName]];
        [sql appendFormat:@"%@ AND ", [self whereClauseWithColumn:columnName value:value
            type:self.columns[columnName]]];
    }
    
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 5, 5)];
    
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    OCI_StatementFree(st);
    
    [self.rows removeObjectAtIndex:row];
    
    return YES;
}

- (BOOL)updateRow:(NSInteger)row columnName:(NSString *)column newValue:(id)value
{
    NSString *formattedValue = [self formatForWhereClause:value type:self.columns[column]];
    NSMutableString *sql = [NSMutableString stringWithFormat:@"UPDATE %@ SET %@ = %@ WHERE ",
        self.name, column, formattedValue];
    for (NSString *columnName in self.columns) {
        id curValue = self.rows[row][[self.columns indexOfKey:columnName]];
        [sql appendFormat:@"%@ AND ", [self whereClauseWithColumn:columnName value:curValue
            type:self.columns[columnName]]];
    }
    
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 5, 5)];
    
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    NSInteger col = [self.columns indexOfKey:column];
    self.rows[row][col] = value ?: [NSNull null];
    
    return YES;
}

- (NSString *)formatForWhereClause:(id)value type:(NSString *)type
{
    if (value == [NSNull null]) {
        return @"NULL";
    }
    if ([type isEqualToString:@"NUMBER"]) {
        return value;
    }
    if ([type isEqualToString:@"VARCHAR2"]) {
        return [NSString stringWithFormat:@"'%@'", value];
    }
    if ([type isEqualToString:@"DATE"]) {
        NSDate *date = (NSDate *)value;
        OCI_Date *ociDate = OCI_DateCreate(self.conn);
        OCI_DateFromCTime(ociDate, NULL, [date timeIntervalSince1970]);
        otext string[256];
        otext *format = "YYYY-MM-DD HH24:MI:SS";
        OCI_DateToText(ociDate, format, 256, string);
        return [NSString stringWithFormat:@"TO_DATE('%s', '%s')", string, format];
    }
    
    return nil;
}

- (NSString *)whereClauseWithColumn:(NSString *)columnName value:(id)value type:(NSString *)type
{
    if (value == [NSNull null]) {
        return [NSString stringWithFormat:@"%@ IS NULL", columnName];
    }
    else {
        return [NSString stringWithFormat:@"%@ = %@", columnName, [self formatForWhereClause:value
            type:type]];
    }
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
