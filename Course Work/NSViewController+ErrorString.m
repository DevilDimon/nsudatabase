//
//  NSViewController+errorString.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "NSViewController+ErrorString.h"
#import "ocilib.h"

@implementation NSViewController (errorString)

- (NSString *)errorString
{
    OCI_Error *error = OCI_GetLastError();
    return [NSString stringWithFormat:@"code  : ORA-%05i\n"
            "msg   : %s\n"
            "sql   : %s\n",
            OCI_ErrorGetOCICode(error),
            OCI_ErrorGetString(error),
            OCI_GetSql(OCI_ErrorGetStatement(error))];
}

@end
