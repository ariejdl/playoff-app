//
//  PLYCommentViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 08/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYCommentViewController.h"
#import "DAKeyboardControl.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"

#import <QuartzCore/QuartzCore.h>

#import "PLYAppDelegate.h"

#import "PLYCommentCell.h"

#import "PlayoffItem.h"
#import "PlayoffComment.h"

static int pageSize = 8;

@implementation PLYCommentViewController

@synthesize comments = _comments;
@synthesize textField = _textField;

-(id)initWithPlayoffId: (NSString *) playoffId withKeyboard: (BOOL) showKeyboard
{
    self = [super init];
    if (self) {
        self.comments = [[NSMutableArray alloc] init];
        self.currentPage = 0;
        self.pageOffset = 0;
        self.playoffId = playoffId;
        self.startShowKeyboard = showKeyboard;
        
        self.loadingView = [PLYUtilities getLoader];
        [self.loadingView setHidden:YES];
        CGRect frame = self.loadingView.frame;
        [self.loadingView setFrame:CGRectMake(frame.origin.x, 30, frame.size.width, frame.size.height)];
        [self.view insertSubview:self.loadingView aboveSubview:self.view.subviews[[self.view.subviews count] - 1]];
    }
    return self;
}

-(void)showLoader
{
    [self.loadingView setHidden:NO];
    [(UIActivityIndicatorView *)self.loadingView.subviews[0] startAnimating];
}

-(void)hideLoader
{
    [self.loadingView setHidden:YES];
    [(UIActivityIndicatorView *)self.loadingView.subviews[0] stopAnimating];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView.separatorColor = [PLYTheme backgroundVeryLightColor];
    
    [self setTitle:@"Comments"];
    
    self.navigationItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(goBack)];
    
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height - 40)];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:tableView];
    [tableView setDelegate:self];
    [tableView setDataSource:self];
    self.tableView = tableView;
    
    UIToolbar *toolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, self.view.bounds.size.height - 40, self.view.bounds.size.width, 40)];
    toolBar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:toolBar];
    
    UIView *textCont = [[UIView alloc] initWithFrame:CGRectMake(5, 5, toolBar.bounds.size.width - (60 + 5 * 3), 30)];
    [textCont setBackgroundColor:[UIColor whiteColor]];
    textCont.layer.cornerRadius = 2;
    [toolBar addSubview:textCont];
    
    UITextField *textField = [[UITextField alloc] initWithFrame:CGRectMake(5, 5, textCont.frame.size.width - 10, textCont.frame.size.height - 5)];
    textField.borderStyle = UITextBorderStyleNone;
    textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [textCont addSubview:textField];
    self.textField = textField;
    
    UIButton *sendButton = [[UIButton alloc] init];
    [PLYTheme setGrayButton:sendButton];
    sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [sendButton setTitle:@"Send" forState:UIControlStateNormal];
    sendButton.frame = CGRectMake(toolBar.bounds.size.width - (60 + 5), 5, 60, 30);
    [sendButton addTarget:self action:@selector(addNewComment) forControlEvents:UIControlEventTouchUpInside];
    [toolBar addSubview:sendButton];
    
    
    self.view.keyboardTriggerOffset = toolBar.bounds.size.height;
    
    [self.view addKeyboardPanningWithActionHandler:^(CGRect keyboardFrameInView) {
        /*
         Try not to call "self" inside this block (retain cycle).
         But if you do, make sure to remove DAKeyboardControl
         when you are done with the view controller by calling:
         [self.view removeKeyboardControl];
         */
        
        CGRect toolBarFrame = toolBar.frame;
        toolBarFrame.origin.y = keyboardFrameInView.origin.y - toolBarFrame.size.height;
        toolBar.frame = toolBarFrame;
        
        CGRect tableViewFrame = tableView.frame;
        tableViewFrame.size.height = toolBarFrame.origin.y;
        tableView.frame = tableViewFrame;
    }];
    
    
    // show more button
    UIView *headerView = [[UIView alloc] init];
    UIButton *loadMoreBtn = [[UIButton alloc] init];
    [PLYTheme containedExpandBut:loadMoreBtn cont:headerView];
    [loadMoreBtn setTitle:@"load previous" forState:UIControlStateNormal];
    [loadMoreBtn addTarget:self action:@selector(loadMoreComments) forControlEvents:UIControlEventTouchUpInside];
    self.loadMoreBut = loadMoreBtn;
    
    self.tableView.tableHeaderView = headerView;
    [self.tableView reloadData];
    
    if (self.startShowKeyboard)
        [textField becomeFirstResponder];
    
    [self updateComments];
}

-(void)loadMoreComments
{
    [self.loadMoreBut setHidden:YES];
    self.currentPage += 1;
    [self updateComments];
}

-(void)updateComments
{
    [self showLoader];
    
    void (^cleanUpZeroResults)(void) = ^(void) {
        UIView *emptyHeader = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 50)];
        [emptyHeader setBackgroundColor:[PLYTheme backgroundVeryLightColor]];
        
        UILabel *emptyText = [[UILabel alloc] initWithFrame:CGRectMake(10, 15, 300, 20)];
        [emptyText setBackgroundColor:[UIColor clearColor]];
        [emptyText setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme mediumFont]]];
        [emptyText setTextAlignment:NSTextAlignmentCenter];
        [emptyText setText: @"no comments yet"];
        [emptyText setTextColor:[PLYTheme backgroundDarkColor]];
        [emptyHeader addSubview:emptyText];
        
        self.startingEmpty = YES;
        
        self.tableView.tableHeaderView = emptyHeader;
    };
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    SMQuery *qry = [[SMQuery alloc] initWithSchema:@"PlayoffComment"];
    [qry orderByField:@"createddate" ascending:NO];
    [qry where:@"playoff" isEqualTo:self.playoffId];
    [qry fromIndex:self.currentPage * pageSize + self.pageOffset toIndex:(self.currentPage + 1) * pageSize - 1 + self.pageOffset];
    
    [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *results) {
        [self hideLoader];

        for (PlayoffComment *comment in results) {
            [self.comments insertObject:comment atIndex:0];
        }
        
        [self.tableView reloadData];
        
        if (self.currentPage == 0 && self.startShowKeyboard && [self.comments count] > 0) {
            NSIndexPath* ip = [NSIndexPath indexPathForRow:[self.comments count] - 1 inSection:0];
            [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
        }
        
        if ([results count] == pageSize) {
            [self.loadMoreBut setHidden:NO];
            [self.tableView.tableHeaderView setHidden:NO];
        } else {
            self.tableView.tableHeaderView = nil;
        }
        
        if ([results count] == 0 && [self.comments count]) {
            cleanUpZeroResults();
        }
        
     
    } onFailure:^(NSError *error) {
        [self hideLoader];

        if (error.userInfo[@"error"] && [[(NSString *)error.userInfo[@"error"] componentsSeparatedByString:@"data within range"] count]) {
            return;
        }
        
        if ([error code] == 416 && [self.comments count] == 0) {
            cleanUpZeroResults();
        } else {
            [self.loadMoreBut setHidden:NO];
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Could not connect to the internet"
                                      message:nil
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];

}

-(void)addNewComment
{
    // TODO: use
    // SMDataStore
    
    NSString* commentString = [self.textField text];
    if ([commentString length] == 0) {
        // fail quietly, shouldn't be possible if button is deactivated
        return;
    }
    
    [self showLoader];
    
    __block PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    __block NSManagedObjectContext *managedObjectContext = [appDelegate.coreDataStore contextForCurrentThread];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id == %@", self.playoffId]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffItem" inManagedObjectContext:managedObjectContext]];
    
    void (^showError)(void) = ^(){
        [self hideLoader];
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Could not connect to the internet"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
    };
    
    [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *playoffs) {
        if ([playoffs count] == 0) {
            showError();
            return;
        }
        
        PlayoffItem *playoffItem = playoffs[0];
        
        PlayoffComment *comment = [NSEntityDescription insertNewObjectForEntityForName:@"PlayoffComment" inManagedObjectContext:managedObjectContext];
        [comment setValue: commentString forKey:@"body"];
        NSString *commentId = [PLYUtilities modelUUID];
        [comment setValue:commentId forKey:[comment primaryKeyField]];
        
        [managedObjectContext saveOnSuccess:^(void) {
            [playoffItem addCommentsObject:comment];
            
            [managedObjectContext saveOnSuccess:^(void) {
                
                SMQuery *qry = [[SMQuery alloc] initWithSchema:@"PlayoffComment"];
                [qry where:@"playoffcomment_id" isEqualTo:commentId];
                
                [[appDelegate.client dataStore] performQuery:qry onSuccess:^(NSArray *comments) {
                    if ([comments count] == 0) {
                        showError();
                        return;
                    }
                    
                    self.pageOffset += 1;
                    
                    if (self.startingEmpty)
                        self.tableView.tableHeaderView  = nil;

                    [self hideLoader];
                    [self.comments addObject:comments[0]];
                    [self.tableView reloadData];
                    [self.textField setText:nil];
                    [self.textField resignFirstResponder];
                    
                    NSIndexPath* ip = [NSIndexPath indexPathForRow:[self.comments count] - 1 inSection:0];
                    [self.tableView scrollToRowAtIndexPath:ip atScrollPosition:UITableViewScrollPositionTop animated:YES];
                    
                } onFailure:^(NSError *error) {
                    showError();
                }];
                
            } onFailure:^(NSError *error) {
                showError();
            }];
        } onFailure:^(NSError *error) {
            showError();
        }];
        
    } onFailure:^(NSError *error) {
        showError();
    }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    else
        return YES;
}

-(void)goBack
{
    if (self.loadingView) [self.loadingView setHidden:YES];
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)dealloc
{
    [self.view removeKeyboardControl];
    [self hideLoader];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

# pragma mark table view stuff

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = @"PLYMainCell";
    PLYCommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell)
        cell = (PLYCommentCell *)[self tableviewCellWithReuseIdentifier:CellIdentifier];
    
    [cell configureCell:[self.comments objectAtIndex:[indexPath indexAtPosition:1]]];
    
    return cell;
    
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[PLYCommentCell alloc] initWithFrame:CGRectZero];
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
    return [self.comments count];
}

-(BOOL) tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}


@end
