//
//  PLYSharePlayoffViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 19/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYSharePlayoffViewController.h"
#import "PLYVideoMixerViewController.h"
#import <Parse/Parse.h>

#import "PLYUtilities.h"
#import "PLYTheme.h"

#define CAPTION_CELL_HEIGHT 100
#define CAPTION_CELL_IMAGE_DIM 90
#define CAPTION_CELL_MARGIN 5
#define CAPTION_TEXT_WIDTH 195

#define CAPTION_FRAME_X (CAPTION_CELL_MARGIN + CAPTION_CELL_IMAGE_DIM + CAPTION_CELL_MARGIN)

@implementation PLYSharePlayoffViewController

@synthesize playoffThreadId = _playoffThreadId;
@synthesize thumbnails = _thumbnails;

-(id)initWithImage: (NSURL *) imageURL
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    [self setupCells];
    [self setTitle:@"Share Image"];
    return self;
}

-(id)initWithVideo
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    self.useVideo = TRUE;
    
    [self setupCells];
    [self setTitle:@"Share Video"];
    
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.useVideo) {
        [self doExportFlow];
    }
}

-(void)doExportFlow
{
    // TODO: display thumbnail
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(prepareExportCommandCompletionNotificationReceiver:)
                                                 name:PLYPrepareExportCommandCompletionNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exportCommandCompletionNotificationReceiver:)
                                                 name:PLYExportCommandCompletionNotification
                                               object:nil];
    
    PLYVideoMixerViewController *mixer = (PLYVideoMixerViewController *)[self.navigationController.viewControllers
                                                                         objectAtIndex:[self.navigationController.viewControllers count] - 2];
    
    [mixer refreshVideoWithCompletionNotification:PLYPrepareExportCommandCompletionNotification];
    
}

- (void)prepareExportCommandCompletionNotificationReceiver:(NSNotification *) notification
{
    [(PLYVideoComposer *)notification.object exportComposition];
}

- (void)exportCommandCompletionNotificationReceiver:(NSNotification *) notification
{
    NSDictionary *exportInfo = (NSDictionary *)notification.object;
    
    AVAssetExportSession *exportSession = (AVAssetExportSession *)exportInfo[@"exportSession"];
    NSArray *compositionItems = ((PLYVideoComposer *)exportInfo[@"composer"]).rawCompositionItems;
    
    self.assetExportSession = exportSession;
    self.rawCompositionItems = compositionItems;
    
    [self getThreeThumbnails:self.assetExportSession.outputURL];
  
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (!self.assetExportSession) return;
    
    if (buttonIndex == 0) {
        [self setNewObjectUploadTodo:self.assetExportSession withCompositionItems:self.rawCompositionItems];
    } else if (buttonIndex == 1) {
        [self uploadNewObject:self.assetExportSession withCompositionItems:self.rawCompositionItems overWWAN:YES];
    } else if (buttonIndex == 2) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setBool:YES forKey:@"alwaysUploadOnCellular"];
        [self uploadNewObject:self.assetExportSession withCompositionItems:self.rawCompositionItems overWWAN:YES];
    }

}

-(void)getThreeThumbnails: (NSURL *) videoURL
{
    NSMutableArray *thumbnails = [[NSMutableArray alloc] init];
    
    AVURLAsset *asset=[[AVURLAsset alloc] initWithURL:videoURL options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    long long pos = asset.duration.value / 4;
    NSArray *thumbTimes = @[
                            [NSValue valueWithCMTime:CMTimeMake(pos * 0, asset.duration.timescale)],
                            [NSValue valueWithCMTime:CMTimeMake(pos * 1, asset.duration.timescale)],
                            [NSValue valueWithCMTime:CMTimeMake(pos * 2, asset.duration.timescale)]
                            ];
    
    __block int i = 0;
    __block typeof(self) weakSelf = self;
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime,
                                                       CGImageRef im_,
                                                       CMTime actualTime,
                                                       AVAssetImageGeneratorResult result, NSError *error){
        
        CGImageRef im = CGImageRetain(im_);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {

            i += 1;
            if (result != AVAssetImageGeneratorSucceeded) {
                [weakSelf.shareButton setEnabled:YES];
                NSLog(@"couldn't generate thumbnail, error:%@", error);
                return;
            }
        
            NSString *outputFile = [[PLYUtilities tempFileURL: @"png"] path];
            NSData *thumbImage = UIImagePNGRepresentation([UIImage imageWithCGImage:im]);
            [thumbImage writeToFile:outputFile atomically:YES];
            
            [thumbnails addObject:outputFile];
            
            if (i == 3) {
                [weakSelf.shareButton setEnabled:YES];
                weakSelf.thumbnails = thumbnails;
            } else if (i == 1) {
                [weakSelf.thumbnailPreview setImage:[UIImage imageWithCGImage:im]];
            }
                
            CGImageRelease(im);
            
        });
        
        
    };
    
    CGSize maxSize = CGSizeMake(200, 200);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:thumbTimes completionHandler:handler];
}

-(void)setNewObjectUploadTodo: (AVAssetExportSession *)exportSession
         withCompositionItems: (NSArray *) compositionItems
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.currentlyUploadingPlayoffId = [PLYUtilities modelUUID];
    
    [self prepareToCompleteShare:self.currentlyUploadingPlayoffId];
    
    [appDelegate addDeferredUpload: self.playoffThreadId
                         playoffId: self.currentlyUploadingPlayoffId
                     mainVideoPath:[exportSession.outputURL path]
                            tracks:compositionItems
                        thumbnails:self.thumbnails];
    
    [self finishAndDismiss];
    
}

- (void)uploadNewObject:(AVAssetExportSession *)exportSession
   withCompositionItems: (NSArray *)compositionItems
               overWWAN:(BOOL)isOverWWAN
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    self.currentlyUploadingPlayoffId = [PLYUtilities modelUUID];
    [self prepareToCompleteShare:self.currentlyUploadingPlayoffId];

    [appDelegate addNewUpload: self.playoffThreadId
                    playoffId:self.currentlyUploadingPlayoffId
                mainVideoPath:[exportSession.outputURL path]
                               tracks:compositionItems
                           thumbnails:self.thumbnails
                            overWWAN:isOverWWAN
                    alreadySerialised:NO completeCallback:nil];
    
    [self finishAndDismiss];

}

-(void)finishAndDismiss
{
    /* if was playing off go back to where started, otherwise hide this navigation controller */
    if (self.playoffThreadId) {
        [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"navigation-bar-1"] forBarMetrics:UIBarMetricsDefault];
        UIViewController *vc = self.navigationController.viewControllers[[self.navigationController.viewControllers count] - 3];
        [self.navigationController popToViewController:vc animated:YES];
    } else {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

/* this is the final stage of the navigation controller, so can do this */
-(void)viewWillDisappear:(BOOL)animated
{
    self.notificationView = nil;
    self.thumbnails = nil;
    self.inputCells = nil;
    self.rawCompositionItems = nil;
    self.assetExportSession = nil;
    [super viewWillDisappear:animated];
}

-(void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text length] > 0) {
        [self.captionPlaceholder setHidden:YES];
    } else {
        [self.captionPlaceholder setHidden:NO];
    }
}

-(void) setupCells;
{
    if (self) {

        // setting up fixed cells
        NSMutableArray *cells = [[NSMutableArray  alloc] init];
        
        UITableViewCell *cell = [[UITableViewCell alloc] init];
        UITextView *captionText = [[UITextView alloc] init];
        UIImageView *imageView = [[UIImageView alloc] init];
        UILabel *captionPlaceholder = [[UILabel alloc] init];
        UISwitch *switchView;
        
        [captionText setDelegate:self];
        self.captionArea = captionText;
        self.captionPlaceholder = captionPlaceholder;
        
        // caption + image
        [cell setFrame:CGRectMake(0, 0, 280, CAPTION_CELL_HEIGHT)];
        
        [imageView setFrame:CGRectMake(CAPTION_CELL_MARGIN, CAPTION_CELL_MARGIN,
                                       CAPTION_CELL_IMAGE_DIM, CAPTION_CELL_IMAGE_DIM)];
        [imageView setBackgroundColor:[PLYTheme backgroundLightColor]];
        [cell.contentView addSubview:imageView];
        [PLYTheme setFullGroupedTableViewCell:cell];
        
        self.thumbnailPreview = imageView;
        
        [captionPlaceholder setFrame:CGRectMake(CAPTION_FRAME_X + 4, CAPTION_CELL_MARGIN, CAPTION_TEXT_WIDTH, 30)];
        [captionPlaceholder setBackgroundColor:[UIColor clearColor]];
        [captionPlaceholder setText:@"Your caption..."];
        [captionPlaceholder setTextColor:[PLYTheme backgroundDarkColor]];
        [captionPlaceholder setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:16]];
        [cell.contentView addSubview:captionPlaceholder];
        
        [captionText setFrame:CGRectMake(CAPTION_FRAME_X,
                                         CAPTION_CELL_MARGIN, CAPTION_TEXT_WIDTH, CAPTION_CELL_IMAGE_DIM)];
        [captionText setBackgroundColor:[UIColor clearColor]];
        [captionText setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:16]];
        captionText.contentInset = UIEdgeInsetsMake(-4,-4,0,0);
        [cell.contentView addSubview:captionText];
        
        [cells addObject:cell];
        
        UISwitch *optionSwitch;
        
        /*
        // location
        cell = [[UITableViewCell alloc] init];
        switchView = [[UISwitch alloc] init];
        [cell.imageView setImage:[UIImage imageNamed:@"placeholder-img-1"]];
        [cell.textLabel setText:@"Location"];
        cell.accessoryView = [[UISwitch alloc] init];
        [cells addObject:cell];
         */

        // 3g/wifi
        cell = [[UITableViewCell alloc] init];
        switchView = [[UISwitch alloc] init];
        [cell.imageView setImage:[UIImage imageNamed:@"icon-share-1"]];
        [cell.textLabel setText:@"Use 3G"];
        [cell.textLabel setFont:[PLYTheme mediumDefaultFont]];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        optionSwitch = [[UISwitch alloc] init];
        cell.accessoryView = optionSwitch;
        [self setSwitchWithCustomFont:optionSwitch];
        [PLYTheme setFullGroupedTableViewCell:cell];
        [cells addObject:cell];
        
        // facebook
        cell = [[UITableViewCell alloc] init];
        switchView = [[UISwitch alloc] init];
        [cell.imageView setImage:[UIImage imageNamed:@"icon-facebook-1"]];
        [cell.textLabel setText:@"Facebook"];
        [cell.textLabel setFont:[PLYTheme mediumDefaultFont]];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        optionSwitch = [[UISwitch alloc] init];
        optionSwitch.on = YES;
        [self setSwitchWithCustomFont:optionSwitch];
        cell.accessoryView = optionSwitch;
        [PLYTheme setTopGroupedTableViewCell:cell];
        [cells addObject:cell];

         // twitter
        cell = [[UITableViewCell alloc] init];
        switchView = [[UISwitch alloc] init];
        [cell.imageView setImage:[UIImage imageNamed:@"icon-twitter-1"]];
        [cell.textLabel setText:@"Twitter"];
        [cell.textLabel setFont:[PLYTheme mediumDefaultFont]];
        [cell.textLabel setBackgroundColor:[UIColor clearColor]];
        optionSwitch = [[UISwitch alloc] init];
        [self setSwitchWithCustomFont:optionSwitch];
        optionSwitch.on = YES;
        cell.accessoryView = optionSwitch;
        [PLYTheme setBotGroupedTableViewCell:cell];
        [cells addObject:cell];
        
        /*
        // youtube
        cell = [[UITableViewCell alloc] init];
        switchView = [[UISwitch alloc] init];
        [cell.imageView setImage:[UIImage imageNamed:@"placeholder-img-1"]];
        [cell.textLabel setText:@"YouTube"];
        cell.accessoryView = [[UISwitch alloc] init];
        [cells addObject:cell];
         */

        self.inputCells = cells;

    }
}

- (void) setSwitchWithCustomFont: (UISwitch *) switchView
{
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    
    self.notificationView = [[PLYSimpleNotificationView alloc] initWithNavigationController:self.navigationController];
    
    UIBarButtonItem *doneBtn = [PLYTheme textBarButtonWithTitle:@"share" target:self selector:@selector(tapShare)];
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = [PLYTheme backgroundDarkColor];
    
    [doneBtn setEnabled:NO];
    self.shareButton = doneBtn;
    
    self.navigationItem.leftBarButtonItem = [PLYTheme backButtonWithTarget:self selector:@selector(goBack)];
    self.navigationItem.rightBarButtonItem = doneBtn;
}

-(void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)tapShare
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    BOOL skipWWANQuery = [defaults boolForKey:@"alwaysUploadOnCellular"];
    
    AFNetworkReachabilityStatus status = [((PLYAppDelegate *)[[UIApplication sharedApplication] delegate]) currentReachabilityStatus];
    if (status == AFNetworkReachabilityStatusReachableViaWiFi) {
        [self uploadNewObject:self.assetExportSession withCompositionItems:self.rawCompositionItems overWWAN:NO];
    } else if (status == AFNetworkReachabilityStatusReachableViaWWAN) {
        if (skipWWANQuery) {
            [self uploadNewObject:self.assetExportSession withCompositionItems:self.rawCompositionItems overWWAN:YES];
        } else {
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                NSError *attributesError = nil;
                NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:
                                                [self.assetExportSession.outputURL path] error:&attributesError];
                
                NSString *bodyString = nil;
                
                if (!attributesError) {
                    NSNumber *fileSizeNumber = [fileAttributes objectForKey:NSFileSize];
                    double fileSize = ((double)[fileSizeNumber longLongValue]) / (1024 * 1024);
                    bodyString = [[NSString alloc] initWithFormat:@"file size %.1fMB", fileSize];
                }
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No WiFi Connection"
                                                                message:bodyString
                                                               delegate:self
                                                      cancelButtonTitle:@"Upload later"
                                                      otherButtonTitles:@"Use Cellular", @"Always Use Cellular", nil];
                [alert show];
            });
            
        }
    } else {
        [self setNewObjectUploadTodo:self.assetExportSession withCompositionItems:self.rawCompositionItems];
    }
}

-(void) prepareToCompleteShare: (NSString *)playoffId;
{
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    UISwitch *switchItem;
    
    switchItem = (UISwitch *)((UITableViewCell *)self.inputCells[2]).accessoryView;
    if ([switchItem isOn]) [appDelegate addUploadToFacebookShare:playoffId];
    
    switchItem = (UISwitch *)((UITableViewCell *)self.inputCells[3]).accessoryView;
    if ([switchItem isOn]) [appDelegate addUploadToTwitterShare:playoffId];
    
//    switchItem = (UISwitch *)((UITableViewCell *)self.inputCells[5]).accessoryView;
//    if ([switchItem isOn]) [appDelegate addUploadToYouTubeShare:playoffId];
    
    [appDelegate setUploadDetails:playoffId details:@{
        @"playoffCaption": [self.captionArea text]
     }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath
{
    return FALSE;
}

-(int)cellIndex: (NSIndexPath *)indexPath
{
    if (indexPath.section == 2) {
        return indexPath.section + indexPath.row;
    } else {
        return indexPath.section + indexPath.row;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ((UITableViewCell *)[self.inputCells objectAtIndex:[self cellIndex:indexPath]]).frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (UITableViewCell *)[self.inputCells objectAtIndex:[self cellIndex:indexPath]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return nil;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return 1;
    } else if (section == 1) {
        return 1;
    } else if (section == 2) {
        return 2;
    }
}


@end
