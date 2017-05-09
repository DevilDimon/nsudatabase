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
    NSLog(@"OCILib error: %s", OCI_ErrorGetString(err));
}


int main(int argc, const char * argv[]) {
    if (OCI_Initialize(error_handler, NULL, OCI_ENV_CONTEXT) == TRUE) {
        NSLog(@"OCILib successfully initialized");
    } else {
        return 1;
    }
    return NSApplicationMain(argc, argv);
}
