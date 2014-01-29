//
//  PLYVideoMixerViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 06/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYVideoMixerViewController.h"
#import "PLYCaptureViewController.h"
#import "PLYSharePlayoffViewController.h"
#import "PLYAppDelegate.h"
#import "PLYUserInformationView.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "PLYUtilities.h"
#import "PLYTheme.h"

#define MAIN_VIDEO_DIM 220
#define MAIN_SCRUBBER_HEIGHT 30
#define MAIN_SCRUBBER_WIDTH (320 - MAIN_MARGIN - MAIN_MARGIN)
#define MAIN_MARGIN 10
#define MAIN_BTN_WIDTH 145
#define MAIN_BTN_HEIGHT 40

#define MAX_MIX_DURATION 45

#define DURATION_BTN_TAG 20

#define FULL_HEADER_HEIGHT (MAIN_MARGIN + MAIN_VIDEO_DIM + MAIN_MARGIN + MAIN_SCRUBBER_HEIGHT + MAIN_MARGIN + MAIN_BTN_HEIGHT + MAIN_MARGIN)

static NSString *cancelOptionGoBack = @"Cancel, lose changes";
static NSString *deleteCellOption = @"Delete Cell";

static NSString *addButtonOptionWebVideo = @"Internet Video";
static NSString *addButtonOptionCameraRoll = @"Camera Roll";
static NSString *addButtonOptionNewVideo = @"Record New Clip";

static NSString *cellButtonActionCopy = @"Copy Clip";
static NSString *cellButtonActionVolume = @"Set Volume";
static NSString *cellButtonActionSave = @"Save to Camera Roll";

static NSString *cellVolumeFull = @"100%";
static NSString *cellVolumeHalf = @"50%";
static NSString *cellVolumeOff = @"0%";

static NSString *duration60 = @"60 seconds";
static NSString *duration45 = @"45 seconds";
static NSString *duration30 = @"30 seconds";
static NSString *duration20 = @"20 seconds";
static NSString *duration12 = @"12 seconds";
static NSString *duration6 = @"6 seconds";
static NSString *duration4 = @"4 seconds";

static const NSString *ItemStatusContext;

@implementation PLYVideoMixerViewController

@synthesize playoffThreadId = _playoffThreadId;
@synthesize playoffItemId = _playoffItemId;
@synthesize scrubber = _scrubber;
@synthesize previewImage = _previewImage;
@synthesize playerItem = _playerItem;
@synthesize fullDuration = _fullDuration;

// creating a composition for an existing playoff
-(id)initWithPlayoffThreadId: (NSString *)threadId playoffItemId: (NSString *) playoffItemId previewImage: (NSString *) previewImage;
{
    self = [self init];
    if (self) {
        self.playoffThreadId = threadId;
        self.playoffItemId = playoffItemId;
        self.existingPlayoffToInitialise = YES;
        self.previewImage = previewImage;
        
        // query for playoff item, get tracks, show progress of each download -> done in series
        // disable playback until all downloaded
    }
    return self;
}

-(id)init
{
    self = [super init];
    if (self) {
        [self setTitle:@"Mix Video"];
        
        // create add and reorder
        self.player = nil;
        self.playerItem = nil;
        self.playerView = nil;
        self.existingPlayoffToInitialise = NO;
        self.tracksChanged = YES;
        
        self.fullDuration = CMTimeMake(MAX_MIX_DURATION * 1000, 1000);
    }
    return self;
}

-(void)tapDeleteCell:(PLYVideoMixerCell *) cell
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:deleteCellOption
                                                    otherButtonTitles: nil];
    
    [actionSheet showInView:self.navigationController.view];
    self.currentlyInterestedCell = cell;
    
    [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:@[@0]];
}

-(void)nextStage
{
    if (self.currentlyDownloading) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Please wait for downloads to complete"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    } else if ([self.currentTableViewCells count] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"You need at least one video"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    
    PLYSharePlayoffViewController *share = [[PLYSharePlayoffViewController alloc] initWithVideo];
    if (self.playoffThreadId) [share setPlayoffThreadId:self.playoffThreadId];
    [self hideMainLoader];
    if (self.player) [self.player pause];
    [self.navigationController pushViewController:share animated:YES];
}

-(void)previousViewController
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:cancelOptionGoBack
                                                    otherButtonTitles: nil];
    
    [actionSheet showInView:self.navigationController.view];
    
    [self pauseAndShowPlay];
    
    [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:@[@0]];
}

-(void) viewDidAppear:(BOOL)animated
{
    /* first use note */
    PLYUserInformationView *firstUse = [[PLYUserInformationView alloc] initWithImage:@"user-info-mixer-1"
                                                                      andFirstUseKey:@"firstUse_useMixer" white:NO];
    if (firstUse) {
        [self.navigationController.view addSubview:firstUse];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // navbar
    self.navigationItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(previousViewController)];
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"dark-navigation-bar-1"] forBarMetrics:UIBarMetricsDefault];
    
    UIBarButtonItem *nextBtn = [PLYTheme textBarButtonWithTitle:@"share" target:self selector:@selector(nextStage)];
    
    if (self.existingPlayoffToInitialise) {
        [nextBtn setEnabled:NO];
    }
    self.navigationItem.rightBarButtonItem = nextBtn;
    
    // content
    self.tableView.separatorColor = [UIColor clearColor];
    
    UIButton *btn;

    [self.tableView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320, FULL_HEADER_HEIGHT)];
    [headerView setBackgroundColor:[PLYTheme backgroundDarkColor]];
    self.tableView.tableHeaderView = headerView;
    
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0,0,320, 40)];
    [footerView setBackgroundColor:[PLYTheme backgroundDarkColor]];
    self.tableView.tableFooterView = footerView;
    
    // scrubber
    UIControl *rectControl = [[UIControl alloc] initWithFrame:CGRectMake(MAIN_MARGIN,
                                                               MAIN_MARGIN + MAIN_VIDEO_DIM + MAIN_MARGIN,
                                                               MAIN_SCRUBBER_WIDTH, MAIN_SCRUBBER_HEIGHT)];
    [rectControl setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    [self.tableView.tableHeaderView addSubview:rectControl];
    
    UIControl *innerRectView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, MAIN_SCRUBBER_HEIGHT, MAIN_SCRUBBER_HEIGHT)];
    [innerRectView setBackgroundColor:[PLYTheme primaryColor]];
    [rectControl addSubview:innerRectView];
    self.scrubber = innerRectView;
    
    // add btn
    btn = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_MARGIN,
                                                     FULL_HEADER_HEIGHT - MAIN_MARGIN - MAIN_BTN_HEIGHT,
                                                     MAIN_BTN_WIDTH,
                                                     MAIN_BTN_HEIGHT)];
    [PLYTheme setStandardButton:btn];
    [btn setTitle:@"Add Clip" forState:UIControlStateNormal];

    self.addClipBtn = btn;
    [self.tableView.tableHeaderView addSubview:btn];
    
    // duration btn
    btn = [[UIButton alloc] initWithFrame:CGRectMake(320 - MAIN_BTN_WIDTH - MAIN_MARGIN,
                                                     FULL_HEADER_HEIGHT - MAIN_MARGIN - MAIN_BTN_HEIGHT,
                                                     MAIN_BTN_WIDTH,
                                                     MAIN_BTN_HEIGHT)];
    [PLYTheme setStandardButton:btn];
    [btn setTag:DURATION_BTN_TAG];
    self.setDurBtn = btn;
    [self.tableView.tableHeaderView addSubview:btn];
    
    // at end
    [self setEditing:YES animated:NO];
    [self setupVideo];
    
    if (self.existingPlayoffToInitialise) {
        [self beginExistingPlayoffInitialisation];
    } else {
        [self setupMainButtons];
    }
}

# pragma mark scrubber stuff

- (void) tapPosition:(id) sender withEvent:(UIEvent *) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.updatedScrubber = YES;
        [self pauseAndShowPlay];
        
        UIControl *control = ((UIControl *)sender);
        UITouch *t = [[event allTouches] anyObject];
        CGFloat xPos = [t locationInView:control].x;
        
        xPos -= MAIN_SCRUBBER_HEIGHT;
        if (xPos < MAIN_SCRUBBER_HEIGHT) xPos += MAIN_SCRUBBER_HEIGHT;
        
        [self.scrubber setFrame:CGRectMake(xPos, 0, MAIN_SCRUBBER_HEIGHT, MAIN_SCRUBBER_HEIGHT)];
        
        [self findNewPositionFromScrubber];
    });
}

-(void)pauseAndShowPlay
{
    [self.player pause];
    [self.videoMaskControl setHidden:NO];
}

- (void) slideAlong:(id) sender withEvent:(UIEvent *) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.updatedScrubber = YES;
        [self pauseAndShowPlay];
        
        UIControl *control = ((UIControl *)sender);
        
        UITouch *t = [[event allTouches] anyObject];
        CGPoint pPrev = [t previousLocationInView:control];
        CGPoint p = [t locationInView:control];
        
        CGFloat xPos = control.frame.origin.x + (p.x - pPrev.x);
        if (xPos < 0) xPos = 0;
        if (xPos > MAIN_SCRUBBER_WIDTH - MAIN_SCRUBBER_HEIGHT) xPos = MAIN_SCRUBBER_WIDTH - MAIN_SCRUBBER_HEIGHT;
        [control setFrame:CGRectMake(xPos, 0, MAIN_SCRUBBER_HEIGHT, MAIN_SCRUBBER_HEIGHT)];
        
        [self findNewPositionFromScrubber];
    });
}

-(void)findNewPositionFromScrubber
{
    float prop = self.scrubber.frame.origin.x / (MAIN_SCRUBBER_WIDTH - MAIN_SCRUBBER_HEIGHT);
    CMTime newPosition = CMTimeMakeWithSeconds(prop * CMTimeGetSeconds(self.playerItem.duration) * 1000, 1000);
    [self.player seekToTime:newPosition];
}

-(void)initScrubberTimer
{
	double interval = .1f;
	
	CMTime playerDuration = [self.playerItem duration];
	if (CMTIME_IS_INVALID(playerDuration))
	{
		return;
	}
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		CGFloat width = CGRectGetWidth([self.scrubber.superview bounds]);
		interval = 0.5f * duration / width;
	}
    
    if (duration) {
        /* Update the scrubber during normal playback. */
        self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                  queue:NULL /* If you pass NULL, the main queue is used. */
                                                             usingBlock:^(CMTime time)
                         {
                             if (!self.updatedScrubber) [self syncScrubber];
                         }];
    }
    
}

- (void)syncScrubber
{
	CMTime playerDuration = self.playerItem.duration;
	if (CMTIME_IS_INVALID(playerDuration))
	{
		[self.scrubber setFrame:CGRectMake(0, 0, MAIN_SCRUBBER_HEIGHT, MAIN_SCRUBBER_HEIGHT)];
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		double time = CMTimeGetSeconds([self.player currentTime]);
        double prop = time / CMTimeGetSeconds(playerDuration);
        if (prop < 0.0) prop = 0.0;
        if (prop > 1.0) prop = 1.0;
        
		[self.scrubber setFrame:CGRectMake((MAIN_SCRUBBER_WIDTH - MAIN_SCRUBBER_HEIGHT) * prop, 0, MAIN_SCRUBBER_HEIGHT, MAIN_SCRUBBER_HEIGHT)];
	}
}

# pragma mark main stuff

-(void)showMainLoader
{
    UIView *loader = [PLYUtilities getLoader];
    [self.navigationController.view addSubview:loader];
    UIActivityIndicatorView *spinner = (UIActivityIndicatorView *)loader.subviews[0];
    [spinner startAnimating];
    [loader setHidden:NO];
    self.mainLoader = loader;
}

-(void)hideMainLoader
{
    if (self.mainLoader) {
        [self.mainLoader setHidden:YES];
        [(UIActivityIndicatorView *)self.mainLoader.subviews[0] stopAnimating];
        self.mainLoader = nil;
    }
}

- (void) addThirdPartyVideoDownloadTrack:(NSString *)url withPath:(NSString *)extension
{
    PLYVideoMixerCell *cell = [[PLYVideoMixerCell alloc] initAsInProgressDownload];
    [self.currentTableViewCells insertObject:cell atIndex:0];
    [cell setSpinnerActive];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    [self.tableView reloadData];
    
    self.currentlyDownloading = YES;
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    void(^cancelDownload)(void) = [appDelegate downloadWebVideo:url
                         fileName: nil
                    withExtension:extension
                        withBlock:^(BOOL success, NSString *path) {
                            [cell setMixerViewController:self];
                            if (success) {
                                [cell stopLoaders];
                                [self insertUserVideo:cell withURL:[NSURL fileURLWithPath: path]];
                            } else {
                                [cell setErrorMessageWithRetryURL:url];
                            }
                            self.currentlyDownloading = NO;
                        }
              andProgressDelegate:cell];
}

-(void)retryDownload:(PLYVideoMixerCell *) cell withURL: (NSString *) url
{
    if (self.currentlyDownloading) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Please wait for downloads to finish"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    self.currentlyDownloading = YES;
    [cell setSpinnerActive];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    [self.tableView reloadData];
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    void(^cancelDownload)(void) = [appDelegate downloadWebVideo:url
                         fileName: nil
                    withExtension:@"mp4"
                        withBlock:^(BOOL success, NSString *path) {
                              if (success) {
                                  [cell stopLoaders];
                                  [self insertUserVideo:cell withURL:[NSURL fileURLWithPath: path]];
                              } else {
                                  [cell setErrorMessageWithRetryURL:url];
                              }
                              self.currentlyDownloading = NO;
                          }
              andProgressDelegate:cell];
}

-(void)beginExistingPlayoffInitialisation
{
    [self showMainLoader];
    
    self.tracksToTickOff = [[NSMutableArray alloc] init];
    __block CMTime longestDur = kCMTimeZero;
    
    void(^trackCallback)(BOOL, NSDictionary *, NSString *, NSError *, NSString *) =
            ^(BOOL success, NSDictionary *track, NSString *path, NSError *err, NSString *videoURL){
        PLYVideoMixerCell *cell;
        for (PLYVideoMixerCell *aCell in self.currentTableViewCells) {
            if ([track valueForKey: @"playoffvideotrack_id"] == [aCell videoTrackId]) {
                cell = aCell;
                break;
            }
        }
        
        [cell stopLoaders];
        
        if (success) {
            [cell addLocalVideo:[NSURL fileURLWithPath:path]];
            
            CMTime dur = CMTimeMake([(NSNumber *)track[@"outerDuration"] longLongValue], [(NSNumber *)track[@"outerDurationTimescale"] longValue]);
            
            if (CMTimeCompare(longestDur, kCMTimeZero) == 0 || CMTimeCompare(longestDur, dur) == -1) {
                longestDur = dur;
                [self setMixDuration:dur];
                [self setMixDurationBtn];
            }
            
        } else {
            [cell setErrorMessageWithRetryURL:videoURL];
        }
        
        [self setCellSpinnerActive:[self.tracksToTickOff lastObject]];
        [self.tracksToTickOff removeLastObject];
        
        if ([self.tracksToTickOff count] == 0) {
            // TODO: check this works as intended
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
    };
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate downloadVideoPlayoffTracks:self.playoffItemId
                              trackCallback:trackCallback
                      initialTracksCallback:^(BOOL success, NSArray *orderedTracks) {
                          [self hideMainLoader];
                          
                          for (NSDictionary *track in [[orderedTracks reverseObjectEnumerator] allObjects]) {
                              [self.tracksToTickOff addObject:track];
                          }
                          
                          [self setProcessedTracks:orderedTracks];
                          [self.tableView reloadData];
                          
                          [self setTracksInQueue:self.tracksToTickOff];
                          
                          [self setCellSpinnerActive:[self.tracksToTickOff lastObject]];
                          [self.tracksToTickOff removeLastObject];
                          
                          [self setupMainButtons];
                          
                          return self.currentTableViewCells;
                      }
                          allTracksCallback:^(BOOL success, NSError *error){
                              [self hideMainLoader];
                          }];
}

-(void)setCellSpinnerActive:(NSDictionary *)track
{
    for (PLYVideoMixerCell *cell in self.currentTableViewCells) {
        if ([track valueForKey: @"playoffvideotrack_id"] == [cell videoTrackId]) {
            [cell stopLoaders];
            [cell setSpinnerActive];
            break;
        }
    }
}

-(void)setTracksInQueue:(NSArray *)tracks
{
    for (NSDictionary *track in tracks) {
        for (PLYVideoMixerCell *cell in self.currentTableViewCells) {
            if ([track valueForKey: @"playoffvideotrack_id"] == [cell videoTrackId]) {
                [cell setLoadingMessage];
                break;
            }
        }
    }
}

-(void) processRawTracks
{
    if (!self.currentRawTracks) return;
    
    CMTime totalDuration = kCMTimeZero;
    for (NSDictionary *track in self.currentRawTracks) {
        totalDuration = CMTimeAdd(totalDuration, CMTimeMake([(NSNumber *)track[@"inner_duration"] longLongValue],
                                                            [(NSNumber *)track[@"inner_timescale"] longValue]));
    }
    
    if (CMTimeCompare(totalDuration, kCMTimeZero) == 0) {
        [self setMixDuration:CMTimeMake(MAX_MIX_DURATION, 1)];
    } else {
        [self setMixDuration:totalDuration];
    }
    
    self.currentProcessedTracks = [self orderRawTracks:self.currentRawTracks];
    
}

-(NSMutableArray *) orderRawTracks:(NSArray *)tracks
{
    self.currentProcessedTracks = [[NSMutableArray alloc] init];
    
    int trackCount = [tracks count];
    int compareTime;
    
    CMTime aTime;
    CMTime currentDur = kCMTimeZero;
    CMTime lastDur = kCMTimeZero;
    
    NSMutableArray *processed = [[NSMutableArray alloc] init];
    
    NSDictionary *track;
    NSMutableDictionary *newTrack;
    NSNumber *start;
    NSNumber *timescale;
    
    for (track in tracks) {
        aTime = CMTimeMake([(NSNumber *)track[@"inner_duration"] longLongValue],
                           [(NSNumber *)track[@"inner_timescale"] longValue]);
        
        newTrack = [[NSMutableDictionary alloc] initWithDictionary:[track copy]];
        timescale = [[NSNumber alloc] initWithLong: aTime.timescale];
        
        currentDur = CMTimeAdd(currentDur, aTime);
        compareTime = CMTimeCompare(currentDur, self.fullDuration);
        
        // longer than max duration
        if (compareTime == 1) {
            aTime = CMTimeSubtract(self.fullDuration, aTime);
            
            compareTime = CMTimeCompare(kCMTimeZero, aTime);
            // less than zero
            if (compareTime == 1) {
                start = @0;
            } else {
                start = [[NSNumber alloc] initWithLongLong:aTime.value];
                timescale = [[NSNumber alloc] initWithLong:aTime.timescale];
            }
        } else {
            start = [[NSNumber alloc] initWithLongLong:lastDur.value];
            if (lastDur.timescale != 1) {
                timescale = [[NSNumber alloc] initWithLong:lastDur.timescale];
            }
        }
        
        [newTrack setValue:start forKey:@"start"];
        [newTrack setValue:timescale forKey:@"outer_timescale"];
        
        [processed addObject:newTrack];
        
        lastDur = currentDur;
    }

    return processed;
}

-(void)setMixDuration:(CMTime)time
{
    int compare = CMTimeCompare(CMTimeMake(MAX_MIX_DURATION * 1000, 1000), time);
    if (compare != -1) {
        self.fullDuration = time;
    }
}

-(void)setMixDurationBtn
{
    float secs = CMTimeGetSeconds(self.fullDuration);
    UIButton *btn = (id)[self.tableView.tableHeaderView viewWithTag:DURATION_BTN_TAG];
    [btn setTitle:[[NSString alloc] initWithFormat:@"Duration (%.1f)", secs, nil] forState:UIControlStateNormal];
}

- (void) durationAction:(UIButton *) sender
{
    if (self.currentlyDownloading) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Please wait for downloads to complete"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles: duration45, duration30,
                                                                       duration20, duration12, duration6, duration4, nil];
    
    [actionSheet showInView:self.navigationController.view];
    
    [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:nil];
}

-(void) setDurationSeconds: (float) seconds
{
    /* serialise all tracks
     * deserialise all tracks direct
     * clear all tracks
     * add each track with config for new duration
     */
    
    NSLog(@"new duration: %f", seconds);
    [self setMixDuration:CMTimeMake(seconds * 1000, 1000)];
    [self setMixDurationBtn];
    
    NSMutableArray *toRecreate = [[NSMutableArray alloc] init];
    
    for (PLYVideoMixerCell *cell in self.currentTableViewCells) {
        [toRecreate addObject:[cell serialiseCellConfig]];
    }
    
    [self.currentTableViewCells removeAllObjects];
    
    for (NSDictionary *ser in toRecreate) {
        PLYVideoMixerCell *cell = [[PLYVideoMixerCell alloc] init];
        
        NSMutableDictionary *updatedConf = [[NSMutableDictionary alloc] initWithDictionary:ser];
        updatedConf[@"outer_duration"] = [NSValue valueWithCMTime:self.fullDuration];
        updatedConf[@"local"] = @YES;
        
        [cell deserialiseDirect:updatedConf withMixerViewController:self];

        [self.currentTableViewCells addObject:cell];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    [self.tableView reloadData];
}

- (void) addAction:(UIButton *) sender
{
    if ([self.currentTableViewCells count] >= MaxTracksCount) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:[[NSString alloc] initWithFormat: @"You've captured the maximum %i clips", MaxTracksCount, nil]
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                    delegate:self
                                    cancelButtonTitle:@"Cancel"
                                    destructiveButtonTitle:nil
                                    otherButtonTitles: addButtonOptionWebVideo, addButtonOptionCameraRoll, addButtonOptionNewVideo, nil];
  
    [actionSheet showInView:self.navigationController.view];
    
    [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:@[@0, @1, @2]];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];

    if ([buttonTitle isEqualToString:cancelOptionGoBack]) {
        [self hideMainLoader];
        if (self.playoffThreadId) {
            [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-1"] forBarMetrics:UIBarMetricsDefault];
        }
        [self.navigationController popViewControllerAnimated:YES];
    } else if ([buttonTitle isEqualToString:deleteCellOption]) {
        NSIndexPath *indexPath = [self.tableView indexPathForCell:self.currentlyInterestedCell];
        [self removeRowAtIndexPath:indexPath];
    } else if  ([buttonTitle isEqualToString:addButtonOptionNewVideo]) {
        PLYCaptureViewController *capController = [[PLYCaptureViewController alloc] initAsStandalone:self];
        [self presentViewController:capController animated:YES completion:^{}];
        
    } else if  ([buttonTitle isEqualToString:addButtonOptionWebVideo]) {
        
        if (self.currentlyDownloading) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Please wait for downloads to complete"
                                      message:nil
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        } else {
            PLYVideoWebBrowserViewController *browser = [[PLYVideoWebBrowserViewController alloc] init];
            [browser setMixerViewController:self];
            [self.navigationController presentViewController:browser animated:YES completion:nil];
        }

    } else if ([buttonTitle isEqualToString:addButtonOptionCameraRoll]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.mediaTypes = [[NSArray alloc] initWithObjects: (NSString *) kUTTypeMovie, nil];
        [picker setDelegate:self];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:picker animated:YES completion:nil];
    } else if ([buttonTitle isEqualToString:cellButtonActionCopy]) {
        if (self.currentlyInterestedCell) {
            PLYVideoMixerCell *cell = [[PLYVideoMixerCell alloc] init];
            [cell deserialiseDirect:[self.currentlyInterestedCell serialiseCellConfig] withMixerViewController:self];
            int index = 0;
            for (UITableViewCell *cell in self.currentTableViewCells) {
                if (cell == self.currentlyInterestedCell) {
                    break;
                }
                index += 1;
            }
            
            if (index >= [self.currentTableViewCells count]) index = 0;

            [self.currentTableViewCells insertObject:cell atIndex:index];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
            [self.tableView reloadData];
        }
    } else if ([buttonTitle isEqualToString:cellButtonActionVolume]) {
        if (self.currentlyInterestedCell) {
            UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                                     delegate:self
                                                            cancelButtonTitle:@"Cancel"
                                                       destructiveButtonTitle:nil
                                                            otherButtonTitles: cellVolumeFull, cellVolumeHalf, cellVolumeOff, nil];
            
//            [actionSheet showFromTabBar:self.tabBarController.tabBar];
            [actionSheet showInView:self.navigationController.view];
            
            [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:nil];
        }
    } else if ([buttonTitle isEqualToString:cellButtonActionSave]) {
        if (self.currentlyInterestedCell) {
            NSURL *movieURL = [self.currentlyInterestedCell serialiseCellConfig][@"URL"];
            if (movieURL) {
                [self showMainLoader];
                ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error){
                    [self hideMainLoader];
                    if(error) {
                        NSLog(@"CameraViewController: Error on saving movie : %@ {imagePickerController}", error);
                    }
                    else {
                        NSLog(@"URL: %@", assetURL);
                    }
                }];
            }
        }
    } else if ([buttonTitle isEqualToString:cellVolumeFull]) {
        if (self.currentlyInterestedCell) {
            [self.currentlyInterestedCell setSoundVolume:1];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
        }
    } else if ([buttonTitle isEqualToString:cellVolumeHalf]) {
        if (self.currentlyInterestedCell) {
            [self.currentlyInterestedCell setSoundVolume:0.5];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
        }
    } else if ([buttonTitle isEqualToString:cellVolumeOff]) {
        if (self.currentlyInterestedCell) {
            [self.currentlyInterestedCell setSoundVolume:0];
            [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
        }
    } else if ([buttonTitle isEqualToString:duration60]) [self setDurationSeconds:60];
     else if ([buttonTitle isEqualToString:duration45]) [self setDurationSeconds:45];
     else if ([buttonTitle isEqualToString:duration30]) [self setDurationSeconds:30];
     else if ([buttonTitle isEqualToString:duration20]) [self setDurationSeconds:20];
     else if ([buttonTitle isEqualToString:duration12]) [self setDurationSeconds:12];
     else if ([buttonTitle isEqualToString:duration6]) [self setDurationSeconds:6];
     else if ([buttonTitle isEqualToString:duration4]) [self setDurationSeconds:4];

}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{

    [picker dismissViewControllerAnimated:YES completion:nil];
    NSURL *videoURL = [info valueForKey:UIImagePickerControllerReferenceURL];
    
    [PLYUtilities videoAssetURLToTempFile:videoURL completion:^(BOOL success, NSURL *videoURL, NSError *error) {
        PLYVideoMixerCell *cell = [[PLYVideoMixerCell alloc] initAsInProgressDownload];
        [self.currentTableViewCells insertObject:cell atIndex:0];
        [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
        [self.tableView reloadData];
        
        [self insertUserVideo:cell withURL:videoURL];
    }];
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
    return [self.currentTableViewCells count];
}

- (UITableViewCell *)tableviewCellWithReuseIdentifier:(NSString *)identifier
{
    UITableViewCell *cell = [[PLYVideoMixerCell alloc] initWithFrame:CGRectZero];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [PLYVideoMixerCell cellHeight];
}
/*
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [(PLYVideoMixerCell *)cell setDragImage];
}*/

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.currentTableViewCells objectAtIndex:[indexPath indexAtPosition:1]];
}

-(UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return UITableViewCellEditingStyleNone; /* use a custom delete but to fire an event */
}

-(BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath
{
    return NO;
}

-(BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath
{
    id obj = [self.currentTableViewCells objectAtIndex:sourceIndexPath.row];
    [self.currentTableViewCells removeObjectAtIndex:sourceIndexPath.row];
    [self.currentTableViewCells insertObject:obj atIndex:destinationIndexPath.row];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
}

-(void)tableView:(UITableView *)tableView
       commitEditingStyle:(UITableViewCellEditingStyle)editingStyle
       forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self removeRowAtIndexPath:indexPath];
    }
}

-(void)removeRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.currentTableViewCells removeObjectAtIndex:indexPath.row];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.tableView endUpdates];
}

-(void)setRawTracks:(NSArray *)tracks
{
    self.currentRawTracks = [[NSMutableArray alloc] initWithArray:tracks];
    [self processRawTracks];
    [self setupTableViewCells];
    
    /* simply set a preview image */
    if ([self.currentProcessedTracks count] > 0) {
        NSDictionary *track = self.currentProcessedTracks[0];
        
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:track[@"URL"] options:nil];
        AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        generator.appliesPreferredTrackTransform=TRUE;
        
        CGSize maxSize = CGSizeMake(MAIN_VIDEO_DIM, MAIN_VIDEO_DIM);
        generator.maximumSize = maxSize;
        [generator generateCGImagesAsynchronouslyForTimes:@[[NSValue valueWithCMTime:kCMTimeZero]] completionHandler:
            ^(CMTime requestedTime, CGImageRef im_, CMTime actualTime,
              AVAssetImageGeneratorResult result, NSError *error){
            
            CGImageRef im = CGImageRetain(im_);
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                 [self.videoPreviewImage setImage:[UIImage imageWithCGImage:im]];
                CGImageRelease(im);
            });
            }];
    }
}

-(void)setProcessedTracks:(NSArray *)tracks
{
    self.currentProcessedTracks = tracks;
    [self setupTableViewCells];
}

/* there are too few cells to make it worthwile worrying about memory, use them in place of data source */
-(void)setupTableViewCells
{
    NSMutableArray *cells = [[NSMutableArray alloc] init];

    for (NSDictionary *trackConf in self.currentProcessedTracks) {
        PLYVideoMixerCell *cell = [[PLYVideoMixerCell alloc] init];

        [cell configureCell:trackConf withContext:@{
         @"is_remote": self.existingPlayoffToInitialise ? @YES : @NO,
         @"duration": [[NSNumber alloc] initWithLongLong:self.fullDuration.value],
         @"duration_timescale": [[NSNumber alloc] initWithLong:self.fullDuration.timescale]
         } mixerVC:self];
        
        [cells addObject:cell];
    }
    
    self.currentTableViewCells = cells;
}

/* grip customization, http://b2cloud.com.au/how-to-guides/reordering-a-uitableviewcell-from-any-touch-point */
- (void) tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [(PLYVideoMixerCell *)cell setDragImage];
}

-(void)dealloc
{
    if (self.playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
        self.playerItem = nil;
    }
}

-(void)setupVideo
{
    CGRect rect = CGRectMake((320 - MAIN_VIDEO_DIM) / 2, MAIN_MARGIN, MAIN_VIDEO_DIM, MAIN_VIDEO_DIM);
    
    // preview image
    UIImageView *videoPreview = [[UIImageView alloc] initWithFrame:rect];
    [self.tableView.tableHeaderView addSubview:videoPreview];
    self.videoPreviewImage = videoPreview;
    if (self.previewImage) {
        [videoPreview setImageWithURL:[NSURL URLWithString:self.previewImage]
                     placeholderImage:[UIImage imageNamed:@"placeholder-vid-1"]
                            completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {}];
    }
    
    // playback
    PLYPlaybackView *playbackView = [[PLYPlaybackView alloc] initWithFrame:rect];
    
    [self.tableView.tableHeaderView addSubview:playbackView];
    self.playerView = playbackView;
    
    UIControl *pauseBut = [[UIControl alloc] initWithFrame:rect];
    [pauseBut setBackgroundColor:[UIColor clearColor]];
    [self.tableView.tableHeaderView addSubview:pauseBut];
    self.pauseButton = pauseBut;
    
    // play pause but
    rect = CGRectMake((320 / 2) - (120 / 2), (MAIN_VIDEO_DIM / 2) - (120 / 2) + MAIN_MARGIN, 120, 120);
    
    UIButton *tapPlayPause = [[UIButton alloc] initWithFrame:rect];
    [tapPlayPause setBackgroundColor:[UIColor clearColor]];
    [tapPlayPause setBackgroundImage:[UIImage imageNamed:@"play-but-1"] forState:UIControlStateNormal];
    self.videoMaskControl = tapPlayPause;
    [self.tableView.tableHeaderView addSubview:tapPlayPause];
    
    // main events
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(changeTracksNotification:)
												 name:PLYChangeMixerTrackNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(editCommandCompletionNotificationReceiver:)
												 name:PLYEditCommandCompletionNotification
											   object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(playerItemDidReachEnd:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:self.playerItem];

}

-(void)changeTracksNotification:(NSNotification*) notification
{
    [self.player pause];
    [self.videoMaskControl setHidden:NO];
    self.tracksChanged = YES;
}

-(void)setupMainButtons
{
    [self setMixDurationBtn];
    
    [self.addClipBtn addTarget:self action:@selector(addAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.setDurBtn addTarget:self action:@selector(durationAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.videoMaskControl addTarget:self action:@selector(tapVideo:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    [self.pauseButton addTarget:self action:@selector(tapPauseVideo) forControlEvents:UIControlEventTouchUpInside];
    
    [(UIControl *)self.scrubber.superview addTarget:self action:@selector(tapPosition:withEvent:) forControlEvents:UIControlEventTouchDown];
    [self.scrubber addTarget:self action:@selector(slideAlong:withEvent:) forControlEvents:UIControlEventTouchDragInside];
}

-(void)tapPauseVideo
{
    [self.player pause];
    [self.videoMaskControl setHidden:NO];
}

-(void)tapVideo:(id)sender withEvent:(UIEvent *)event
{
    self.updatedScrubber = NO;
    [self.videoMaskControl setHidden:YES];
    if (self.tracksChanged) {
        [self refreshVideoWithCompletionNotification:PLYEditCommandCompletionNotification];
    } else {
        [self play];
    }
}

/* called when tap video or scrubber and cells have changed */
-(PLYVideoComposer *)refreshVideoWithCompletionNotification: (NSString *)notificationName
{
    PLYVideoComposer *composer = [[PLYVideoComposer alloc] init];
    
    NSMutableArray *serialised = [[NSMutableArray alloc] init];
    int layerIndex = 1;

    for (PLYVideoMixerCell *cell in self.currentTableViewCells) {
        NSDictionary *ser = [cell serialiseCellConfig];
        if ([ser valueForKey:@"URL"]) {
            NSMutableDictionary *serFull = [[NSMutableDictionary alloc] initWithDictionary:ser];
            [serFull setValue:[NSNumber numberWithInt:layerIndex] forKey:@"layer_index"];
            [serialised addObject:serFull];
            layerIndex += 1;
        }
    }
    
    [composer setupComposition:serialised withDuration:self.fullDuration withNotificationName: notificationName];
    return composer;
}


- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == &ItemStatusContext) {
        [self initScrubberTimer];
        return;
    }
    
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

/*
- (void)syncUI {
    if ((self.player.currentItem != nil) && ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
        //        self.playButton.enabled = YES;
        //[self play];
    } else {
        //        self.playButton.enabled = NO;
    }
}

*/

- (void)play
{
    [self.player play];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.videoMaskControl setHidden:NO];
    [self.player seekToTime:kCMTimeZero];
}

- (void)reloadPlayerView
{
	// This method is called every time a tool has been applied to a composition
	// It reloads the player view with the updated composition
	// Create a new AVPlayerItem and make it our player's current item.
	self.videoComposition.animationTool = NULL;
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
	playerItem.videoComposition = self.videoComposition;
	playerItem.audioMix = self.audioMix;
    
    if (self.timeObserver && self.player) [self.player removeTimeObserver:self.timeObserver];
    if (!self.player) self.player = [AVPlayer playerWithPlayerItem:playerItem];
    
	[[self player] replaceCurrentItemWithPlayerItem:playerItem];
    
    self.playerItem = playerItem;
    
    [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
    
    [self.playerView setPlayer:self.player];
    
    self.tracksChanged = NO;
    
    [self play];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (self.playerItem != nil) {
        [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
        [self reloadPlayerView];
    }
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    if (self.playerItem != nil) [self.playerItem removeObserver:self forKeyPath:@"status"];
    if (self.player != nil && self.timeObserver != nil) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

- (void)editCommandCompletionNotificationReceiver:(NSNotification*) notification
{
	if ([[notification name] isEqualToString:PLYEditCommandCompletionNotification]) {
		// Update the document's composition, video composition etc
		self.composition = [[notification object] mutableComposition];
		self.videoComposition = [[notification object] mutableVideoComposition];
		self.audioMix = [[notification object] mutableAudioMix];
		dispatch_async( dispatch_get_main_queue(), ^{
			[self reloadPlayerView];
		});
	}
}

-(void)insertUserVideo: (PLYVideoMixerCell *) cell withURL: (NSURL *)videoURL
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:videoURL];
    CMTime duration = playerItem.duration;
    
    NSDictionary *config = @{
                             @"local": @TRUE,
                             @"URL": videoURL,
                             @"inner_duration": [[NSNumber alloc] initWithLongLong:duration.value],
                             @"inner_timescale": [[NSNumber alloc] initWithLong:duration.timescale]
                             };
    
    [cell configureCell:config withContext:@{
     @"is_remote": @NO,
     @"duration": [[NSNumber alloc] initWithLongLong:self.fullDuration.value],
     @"duration_timescale": [[NSNumber alloc] initWithLong:self.fullDuration.timescale]
     } mixerVC:self];
    
    cell.inProgressDownload = NO;
}

- (void) addFreshCapture: (NSURL *)url
{
    PLYVideoMixerCell *cell = [[PLYVideoMixerCell alloc] initAsInProgressDownload];
    [self.currentTableViewCells insertObject:cell atIndex:0];
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    [self.tableView reloadData];
    [self insertUserVideo:cell withURL:url];
}

- (void) showActionSheetForCell:(UITableViewCell *)cell
{
    self.currentlyInterestedCell = cell;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles: cellButtonActionCopy, cellButtonActionVolume, cellButtonActionSave, nil];
    
    [actionSheet showInView:self.navigationController.view];
    
    [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:@[@0, @1, @2]];
}

@end
