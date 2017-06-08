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
#import "ReportViewController.h"
#import "Table.h"

@interface CodeViewController ()

@property (nonatomic) IBOutlet MGSFragariaView *codeView;

@end


@implementation CodeViewController

- (void)viewDidLoad
{
    self.codeView.syntaxDefinitionName = @"sql";
}

- (IBAction)onExecute:(id)sender
{
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main"
            bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    [progressWC.window makeKeyWindow];
    
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    
    if (OCI_ExecuteStmt(st, [self.codeView.textView.string otext]) == TRUE) {
        
        NSString *selectString = @"SELECT";
        NSString *code = self.codeView.textView.string;
        NSRange prefixRange = [code rangeOfString:selectString
                                               options:(NSAnchoredSearch | NSCaseInsensitiveSearch)];
        if (prefixRange.location == NSNotFound) {
            OCI_StatementFree(st);
            [self dismissController:nil];
            return;
        }
        
        ReportViewController *vc = [[NSStoryboard storyboardWithName:@"Main"
            bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ReportViewController"];
        vc.table = [[Table alloc] initWithName:nil connection:self.conn resultSet:OCI_GetResultset(st)];
        
        [self presentViewControllerAsModalWindow:vc];
        
    }
    
    [self.view.window endSheet:progressWC.window];
}

@end
