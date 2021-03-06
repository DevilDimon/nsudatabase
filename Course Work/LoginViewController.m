//
//  LoginViewController.m
//  Course Work
//
//  Created by Dmitriy Serov on 09/05/2017.
//  Copyright © 2017 NSU. All rights reserved.
//

#import "LoginViewController.h"
#import "MainWindowController.h"
#import "MainViewController.h"
#import "NSViewController+ErrorString.h"
#import "NSString+Oracle.h"
#import "AppDelegate.h"
#import "ocilib.h"

@interface LoginViewController ()

@property (nonatomic) IBOutlet NSTextField *connectionTextField;
@property (nonatomic) IBOutlet NSTextField *loginTextField;
@property (nonatomic) IBOutlet NSSecureTextField *passwordTextField;

@property (nonatomic) OCI_Connection *conn;

@end


@implementation LoginViewController

- (void)viewWillAppear
{
    self.view.window.initialFirstResponder = self.connectionTextField;
}

- (void)prepareForSegue:(NSStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowMainWindow"]) {
        MainWindowController *mainWC = (MainWindowController *)segue.destinationController;
        MainViewController *mainVC = (MainViewController *)mainWC.contentViewController;
        mainVC.connection = self.conn;
    }
}

- (IBAction)onLoginPressed:(id)sender
{
    
    NSWindowController *progressWC = [[NSStoryboard storyboardWithName:@"Main" bundle:[NSBundle mainBundle]] instantiateControllerWithIdentifier:@"ProgressWindowController"];
    
    [self.view.window beginSheet:progressWC.window completionHandler:^(NSModalResponse response) {}];
    
    // TODO: REMOVE
    self.connectionTextField.stringValue = @"localhost:49161";
    self.loginTextField.stringValue = @"system";
    self.passwordTextField.stringValue = @"oracle";
    
    self.conn = OCI_ConnectionCreate([self.connectionTextField.stringValue UTF8String],
        [self.loginTextField.stringValue UTF8String], [self.passwordTextField.stringValue UTF8String], OCI_SESSION_DEFAULT);
    
    if (!self.conn) {
        NSAlert *alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleCritical;
        alert.messageText = @"Login Error";
        alert.informativeText = [self errorString];
        [alert runModal];
        
        [self.view.window endSheet:progressWC.window];
        return;
    }
    
    OCI_SetAutoCommit(self.conn, TRUE);
    
    [self.view.window endSheet:progressWC.window];
    [self performSegueWithIdentifier:@"ShowMainWindow" sender:sender];
    [self.view.window close];
}


@end
