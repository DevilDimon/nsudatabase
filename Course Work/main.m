//
//  main.m
//  Course Work
//
//  Created by Dmitriy Serov on 01/04/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ocilib.h"

static void error_handler(OCI_Error *err) {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleCritical;
    alert.messageText = @"Error";
    alert.informativeText = [NSString stringWithFormat:@"code  : ORA-%05i\n"
                                    "msg   : %s\n"
                                    "sql   : %s\n",
                                    OCI_ErrorGetOCICode(err),
                                    OCI_ErrorGetString(err),
                                    OCI_GetSql(OCI_ErrorGetStatement(err))];
    [alert runModal];
}


int main(int argc, const char * argv[]) {
    if (OCI_Initialize(error_handler, NULL, OCI_ENV_CONTEXT) == TRUE) {
        NSLog(@"OCILib successfully initialized");
    } else {
        return 1;
    }
    return NSApplicationMain(argc, argv);
}
