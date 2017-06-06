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
    OCI_Statement *st = OCI_StatementCreate(self.conn);
    OCI_ExecuteStmt(st, [self.codeView.textView.string otext]);
    OCI_StatementFree(st);
}

@end
