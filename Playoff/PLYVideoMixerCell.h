//
//  PLYVideoMixerCell.h
//  Playoff
//
//  Created by Arie Lakeman on 06/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <ASIHTTPRequest.h>


extern NSString* const deletePlyMixerCell;

@interface PLYVideoMixerCell : UITableViewCell<ASIProgressDelegate>

@property BOOL inProgressDownload;

@property (weak) UIViewController *mixerViewController;

@property NSMutableDictionary *currentConfig;
@property CMTime outerStart;
@property CMTimeRange innerTimeRange;
@property CMTime innerDuration;
@property CMTime outerDuration;
@property float soundVolume;
@property NSString *videoTrackId;
@property NSString *retryDownloadURL;

@property UIView *coverLayer;
@property UIActivityIndicatorView *coverSpinner;
@property UIView *progressBarBack;
@property UIView *progressBar;
@property UIButton *loadingMessage;
@property UIControl *mainTrackView;

@property float cachedTrackX;
@property float resizeLeftDelta;
@property float cachedTrackWidth;
@property float resizeRightDelta;

/* resizing properties */
@property float lastXpx;
@property float currentXpx;
@property float minXpx;
@property float maxXpx;
@property CMTime minXtime;
@property CMTime maxXtime;

- (id) initAsInProgressDownload;

+ (CGFloat)cellHeight;
- (void) configureCell:(NSDictionary *)config withContext:(NSDictionary *)context mixerVC: (UIViewController *) mixer;
- (void) deserialiseDirect: (NSDictionary *)config withMixerViewController: (UIViewController *)mixerVC;
- (void) setDragImage;

- (void) imageMoved:(id) sender withEvent:(UIEvent *) event;
- (void) resizeLeft:(id) sender withEvent:(UIEvent *) event;
- (void) resizeRight:(id) sender withEvent:(UIEvent *) event;

- (void) addLocalVideo: (NSURL *) videoURL;
- (void) setSpinnerActive;
- (void) setLoadingMessage;
- (void) setErrorMessageWithRetryURL: (NSString *)url;
- (void) stopLoaders;

- (NSDictionary *)serialiseCellConfig;

@end
