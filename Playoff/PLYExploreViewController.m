//
//  PLYExploreViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYExploreViewController.h"
#import "PLYMainThreadCell.h"
#import "PLYThreadViewController.h"

#import "PLYAppDelegate.h"

#import "PlayoffThread.h"
#import "PlayoffItem.h"
#import "PlayoffComment.h"

#import "PLYUtilities.h"
#import "PLYTheme.h"

#define NAVBAR_HEIGHT 44
#define CARET_DIM 24

#define TITLE_LABEL_TAG 1
#define TITLE_CARET_TAG 2

static NSString *slideBtn1 = @"Editor's Picks";
static NSString *slideBtn2 = @"Hot";
static NSString *slideBtn3 = @"Now";
static NSString *slideBtn4 = @"All Time Best";

static int pageSize = 6;

@implementation PLYExploreViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.currentData = [[NSMutableArray alloc] init];
    self.currentExploreCategory = nil;
    self.currentPage = 0;
    
    self.slideDownButtons = [[PLYSlideDownButtonList alloc]
                             initWithNavigationController:self.navigationController
                             buttons: @[slideBtn1, slideBtn2, slideBtn3, slideBtn4]
                             customTopOffset:20]; // top offset for pull to refresh
    
    [self setupSlideDownButtons];
    
    [self setupNavBarTitleView];
    
    // will be replaced by selection logic to populate etc.
    [self updateNavigationBarTitle:@"Explore"];
    
    // show more button
    UIView *footerView = [[UIView alloc] init];
    UIButton *loadMoreBtn = [[UIButton alloc] init];
    [PLYTheme containedExpandBut:loadMoreBtn cont:footerView];
    [loadMoreBtn addTarget:self action:@selector(loadMorePlayoffs) forControlEvents:UIControlEventTouchUpInside];
    self.loadMoreBut = loadMoreBtn;
    
    self.tableView.tableFooterView = footerView;

    UISwipeGestureRecognizer *gesture = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    gesture.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.tableView addGestureRecognizer:gesture];
    
    [self initialiseData];
}

-(void)loadMorePlayoffs
{
    [self.loadMoreBut setHidden:YES];
    self.currentPage += 1;
    [self refreshData];
}

-(void)initialiseData
{
    if (self.currentExploreCategory == nil || [self.currentData count] == 0) {
        if (self.currentExploreCategory == nil) {
            self.currentExploreCategory = slideBtn2;
        }
        [self.pullToRefreshView startLoadingAndExpand:YES animated:NO];        
        [self refreshData];
    }
}

- (BOOL)pullToRefreshViewShouldStartLoading:(SSPullToRefreshView *)view
{
    self.currentPage = 0;
    [self refreshData];
    return TRUE;
}

-(void) setupNavBarTitleView
{
    UINavigationItem *navigationItem = self.navigationItem;
    
    UIControl *titleView = [[UIControl alloc] init];
//    [titleView setBackgroundColor:[PLYTheme primaryColor]];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    [titleLabel setBackgroundColor:[UIColor clearColor]];
    [titleLabel setTag:TITLE_LABEL_TAG];
    [titleLabel setTextColor:[UIColor whiteColor]];
//    [titleLabel setShadowColor:[UIColor blackColor]];
//    [titleLabel setShadowOffset:CGSizeMake(0, -1)];
    [titleView addSubview:titleLabel];

    UIImageView *caretView = [[UIImageView alloc] init];
    [caretView setTag:TITLE_CARET_TAG];
    [caretView setImage:[UIImage imageNamed:@"caret-1"]];
    [titleView addSubview:caretView];
    
    [navigationItem setTitleView:titleView];
    
    [titleView addTarget:self action:@selector(showSlideDownButtons) forControlEvents:UIControlEventTouchUpInside];
}

-(void)showSlideDownButtons
{
    if (self.slideDownButtons.currentlyShowing) {
        [self.slideDownButtons animateSlideUpButtons];
    } else {
        [self.slideDownButtons animateSlideDownButtons];
    }
}

-(void)updateNavigationBarTitle: (NSString *)newTitle
{
    UIView *titleView = self.navigationItem.titleView;
    UILabel *titleLabel = (UILabel *)[titleView viewWithTag:TITLE_LABEL_TAG];
    UIImageView *caretView = (UIImageView *)[titleView viewWithTag:TITLE_CARET_TAG];
    
    CGSize labelSize = [newTitle sizeWithFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:24]];
//    CGSize labelSize = [newTitle sizeWithFont:[UIFont systemFontOfSize:20]];
    
    [titleLabel setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:24]];
//    [titleLabel setFont:[UIFont systemFontOfSize:20]];
    [titleLabel setText: newTitle];
    [titleLabel setFrame:CGRectMake(0, 0, labelSize.width, labelSize.height)];
    
    [caretView setFrame:CGRectMake(labelSize.width + 2, 2, CARET_DIM, CARET_DIM)];
    
    [titleView setFrame:CGRectMake(0, 0, titleLabel.frame.size.width, titleLabel.frame.size.height)];
    
    [titleLabel setText:newTitle];

    [self.navigationItem setTitleView:titleView];
}

-(void)setupSlideDownButtons
{
    for (UIButton *button in [self.slideDownButtons tappableButtons]) {
        [button addTarget:self action:@selector(tapSlideDownButton:) forControlEvents:UIControlEventTouchUpInside];
    }
}

-(void)showEmptyMessage
{
    UILabel *headerView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 320, 80)];
    [headerView setBackgroundColor:[UIColor clearColor]];
    [headerView setTextAlignment:NSTextAlignmentCenter];
    [headerView setTextColor:[PLYTheme backgroundDarkColor]];
    [headerView setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
    [headerView setText:@"No Playoffs, try another category"];
    self.tableView.tableHeaderView = headerView;
}

-(void)hideEmptyMessage
{
    self.tableView.tableHeaderView = nil;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
}

/*
 * must be approved_for_sharing
 *
 * first part: https://developer.stackmob.com/tutorials/ios/Read-into-Table-View
 *
 * http://stackmob.github.io/stackmob-ios-sdk/Classes/SMQuery.html#//api/name/where:isIn:
 */
-(void)submitQueryAndUpdate: (SMQuery *) baseQry sortByTime: (BOOL) sortByTime
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [baseQry fromIndex:self.currentPage * pageSize toIndex:(self.currentPage + 1) * pageSize - 1];
    [baseQry where: @"approved_for_sharing" isEqualTo:@TRUE];
    
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
//        } else if ([error code] == 416) {
//            [self.tableView.tableFooterView setHidden:YES];
        } else {
            [self.loadMoreBut setHidden:NO];
        }
    };
    
    [[appDelegate.client dataStore] performQuery:baseQry onSuccess:^(NSArray *results) {
        if ([results count] == 0) {
            [self showEmptyMessage];
            return;
        }
        
        NSMutableArray * playoffIds = [[NSMutableArray alloc] init];
        
        for (PlayoffThread *res in results) {
            int i = 0;
            NSString *p1 = [res valueForKey:@"popular1"];
            NSString *p2 = [res valueForKey:@"popular2"];
            NSString *p3 = [res valueForKey:@"popular3"];
            if (p1) [playoffIds addObject:p1];
            if (p2) [playoffIds addObject:p2];
            if (p3) [playoffIds addObject:p3];
            
            for (NSString *pId in (NSArray *)[res valueForKey:@"playoffs"]) {
                i += 1;
                [playoffIds addObject:pId];
                if (i==5) break;
            }
        }
        
        if ([playoffIds count] == 0) {
            [self.currentData removeAllObjects];
            [self.tableView reloadData];
            [self.pullToRefreshView finishLoading];
            return;
        }
        
        /* a client side join */
        SMQuery *qry = [[SMQuery alloc] initWithSchema:@"PlayoffItem"];
        [qry where:@"playoffitem_id" isIn:playoffIds];
        [qry orderByField:@"likes_count" ascending:NO];
        [qry where: @"approved_for_sharing" isEqualTo:@TRUE];
        
        [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *playoffResults) {

            NSMutableDictionary *threadCaptions = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *groupedThreads = [[NSMutableDictionary alloc] init];
            
            for (PlayoffItem *p in playoffResults) {
                NSString *threadId = (NSString *)[p valueForKey:@"thread"];
                NSString *cap = [p valueForKey:@"caption"];
                
                NSMutableArray *caps = (NSMutableArray *)[threadCaptions valueForKey:threadId];
                NSMutableArray *playoffs = (NSMutableArray *)[groupedThreads valueForKey:threadId];
                
                if (!caps)
                    caps = [[NSMutableArray alloc] init];
                
                if (!playoffs)
                    playoffs = [[NSMutableArray alloc] init];
                
                
                [caps addObject:@{
                 @"user": [PLYUtilities usernameFromOwner:[p valueForKey:@"sm_owner"]],
                 @"body": cap
                 }];
                
                [playoffs addObject: p];
                
                [threadCaptions setValue:caps forKey:threadId];
                [groupedThreads setValue: playoffs forKey: threadId];
            }
            
            NSComparisonResult (^popSorter)(id a, id b) = ^(id a, id b) {
                return [(NSNumber *)[(NSDictionary *)b valueForKey: @"likes_count"]
                        compare:(NSNumber *)[(NSDictionary *)a valueForKey: @"likes_count"]];
            };
            
            NSComparisonResult (^timeSorter)(id a, id b) = ^(id a, id b) {
                NSDate *d1 = (NSDate *)[(NSDictionary *)a valueForKey: @"createddate"];
                NSDate *d2 = (NSDate *)[(NSDictionary *)b valueForKey: @"createddate"];
                return [d2 compare:d1];
            };
            
            NSArray *sortedThreads;
            
            if (sortByTime) {
                sortedThreads = [results sortedArrayUsingComparator:timeSorter];
            } else {
                sortedThreads = [results sortedArrayUsingComparator:popSorter];
            }
            
            NSMutableArray *processedThreads = [[NSMutableArray alloc] init];
            
            
            for (PlayoffThread *thread in sortedThreads) {
                NSString *threadId = (NSString *)[thread valueForKey:@"playoffthread_id"];
                NSDictionary *procThread = [appDelegate getProcessedThread:thread
                                                            threadCaptions:[threadCaptions valueForKey: threadId]
                                                            threadPlayoffs:[groupedThreads valueForKey: threadId]];
                
                
                [processedThreads addObject:procThread];
            }
            
            if (self.currentPage == 0) [self.currentData removeAllObjects];
            
            for (NSDictionary *d in processedThreads) {
                [self.currentData insertObject:d atIndex:[self.currentData count]];
            }
            
            if ([processedThreads count] == pageSize) {
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
    
}

-(void) queryAndUpdateEditorPicks
{
    /* recently curated */
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    SMQuery *qry = [[SMQuery alloc] initWithSchema:@"CuratedPlayoffThread"];
    [qry orderByField:@"createddate" ascending:NO];
    [qry fromIndex:self.currentPage * pageSize toIndex:(self.currentPage + 1) * pageSize - 1];
    
    [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *results) {
        NSMutableArray *threads = [[NSMutableArray alloc] init];
        
        for (NSDictionary *curated in results) {
            [threads addObject:[curated valueForKey:@"playoffthread_id"]];
        }
        
        SMQuery *baseQry = [[SMQuery alloc] initWithSchema:@"PlayoffThread"];
        [baseQry where:@"playoffthread_id" isIn:threads];
        
        [self submitQueryAndUpdate:baseQry sortByTime:YES];
    } onFailure:^(NSError *error){
        [self.pullToRefreshView finishLoading];
    }];
}

-(void) queryAndUpdateHot
{
    /* order by likes, past 24 hrs */
    
    SMQuery *baseQry = [[SMQuery alloc] initWithSchema:@"PlayoffThread"];
    [baseQry where:@"createddate" isGreaterThan:[[NSDate date] dateByAddingTimeInterval:-60*60*24*7]]; // TODO: change this to 1 day, just testing here
    [baseQry orderByField:@"likes_count" ascending:NO];
    
    [self submitQueryAndUpdate: baseQry sortByTime:NO];
    
}

-(void) queryAndUpdateNow
{
    /* all most recent */
    SMQuery *baseQry = [[SMQuery alloc] initWithSchema:@"PlayoffThread"];
    [baseQry orderByField:@"createddate" ascending:NO];
    
    [self submitQueryAndUpdate: baseQry sortByTime:YES];

}

-(void) queryAndUpdateAllTimeBest
{
    /* order by likes */
    
    SMQuery *baseQry = [[SMQuery alloc] initWithSchema:@"PlayoffThread"];
    [baseQry orderByField:@"likes_count" ascending:NO];
    
    [self submitQueryAndUpdate: baseQry sortByTime:NO];
}

-(void)refreshData
{
    if ([self.currentExploreCategory isEqualToString:slideBtn1]) {
        [self queryAndUpdateEditorPicks];
    } else if ([self.currentExploreCategory isEqualToString:slideBtn2]) {
        [self queryAndUpdateHot];
    } else if ([self.currentExploreCategory isEqualToString:slideBtn3]) {
        [self queryAndUpdateNow];
    } else if ([self.currentExploreCategory isEqualToString:slideBtn4]) {
        [self queryAndUpdateAllTimeBest];
    }
}

- (void) tapSlideDownButton:(id) sender
{
    NSString *btnTitle = [(UIButton *)sender titleLabel].text;
    
    if (btnTitle != self.currentExploreCategory) {
        self.currentExploreCategory = btnTitle;
        [self updateNavigationBarTitle:btnTitle];
    }
    
    self.currentPage = 0;
    [self.slideDownButtons animateSlideUpButtons];
    [self.tableView setContentOffset:CGPointMake(0, -self.pullToRefreshView.contentView.frame.size.height) animated:NO];
    [self.pullToRefreshView startLoadingAndExpand:YES animated:YES];
    
    [self refreshData];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"PLYMainCell";
    PLYMainThreadCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = (PLYMainThreadCell *)[self tableviewCellWithReuseIdentifier:CellIdentifier];
    
    [cell configureCell:[self.currentData objectAtIndex:[indexPath indexAtPosition:1]]];

    return cell;
    
}

-(void)didSwipe:(UIGestureRecognizer *)gestureRecognizer {
    
    if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
        CGPoint swipeLocation = [gestureRecognizer locationInView:self.tableView];
        NSIndexPath *swipedIndexPath = [self.tableView indexPathForRowAtPoint:swipeLocation];
        [self selectCellAtIndexPath:swipedIndexPath];
    }
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[PLYMainThreadCell alloc] initWithFrame:CGRectZero];
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

-(void)selectCellAtIndexPath: (NSIndexPath *) indexPath
{
    /*
    PLYThreadViewController *newView = [[PLYThreadViewController alloc]
                                        initWithThread:
                                        [self.currentData objectAtIndex:[indexPath indexAtPosition:1]]];
     */
    
    PLYThreadViewController *newView = [[PLYThreadViewController alloc]
                                        initWithThreadId:((NSDictionary *)[self.currentData objectAtIndex:[indexPath indexAtPosition:1]])[@"id"]];
    
    [self.slideDownButtons animateSlideUpButtons];
    [self.navigationController pushViewController:newView animated:YES];
}

- (void) tableView: (UITableView *) tableView didSelectRowAtIndexPath: (NSIndexPath *) indexPath
{
    [self selectCellAtIndexPath:indexPath];
}

@end
