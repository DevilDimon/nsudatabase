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

static NSString *const VarcharLimit = @"64";


@interface Table ()

@end


@implementation Table

- (instancetype)initWithName:(NSString *)name connection:(OCI_Connection *)conn
    resultSet:(OCI_Resultset *)rs
{
    self = [super init];
    if (self) {
        _name = name;
        _conn = conn;
        _rs = rs;
    }
    
    return self;
}

- (BOOL)refresh
{
    if (self.rs) {
        MutableOrderedDictionary *newColumns = [MutableOrderedDictionary dictionary];
        int n = OCI_GetColumnCount(self.rs);
        for (int i = 1; i <= n; i++) {
            OCI_Column *column = OCI_GetColumn(self.rs, i);
            NSString *columnName = [NSString stringWithOtext:OCI_ColumnGetName(column)];
            NSString *columnType = [NSString stringWithOtext:OCI_ColumnGetSQLType(column)];
            if ([self isTypeSupported:columnType]) {
                newColumns[columnName] = columnType;
            }

        }
        
        self.columns = [newColumns copy];
        
        [self getNewRows:self.rs];
        
        return YES;
    }
    
    
    OCI_TypeInfo *info = OCI_TypeInfoGet(self.conn, [self.name otext], OCI_TIF_TABLE);
    if (!info) {
        return NO;
    }
    
    int n = OCI_TypeInfoGetColumnCount(info);
    
    MutableOrderedDictionary *newColumns = [MutableOrderedDictionary dictionary];
    NSMutableArray *newNullableColumns = [NSMutableArray array];
    for (int i = 1; i <= n; i++) {
        OCI_Column *column = OCI_TypeInfoGetColumn(info, i);
        NSString *columnName = [NSString stringWithOtext:OCI_ColumnGetName(column)];
        NSString *columnType = [NSString stringWithOtext:OCI_ColumnGetSQLType(column)];
        if ([self isTypeSupported:columnType]) {
            newColumns[columnName] = columnType;
            if (OCI_ColumnGetNullable(column) == TRUE) {
                [newNullableColumns addObject:columnName];
            }
        }
    }
    
    self.columns = [newColumns copy];
    self.nullableColumns = newNullableColumns;
    OCI_TypeInfoFree(info);
    
    self.rows = [NSMutableArray array];
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmtFmt(st, "SELECT * FROM %m", [self.name otext]) != TRUE) {
        OCI_StatementFree(st);
        return NO;
    }
    OCI_Resultset *rs = OCI_GetResultset(st);
    
    [self getNewRows:rs];
    
    if (self.rs) {
        OCI_StatementFree(OCI_ResultsetGetStatement(self.rs));
    }
    
    return YES;
}

- (void)getNewRows:(OCI_Resultset *)rs
{
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

- (BOOL)insertRowWithColumns:(NSArray *)columns values:(NSArray *)values
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"INSERT INTO %@ VALUES (", self.name];
    
    for (int i = 0; i < columns.count; i++) {
        [sql appendFormat:@"%@, ", [self formatForInsert:values[i] type:self.columns[columns[i]]]];
    }
    
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 2, 2)];
    [sql appendString:@")"];
    
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    [self refresh];
    
    return YES;
}

- (NSString *)formatForInsert:(NSString *)value type:(NSString *)type
{
    if ([value isEqualToString:@"NULL"]) {
        return value;
    }
    if ([type isEqualToString:@"NUMBER"]) {
        return value;
    }
    if ([type isEqualToString:@"VARCHAR2"]) {
        return [NSString stringWithFormat:@"'%@'", value];
    }
    if ([type isEqualToString:@"DATE"]) {
        NSString *format = @"YYYY-MM-DD HH24:MI:SS";
        return [NSString stringWithFormat:@"TO_DATE('%@', '%@')", value, format];
    }
    
    return nil;
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

- (BOOL)alterName:(NSString *)name
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME TO %@", self.name, name];
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    self.name = name;
    return YES;
}

- (BOOL)alterAttributeName:(NSString *)attribute newName:(NSString *)newName
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ RENAME COLUMN %@ TO %@", self.name,
        attribute, newName];
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    return [self refresh];
}

- (BOOL)alterAttributeType:(NSString *)attribute newType:(NSString *)type
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *newType = type;
    if ([type isEqualToString:@"VARCHAR2"]) {
        newType = [NSString stringWithFormat:@"VARCHAR2(%@)", VarcharLimit];
    }
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ MODIFY (%@ %@)", self.name,
                     attribute, newType];
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    return [self refresh];
}

- (BOOL)alterAttributeNullability:(NSString *)attribute nullability:(BOOL)nullability
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ MODIFY (%@ %@)", self.name,
        attribute, nullability ? @"NULL" : @"NOT NULL"];
    
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    if (nullability) {
        [self.nullableColumns addObject:attribute];
    }
    else {
        [self.nullableColumns removeObject:attribute];
    }
    
    return YES;
}

- (BOOL)addAttribute
{
    static NSUInteger attributeNum = 0;
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ ADD (%@_attrib_%lu NUMBER)",
        self.name, self.name, (unsigned long)attributeNum++];
    
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    return [self refresh];
}

- (BOOL)removeAttribute:(NSString *)attribute
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ DROP COLUMN %@", self.name,
        attribute];
    
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    return [self refresh];
}

- (BOOL)refreshConstraints
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"SELECT cc.constraint_name, cc.column_name \
                     FROM all_constraints c \
                     JOIN all_cons_columns cc ON (c.owner = cc.owner \
                     AND c.constraint_name = cc.constraint_name) \
                     WHERE c.constraint_type = 'U' \
                     AND c.table_name = '%@'", self.name];
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    MutableOrderedDictionary *newUniqueColumns = [MutableOrderedDictionary dictionary];
    OCI_Resultset *rs = OCI_GetResultset(st);
    while (OCI_FetchNext(rs)) {
        NSString *constraintName = [NSString stringWithOtext:OCI_GetString(rs, 1)];
        NSString *columnName = [NSString stringWithOtext:OCI_GetString(rs, 2)];
        if (!newUniqueColumns[constraintName]) {
            newUniqueColumns[constraintName] = [NSMutableArray array];
        }
        [newUniqueColumns[constraintName] addObject:columnName];
    }
    
    OCI_StatementFree(st);
    self.uniqueColumns = [newUniqueColumns copy];
    
    return YES;
}

- (BOOL)makeUnique:(NSArray<NSString *> *)attributes
{
    NSMutableString *sql = [NSMutableString stringWithFormat:@"ALTER TABLE %@ ADD CONSTRAINT %@",
        self.name, self.name];
    for (NSString *attribute in attributes) {
        [sql appendFormat:@"_%@", attribute];
    }
    [sql appendString:@"_uq UNIQUE ("];
    
    for (NSString *attribute in attributes) {
        [sql appendFormat:@"%@, ", attribute];
    }
    
    [sql deleteCharactersInRange:NSMakeRange(sql.length - 2, 2)];
    [sql appendString:@")"];
    
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    return [self refreshConstraints];
}

- (BOOL)removeConstraint:(NSString *)constraint
{
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    NSString *sql = [NSString stringWithFormat:@"ALTER TABLE %@ DROP CONSTRAINT %@", self.name,
        constraint];
    if (OCI_ExecuteStmt(st, [sql otext]) != TRUE) {
        return NO;
    }
    
    OCI_StatementFree(st);
    
    return [self refreshConstraints];
}


@end
