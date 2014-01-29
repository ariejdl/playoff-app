//
//  PLYVideoMixerViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 06/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "PLYVideoWebBrowserViewController.h"

#import "PLYVideoMixerCell.h"

#import "PLYPlaybackView.h"
#import "PLYVideoComposer.h"
#import "PLYVideoComposer.h"

@interface PLYVideoMixerViewController : UITableViewController<UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate, UIImagePickerControllerDelegate>

@property NSString *playoffThreadId;
@property NSString *playoffItemId;
@property NSString *previewImage;

@property (nonatomic) AVPlayer *player;
@property AVPlayerLayer *playerLayer;
@property (nonatomic, weak) AVPlayerItem *playerItem;
@property (nonatomic, weak) PLYPlaybackView *playerView;

@property PLYVideoMixerCell *currentlyInterestedCell;

@property double currentTime;
@property (readonly) double duration;

@property AVMutableComposition *composition;
@property AVMutableVideoComposition *videoComposition;
@property AVMutableAudioMix *audioMix;

@property NSMutableArray *currentRawTracks;
@property NSMutableArray *currentProcessedTracks;
@property NSMutableArray *tracksToTickOff;
@property NSMutableArray *currentTableViewCells;

@property BOOL existingPlayoffToInitialise;
@property (atomic) BOOL tracksChanged;
@property BOOL currentlyDownloading;
@property CMTime fullDuration;

@property UIView *mainLoader;
@property UIImageView *videoPreviewImage;

// main buts
@property UIButton *addClipBtn;
@property UIButton *setDurBtn;
@property UIButton *videoMaskControl;
@property UIControl *pauseButton;

// scrubber stuff
@property id timeObserver;
@property (atomic) BOOL updatedScrubber;
@property UIControl *scrubber;

-(id)initWithPlayoffThreadId: (NSString *)threadId playoffItemId: (NSString *) playoffItemId previewImage: (NSString *) previewImage;

-(void)setRawTracks:(NSArray *)tracks;

- (void) addAction:(UIButton *) sender;
- (void) editAction:(UIButton *) sender;
- (void)insertNewCell:(NSDictionary *)info;

-(void)tapDeleteCell:(PLYVideoMixerCell *) cell;

- (void) addThirdPartyVideoDownloadTrack: (NSString *) url withPath: (NSString *) extension;

- (void) showActionSheetForCell: (UITableViewCell *) cell;

- (void) addFreshCapture: (NSURL *)url;
-(void)retryDownload:(PLYVideoMixerCell *) cell withURL: (NSString *) url;

-(PLYVideoComposer *)refreshVideoWithCompletionNotification: (NSString *)notificationName;

@end
