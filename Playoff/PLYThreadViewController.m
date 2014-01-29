//
//  PLYThreadViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 04/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYThreadViewController.h"
#import "PLYExpandedViewCell.h"

#import "PLYAppDelegate.h"
#import "PlayoffItem.h"
#import "PlayoffThread.h"

#import "PLYUserInformationView.h"

#import "PLYTheme.h"

static int pageSize = 5;
static NSString *defaultTitle = @"Playoff Thread";

@implementation PLYThreadViewController

-(id)initWithThread: (NSDictionary *)thread
{
    [self.tableView setDelegate:self];
    self.currentPage = 0;
    self.playoffThreadId = thread[@"id"];
    
    self = [super init];
    
    if ([(NSString *)thread[@"title"] length] > 0) {
        [self setTitle:thread[@"title"]];
    } else {
        [self setTitle:defaultTitle];
    }

    self.currentData = thread[@"items"];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupFooter];
    
    return self;
}

-(void)setupSinglePlayoff
{
    [self.pullToRefreshView startLoadingAndExpand:YES animated:YES];
    
    void (^handleError)(NSError *error) = ^(NSError *error) {
        [self.pullToRefreshView finishLoading];
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Could not find playoff"
                                  message:error.localizedDescription
                                  delegate:self
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    SMQuery *qry = [[SMQuery alloc] initWithSchema:@"PlayoffItem"];
    [qry where:@"playoffitem_id" isEqualTo: self.singlePlayoffId];
    
    [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *results) {
        if ([results count] == 0) {
            handleError(nil);
            return;
        }
        
        [self.pullToRefreshView finishLoading];
        
        [self.currentData removeAllObjects];
        [self.currentData addObject:[appDelegate getProcessedPlayoff:results[0]]];
        [self.tableView reloadData];
        
        self.playoffThreadId = [(NSDictionary *)results[0] valueForKey:@"thread"];
        [self setTitle:@"Single Playoff"];
        
        [self setupHeaderThread];
    } onFailure:handleError];
}

-(id)initWithSinglePlayoffId: (NSString *) playoffId
{
    self = [super init];
    
    if (self) {
        self.singlePlayoffId = playoffId;
        self.singlePlayoff = TRUE;
        self.currentData = [[NSMutableArray alloc] init];
    }

    return self;
}

-(void)setupHeaderThread
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 40)];
    
    UIButton *loadMoreBtn = [[UIButton alloc] initWithFrame:CGRectMake(5, 5, 310, 35)];
    [loadMoreBtn setTitle:@"See thread" forState:UIControlStateNormal];
    [PLYTheme setGrayButton:loadMoreBtn];
    [headerView addSubview:loadMoreBtn];
    [loadMoreBtn addTarget:self action:@selector(goToThread) forControlEvents:UIControlEventTouchUpInside];
    
    self.tableView.tableHeaderView = headerView;
}

-(void)goToThread
{
    PLYThreadViewController *fullThread = [[PLYThreadViewController alloc] initWithThreadId:self.playoffThreadId];
    if (self.currentCell) [self.currentCell dehighlight];
    [self.navigationController pushViewController:fullThread animated:YES];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(id)initWithThreadId: (NSString *)threadId
{
    self = [super init];
    self.playoffThreadId = threadId;
    self.startingEmpty = TRUE;
    self.currentData = [[NSMutableArray alloc] init];
    
    [self setupFooter];
    [self setTitle:defaultTitle];
    
    return self;
}

-(void)setupFooter
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
    [self.pullToRefreshView startLoadingAndExpand:YES animated:YES];
    [self refreshData];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.navigationItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(handleBack)];
    
    if (self.startingEmpty) {
        [self.pullToRefreshView startLoadingAndExpand:YES animated:YES];
        [self refreshData];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(pauseAnyVideo) name:@"startCapturingMain" object:nil];
    } else if (self.singlePlayoff) {
        [self setupSinglePlayoff];
    }
}

-(void)handleBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)pauseAnyVideo
{
    if (self.currentCell) [self.currentCell dehighlight];
}

- (BOOL)pullToRefreshViewShouldStartLoading:(SSPullToRefreshView *)view
{
    if (self.singlePlayoff) return FALSE;
    
    self.currentPage = 0;
    [self refreshData];
    return TRUE;
}

-(void)dealloc
{
    if (self.currentCell) [self.currentCell dehighlight];
    self.currentCell = nil;
    if (self.currentData) {
        [self.currentData removeAllObjects];
        [self.tableView reloadData];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void) refreshData
{
    void (^handleError)(NSError *error) = ^(NSError *error) {
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
        }
        
        [self.loadMoreBut setHidden:NO];
    };
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    SMQuery *qry = [[SMQuery alloc] initWithSchema:@"PlayoffItem"];
    [qry orderByField:@"likes_count" ascending:NO];
    [qry where:@"thread" isEqualTo: self.playoffThreadId];
    [qry fromIndex:self.currentPage * pageSize toIndex:(self.currentPage + 1) * pageSize - 1];
    
    [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *results) {
        NSMutableArray *processedPlayoffs = [[NSMutableArray alloc] init];
        NSString *threadTitle = nil;
        NSError *error;
        NSRegularExpression *titleRegex = [NSRegularExpression regularExpressionWithPattern:@"#([a-zA-Z]+)"
                                                                                    options:NSRegularExpressionCaseInsensitive
                                                                                      error:&error];
        for (NSDictionary *playoff in results) {
            if (!playoff) continue;

            if ([playoff valueForKey: @"caption"]) {
                NSString *cap = (NSString *)[playoff valueForKey: @"caption"];
                NSRange match = [titleRegex rangeOfFirstMatchInString:cap options:NSMatchingReportCompletion range:NSMakeRange(0, [cap length])];
                
                if (!NSEqualRanges(match, NSMakeRange(NSNotFound, 0)) && threadTitle == nil) {
                    threadTitle = [cap substringWithRange:match];
                }
            }
            
            [processedPlayoffs addObject: [appDelegate getProcessedPlayoff: playoff]];
        }
        
        if (self.currentPage == 0) [self.currentData removeAllObjects];
        
        for (NSDictionary *d in processedPlayoffs) {
            [self.currentData insertObject:d atIndex:[self.currentData count]];
        }
        
        if ([processedPlayoffs count] == pageSize) {
            [self.tableView.tableFooterView setHidden:NO];
        } else {
            [self.tableView.tableFooterView setHidden:YES];
        }
        
        [self.tableView reloadData];
        
        if (self.title == defaultTitle && threadTitle != nil)
            [self setTitle:threadTitle];
        
        if (self.currentPage == 0) {
            [self.tableView setContentOffset:CGPointZero animated:YES];
            [self.pullToRefreshView finishLoading];
            [self.tableView setContentOffset:CGPointMake(0, -self.pullToRefreshView.contentView.frame.size.height) animated:YES];
        }
        
        [self highlightMostVisible];
        
        
    } onFailure:handleError];
    
    // query playoffs on this thread ID -> page playoffs and sort on likes count
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
//    [self dehighlightLast];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self highlightMostVisible];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    [self highlightMostVisible];
}

-(void)dehighlightLast
{
    if (self.currentCell != nil) {
        [self.currentCell dehighlight];
//        [self.currentCell unloadVideo];
        self.currentCell = nil;
    }
}

-(void)startCurrent
{
    if (self.currentCell != nil) {
        [self.currentCell highlight];
        [self.currentCell play];
    }
}

-(void)refreshContent
{
    // self.maxOffset
    [self.pullToRefreshView finishLoading];
}

-(void)highlightMostVisible
{
    NSIndexPath *path;
    CGFloat propShown;
    CGFloat bestProp = 0.0;
    PLYExpandedViewCell *mostVisibleCell;
    
    for (PLYExpandedViewCell *cell in self.tableView.visibleCells) {      
        
        path = [self.tableView indexPathForCell:cell];
        CGRect rectOfCellInTableView = [self.tableView rectForRowAtIndexPath:path];
        CGRect rectOfCellInSuperview = [self.tableView convertRect:rectOfCellInTableView toView:[self.tableView superview]];
        
        if (rectOfCellInSuperview.origin.y > 0) {
            propShown = (self.tableView.superview.frame.size.height - rectOfCellInSuperview.origin.y) / self.tableView.superview.frame.size.height;
        } else {
            propShown = (rectOfCellInSuperview.origin.y + self.tableView.superview.frame.size.height) / self.tableView.superview.frame.size.height;
        }
        
        if (propShown > bestProp) {
            bestProp = propShown;
            mostVisibleCell = cell;
        }
    }
    
    if (self.currentCell != mostVisibleCell) {
        [self dehighlightLast];
        self.currentCell = mostVisibleCell;
        [self startCurrent];
    }
}
/*
-(void)viewWillDisappear:(BOOL)animated
{
    [self dehighlightLast];
    
    [super viewWillDisappear:animated];
}
-(void)viewDidDisappear:(BOOL)animated
{

}*/

-(void)viewWillDisappear:(BOOL)animated
{
//    if (self.currentCell)
//        [self.currentCell unloadVideo];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.currentCell = nil;
    NSIndexPath *pth = [NSIndexPath indexPathForRow:0 inSection:0];
    self.currentCell = (PLYExpandedViewCell *)[self.tableView cellForRowAtIndexPath:pth];
    
    /* first use note */
    PLYUserInformationView *firstUse = [[PLYUserInformationView alloc] initWithImage:@"user-info-playoff-1" andFirstUseKey:@"firstUse_playoff"];
    if (firstUse) {
        [self.tabBarController.view addSubview:firstUse];
    }
    
    [self startCurrent];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"PLYMainCell";
    PLYExpandedViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
        cell = (PLYExpandedViewCell *)[self tableviewCellWithReuseIdentifier:CellIdentifier];
    
    [cell configureCell:[self.currentData objectAtIndex:[indexPath indexAtPosition:1]]];
    [cell setNavigationController:self.navigationController];
    
    return cell;
    
}
/*
-(void)viewDidAppear:(BOOL)animated
{
    // start the first item
    
    NSIndexPath *pth = [NSIndexPath indexPathForRow:0 inSection:0];
    PLYExpandedViewCell *cell = [self.tableView cellForRowAtIndexPath:pth];

    [cell loadVideo];
}
*/
- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[PLYExpandedViewCell alloc] initWithFrame:CGRectZero];
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

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

-(void)scrollViewDidScrollToTop:(UIScrollView *)scrollView
{
    [self highlightMostVisible];
}

@end
