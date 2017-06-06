//
//  CodeViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 14/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "CodeViewController.h"
#import <Fragaria.h>
#import "NSString+Oracle.h"
#import "NSViewController+ErrorString.h"

@interface CodeViewController ()

@property (nonatomic) IBOutlet MGSFragariaView *codeView;

@end


@implementation CodeViewController

- (void)viewDidLoad
{
    self.codeView.syntaxDefinitionName = @"sql";
    self.codeView.string = @"-- Type a single SQL statement or a PL/SQL block";
}

- (IBAction)onExecute:(id)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main"
            bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    
    if (OCI_ExecuteStmt(st, [self.codeView.textView.string otext]) != TRUE) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Table Update Error";
        alert.informativeText = [self errorString];
        [alert runModal];
    }
    else {
        [self dismissController:nil];
    }
    
    [self.view.window endSheet:progressWC.window];
    OCI_StatementFree(st);
}

@end
