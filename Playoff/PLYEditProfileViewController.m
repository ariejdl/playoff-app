//
//  PLYEditProfileViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 16/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYEditProfileViewController.h"
#import "PLYProfileViewController.h"
#import <QuartzCore/QuartzCore.h>

#import <SDWebImage/UIImageView+WebCache.h>

#import "PLYAppDelegate.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"

#import "User.h"

#define MAIN_PAD 10
#define PROF_IMAGE_DIM 110

@implementation PLYEditProfileViewController

@synthesize loaderView = _loaderView;

-(id)initWithUserDict: (NSDictionary *) profile
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    
    if (self) {
        self.currentUserDict = profile;
    }
    
    return self;
}


- (void) handleBack:(id)sender
{
    UIViewController *prevVC = [self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 2];
    if ([prevVC respondsToSelector:@selector(reloadUserInfo)]) {
        PLYProfileViewController *profVC = (PLYProfileViewController *) prevVC;
        [profVC reloadUserInfo];
    }

    if (self.loaderView) [self.loaderView removeFromSuperview];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.backgroundColor = [PLYTheme backgroundDarkColor];
    self.tableView.backgroundView = nil;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;

    self.navigationItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(handleBack:)];
   
    // save btn
    self.navigationItem.rightBarButtonItem = [PLYTheme textBarButtonWithTitle:@"save" target:self selector:@selector(saveChanges)];
    
    [self setTitle: @"Editing Profile"];
    
    // cells
    UITableViewCell *imgCell = [[UITableViewCell alloc] initWithFrame: CGRectZero];
    UITableViewCell *bioCell = [[UITableViewCell alloc] initWithFrame: CGRectZero];
    UITableViewCell *logoutCell = [[UITableViewCell alloc] initWithFrame: CGRectZero];

    [PLYTheme setTopGroupedTableViewCell:imgCell];
    [PLYTheme setMidGroupedTableViewCell:bioCell];
    [PLYTheme setBotGroupedTableViewCell:logoutCell];
    
    [imgCell setSelectionStyle: UITableViewCellSelectionStyleNone];
    [bioCell setSelectionStyle: UITableViewCellSelectionStyleNone];
    [logoutCell setSelectionStyle: UITableViewCellSelectionStyleNone];
    
    // profile image stuff
    UIImageView *profileImage = [[UIImageView alloc] initWithFrame: CGRectMake(MAIN_PAD, MAIN_PAD, PROF_IMAGE_DIM, PROF_IMAGE_DIM)];
    
    UILabel *editImage = [[UILabel alloc] initWithFrame: CGRectMake(PROF_IMAGE_DIM - 50, PROF_IMAGE_DIM - 20, 50, 20)];
    [editImage setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.4]];
    editImage.textColor = [UIColor whiteColor];
    [editImage setFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:12]];
    [editImage setTextAlignment: NSTextAlignmentCenter];
    [editImage setText: @"change"];
    [profileImage addSubview: editImage];
    
    UIButton *editImageBtn = [[UIButton alloc] initWithFrame: CGRectMake(MAIN_PAD, MAIN_PAD, PROF_IMAGE_DIM, PROF_IMAGE_DIM)];
    [editImageBtn addTarget:self action:@selector(chooseNewProfileImage) forControlEvents:UIControlEventTouchUpInside];
    
    NSString *profImageURL = [self.currentUserDict valueForKey:@"profile_image"];
    [profileImage setImage:[UIImage imageNamed:@"prof-medium-1"]];
    
    if (profImageURL) {
        [profileImage setImageWithURL:[NSURL URLWithString:profImageURL]
             placeholderImage:nil
                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                        
                    }];
    }
    
    [imgCell.contentView addSubview: profileImage];
    [imgCell.contentView addSubview:editImageBtn];
    
    // profile name
    UILabel *profileName = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_PAD + PROF_IMAGE_DIM + MAIN_PAD, MAIN_PAD, 120, 20)];
    [profileName setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]]];
    [profileName setText:self.currentUserDict[@"username"]];
    [profileName setBackgroundColor:[UIColor clearColor]];
    [imgCell.contentView addSubview:profileName];
    
    // bio stuff
    UILabel *placeholderLabel = [[UILabel alloc] initWithFrame: CGRectMake(MAIN_PAD + 4, MAIN_PAD + 4, 100, 20)];
    [placeholderLabel setText: @"A short bio"];
    [placeholderLabel setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:15]];
    placeholderLabel.textColor = [PLYTheme backgroundDarkColor];
    [placeholderLabel setBackgroundColor:[UIColor clearColor]];
    self.placeholderBio = placeholderLabel;
    
    UITextView *bio = [[UITextView alloc] initWithFrame: CGRectMake(MAIN_PAD, MAIN_PAD, 280, 100)];
    [bio setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:.1]];
    [bio setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:15]];
    [bio setDelegate:self];
    bio.layer.cornerRadius = 5;
    [bio setBackgroundColor:[UIColor whiteColor]];
    bio.contentInset = UIEdgeInsetsMake(-(MAIN_PAD / 2), -(MAIN_PAD / 2), 0, 0);
    
    [bio setText:[self.currentUserDict valueForKey:@"bio"]];
    if ([self.currentUserDict valueForKey:@"bio"] && [(NSString *)[self.currentUserDict valueForKey:@"bio"] length] > 0) {
        [placeholderLabel setHidden:YES];
    } else {
        [placeholderLabel setHidden:NO];
    }
    
    [bioCell.contentView addSubview: placeholderLabel];
    [bioCell.contentView addSubview: bio];
    
    // logout btn
    UIButton *logoutBtn = [[UIButton alloc] initWithFrame: CGRectMake(MAIN_PAD, MAIN_PAD, 280, 40)];
    [logoutBtn addTarget:self action:@selector(logUserOut) forControlEvents:UIControlEventTouchUpInside];
    [PLYTheme setGrayButton:logoutBtn];
    [logoutBtn setTitle:@"Logout" forState:UIControlStateNormal];
    
    [logoutCell.contentView addSubview: logoutBtn];

    self.cells = @[imgCell, bioCell, logoutCell];
    self.fields = @[profileImage, editImageBtn, bio, logoutBtn];
}

-(void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text length] > 0) {
        [self.placeholderBio setHidden:YES];
    } else {
        [self.placeholderBio setHidden:NO];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *imgURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    UIImage *image = [info valueForKey:UIImagePickerControllerOriginalImage];
    [self uploadProfileImage:imgURL uploadImage: image];
}

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {
    
    if ([navigationController isKindOfClass:[UIImagePickerController class]] &&
        ((UIImagePickerController *)navigationController).sourceType == UIImagePickerControllerSourceTypePhotoLibrary) {
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

-(void)saveChanges
{
    UIView *loaderView = [PLYUtilities getLoader];
    if (self.loaderView) [self.loaderView removeFromSuperview];
    self.loaderView = loaderView;
    [self.navigationController.view addSubview:loaderView];
    [(UIButton *)self.fields[1] setEnabled:NO];
    [loaderView setFrame:CGRectMake(loaderView.frame.origin.x, 100, loaderView.frame.size.width, loaderView.frame.size.height)];
    [(UIActivityIndicatorView *)[loaderView subviews][0] startAnimating];
    
    void (^cleanupFn)(void) = ^() {
        [loaderView removeFromSuperview];
        [(UIButton *)self.fields[1] setEnabled:YES];
    };
    
    void (^errorFn)(NSError *) = ^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"There was a problem uploading"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        cleanupFn();
    };
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username == %@", self.currentUserDict[@"username"]]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
        if (results == 0) {
            errorFn(nil);
        }
        
        User *user = results[0];
        
        UITextView *textView = (UITextView *)self.fields[2];
        [user setValue: [textView text] forKey: @"bio"];
         [textView resignFirstResponder];
        
        
        [managedObjectContext saveOnSuccess:^(void) {
            cleanupFn();
        } onFailure:errorFn];
        
    } onFailure:errorFn];
}

-(void)logUserOut
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate.client logoutOnSuccess:^(NSDictionary *res){
        [appDelegate presentLogin:YES];
    } onFailure:^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"There was a problem logging you out"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    }];
}


-(void)chooseNewProfileImage
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    [picker setDelegate:self];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:picker animated:YES completion:nil];
}

-(void)uploadProfileImage:(NSURL *)imageURL  uploadImage:(UIImage *) uploadImage
{
    NSString *ext = [[[imageURL lastPathComponent] componentsSeparatedByString: @"."] lastObject];
    NSString *mimeType = @{
        @"JPG": @"image/jpeg",
        @"PNG": @"image/png",
        @"GIF": @"image/gif"
    }[ext];
    
    UIView *loaderView = [PLYUtilities getLoader];
    if (self.loaderView) [self.loaderView removeFromSuperview];
    self.loaderView = loaderView;
    [self.navigationController.view addSubview:loaderView];
    [(UIButton *)self.fields[1] setEnabled:NO];
    [(UIActivityIndicatorView *)[loaderView subviews][0] startAnimating];

    void (^cleanupFn)(void) = ^() {
        [loaderView removeFromSuperview];
        [(UIButton *)self.fields[1] setEnabled:YES];
    };
    
    void (^errorFn)(NSError *) = ^(NSError *error) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"There was a problem uploading"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        cleanupFn();
    };
    
    if (!mimeType)  {
        errorFn(nil);
        return;
    }
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
     
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username == %@", self.currentUserDict[@"username"]]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
        if (results == 0) {
            errorFn(nil);
        }

        NSData *imageData = UIImageJPEGRepresentation(uploadImage, 0.7);
        User *user = results[0];
        
        [user setValue:[SMBinaryDataConversion stringForBinaryData:imageData
                                                              name:[[NSString alloc]
                                                                    initWithFormat:@"profile.%@", ext, nil] contentType:mimeType]
                        forKey:@"profile_image"];
        
        [managedObjectContext saveOnSuccess:^(void) {
            [(UIImageView *)self.fields[0] setImage:[UIImage imageWithData:imageData]];
            cleanupFn();
        } onFailure:errorFn];
        
    } onFailure:errorFn];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MainCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];


    if ([indexPath indexAtPosition:1] == 0) {
        return self.cells[0];
    } else if ([indexPath indexAtPosition:1] == 1) {
        return self.cells[1];
    } else if ([indexPath indexAtPosition:1] == 2) {
        return self.cells[2];
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([indexPath indexAtPosition:1] == 0) {
        return PROF_IMAGE_DIM + 20;
    } else if ([indexPath indexAtPosition:1] == 1) {
        return 120;
    } else if ([indexPath indexAtPosition:1] == 2) {
        return 60;
    }
    return 40;
}


@end
