//
//  PLYHomeViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYProfileViewController.h"

#import "PLYHomeViewController.h"
#import "PLYUserActivityCell.h"
#import "PLYThreadViewController.h"
#import "PLYUserInformationView.h"

#import "PLYAppDelegate.h"

#import "User.h"
#import "PlayoffItem.h"
#import "PLYTheme.h"

static int pageSize = 8;

@implementation PLYHomeViewController

static NSString *CellTableIdentifier = @"CellTableIdentifier";

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.currentData = [[NSMutableArray alloc] init];
    self.currentPage = 0;
    [self.tableView setBackgroundColor:[PLYTheme backgroundVeryLightColor]];
    
    // show more button
    UIView *footerView = [[UIView alloc] init];
    UIButton *loadMoreBtn = [[UIButton alloc] init];
    [PLYTheme containedExpandBut:loadMoreBtn cont:footerView];
    [loadMoreBtn addTarget:self action:@selector(loadMorePlayoffs) forControlEvents:UIControlEventTouchUpInside];
    self.loadMoreBut = loadMoreBtn;
    
    self.tableView.tableFooterView = footerView;
    
    UIImageView *navLogo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"nav-logo-1"]];
    [navLogo setFrame:CGRectMake(0, 0, 200, 40)];
    [self.navigationItem setTitleView:navLogo];

    
    self.navigationItem.rightBarButtonItem = [PLYTheme barButtonWithTarget:self selector:@selector(showProfile)
                                                                      img1:@"profile-but-1" img2:@"profile-but-sel-1"];
    
    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    gesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:gesture];
    
    [self refreshData];
    
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self setupSyncItems];
}

-(void)setupSyncItems
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    if ([appDelegate availableUploadsToSync]) {
        self.navigationItem.leftBarButtonItem = [PLYTheme barButtonWithTarget:self selector:@selector(syncItems)
                                                                         img1:@"sync-but-1" img2:@"sync-but-sel-1"];
        
        /* first use note */
        PLYUserInformationView *firstUse = [[PLYUserInformationView alloc] initWithImage:@"user-info-sync-1" andFirstUseKey:@"firstUse_sync"];
        if (firstUse) {
            [self.tabBarController.view addSubview:firstUse];
        }
        
    } else {
        if (self.navigationItem.leftBarButtonItem) {
            self.navigationItem.leftBarButtonItem = nil;
        }
    }
}

-(void)syncItems
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *upload = [appDelegate nextUploadToSync];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL skipWWANQuery = [defaults boolForKey:@"alwaysUploadOnCellular"];
    
    if ([appDelegate currentReachabilityStatus] == AFNetworkReachabilityStatusReachableViaWiFi ||
            ([appDelegate currentReachabilityStatus] == AFNetworkReachabilityStatusReachableViaWWAN && skipWWANQuery)) {
        NSNumber *outstanding = upload[@"outstandingCount"];
        
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Synchronise"
                                  message:[[NSString alloc] initWithFormat:@"%@ remaining, start first, or delete?", outstanding, nil]
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Upload", @"Delete", nil];
        [alertView show];
    } else if ([appDelegate currentReachabilityStatus] == AFNetworkReachabilityStatusReachableViaWWAN) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Synchronise"
                                  message:[[NSString alloc] initWithFormat:@"upload over wifi or delete next?", nil]
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:@"Upload", @"Delete", nil];
        [alertView show];
    } else {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Synchronise"
                                  message:@"No internet connection"
                                  delegate:self
                                  cancelButtonTitle:@"Cancel"
                                  otherButtonTitles:nil];
        [alertView show];
        [self setupSyncItems];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSDictionary *upload = [appDelegate nextUploadToSync];
    if (!upload) return;
    
    if ([title isEqualToString:@"Upload"]) {
        [appDelegate syncUpload:upload[@"playoffId"] complete:^(BOOL success, NSString *message) {
            [self setupSyncItems];
        }];
    } else if ([title isEqualToString:@"Delete"]) {
        [appDelegate deleteUpload:upload[@"playoffId"]];
        [self setupSyncItems];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

-(void)showProfile
{
    UIViewController *profVC = [[PLYProfileViewController alloc] initWithUsername:nil];
    [self.navigationController pushViewController:profVC animated:YES];
}

- (BOOL)pullToRefreshViewShouldStartLoading:(SSPullToRefreshView *)view
{
    self.currentPage = 0;
    [self refreshData];
    return TRUE;
}

-(void)loadMorePlayoffs
{
    [self.loadMoreBut setHidden:YES];
    self.currentPage += 1;
    [self refreshData];
}

-(void)showEmptyMessage
{
    UILabel *headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    [headerView setTextAlignment:NSTextAlignmentCenter];
    [headerView setTextColor:[PLYTheme backgroundDarkColor]];
    [headerView setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
    [headerView setText:@"No Playoffs, follow others!"];
    self.tableView.tableHeaderView = headerView;
}

-(void)hideEmptyMessage
{
    self.tableView.tableHeaderView = nil;
}

-(void)refreshData
{
    /*
     * get users following
     *
     * - find playoffs with sm_owner equal to their name in (usernames...) approved_for_sharings
     * - get my/friends playoff threads
     */
    
    [self.pullToRefreshView startLoadingAndExpand:YES animated:NO];

    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
 
    void (^failureHandler)(NSError *) = ^(NSError *error) {
        [self.pullToRefreshView finishLoading];
        if ([error code] == -105) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"No Internets!"
                                      message:@"you appear to be offline"
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
            return;
        } else if ([error code] == -109) {
            [appDelegate presentLogin:YES];
//        } else if (error != nil && [error code] == 416) {
//            [self.tableView.tableFooterView setHidden:YES];
        }
        [self.loadMoreBut setHidden:NO];
    };
    
    [appDelegate.client getLoggedInUserOnSuccess:^(NSDictionary *item) {
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username == %@", item[@"username"]]];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
        
        [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
            if ([results count] == 0) {
                failureHandler(nil);
                return;
            }
            User *user = results[0];
            NSMutableArray *followingNames = [[NSMutableArray alloc] init];
            for (User *u in [user following]) {
                [followingNames addObject:[NSString stringWithFormat:@"user/%@",[u valueForKey:@"username"], nil]];
            }

            if ([followingNames count] == 0) {
                self.currentData = [[NSMutableArray alloc] init];
                [self.tableView reloadData];
                [self.pullToRefreshView finishLoading];
                [self showEmptyMessage];
                return;
            }
            
            SMQuery *baseQry = [[SMQuery alloc] initWithSchema:@"PlayoffItem"];
            [baseQry orderByField:@"createddate" ascending:NO];
            [baseQry fromIndex:self.currentPage * pageSize toIndex:(self.currentPage + 1) * pageSize - 1];
            [baseQry where: @"approved_for_sharing" isEqualTo:@TRUE];
            [baseQry where: @"sm_owner" isIn:followingNames];
            
            [[appDelegate.client dataStore] performQuery:baseQry onSuccess:^(NSArray *results) {
                
                [self.pullToRefreshView finishLoading];
                
                NSMutableArray *processedPlayoffs = [[NSMutableArray alloc] init];
                for (PlayoffItem *playoff in results) {
                    
                    User *owner = nil;
                    for (User *u in [user following]) {
                        NSString *ownerName = [[[playoff valueForKey:@"sm_owner"] componentsSeparatedByString:@"/"] lastObject];
                        if ([(NSString *)[u valueForKey: @"username"] isEqualToString: ownerName]) {
                            owner = u;
                            break;
                        }
                    }
                    
                    [processedPlayoffs addObject:@{
                        @"user": @{
                            @"username": [playoff valueForKey:@"sm_owner"],
                            @"profile_image": (owner != nil && [owner valueForKey: @"profile_image"]) ?
                                                                [owner valueForKey: @"profile_image"] : [NSNull null]
                        },
                        @"id": [playoff valueForKey:@"playoffitem_id"],
                        @"thread_id": [playoff valueForKey:@"thread"] ? [playoff valueForKey:@"thread"] : [NSNull null],
                        @"likes_count": [playoff valueForKey: @"likes_count"] ?  [playoff valueForKey: @"likes_count"] : @0,
                        @"caption": [playoff valueForKey: @"caption"] ? [playoff valueForKey: @"caption"] : @"",
                        @"preview_image_1": [playoff valueForKey: @"thumbnail1"],
                        @"preview_image_2": [playoff valueForKey: @"thumbnail2"],
                        @"preview_image_3": [playoff valueForKey: @"thumbnail3"],
                        @"createddate": [playoff valueForKey: @"createddate"],
                     }];
                }
                
                if (self.currentPage == 0) [self.currentData removeAllObjects];
                 
                for (NSDictionary *d in processedPlayoffs) {
                    [self.currentData insertObject:d atIndex:[self.currentData count]];
                }
                 
                if ([processedPlayoffs count] == pageSize) {
                    [self.tableView.tableFooterView setHidden:NO];
                } else {
                    [self.tableView.tableFooterView setHidden:NO];
                }

                [self hideEmptyMessage];
                [self.tableView reloadData];
                [self.loadMoreBut setHidden:NO];
                 
                if (self.currentPage == 0) {
                    [self.tableView setContentOffset:CGPointZero animated:YES];
                    [self.pullToRefreshView finishLoading];
                    [self.tableView setContentOffset:CGPointMake(0, -self.pullToRefreshView.contentView.frame.size.height) animated:YES];
                }

            } onFailure:failureHandler];
        } onFailure:failureHandler];
    } onFailure:failureHandler];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
//    PLYUserActivityCell.h
    NSString *CellIdentifier = @"PLYMainCell";
    PLYUserActivityCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = (PLYUserActivityCell *)[self tableviewCellWithReuseIdentifier:CellIdentifier];
    
    [cell configureCell:[self.currentData objectAtIndex:[indexPath indexAtPosition:1]]];

    return cell;
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[PLYUserActivityCell alloc] initWithFrame:CGRectZero];
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    return cell.frame.size.height;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.currentData count];
}

-(void)didSwipe:(UIGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint swipeLocation = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
        [self selectCellAtIndexPath:swipedIndexPath];
    }
}

-(void)selectCellAtIndexPath: (NSIndexPath *) indexPath
{
    PLYThreadViewController *newView = [[PLYThreadViewController alloc]
                                        initWithSinglePlayoffId:[self.currentData objectAtIndex:[indexPath indexAtPosition:1]][@"id"]];
    [self.navigationController pushViewController:newView animated:YES];
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
    [self selectCellAtIndexPath:indexPath];
}

@end
