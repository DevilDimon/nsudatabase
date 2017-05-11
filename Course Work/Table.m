//
//  Table.m
//  Course Work
//
//  Created by Dmitriy Serov on 11/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "Table.h"
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
    
    NSMutableDictionary *newColumns = [NSMutableDictionary dictionary];
    for (int i = 1; i <= n; i++) {
        OCI_Column *column = OCI_TypeInfoGetColumn(info, i);
        NSString *columnName = [NSString stringWithOtext:OCI_ColumnGetName(column)];
        NSString *columnType = [NSString stringWithOtext:OCI_ColumnGetSQLType(column)];
        Class class = [self classFromDataType:columnType];
        if (class) {
            newColumns[columnName] = [NSValue value:&class withObjCType:@encode(Class)];
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
            [row addObject:[self objectFromResultSet:rs column:column]];
        }
        [self.rows addObject:[row copy]];
    }
    
    return YES;
}

- (Class)classFromDataType:(NSString *)type
{
    if ([type isEqualToString:@"NUMBER"]) {
        return [NSNumber class];
    }
    if ([type isEqualToString:@"VARCHAR2"]) {
        return [NSString class];
    }
    if ([type isEqualToString:@"DATE"]) {
        return [NSDate class];
    }
    
    return nil;
}

- (id)objectFromResultSet:(OCI_Resultset *)rs column:(NSString *)column
{
    const otext *o_column = [column otext];
    NSString *type = [NSString stringWithOtext:OCI_ColumnGetSQLType(OCI_GetColumn2(rs, o_column))];
    if ([type isEqualToString:@"NUMBER"]) {
        return @(OCI_GetInt2(rs, o_column));
    }
    if ([type isEqualToString:@"VARCHAR2"]) {
        return [NSString stringWithOtext:OCI_GetString2(rs, o_column)];
    }
    if ([type isEqualToString:@"DATE"]) {
        OCI_Date *date = OCI_GetDate2(rs, o_column);
        time_t time;
        OCI_DateToCTime(date, NULL, &time);
        return [NSDate dateWithTimeIntervalSince1970:time];
    }
    
    return nil;
}

@end
