//
//  PLYSignInViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 28/04/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYSignInViewController.h"
#import "PLYAppDelegate.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"

#import <StackMob.h>
#import <QuartzCore/QuartzCore.h>

#define BG_IMAGE_TAG 1
#define USERNAME_TAG 2
#define PASSWORD_TAG 3

@implementation PLYSignInViewController

-(id) init
{
    self = [super initWithNibName:@"PLYSignInViewController" bundle:[NSBundle mainBundle]];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [PLYTheme backgroundLightColor];
    
    UINavigationBar *navBar = (UINavigationBar *)[self.view viewWithTag:11];
    UINavigationItem *navItem = [[UINavigationItem alloc] initWithTitle:@"Sign In"];
    [navBar pushNavigationItem:navItem animated:NO];
    
    navItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(goBack:)];
    navItem.rightBarButtonItem = [PLYTheme textBarButtonWithTitle:@"done" target:self selector:@selector(completeSignIn:)];
    
    self.notificationView = [[PLYSimpleNotificationView alloc] initWithCustomNavBar:navBar];
    
    UIImage *bgImage = (UIImage *)[self.view viewWithTag:BG_IMAGE_TAG];
	// Do any additional setup after loading the view.
    [self setupUsernamePasswordFields];
}

-(void)setupUsernamePasswordFields
{
    
    UITableView *tableView = (UITableView *)[self.view viewWithTag:12];
    tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    
    tableView.backgroundView = nil;
    tableView.backgroundColor = [PLYTheme backgroundLightColor];
    
    CGRect rowRect = CGRectMake(5, 5, 200, 70);
    UITableViewCell *row1 = [[UITableViewCell alloc] initWithFrame:rowRect];
    UITableViewCell *row2 = [[UITableViewCell alloc] initWithFrame:rowRect];
    
    [PLYTheme setTopGroupedTableViewCell:row1];
    [PLYTheme setBotGroupedTableViewCell:row2];
    
    UITextField *field1 = [[UITextField alloc] initWithFrame:CGRectMake(20, 8, 280, 35)];
    UITextField *field2 = [[UITextField alloc] initWithFrame:CGRectMake(20, 8, 280, 35)];
    [field1 setTag:USERNAME_TAG];
    [field2 setTag:PASSWORD_TAG];
    
    [field1 setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:20]];
    [field2 setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:20]];
    
    [field1 setBackgroundColor:[UIColor whiteColor]];
    [field2 setBackgroundColor:[UIColor whiteColor]];
    
    field1.layer.cornerRadius = 2;
    field2.layer.cornerRadius = 2;
    
    /* padding */
    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    field1.leftView = paddingView;
    field1.leftViewMode = UITextFieldViewModeAlways;
    field1.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 5, 0)];
    field2.leftView = paddingView;
    field2.leftViewMode = UITextFieldViewModeAlways;
    field2.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    
    /* border ... */
    [field1 setBorderStyle:UITextBorderStyleNone];
    [field2 setBorderStyle:UITextBorderStyleNone];
    
    [field1 setPlaceholder:@"username"];
    [field2 setPlaceholder:@"password"];
    
    [field2 setSecureTextEntry:YES];
    
    [field1 setDelegate:self];
    [field2 setDelegate:self];
    
    field1.autocapitalizationType = UITextAutocapitalizationTypeNone;
    field2.autocapitalizationType = UITextAutocapitalizationTypeNone;
    
    [field1 becomeFirstResponder];
    
    [row1 addSubview:field1];
    [row2 addSubview:field2];
    
    self.rows = @[row1, row2];
}

#pragma mark table view stuff

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

-(BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.rows[[indexPath indexAtPosition:1]];
}

#pragma mark other stuff

-(CGFloat) tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 55;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField.tag == USERNAME_TAG) {
        [(UITextField *)[self.view viewWithTag:PASSWORD_TAG] becomeFirstResponder];
    } else {
        [self completeSignIn:NULL];
    }
    
    return NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)completeSignIn:(id)sender {
    if (self.startedLoading) {
        [self.notificationView animateInNotificationWithMessage:@"Please wait"];
        return;
    }
    
    NSString *username = [(UITextField *)[self.view viewWithTag:USERNAME_TAG] text];
    NSString *password = [(UITextField *)[self.view viewWithTag:PASSWORD_TAG] text];
    
    if (!([username length] > 0)) {
        [self.notificationView animateInNotificationWithMessage:@"No username"];
        return;
    }
    
    if (!([password length] > 0)) {
        [self.notificationView animateInNotificationWithMessage:@"Password not given"];
        return;
    }
    
    UIView *loader = [PLYUtilities getLoader];
    [loader setFrame:CGRectMake(loader.frame.origin.x, 110, loader.frame.size.width, loader.frame.size.height)];
    [(UIActivityIndicatorView *)loader.subviews[0] startAnimating];
    [self.navigationController.view addSubview:loader];
    self.loaderView = loader;
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    SMClient *client = ((PLYAppDelegate *)[[UIApplication sharedApplication] delegate]).client;
    self.startedLoading = YES;
    [client loginWithUsername:username password:password
                    onSuccess:^(NSDictionary *result) {
                        self.startedLoading = NO;
                        [loader removeFromSuperview];
                        self.loaderView = nil;
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
                        [appDelegate completeUserLogin];
                    }
                    onFailure:^(NSError *error) {
                        self.startedLoading = NO;
                        [loader removeFromSuperview];
                        self.loaderView = nil;
                        [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                        
                        [self.notificationView animateInNotificationWithMessage:@"We couldn't sign you in"];
                    }];
    
}
- (void)goBack:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    if (self.loaderView) [self.loaderView removeFromSuperview];
}


@end
