//
//  PLYRegisterViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 29/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYRegisterViewController.h"


#import <Accounts/Accounts.h>
#import <Twitter/Twitter.h>
#import "PLYRegisterViewController.h"
#import <StackMob.h>
#import <QuartzCore/QuartzCore.h>

#import "PLYAppDelegate.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"
#import "User.h"

@implementation PLYRegisterViewController

-(NSArray *)facebookPermissions
{
    return @[ @"user_about_me", @"user_relationships", @"user_location"];
}

-(id)init
{
    self = [super initWithNibName:@"PLYRegisterViewController" bundle:[NSBundle mainBundle]];
    
    if (self) {
        CGRect rowRect = CGRectMake(5, 5, 200, 70);
        CGRect tfRect = CGRectMake(5, 2, 280, 34);
        
        UIView *row1 = [[UIView alloc] initWithFrame:rowRect];
        UIView *row2 = [[UIView alloc] initWithFrame:rowRect];
        UIView *row3 = [[UIView alloc] initWithFrame:rowRect];
        
        UITextField *input1 = [[UITextField alloc] initWithFrame:tfRect];
        UITextField *input2 = [[UITextField alloc] initWithFrame:tfRect];
        UITextField *input3 = [[UITextField alloc] initWithFrame:tfRect];
        
        [input1 setPlaceholder:@"username"];
        [input2 setPlaceholder:@"password"];
        [input3 setPlaceholder:@"email"];
        
        input1.returnKeyType = UIReturnKeyNext;
        input2.returnKeyType = UIReturnKeyNext;
        input3.returnKeyType = UIReturnKeyDone;
        
        [input1 setDelegate: self];
        [input2 setDelegate: self];
        [input3 setDelegate: self];
        
        /* pads */
        UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
        input1.leftView = paddingView;
        input1.leftViewMode = UITextFieldViewModeAlways;
        input1.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        
        paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
        input2.leftView = paddingView;
        input2.leftViewMode = UITextFieldViewModeAlways;
        input2.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        
        paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
        input3.leftView = paddingView;
        input3.leftViewMode = UITextFieldViewModeAlways;
        input3.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
        
        /* color border radii */
        input1.layer.cornerRadius = 2;
        input2.layer.cornerRadius = 2;
        input3.layer.cornerRadius = 2;
        
        [input1 setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:20]];
        [input2 setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:20]];
        [input3 setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:20]];
        
        [input1 setBackgroundColor:[UIColor whiteColor]];
        [input2 setBackgroundColor:[UIColor whiteColor]];
        [input3 setBackgroundColor:[UIColor whiteColor]];
        
        /* caps */
        input1.autocapitalizationType = UITextAutocapitalizationTypeNone;
        input3.autocapitalizationType = UITextAutocapitalizationTypeNone;
        
        [input1 setBorderStyle:UITextBorderStyleNone];
        [input2 setBorderStyle:UITextBorderStyleNone];
        [input3 setBorderStyle:UITextBorderStyleNone];
        
        [input1 setAutocorrectionType:UITextAutocorrectionTypeNo];
        [input2 setAutocorrectionType:UITextAutocorrectionTypeNo];
        [input3 setAutocorrectionType:UITextAutocorrectionTypeNo];
        
        [input2 setSecureTextEntry:YES];
        
        UIButton *btn1 = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 290, 40)];
        UIButton *btn2 = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 290, 40)];
        
        [PLYTheme setStandardButtonGrad:btn1];
        [PLYTheme setStandardButtonGrad:btn2];
        
        [btn1 setTitle:@"Sign in with Facebook" forState:UIControlStateNormal];
        [btn2 setTitle:@"Sign in with Twitter" forState:UIControlStateNormal];
        [btn1 addTarget:self action:@selector(facebookSignIn) forControlEvents:UIControlEventTouchUpInside];
        [btn2 addTarget:self action:@selector(twitterSignIn) forControlEvents:UIControlEventTouchUpInside];
        
        [row1 addSubview:input1];
        [row2 addSubview:input2];
        [row3 addSubview:input3];
        
        self.rows = @[row1, row2, row3, btn1, btn2, input1, input2, input3];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationBar *navBar = (UINavigationBar *)[self.view viewWithTag:2];
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Register"];
    [navBar pushNavigationItem:navItem animated:NO];
    
    navItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(goBack:)];
    navItem.rightBarButtonItem = [PLYTheme textBarButtonWithTitle:@"done" target:self selector:@selector(completeRegistration:)];
    
    self.notificationView = [[PLYSimpleNotificationView alloc] initWithCustomNavBar:navBar];
    
    UITableView *tableView = (UITableView *)[self.view viewWithTag:1];
    tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 20)];
    
    tableView.backgroundView = nil;
    tableView.backgroundColor = [PLYTheme backgroundLightColor];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == [self.rows objectAtIndex:5]) {
        [(UITextField *)[self.rows objectAtIndex:6] becomeFirstResponder];
    } else if (textField == [self.rows objectAtIndex:6]) {
        [(UITextField *)[self.rows objectAtIndex:7] becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    
    return NO;
}

# pragma mark table view stuff

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 3;
    } else {
        return 2;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];

    if ([indexPath indexAtPosition:0] == 0) {
        [cell.contentView addSubview:[self.rows objectAtIndex:[indexPath indexAtPosition:1]]];
        
        if ([indexPath indexAtPosition:1] == 0) {
            [PLYTheme setTopGroupedTableViewCell:cell];
        } else if ([indexPath indexAtPosition:1] == 1) {
            [PLYTheme setMidGroupedTableViewCell:cell];
        } else if ([indexPath indexAtPosition:1] == 2) {
            [PLYTheme setBotGroupedTableViewCell:cell];
        }
    } else {
        UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
        [cell.contentView addSubview:[self.rows objectAtIndex:[indexPath indexAtPosition:1] + 3]];
        
        if ([indexPath indexAtPosition:1] == 0) {
            [PLYTheme setTopGroupedTableViewCell:cell];
        } else if ([indexPath indexAtPosition:1] == 1) {
            [PLYTheme setBotGroupedTableViewCell:cell];
        }
    }
    
    return cell;
}

# pragma mark other stuff

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    if (self.loaderView) [self.loaderView removeFromSuperview];
}
- (void)completeRegistration:(id)sender {
    if (self.startedLoading) {
        [self.notificationView animateInNotificationWithMessage:@"Please wait"];
        return;
    }
    
    NSString *username = [(UITextField *)[self.rows objectAtIndex:5] text];
    NSString *pass = [(UITextField *)[self.rows objectAtIndex:6] text];
    NSString *email = [(UITextField *)[self.rows objectAtIndex:7] text];
    
    if (!([username length] > 1)) {
        [self.notificationView animateInNotificationWithMessage:@"Username too short"];
        return;
    }
    
    if (!([pass length] > 5)) {
        [self.notificationView animateInNotificationWithMessage:@"Password must be at least 6 characters"];
        return;
    }
    
    if (![PLYUtilities validEmail:email]) {
        [self.notificationView animateInNotificationWithMessage:@"Invalid email address"];
        return;
    }
    
    if ([[username componentsSeparatedByString:@"@"] count] > 1 ||
        [[username componentsSeparatedByString:@"?"] count] > 1) {
        
        [self.notificationView animateInNotificationWithMessage:@"username should not have special characters"];
        return;
    }
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    SMCoreDataStore *coreDataStore = [appDelegate.client coreDataStoreWithManagedObjectModel:appDelegate.managedObjectModel];
    NSManagedObjectContext *managedObjectContext = [coreDataStore contextForCurrentThread];
    
    User *currentUser = [NSEntityDescription insertNewObjectForEntityForName:@"User" inManagedObjectContext:managedObjectContext];
    
    username = [username lowercaseString];
    email = [email lowercaseString];
    
    [currentUser setValue:username forKey:[currentUser primaryKeyField]];
    [currentUser setPassword:pass];
    [currentUser setEmail:email];
    
    [managedObjectContext insertObject:currentUser];
    
    UIView *loader = [PLYUtilities getLoader];
    [loader setFrame:CGRectMake(loader.frame.origin.x, 110, loader.frame.size.width, loader.frame.size.height)];
    [(UIActivityIndicatorView *)loader.subviews[0] startAnimating];
    [self.navigationController.view addSubview:loader];
    self.loaderView = loader;
    
    NSFetchRequest *fetchRequest1 = [[NSFetchRequest alloc] init];
    [fetchRequest1 setPredicate:[NSPredicate predicateWithFormat:@"username == %@", username]];
    [fetchRequest1 setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
    
    self.startedLoading = YES;
    void (^insertUser)(void) = ^(void) {
        [managedObjectContext saveOnSuccess:^{
            SMClient *client = ((PLYAppDelegate *)[[UIApplication sharedApplication] delegate]).client;
            [client loginWithUsername:username password:pass onSuccess:^(NSDictionary *result){
                self.startedLoading = NO;
                [loader removeFromSuperview];
                self.loaderView = nil;
                PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate completeUserLogin];
            } onFailure:^(NSError *err){
                self.startedLoading = NO;                
                [loader removeFromSuperview];
                self.loaderView = nil;
                [self.notificationView animateInNotificationWithMessage:@"error signing up"];
            }];
        } onFailure:^(NSError *error) {
            self.startedLoading = NO;
            [loader removeFromSuperview];
            self.loaderView = nil;
            [self.notificationView animateInNotificationWithMessage:@"We couldn't sign you up"];
        }];
    };
    
    void (^checkEmail)(void) = ^(void) {
        NSFetchRequest *fetchRequest2 = [[NSFetchRequest alloc] init];
        [fetchRequest2 setPredicate:[NSPredicate predicateWithFormat:@"email == %@", email]];
        [fetchRequest2 setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
        
        [managedObjectContext executeFetchRequest:fetchRequest2 onSuccess:^(NSArray *results) {
            if ([results count] > 0) {
                [loader removeFromSuperview];
                [self.notificationView animateInNotificationWithMessage:@"email already being used"];
            } else {
                insertUser();
            }
        } onFailure:^(NSError *error) {
            insertUser();
        }];
    };
    
    [managedObjectContext executeFetchRequest:fetchRequest1 onSuccess:^(NSArray *results) {
        if ([results count] > 0) {
            [loader removeFromSuperview];
            [self.notificationView animateInNotificationWithMessage:@"username already being used"];
        } else {
            checkEmail();
        }
    } onFailure:^(NSError *error) {
        checkEmail();
    }];
    
}

-(void)updateFacebookBtn:(BOOL)active
{
    UIButton *facebookBtn = [self.rows objectAtIndex:3];
    
    if (active) {
        [facebookBtn setTitle:@"Logged in with facebook" forState:UIControlStateNormal];
        [facebookBtn setBackgroundColor:[UIColor grayColor]];
        [facebookBtn setEnabled:NO];
    } else {
        [facebookBtn setTitle:@"Login with Facebook" forState:UIControlStateNormal];
    }
}

- (void)facebookSignIn{
    PLYAppDelegate *app = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [app openSessionWithCanShowError:YES stateOpenBlock:^() {
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"hasUsedFacebook"];
        [self updateFacebookBtn:YES];
    } stateClosedBlock:^{
        [self updateFacebookBtn:NO];
    }];
}

- (void)twitterSignIn{
    PLYAppDelegate *app = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [app twitterSignInWithBlock:^(BOOL success, ACAccount *acct) {
        if (success) {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                UIButton *btn = (UIButton *)self.rows[4];
                [btn setBackgroundColor:[UIColor grayColor]];
                [btn setTitle:@"signed in with Twitter" forState:UIControlStateNormal];
                [btn setEnabled:NO];
            });
        }
    }];
}
@end
