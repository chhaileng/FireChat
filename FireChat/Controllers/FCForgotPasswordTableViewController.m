//
//  FCForgotPasswordTableViewController.m
//  FireChat
//
//  Created by soknaly on 10/29/16.
//  Copyright © 2016 Sokna Ly. All rights reserved.
//

#import "FCForgotPasswordTableViewController.h"
#import "FCTextField.h"

@interface FCForgotPasswordTableViewController ()

@property (nonatomic, weak) IBOutlet FCTextField *emailTextField;

@end

@implementation FCForgotPasswordTableViewController

- (void)viewDidLoad {
  [super viewDidLoad];
}

#pragma mark - Validation

- (void)validateForgetPasswordWithSuccess:(void(^)())success {
  NSString *message = nil;
  if ([self.emailTextField.text isEmpty]) {
    message = @"Please input your email!";
    [self.emailTextField becomeFirstResponder];
  } else if (![self.emailTextField.text isValidEmail]) {
    message = @"Please input a valid email!";
    [self.emailTextField becomeFirstResponder];
  }
  if (message) {
    [FCAlertController showErrorWithTitle:@"Reset Password Failed"
                                  message:message
                         inViewController:self];
  } else {
    success();
  }
}

#pragma mark - Actions

- (IBAction)dismissButtonAction:(id)sender {
  [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetButtonAction:(id)sender {
  [self validateForgetPasswordWithSuccess:^{
    [FCProgressHUD show];
    [[FIRAuth auth] sendPasswordResetWithEmail:self.emailTextField.text completion:^(NSError * _Nullable error) {
      [FCProgressHUD dismiss];
      if (error) {
        [FCAlertController showErrorWithTitle:@"Reset Password Failed"
                                      message:error.localizedDescription
                             inViewController:self];
      } else {
        [FCAlertController showErrorWithTitle:@"Reset Password Successfully"
                                      message:@"Your reset password request has been sent. Please check your email!"
                             inViewController:self handlerBlock:^{
                               [self dismissViewControllerAnimated:YES completion:nil];
                             }];
      }
    }];
  }];
}


@end
