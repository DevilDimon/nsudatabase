//
//  AppDelegate.m
//  Course Work
//
//  Created by Dmitriy Serov on 01/04/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "AppDelegate.h"
#import "ocilib.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationWillTerminate:(NSNotification *)notification
{
    OCI_Cleanup();
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


@end
