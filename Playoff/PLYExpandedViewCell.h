//
//  PLYExpandedViewCell.h
//  Playoff
//
//  Created by Arie Lakeman on 04/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>
#import <QuartzCore/QuartzCore.h>
#import <ASIHTTPRequest.h>

#import <MessageUI/MessageUI.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "PLYPlaybackView.h"

typedef void(^EMPTY_CALLBACK)(void);

@interface PLYExpandedViewCell : UITableViewCell <UIActionSheetDelegate, ASIProgressDelegate, MFMailComposeViewControllerDelegate>

@property (readwrite, copy) EMPTY_CALLBACK cancelDownload;
@property (nonatomic) AVPlayer *player;
@property (nonatomic) AVPlayerItem *playerItem;
@property (nonatomic, weak) PLYPlaybackView *playerView;
@property (nonatomic) NSDictionary *config;
@property UIView *progressBack;
@property UIView *progressBar;
@property UIControl *scrubber;
@property UIButton *playButton;
@property (atomic) BOOL startedLoadingVideo;
@property (atomic) BOOL haveVideo;
@property (atomic) BOOL updatedScrubber;
@property (atomic) BOOL haveStatusObserver;
@property id timeObserver;

@property (weak) UINavigationController *navigationController;

-(void)configureCell:(NSDictionary *)config;

- (void)loadVideo;
- (void)play;
- (void)syncUI;

-(void)dehighlight;
-(void)highlight;

@end
