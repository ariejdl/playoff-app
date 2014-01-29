//
//  PLYProfileViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 15/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYProfileViewController.h"

#import "PLYAppDelegate.h"

#import "PLYThreadViewController.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "PLYEditProfileViewController.h"

#import "PLYUtilities.h"
#import "PLYTheme.h"
#import "User.h"

#define MAIN_PAD 5
#define PROFILE_IMAGE_DIM 110
#define PROF_HORIZONTAL_SPACE (320 - (MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + MAIN_PAD))
#define USER_INFO_ITEM_WIDTH 65
#define PROFILE_NAME_HEIGHT 34
#define USER_INFO_ITEM_HEIGHT 34
#define FOLLOW_BUTTON_HEIGHT 34

#define PROFILE_IMAGE_TAG 1
#define PROFILE_NAME_TAG 2
#define INFO_BTN_1_TAG 3
#define INFO_BTN_2_TAG 4
#define INFO_BTN_3_TAG 5
#define FOLLOW_BTN_TAG 6

#define INFO_BTN_1_TEXT_TAG 7
#define INFO_BTN_2_TEXT_TAG 8
#define INFO_BTN_3_TEXT_TAG 9

#define USER_BIO_TAG 10


static int pageSize = 9; // multiple of 3

@implementation PLYProfileViewController

@synthesize loaderView = _loaderView;

-(id) initWithUsername: (NSString *) username
{
    self = [super init];
    self.currentPage = 0;
    self.currentData = [[NSMutableArray alloc] init];
    self.profileDict = nil;
    self.initDownloadCount = 4;
    
    // assume it is self
    if (username == nil) {
        self.isSelf = YES;
        
        PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate.client getLoggedInUserOnSuccess:^(NSDictionary *result) {
            NSString *uname = result[@"username"];
            NSArray *unameFull = [uname componentsSeparatedByString:@"/"];
            if ([unameFull count] > 0) {
                self.currentUsername = [unameFull lastObject];
            } else {
                self.currentUsername = uname;
            }
            
            self.profileDict = result;
            [self setupProfileInfo];
        }onFailure:^(NSError *error){
            /*
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Could not find user"
                                      message:nil
                                      delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
             */
            
            if (self.isSelf) {
                PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
                [appDelegate.client logoutOnSuccess:^(NSDictionary *res){
                    [appDelegate presentLogin:YES];
                } onFailure:^(NSError *error) {
                    [appDelegate presentLogin:YES];
                }];
            }
            
        }];
    } else {
        NSArray *unameFull = [username componentsSeparatedByString:@"/"];
        if ([unameFull count] > 0) {
            self.currentUsername = [unameFull lastObject];
        } else {
            self.currentUsername = username;
        }
    }
    
    return self;
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (self.loaderView) [self.loaderView removeFromSuperview];
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.initDownloadCount) {
        [self showLoader];
    }
    self.tableView.separatorColor = [UIColor clearColor];
    self.navigationItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(handleBack)];
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320,
                                                                  MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD)];
    [headerView setBackgroundColor:[PLYTheme backgroundDarkColor]];
    [self.tableView setBackgroundColor:[PLYTheme backgroundDarkColor]];
    
    UIImageView *imageView;
    UILabel *label;
    UIControl *ctrl;
    
    // profile image
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_PAD, MAIN_PAD,
                                                              PROFILE_IMAGE_DIM, PROFILE_IMAGE_DIM)];
    [imageView setImage:[UIImage imageNamed:@"prof-medium-1"]];
    [imageView setTag:PROFILE_IMAGE_TAG];
    [headerView addSubview:imageView];
    
    
    // username
    label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD,
                                                      MAIN_PAD, PROF_HORIZONTAL_SPACE, PROFILE_NAME_HEIGHT)];
    [label setFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]]];
    [label setTag:PROFILE_NAME_TAG];
    [label setTextColor:[UIColor whiteColor]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [headerView addSubview:label];
    
    // info btn1
    ctrl = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD,
                                                     MAIN_PAD + PROFILE_NAME_HEIGHT + MAIN_PAD - 1,
                                                     USER_INFO_ITEM_WIDTH, USER_INFO_ITEM_HEIGHT)];
    [ctrl setTag:INFO_BTN_1_TAG];
    [ctrl setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.05]];
    [headerView addSubview:ctrl];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, USER_INFO_ITEM_WIDTH, 22)];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTag:INFO_BTN_1_TEXT_TAG];
    [label setTextColor:[UIColor colorWithWhite:0.7 alpha:1]];
    [ctrl addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, USER_INFO_ITEM_HEIGHT - 14, USER_INFO_ITEM_WIDTH, 14)];
    [label setText:@"playoffs"];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme smallFont]]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor colorWithWhite:0.7 alpha:1]];
    [ctrl addSubview:label];
    
    // info btn2
    ctrl = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + USER_INFO_ITEM_WIDTH,
                                                     MAIN_PAD + PROFILE_NAME_HEIGHT + MAIN_PAD - 1,
                                                     USER_INFO_ITEM_WIDTH, USER_INFO_ITEM_HEIGHT)];
    [ctrl setTag:INFO_BTN_2_TAG];
    [ctrl setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.05]];
    [headerView addSubview:ctrl];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, USER_INFO_ITEM_WIDTH, 22)];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTag:INFO_BTN_2_TEXT_TAG];
    [label setTextColor:[UIColor colorWithWhite:0.7 alpha:1]];
    [ctrl addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, USER_INFO_ITEM_HEIGHT - 14, USER_INFO_ITEM_WIDTH, 14)];
    [label setText:@"followers"];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme smallFont]]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor colorWithWhite:0.7 alpha:1]];
    [ctrl addSubview:label];
    
    // info btn3
    ctrl = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD +
                                                       USER_INFO_ITEM_WIDTH + USER_INFO_ITEM_WIDTH,
                                                     MAIN_PAD + PROFILE_NAME_HEIGHT + MAIN_PAD - 1,
                                                     USER_INFO_ITEM_WIDTH, USER_INFO_ITEM_HEIGHT)];
    [ctrl setTag:INFO_BTN_3_TAG];
    [ctrl setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.05]];
    [headerView addSubview:ctrl];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, USER_INFO_ITEM_WIDTH, 22)];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTag:INFO_BTN_3_TEXT_TAG];
    [label setTextColor:[UIColor colorWithWhite:0.7 alpha:1]];
    [ctrl addSubview:label];
    
    label = [[UILabel alloc] initWithFrame:CGRectMake(0, USER_INFO_ITEM_HEIGHT - 14, USER_INFO_ITEM_WIDTH, 14)];
    [label setText:@"following"];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme smallFont]]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor colorWithWhite:0.7 alpha:1]];
    [ctrl addSubview:label];
    
    // follow btn
    UIButton *btn = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD,
                                                     MAIN_PAD + PROFILE_NAME_HEIGHT + MAIN_PAD +
                                                        FOLLOW_BUTTON_HEIGHT + MAIN_PAD - 2,
                                                     PROF_HORIZONTAL_SPACE, USER_INFO_ITEM_HEIGHT)];
    [btn setTag:FOLLOW_BTN_TAG];
    [btn setTitle:@"Follow" forState:UIControlStateNormal];
    [PLYTheme setStandardButton:btn];
    [btn addTarget:self action:@selector(followUnfollowUser) forControlEvents:UIControlEventTouchUpInside];
    [btn setEnabled:NO];
    [headerView addSubview:btn];
    self.followButton = btn;
    
    self.tableView.tableHeaderView = headerView;
    
    if (self.isSelf) {
        [self setupEditButton];
    }
    
    // user bio
    label = [[UILabel alloc] init];
    [label setHidden:YES];
    [label setTag:USER_BIO_TAG];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor colorWithWhite:0.9 alpha:1]];
    label.lineBreakMode = NSLineBreakByWordWrapping;
    label.font = [PLYTheme mediumDefaultFont];
    [self.tableView.tableHeaderView addSubview:label];
    
    // footer ...
    [self setupFooterMoreButton];
    
    [self setupProfileInfo];
}

-(void) setupEditButton
{
    self.navigationItem.rightBarButtonItem = [PLYTheme barButtonWithTarget:self selector:@selector(editSelfView)
                                                                      img1:@"edit-but-1" img2:@"edit-but-sel-1"];
}

-(void)handleBack
{
    [self.navigationController popViewControllerAnimated:YES];
    [self hideLoader];
}

-(void)setupFooterMoreButton
{
    // show more button
    UIView *footerView = [[UIView alloc] init];
    UIButton *loadMoreBtn = [[UIButton alloc] init];
    [PLYTheme containedExpandBut:loadMoreBtn cont:footerView];
    [loadMoreBtn addTarget:self action:@selector(loadMorePlayoffs) forControlEvents:UIControlEventTouchUpInside];
    self.loadMoreBut = loadMoreBtn;
    
    self.tableView.tableFooterView = footerView;
    
}

-(void)loadMorePlayoffs
{
    [self.loadMoreBut setHidden:YES];
    self.currentPage += 1;
    [self fetchPlayoffs];
}

-(void)fetchPlayoffs
{
    if (!self.currentUsername || self.currentUsername == nil) return;
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    void (^failureHandler)(NSError *) = ^(NSError *error) {
        [self.loadMoreBut setHidden:NO];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    };
        
    SMQuery *qry = [[SMQuery alloc] initWithSchema:@"PlayoffItem"];
    [qry orderByField:@"createddate" ascending:NO];
    [qry where:@"sm_owner" isEqualTo:[[NSString alloc] initWithFormat:@"user/%@", self.currentUsername, nil]];
    [qry fromIndex:self.currentPage * pageSize toIndex:(self.currentPage + 1) * pageSize - 1];
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *results) {
        
        if (self.currentPage == 0) [self.currentData removeAllObjects];
        
        for (NSDictionary *d in results) {
            [self.currentData insertObject:d atIndex:[self.currentData count]];
        }
        
        if ([results count] == pageSize) {
            [self.tableView.tableFooterView setHidden:NO];
        } else {
            [self.tableView.tableFooterView setHidden:YES];
        }
        
        [self.tableView reloadData];
        [self.loadMoreBut setHidden:NO];
        
    } onFailure:failureHandler];
}

-(void)editSelfView
{
    PLYEditProfileViewController *editProf = [[PLYEditProfileViewController alloc]
                                              initWithUserDict:self.profileDict];
    if (self.loaderView) [self.loaderView removeFromSuperview];
    [self.navigationController pushViewController:editProf animated:YES];
}

-(void)followUnfollowUser
{
    if ([self.followButton.titleLabel.text isEqualToString: @"Follow"]) {
        [self doFollowUnfollow:YES];
    } else {
        [self doFollowUnfollow:NO];
    }
}

-(void) doFollowUnfollow: (BOOL) follow
{
    if (self.followingTransition) return;
    self.followingTransition = YES;
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self showLoader];
    
    void (^tidyUp)(BOOL) = ^(BOOL good) {
        self.followingTransition = NO;
        [self hideLoader];
        if (!good) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:follow ? @"There was a problem following" : @"There was a problem unfollowing"
                                      message:nil
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
    NSFetchRequest *fetchRequest1 = [[NSFetchRequest alloc] init];
    [fetchRequest1 setPredicate:[NSPredicate predicateWithFormat:@"username == %@", self.myUsername]];
    [fetchRequest1 setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest1 onSuccess:^(NSArray *results1) {
        if ([results1 count] > 0) {
            User *followerUser = results1[0];
            
            NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
            NSFetchRequest *fetchRequest2 = [[NSFetchRequest alloc] init];
            [fetchRequest2 setPredicate:[NSPredicate predicateWithFormat:@"username == %@", self.currentUsername]];
            [fetchRequest2 setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
            
            [managedObjectContext executeFetchRequest:fetchRequest2 onSuccess:^(NSArray *results2) {
                if ([results2 count] > 0) {
                    User *followingUser = results2[0];
                    if (follow) {
                        [followingUser addFollowersObject:followerUser];
                    } else {
                        [followingUser removeFollowersObject:followerUser];
                    }
                    
                    [managedObjectContext saveOnSuccess:^(void) {
                        [self.followButton setTitle:(follow ? @"Unfollow" : @"Follow") forState:UIControlStateNormal];
                        [self refreshFollowerCount];
                        
                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                        NSInteger followingCount = [defaults integerForKey:@"followingFeedItemCount"];
                        if (follow)
                            followingCount += 1;
                        else
                            followingCount -= 1;
                        
                        [defaults setInteger:followingCount forKey:@"followingFeedItemCount"];
                        
                        tidyUp(YES);
                    } onFailure:^(NSError *error) {
                        tidyUp(NO);
                    }];
                } else {
                    tidyUp(NO);
                }
            } onFailure:^(NSError *error) {
                tidyUp(NO);
            }];
            
        } else {
            tidyUp(NO);
        }
    } onFailure:^(NSError *error) {
        tidyUp(NO);
    }];
}


-(void)refreshFollowerCount
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    UILabel *followersLabel = (UILabel *)[self.view viewWithTag:INFO_BTN_2_TEXT_TAG];
    SMQuery *followerCountQuery = [[SMQuery alloc] initWithSchema:@"User"];
    [followerCountQuery where:@"following" isEqualTo:self.currentUsername];
    
    [appDelegate.client.dataStore performCount:followerCountQuery onSuccess:^(NSNumber *count) {
        [followersLabel setText:[[NSString alloc] initWithFormat:@"%@", count]];
        [self decrementInitItemsCountHideLoader];
    } onFailure:^(NSError *error) {
        [followersLabel setText:@"-"];
        [self decrementInitItemsCountHideLoader];
    }];
}

/* check to see if already following */
-(void)checkAndSetupFollowButton
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    void (^tidyUp)(void) = ^(void) {
        [self.followButton setEnabled:YES];
        [self decrementInitItemsCountHideLoader];
    };
    
    NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
    NSFetchRequest *fetchRequest1 = [[NSFetchRequest alloc] init];
    [fetchRequest1 setPredicate:[NSPredicate predicateWithFormat:@"username == %@", self.myUsername]];
    [fetchRequest1 setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest1 onSuccess:^(NSArray *results1) {
        if ([results1 count] > 0) {
            User *followerUser = results1[0];
            
            NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
            NSFetchRequest *fetchRequest2 = [[NSFetchRequest alloc] init];
            [fetchRequest2 setPredicate:[NSPredicate predicateWithFormat:@"username == %@", self.currentUsername]];
            [fetchRequest2 setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
            
            [managedObjectContext executeFetchRequest:fetchRequest2 onSuccess:^(NSArray *results2) {
                if ([results2 count] > 0) {
                    User *followingUser = results2[0];
                    
                    for (User *follower in followingUser.followers) {
                        if ([(NSString *)[follower valueForKey:@"username"] isEqualToString: [followerUser valueForKey:@"username"]]) {
                            [self.followButton setTitle:@"Unfollow" forState:UIControlStateNormal];
                            break;
                        }
                    }
                    
                    tidyUp();

                } else {
                    tidyUp();
                }
            } onFailure:^(NSError *error) {
                tidyUp();
            }];
            
        } else {
            tidyUp();
        }
    } onFailure:^(NSError *error) {
        tidyUp();
    }];
}

-(void)decrementInitItemsCountHideLoader
{
    if (self.initDownloadCount) {
        self.initDownloadCount -= 1;
        if (self.initDownloadCount == 0) {
            [self hideLoader];
        }
    }
}

-(void)setupProfileInfo
{
    if (!self.currentUsername) return;
    
    UIImageView *imageView = (UIImageView *)[self.view viewWithTag:PROFILE_IMAGE_TAG];
    UILabel *usernameLabel = (UILabel *)[self.view viewWithTag:PROFILE_NAME_TAG];
    UILabel *playoffsLabel = (UILabel *)[self.view viewWithTag:INFO_BTN_1_TEXT_TAG];
    UILabel *followingLabel = (UILabel *)[self.view viewWithTag:INFO_BTN_3_TEXT_TAG];
    
    [usernameLabel setText:self.currentUsername];
    
    [self setTitle:self.currentUsername];
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    
    SMQuery *playoffsCountQuery = [[SMQuery alloc] initWithSchema:@"PlayoffItem"];
    [playoffsCountQuery where:@"sm_owner" isEqualTo: [[NSString alloc] initWithFormat:@"user/%@", self.currentUsername, nil]];
    
    [appDelegate.client.dataStore performCount:playoffsCountQuery onSuccess:^(NSNumber *count) {
        [playoffsLabel setText:[[NSString alloc] initWithFormat:@"%@", count]];
        [self decrementInitItemsCountHideLoader];
    } onFailure:^(NSError *error) {
        [playoffsLabel setText:@"-"];
        [self decrementInitItemsCountHideLoader];
    }];
    
    [self refreshFollowerCount];
    
    SMQuery *followingCountQuery = [[SMQuery alloc] initWithSchema:@"User"];
    [followingCountQuery where:@"followers" isEqualTo:self.currentUsername];
    
    [appDelegate.client.dataStore performCount:followingCountQuery onSuccess:^(NSNumber *count) {
        [followingLabel setText:[[NSString alloc] initWithFormat:@"%@", count]];
        [self decrementInitItemsCountHideLoader];
    } onFailure:^(NSError *error) {
        [followingLabel setText:@"-"];
        [self decrementInitItemsCountHideLoader];
    }];
    
    self.profileImageView = imageView;
    
    if (self.profileDict != nil) {
        [self reloadProfileImage];
        [self addUserBio];
    } else {
        
        SMQuery *fullUserQuery = [[SMQuery alloc] initWithSchema:@"User"];
        [fullUserQuery where:@"username" isEqualTo: self.currentUsername];
        
        [appDelegate.client.dataStore performQuery:fullUserQuery onSuccess:^(NSArray *results) {
            if ([results count] == 0) return;
            self.profileDict = results[0];
            [self reloadProfileImage];
            [self addUserBio];
        } onFailure:^(NSError *error) {}];

    }
    
    if (!self.isSelf) {
        [appDelegate.client getLoggedInUserOnSuccess:^(NSDictionary *result) {
            self.myUsername = result[@"username"];
            if ([(NSString *)result[@"username"] isEqualToString: self.currentUsername]) {
                self.isSelf = YES;
                [self decrementInitItemsCountHideLoader];
                [self setupEditButton];
            } else {
                [self checkAndSetupFollowButton];
                NSString *myUsername = result[@"username"];
                
                SMQuery *isFollowingQuery = [[SMQuery alloc] initWithSchema:@"User"];
                [isFollowingQuery where:@"username" isEqualTo:self.currentUsername];
                [isFollowingQuery where:@"followers" isEqualTo:myUsername];
                

                [appDelegate.client.dataStore performCount:followingCountQuery onSuccess:^(NSNumber *count) {
                    UIButton *followBtn = (UIButton *)[self.view viewWithTag:FOLLOW_BTN_TAG];
                    
                    if ([count intValue] == 0) {
                        [followBtn setTitle: @"Follow" forState:UIControlStateNormal];
                    } else {
                        [followBtn setTitle: @"Unfollow" forState:UIControlStateNormal];
                    }
                } onFailure:^(NSError *error) {
                }];
            }
            
        }onFailure:^(NSError *error){
        }];
        
        // follower/following
    } else {
        [self decrementInitItemsCountHideLoader];
    }
    
    [self fetchPlayoffs];
}

-(void)reloadProfileImage
{
    if (self.profileDict == nil) return;
    
    NSString *profImg = self.profileDict[@"profile_image"];
    if (profImg && [profImg length] > 0) {
        [self.profileImageView setImageWithURL:[NSURL URLWithString:profImg]
                  placeholderImage:[UIImage imageNamed:@"prof-medium-1"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                             
                         }];
    }
    
}

-(void)addUserBio
{
    NSString *bio = self.profileDict[@"bio"];
    UILabel *userBio = (UILabel *)[self.view viewWithTag:USER_BIO_TAG];
    userBio.numberOfLines = 0;
    [userBio setFrame:CGRectMake(MAIN_PAD, MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD, 320 - (MAIN_PAD + MAIN_PAD), 0)];
    
    if (!bio || [bio length] == 0 || bio == nil) {
        [userBio setHidden:YES];
        [userBio setText:@""];
        [userBio sizeToFit];
        
        [self.tableView.tableHeaderView setFrame:CGRectMake(0, 0, 320, MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + MAIN_PAD)];
        [self.tableView setTableHeaderView:self.tableView.tableHeaderView];
    } else {
        [userBio setHidden:NO];
        [userBio setText:bio];
        [userBio sizeToFit];
        
        [self.tableView.tableHeaderView setFrame:CGRectMake(0, 0, 320, MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + userBio.frame.size.height + MAIN_PAD)];
        [self.tableView setTableHeaderView:self.tableView.tableHeaderView];
    }
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return ceil((float)[self.currentData count] / 3);
}

-(void)tapPlayoff:(id)sender
{
    NSString *playoffItemId = [[(UIButton *)sender titleLabel] text];
    PLYThreadViewController *vc = [[PLYThreadViewController alloc] initWithSinglePlayoffId: playoffItemId];
    if (self.loaderView) [self.loaderView removeFromSuperview];
    [self.navigationController pushViewController:vc animated:YES];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{

    static NSString *CellIdentifier = @"MainCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
    
    [cell setFrame:CGRectMake(0, 0, 320, 105)];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];

    UIImageView *img1 = [[UIImageView alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    UIImageView *img2 = [[UIImageView alloc] initWithFrame:CGRectMake(5 + 100 + 5, 5, 100, 100)];
    UIImageView *img3 = [[UIImageView alloc] initWithFrame:CGRectMake(5 + 100 + 5 + 100 + 5, 5, 100, 100)];
    
    UIButton *img1Btn = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 100, 100)];
    UIButton *img2Btn = [[UIButton alloc] initWithFrame:CGRectMake(5 + 100 + 5, 5, 100, 100)];
    UIButton *img3Btn = [[UIButton alloc] initWithFrame:CGRectMake(5 + 100 + 5 + 100 + 5, 5, 100, 100)];
    
    [cell.contentView addSubview:img1Btn];
    [cell.contentView addSubview:img2Btn];
    [cell.contentView addSubview:img3Btn];
    
    [img1Btn addTarget:self action:@selector(tapPlayoff:) forControlEvents:UIControlEventTouchUpInside];
    [img2Btn addTarget:self action:@selector(tapPlayoff:) forControlEvents:UIControlEventTouchUpInside];
    [img3Btn addTarget:self action:@selector(tapPlayoff:) forControlEvents:UIControlEventTouchUpInside];
    
    NSUInteger img1Idx = [indexPath indexAtPosition:1] * 3;
    NSUInteger img2Idx = [indexPath indexAtPosition:1] * 3 + 1;
    NSUInteger img3Idx = [indexPath indexAtPosition:1] * 3 + 2;
    
    if ([self.currentData count] > img1Idx) {
        NSDictionary *img1Obj = [self.currentData objectAtIndex:img1Idx];
        [cell.contentView addSubview:img1];
        [img1Btn setTitle:img1Obj[@"playoffitem_id"] forState:UIControlStateNormal];
        [img1 setImageWithURL:[NSURL URLWithString:[img1Obj valueForKey:@"thumbnail1"]]
                  placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                             
                         }];
    }
    
    if ([self.currentData count] > img2Idx) {
        NSDictionary *img2Obj = [self.currentData objectAtIndex:img2Idx];
        [cell.contentView addSubview:img2];
        [img2Btn setTitle:img2Obj[@"playoffitem_id"] forState:UIControlStateNormal];
        [img2 setImageWithURL:[NSURL URLWithString:[img2Obj valueForKey:@"thumbnail1"]]
             placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                        
                    }];
    }
    
    if ([self.currentData count] > img3Idx) {
        NSDictionary *img3Obj = [self.currentData objectAtIndex:img3Idx];
        [cell.contentView addSubview:img3];
        [img3Btn setTitle:img3Obj[@"playoffitem_id"] forState:UIControlStateNormal];
        [img3 setImageWithURL:[NSURL URLWithString:[img3Obj valueForKey:@"thumbnail1"]]
             placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                    completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                        
                    }];
    }
     
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 105;
}
    
-(void)showLoader
{
    UIView *loaderView = [PLYUtilities getLoader];
    self.loaderView = loaderView;
    [self.navigationController.view addSubview:loaderView];
//    [loaderView setFrame:CGRectMake(loaderView.frame.origin.x, 100, loaderView.frame.size.width, loaderView.frame.size.height)];
    [(UIActivityIndicatorView *)[loaderView subviews][0] startAnimating];
}

-(void)hideLoader
    {
        [self.loaderView removeFromSuperview];
    }
    
/* e.g. after editing */
-(void)reloadUserInfo
{
    [self showLoader];
    
    void (^cleanupFn)(void) = ^() {
        [self hideLoader];
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
    
    SMQuery *fullUserQuery = [[SMQuery alloc] initWithSchema:@"User"];
    [fullUserQuery where:@"username" isEqualTo: self.currentUsername];

    [appDelegate.client.dataStore performQuery:fullUserQuery onSuccess:^(NSArray *results) {
        if ([results count] == 0) return;
        self.profileDict = results[0];
        [self setupProfileInfo];
        cleanupFn();
    } onFailure:errorFn];
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
