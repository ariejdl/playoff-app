//
//  PLYExpandedViewCell.m
//  Playoff
//
//  Created by Arie Lakeman on 04/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYExpandedViewCell.h"
#import "PLYPlaybackView.h"
#import <AVFoundation/AVFoundation.h>
#import <SDWebImage/UIImageView+WebCache.h>
#import <QuartzCore/QuartzCore.h>

#import "PLYVideoMixerViewController.h"

#import "PLYCommentViewController.h"
#import "PLYProfileViewController.h"

#import "PLYAppDelegate.h"

#import "PlayoffItem.h"
#import "PlayoffThread.h"
#import "User.h"

#import "PLYUtilities.h"
#import "PLYTheme.h"

#define CELL_DIM 310
#define MAIN_PAD 5
#define PROFILE_IMAGE_DIM 30
#define ICON_DIM 20
#define MAIN_BTN_HEIGHT 30
#define ALL_COMMENTS_BTN_HEIGHT 20
#define PROGRESS_HEIGHT 40
#define PROGRESS_WIDTH 220
#define PROGRESS_INNER_PAD 5
#define SCRUBBER_DIM 30
#define PLAY_BUTTON_DIM 120

#define PROFILE_IMAGE_TAG 3
#define USER_IMAGE_TAG 15
#define USER_IMAGE_BTN_TAG 21
#define USERNAME_TAG 4
#define TIME_TAG 5
#define LINE_TAG 8
#define LIKES_ICON_TAG 16
#define LIKES_TAG 17
#define COMMENTS_TAG 9
#define COMMENTS_ICON_TAG 10
#define ALL_COMMENTS_BTN_TAG 11
#define LIKE_BTN_TAG 12
#define COMMENT_BTN_TAG 13
#define PLAYOFF_BTN_TAG 18
#define MORE_BTN_TAG 14
#define PLACEHOLDER_IMAGE_TAG 19
#define VIEW_PROFILE_BTN_TAG 20
#define SCRUBBER_BACKGROUND_TAG 21

static const NSString *ItemStatusContext;

@implementation PLYExpandedViewCell

@synthesize config = _config;
@synthesize navigationController = _navigationController;
@synthesize progressBack = _progressBack;
@synthesize progressBar = _progressBar;
@synthesize scrubber = _scrubber;

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    self.player = nil;
    self.playerItem = nil;
    self.playerView = nil;
    self.cancelDownload = ^{};
    
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *label;
        UIImageView *imageView;
        UIImage *image;
        UIView *simpleView;
        UIControl *simpleControl;
        UIControl *innerView;
        UIButton *btn;
        CGRect rect;
        
        [self.contentView setBackgroundColor:[UIColor whiteColor]];
        
        // user icon
        imageView = [[UIImageView alloc] init];
        [imageView setBackgroundColor:[UIColor lightGrayColor]];
        [imageView setFrame: CGRectMake(MAIN_PAD, MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD, PROFILE_IMAGE_DIM, PROFILE_IMAGE_DIM)];
        [imageView setTag:USER_IMAGE_TAG];
        [self.contentView addSubview:imageView];
        
        // user icon btn
        btn = [[UIButton alloc] init];
        [btn setFrame: CGRectMake(MAIN_PAD, MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD, PROFILE_IMAGE_DIM, PROFILE_IMAGE_DIM)];
        [btn setTag:USER_IMAGE_BTN_TAG];
        [btn addTarget:self action:@selector(viewUserProfile) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:btn];
        
        // username
        btn = [[UIButton alloc] init];
        [btn setFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD, MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD, 200, PROFILE_IMAGE_DIM)];
        [btn setBackgroundColor:[UIColor clearColor]];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [btn.titleLabel setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:14]];
        [btn setTitleColor:[PLYTheme primaryColor] forState:UIControlStateNormal];
        [btn setTag:USERNAME_TAG];
        [btn addTarget:self action:@selector(viewUserProfile) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:btn];
        
        // upload time
        label = [[UILabel alloc] init];
        [label setFrame:CGRectMake(320 - (100 + MAIN_PAD), MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD, 100, PROFILE_IMAGE_DIM)];
        [label setTextAlignment:NSTextAlignmentRight];
        [label setTextColor:[PLYTheme backgroundDarkColor]];
        [self.contentView addSubview:label];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTag:TIME_TAG];
        
        // preview video image
        CGRect mainRect = CGRectMake(MAIN_PAD, MAIN_PAD, CELL_DIM, CELL_DIM);
        imageView = [[UIImageView alloc] initWithFrame:mainRect];
        [imageView setTag:PLACEHOLDER_IMAGE_TAG];
        [self.contentView addSubview:imageView];

        // playback area
        PLYPlaybackView *playbackView = [[PLYPlaybackView alloc] initWithFrame:mainRect];
        [self.contentView addSubview: playbackView];
        self.playerView = playbackView;
        
        // pause but
        UIControl *pauseBut = [[UIControl alloc] initWithFrame:mainRect];
        [pauseBut setBackgroundColor:[UIColor clearColor]];
        [pauseBut addTarget:self action:@selector(tapPause) forControlEvents:UIControlEventTouchUpInside];
        [self.contentView addSubview:pauseBut];
        
        // play button
        btn = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD + ((CELL_DIM / 2) - (PLAY_BUTTON_DIM / 2)),
                                                         MAIN_PAD + ((CELL_DIM / 2) - (PLAY_BUTTON_DIM / 2)),
                                                         PLAY_BUTTON_DIM, PLAY_BUTTON_DIM)];
        [btn setBackgroundImage:[UIImage imageNamed:@"play-but-1"] forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor clearColor]];
        [btn addTarget:self action:@selector(tapPlay) forControlEvents:UIControlEventTouchUpInside];
        [btn setHidden:YES];
        [self.contentView addSubview:btn];
        self.playButton = btn;
        
        // loading progress
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake((320 / 2) - (PROGRESS_WIDTH / 2),
                                                              MAIN_PAD + ((CELL_DIM / 2) - (PROGRESS_HEIGHT / 2)),
                                                              PROGRESS_WIDTH, PROGRESS_HEIGHT)];
        image = [UIImage imageNamed:@"progress-surround-1"];
        image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(16, 16, 16, 16)];
        [imageView setImage:image];
        [imageView setHidden:YES];
        [self.contentView addSubview:imageView];
        self.progressBack = imageView;
        
        simpleView = [[UIView alloc] init];
        [simpleView setBackgroundColor:[UIColor whiteColor]];
        [simpleView setHidden:YES];
        [self.contentView addSubview:simpleView];
        simpleView.layer.cornerRadius = 1;
        self.progressBar = simpleView;
        
        // scrubber
        simpleControl = [[UIControl alloc]
                         initWithFrame:CGRectMake(MAIN_PAD, MAIN_PAD + CELL_DIM, CELL_DIM, SCRUBBER_DIM)];
        [simpleControl setBackgroundColor:[PLYTheme backgroundLightColor]];
        [simpleControl setTag:SCRUBBER_BACKGROUND_TAG];
        [self.contentView addSubview:simpleControl];
        
        innerView = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, SCRUBBER_DIM, SCRUBBER_DIM)];
        [innerView setBackgroundColor:[PLYTheme backgroundMediumColor]];
        [simpleControl addSubview:innerView];
        self.scrubber = innerView;
        
        // likes icon
        imageView = [[UIImageView alloc] init];
        [imageView setImage: [UIImage imageNamed:@"like-small-1"]];
        [imageView setFrame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM - ICON_DIM,
                                        MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD, ICON_DIM, ICON_DIM)];
        [imageView setTag:LIKES_ICON_TAG];
        [self.contentView addSubview:imageView];
        
        // likes count
        label = [[UILabel alloc] init];
        [label setFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD,
                                   MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD,
                                   150, ICON_DIM)];
        [self.contentView addSubview:label];
        [label setTextColor:[PLYTheme backgroundDarkColor]];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTag:LIKES_TAG];
        
        // comments icon
        imageView = [[UIImageView alloc] init];
        [imageView setImage:[UIImage imageNamed:@"comment-small-1"]];
        [imageView setFrame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM - ICON_DIM,
                                        MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD + ICON_DIM + MAIN_PAD,
                                        ICON_DIM, ICON_DIM)];
        [imageView setTag:COMMENTS_ICON_TAG];
        [imageView setHidden:YES];
        [self.contentView addSubview:imageView];
        
        // comments
        label = [[UILabel alloc] init];
        [label setTag:COMMENTS_TAG];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [PLYTheme mediumDefaultFont];
        label.numberOfLines = 0;
        [self.contentView addSubview:label];
        
        // all comments btn
        btn = [[UIButton alloc] init];
        [btn setTitle: @"show all comments" forState: UIControlStateNormal];
        [btn addTarget:self action:@selector(showAllComments) forControlEvents:UIControlEventTouchUpInside];
        [btn setTag: ALL_COMMENTS_BTN_TAG];
        [btn.titleLabel setFont: [PLYTheme mediumDefaultFont]];
        [btn setTitleColor:[PLYTheme primaryColorDark] forState:UIControlStateHighlighted];
        [btn setBackgroundColor:[UIColor clearColor]];
        [btn setTitleColor:[PLYTheme primaryColor] forState:UIControlStateNormal];
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [self.contentView addSubview: btn];
        
        // like btn
        btn = [[UIButton alloc] init];
        [btn setTitle: @"like" forState: UIControlStateNormal];
        [btn addTarget:self action:@selector(likePlayoffItem) forControlEvents:UIControlEventTouchUpInside];
        [btn setTag: LIKE_BTN_TAG];
        [btn.titleLabel setFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:15]];
        [PLYTheme setStandardButton:btn];
        [self.contentView addSubview: btn];
        
        // comment btn
        btn = [[UIButton alloc] init];
        [btn setTitle: @"comment" forState: UIControlStateNormal];
        [btn addTarget:self action:@selector(commentEvent) forControlEvents:UIControlEventTouchUpInside];
        [btn setTag: COMMENT_BTN_TAG];
        [btn.titleLabel setFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:15]];
        [PLYTheme setStandardButton:btn];
        [self.contentView addSubview: btn];
        
        // playoff btn
        btn = [[UIButton alloc] init];
        [btn setTitle: @"playoff!" forState: UIControlStateNormal];
        [btn addTarget:self action:@selector(playoffEvent) forControlEvents:UIControlEventTouchUpInside];
        [btn setTag: PLAYOFF_BTN_TAG];
        [btn.titleLabel setFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:15]];
//        [btn setBackgroundColor:[PLYTheme primaryColor]];
        [PLYTheme setStandardButton:btn];
        [self.contentView addSubview: btn];
        
        // more
        btn = [[UIButton alloc] init];
        [btn setTitle: @"..." forState: UIControlStateNormal];
        [btn addTarget:self action:@selector(moreBtnEvent) forControlEvents:UIControlEventTouchUpInside];
        [btn setTag: MORE_BTN_TAG];
        [btn.titleLabel setFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:15]];
//        [btn setBackgroundColor:[PLYTheme primaryColor]];
        [PLYTheme setGrayButton:btn];
        [self.contentView addSubview: btn];
        
        /* elements:
         *
         * - placeholder image of video
         * - download progress
         * 
         */
    }
    
    return self;
}

-(void)tapPause
{
    self.updatedScrubber = NO;
    [self.playButton setHidden:NO];
    if (self.haveVideo) {
        [self.player pause];
    }
}

-(void)tapPlay
{
    [self play];
}

-(void)showAllComments {
    UIViewController *commentVC = [[PLYCommentViewController alloc] initWithPlayoffId:self.config[@"id"] withKeyboard:NO];
    commentVC.hidesBottomBarWhenPushed = YES;
    [self dehighlight];
    [self.navigationController pushViewController:commentVC animated:YES];
}

-(void)likePlayoffItem {
    NSString *playoffId = (NSString *)self.config[@"id"];
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [appDelegate likePlayoff:playoffId completeCallback:^(BOOL success, BOOL alreadyLiked, int likesCount, NSError *err) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        if (alreadyLiked) {
            UIButton *btn = (UIButton *)[self.contentView viewWithTag:LIKE_BTN_TAG];
            [btn setEnabled:NO];
        } else if (success) {
            UILabel *label = (UILabel *)[self.contentView viewWithTag:LIKES_TAG];
            [label setText: [[NSString alloc] initWithFormat: @"%d", likesCount, nil]];

            NSMutableDictionary *conf = (NSMutableDictionary *)self.config;
            [conf setValue:[NSNumber numberWithInt:likesCount] forKey:@"likes"];
                            
            // switch to like/unlike
            // cache likes on client
        } else {
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Problem liking"
                                      message:nil
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        }
    }];
    
}

-(void)viewUserProfile
{
    PLYProfileViewController *profile = [[PLYProfileViewController alloc] initWithUsername:self.config[@"user"]];
    [self dehighlight];
    [self.navigationController pushViewController:profile animated:YES];
}

-(void)unlikePlayoffItem
{
    
}

-(void)commentEvent {
    UIViewController *commentVC = [[PLYCommentViewController alloc] initWithPlayoffId:self.config[@"id"] withKeyboard:YES];
    commentVC.hidesBottomBarWhenPushed = YES;
    [self dehighlight];
    [self.navigationController pushViewController:commentVC animated:YES];
}

-(void)playoffEvent {
    // mixer push
    PLYVideoMixerViewController *mixer = [[PLYVideoMixerViewController alloc]
                                          initWithPlayoffThreadId:self.config[@"thread_id"]
                                          playoffItemId:self.config[@"id"]
                                          previewImage:self.config[@"preview_image_1"]];
    
    mixer.hidesBottomBarWhenPushed = YES;
    [self dehighlight];
    [self.navigationController pushViewController:mixer animated:YES];
}

-(void)moreBtnEvent {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:@"Flag as inappropriate", @"share via email", nil];
    
    [actionSheet showFromRect:CGRectMake(0, 0, 320, 0) inView:self.superview.superview animated:YES];
    
    [PLYTheme setActionSheetStyle:actionSheet warnButIdxs:@[@0, @1]];
}

-(void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        NSString *playoffId = (NSString *)self.config[@"id"];
        PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
        [appDelegate flagPlayoff:playoffId];
    } else if (buttonIndex == 1) {
        NSString *shareURL = [PLYUtilities getPlayoffShareURL:self.config[@"id"]];

        MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
//        controller.mailComposeDelegate = self;
        [controller setDelegate:self];
        [controller setMailComposeDelegate:self];
        [controller setSubject:@"Playoff!"];
        [controller setMessageBody:[[NSString alloc]
                                    initWithFormat:@"Check out this Playoff video mashup!\n\n %@", shareURL, nil] isHTML:NO];
        if (controller) [self.navigationController presentModalViewController:controller animated:YES];
    }
}

-(void) mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
    if ([MFMailComposeViewController canSendMail] && result == MFMailComposeResultSent) {}
    [controller dismissViewControllerAnimated:YES completion:^(void) {}];
}

-(void)configureCell:(NSDictionary *)config
{
    self.config = config;
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    NSArray *comments = config[@"summary_comments"];
    BOOL isVideo = (BOOL)config[@"has_video"];
    CGFloat topOffset = (MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD + ICON_DIM + MAIN_PAD + MAIN_PAD);
    UILabel *label;
    UIImageView *imageView;
    UIView *rectView;
    UIButton *btn;
    CGRect rect;
    
    // placeholder
    imageView = (UIImageView *)[self.contentView viewWithTag:PLACEHOLDER_IMAGE_TAG];
    [imageView setImageWithURL:[NSURL URLWithString:config[@"preview_image_1"]]
                 placeholderImage:[UIImage imageNamed:@"placeholder-vid-1"]
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                            
                        }];
    
    // user image
    imageView = (UIImageView *)[self.contentView viewWithTag:USER_IMAGE_TAG];
    [appDelegate setProfileImage:config[@"user"] imageView:imageView withBlock:^(BOOL success) {}];

    // username
    btn = (UIButton *)[self.contentView viewWithTag:USERNAME_TAG];
    [btn setTitle:[PLYUtilities usernameFromOwner: config[@"user"]] forState:UIControlStateNormal];
    
    // timestamp
    label = (UILabel *)[self.contentView viewWithTag:TIME_TAG];
    [label setText:[PLYUtilities millisToPrettyTime:[(NSNumber *)config[@"createddate"] doubleValue]]];
    
    // likes count
    label = (UILabel *)[self.contentView viewWithTag:LIKES_TAG];
    [label setText: [[NSString alloc] initWithFormat: @"%@", config[@"likes"], nil]];
    
    if ([comments count] > 0) {
        rectView = (UIView *)[self.contentView viewWithTag:COMMENTS_ICON_TAG];
        [rectView setHidden:NO];
        
        label = (UILabel *)[self.contentView viewWithTag:COMMENTS_TAG];
        [PLYUtilities setupCommentsLabel: label
                                comments: comments
                                   frame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD,
                                                     MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + CELL_DIM + SCRUBBER_DIM + MAIN_PAD + ICON_DIM + MAIN_PAD,
                                                         320 - (MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + MAIN_PAD), 0)];
        
        topOffset += label.frame.size.height > ICON_DIM ? label.frame.size.height : ICON_DIM;
    }
    
    // all comments btn
    btn = (UIButton *)[self.contentView viewWithTag:ALL_COMMENTS_BTN_TAG];
    [btn setFrame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD, topOffset, 140, ALL_COMMENTS_BTN_HEIGHT)];
    
    // like btn
    btn = (UIButton *)[self.contentView viewWithTag:LIKE_BTN_TAG];
    [btn setFrame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD,
                              topOffset + ALL_COMMENTS_BTN_HEIGHT + MAIN_PAD,
                              45, MAIN_BTN_HEIGHT)];
    
    
    if ([appDelegate alreadyLikedPlayoff:config[@"id"]])
        [btn setEnabled: NO];
    
    // comment btn
    btn = (UIButton *)[self.contentView viewWithTag:COMMENT_BTN_TAG];
    [btn setFrame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + 45 + MAIN_PAD,
                              topOffset + ALL_COMMENTS_BTN_HEIGHT + MAIN_PAD,
                              80, MAIN_BTN_HEIGHT)];
    
    // playoff btn
    btn = (UIButton *)[self.contentView viewWithTag:PLAYOFF_BTN_TAG];
    [btn setFrame: CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD + 45 + MAIN_PAD + 80 + MAIN_PAD,
                              topOffset + ALL_COMMENTS_BTN_HEIGHT + MAIN_PAD,
                              80, MAIN_BTN_HEIGHT)];
    
    // more
    btn = (UIButton *)[self.contentView viewWithTag:MORE_BTN_TAG];
    [btn setFrame: CGRectMake(320 - (MAIN_PAD + 40),
                              topOffset + ALL_COMMENTS_BTN_HEIGHT + MAIN_PAD,
                              40, MAIN_BTN_HEIGHT)];
    
    
    rect = CGRectMake(0, 0, 320, topOffset +
                        MAIN_PAD + ALL_COMMENTS_BTN_HEIGHT +
                        MAIN_PAD + MAIN_BTN_HEIGHT + MAIN_PAD
                            );

    
    [self setFrame:rect];
}

- (void)syncUI {
    if ((self.player.currentItem != nil) && ([self.player.currentItem status] == AVPlayerItemStatusReadyToPlay)) {
//        self.playButton.enabled = YES;
        [self play];
    } else {
//        self.playButton.enabled = NO;
    }
}

- (void) tapPosition:(id) sender withEvent:(UIEvent *) event
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        self.updatedScrubber = YES;
        [self pauseAndShowPlay];
        
        UIControl *control = ((UIControl *)sender);
        UITouch *t = [[event allTouches] anyObject];
        CGFloat xPos = [t locationInView:control].x;
        
        xPos -= SCRUBBER_DIM;
        if (xPos < SCRUBBER_DIM) xPos += SCRUBBER_DIM;
        
        [self.scrubber setFrame:CGRectMake(xPos, 0, SCRUBBER_DIM, SCRUBBER_DIM)];
        
        [self findNewPositionFromScrubber];
    });
}

-(void)pauseAndShowPlay
{
    [self.player pause];
    [self.playButton setHidden:NO];
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
        if (xPos > CELL_DIM - SCRUBBER_DIM) xPos = CELL_DIM - SCRUBBER_DIM;
        [control setFrame:CGRectMake(xPos, 0, SCRUBBER_DIM, SCRUBBER_DIM)];
        
        [self findNewPositionFromScrubber];
    });
}

-(void)findNewPositionFromScrubber
{
    float prop = self.scrubber.frame.origin.x / (CELL_DIM - SCRUBBER_DIM);
    CMTime newPosition = CMTimeMakeWithSeconds(prop * CMTimeGetSeconds(self.playerItem.duration), 1000);
    [self.player seekToTime:newPosition];
}

-(void)highlight;
{
    if (self.player) {
        [self.playButton setHidden:YES];
        [self play];
    }
}

-(void)dehighlight
{
    [self setBackgroundColor:[UIColor clearColor]];
    
    if (self.player) {
        [self.playButton setHidden:NO];
        [self.player pause];
    }
    
    if (self.cancelDownload) {
        [self hideProgress];
        self.cancelDownload();
    }
    
    [self dettachScrubberTimer];
}

-(void)dealloc
{
    if (self.playerItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:AVPlayerItemDidPlayToEndTimeNotification
                                                      object:self.playerItem];
    }
}

- (void)loadVideo
{
    if (self.startedLoadingVideo || self.haveVideo) return;
    self.startedLoadingVideo = YES;
    
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    
    if (self.config[@"video_url"] == [NSNull null]) {
        return;
    }
    
    [appDelegate downloadVideoPlayoff:self.config[@"id"] videoURL:self.config[@"video_url"] progressDelegate:self
     callback:^(BOOL success, NSString *videoPath, NSError *err, NSString *vidURL){
         [self hideProgress];
         self.startedLoadingVideo = NO;
         if (success) {
             self.haveVideo = YES;
             self.cancelDownload = ^{};
             
             NSURL *fileURL =[NSURL fileURLWithPath:videoPath];
             AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
             NSString *tracksKey = @"tracks";
             
             [asset loadValuesAsynchronouslyForKeys:@[tracksKey] completionHandler: ^{
                  dispatch_async(dispatch_get_main_queue(), ^{
                     NSError *error;
                     AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
                     
                     if (status == AVKeyValueStatusLoaded) {
                         
                         if (self.playerItem && self.haveStatusObserver) {
                             [self.playerItem removeObserver:self forKeyPath:@"status"];
                             self.haveStatusObserver = YES;
                             
                             [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                             name:AVPlayerItemDidPlayToEndTimeNotification
                                                                           object:self.playerItem];
                         }
                         
                         
                         self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
                         [self reattachScrubberTimer];
                         
                         [[NSNotificationCenter defaultCenter] addObserver:self
                                                                  selector:@selector(playerItemDidReachEnd:)
                                                                      name:AVPlayerItemDidPlayToEndTimeNotification
                                                                    object:self.playerItem];
                         
                         if (!self.player) {
                             self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
                         }
                         
                         [self.playerView setPlayer:self.player];
                         
                         [(UIControl *)self.scrubber.superview addTarget:self action:@selector(tapPosition:withEvent:) forControlEvents:UIControlEventTouchDown];
                         [self.scrubber addTarget:self action:@selector(slideAlong:withEvent:) forControlEvents:UIControlEventTouchDragInside];
                     }
                     else {
                         // You should deal with the error appropriately.
                         NSLog(@"The asset's tracks were not loaded:\n%@", [error localizedDescription]);
                     }
                 });
              }];
         }
     } getCancelCallback: ^(EMPTY_CALLBACK cd) {
         self.cancelDownload = cd;
     }];

}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == &ItemStatusContext) {
        [self initScrubberTimer];
        dispatch_async(dispatch_get_main_queue(),
                       ^{
                           [self syncUI];
                       });
        return;
    }

    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

-(void)reattachScrubberTimer
{
    if (self.playerItem != nil && !self.haveStatusObserver) {
        [self.playerItem addObserver:self forKeyPath:@"status" options:0 context:&ItemStatusContext];
        self.haveStatusObserver = YES;
    }
}

-(void)dettachScrubberTimer
{
    if (self.playerItem != nil && self.haveStatusObserver) {
        [self.playerItem removeObserver:self forKeyPath:@"status"];
        self.haveStatusObserver = NO;
    }
    
    if (self.player != nil && self.timeObserver != nil) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
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
    
	/* Update the scrubber during normal playback. */
	self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC)
                                                                queue:NULL /* If you pass NULL, the main queue is used. */
                                                           usingBlock:^(CMTime time)
                      {
                          if (!self.updatedScrubber) [self syncScrubber];
                      }];
    
}

- (void)syncScrubber
{
	CMTime playerDuration = self.playerItem.duration;
	if (CMTIME_IS_INVALID(playerDuration))
	{
		[self.scrubber setFrame:CGRectMake(0, 0, SCRUBBER_DIM, SCRUBBER_DIM)];
		return;
	}
    
	double duration = CMTimeGetSeconds(playerDuration);
	if (isfinite(duration))
	{
		double time = CMTimeGetSeconds([self.player currentTime]);
        double prop = time / CMTimeGetSeconds(playerDuration);
        if (prop < 0.0) prop = 0.0;
        if (prop > 1.0) prop = 1.0;
        
		[self.scrubber setFrame:CGRectMake((CELL_DIM - SCRUBBER_DIM) * prop, 0, SCRUBBER_DIM, SCRUBBER_DIM)];
	}
}

- (void)play
{
    self.updatedScrubber = NO;
    [self.playButton setHidden:YES];
    if (!self.haveVideo) {
        [self loadVideo];
    } else {
        [self.player play];
    }
}

-(void)setProgress:(float)newProgress
{
    [self.progressBack setHidden:NO];
    [self.progressBar setHidden:NO];
    
    CGRect mainRect = self.progressBack.frame;
    
    [self.progressBar setFrame:CGRectMake(mainRect.origin.x + PROGRESS_INNER_PAD,
                                          mainRect.origin.y + PROGRESS_INNER_PAD,
                                          (mainRect.size.width - PROGRESS_INNER_PAD - PROGRESS_INNER_PAD) * newProgress,
                                          mainRect.size.height - PROGRESS_INNER_PAD - PROGRESS_INNER_PAD)];


}

-(void)hideProgress
{
    [self.progressBar setHidden:YES];
    [self.progressBack setHidden:YES];
}

- (void)playerItemDidReachEnd:(NSNotification *)notification {
    [self.player seekToTime:kCMTimeZero];
    [self.playButton setHidden:NO];
}

@end
