//
//  PLYVideoMixerCell.m
//  Playoff
//
//  Created by Arie Lakeman on 06/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYVideoMixerCell.h"
#import "PLYVideoMixerViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <QuartzCore/QuartzCore.h>
#import "PLYUtilities.h"
#import "PLYTheme.h"
#import "PLYVideoMixerViewController.h"

#define CELL_HEIGHT 70
#define HALF_CELL_HEIGHT 35
#define PROGRESS_AREA_HEIGHT 50
#define PROGRESS_AREA_WIDTH 300

#define RESIZER_WIDTH 24
#define RESIZER_HEIGHT (CELL_HEIGHT)
#define MIN_CLIP_WIDTH 30

#define TRACK_PX_WIDTH 320
#define TRACK_MARGIN_PX (RESIZER_WIDTH / 2)

#define MAIN_TRACK_TAG 1
#define TRACK_IMAGES_AREA_TAG 2
#define TRACK_LEFT_RESIZE_TAG 3
#define TRACK_RIGHT_RESIZE_TAG 4

#define INVALID_PX_VALUE -10000

/*
 * TODO: use of UIViewControl and UIView naming in configure/init, use NSValue initWithCMTime instead of dicts
 */

extern NSString* const deletePlyMixerCell = @"deletePlyMixerCell";

@implementation PLYVideoMixerCell

@synthesize soundVolume = _soundVolume;
@synthesize coverLayer = _coverLayer;
@synthesize coverSpinner = _coverSpinner;
@synthesize progressBarBack = _progressBarBack;
@synthesize progressBar = _progressBar;

@synthesize currentXpx = _currentXpx;
@synthesize minXpx = _minXpx;
@synthesize maxXpx = _maxXpx;
@synthesize minXtime = _minXtime;
@synthesize maxXtime = _maxXtime;

+(CGFloat)cellHeight
{
    return CELL_HEIGHT;
}


// TODO: check for bugs arising from setting edges to center not to extremities of clip itself
// TODO: implement min and max, calculate proposed width, or x offset -- too close to right or left

- (id) initAsInProgressDownload
{
    self = [self init];
    self.inProgressDownload = YES;
    return self;
}

-(void)resetResizeValues
{
    self.lastXpx = INVALID_PX_VALUE;
    self.currentXpx = INVALID_PX_VALUE;
    self.minXpx = INVALID_PX_VALUE;
    self.maxXpx = INVALID_PX_VALUE;
    self.minXtime = kCMTimeInvalid;
    self.maxXtime = kCMTimeInvalid;
}

-(id)init
{
    self = [super init];
    if (self) {
        [self resetResizeValues];
        
        /* other stuff */
        self.videoTrackId = nil;
        self.soundVolume = 1.0;
        self.inProgressDownload = nil;
        
        self.cachedTrackX = -1;
        self.cachedTrackWidth = -1;
        self.resizeLeftDelta = 0.0;
        self.resizeRightDelta = 0.0;
        
        UIButton *btn;
        UIView *rectView;
        UIControl *rectControl;
        UIControl *rectControlSub;
        UIView *rectSubview;
        UILabel *labelView;
        UIControl *cellBack;
        
        cellBack = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 320, CELL_HEIGHT)];
        [cellBack addTarget:self action:@selector(slideAlong:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [self.contentView addSubview:cellBack];
        
        // the main box that contains thumbnails and resizers
        rectControl = [[UIControl alloc] init];
        rectControl.tag = MAIN_TRACK_TAG;
        [cellBack addSubview:rectControl];
        self.mainTrackView = rectControl;
        
        // the thumbnails inside the box
        rectControlSub = [[UIControl alloc] init];
        rectControlSub.tag = TRACK_IMAGES_AREA_TAG;
        [rectControlSub setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.2]];
        rectControlSub.clipsToBounds = YES;
        [self.mainTrackView addSubview:rectControlSub];
        [rectControlSub addTarget:self action:@selector(slideAlong:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        
        // TODO: add tap and hold (long tap) -> UIActionSheet -> set transparency -> set volume
        //        self.mixerViewController
        UILongPressGestureRecognizer *longpressGesture =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressHandler:)];
        longpressGesture.minimumPressDuration = 1.2;
        [longpressGesture setDelegate:self];
        [rectControlSub addGestureRecognizer:longpressGesture];
//        longpressGesture.cancelsTouchesInView = NO;
        
        // left resizer
        btn = [[UIButton alloc] init];
        btn.tag = TRACK_LEFT_RESIZE_TAG;
        [btn setBackgroundImage:[UIImage imageNamed:@"resize-left-1"] forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor clearColor]];
        [rectControl addSubview:btn];
        [btn addTarget:self action:@selector(resizeLeft:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [btn addTarget:self action:@selector(finishResizeLeft) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(finishResizeLeft) forControlEvents:UIControlEventTouchUpOutside];
        
        // right resizer
        btn = [[UIButton alloc] init];
        btn.tag = TRACK_RIGHT_RESIZE_TAG;
        [btn setBackgroundImage:[UIImage imageNamed:@"resize-right-1"] forState:UIControlStateNormal];
        [btn setBackgroundColor:[UIColor clearColor]];
        [rectControl addSubview:btn];
        [btn addTarget:self action:@selector(resizeRight:withEvent:) forControlEvents:UIControlEventTouchDragInside];
        [btn addTarget:self action:@selector(finishResizeRight) forControlEvents:UIControlEventTouchUpInside];
        [btn addTarget:self action:@selector(finishResizeRight) forControlEvents:UIControlEventTouchUpOutside];
        
        // cover layer
        rectView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, CELL_HEIGHT)];
        [rectView setHidden:YES];
        [rectView setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.2]];
        [self.contentView addSubview:rectView];
        self.coverLayer = rectView;
        
        // progress back
        rectSubview = [[UIView alloc] initWithFrame:CGRectMake((320 / 2) - (PROGRESS_AREA_WIDTH / 2),
                                                               (CELL_HEIGHT / 2) - (PROGRESS_AREA_HEIGHT / 2),
                                                               PROGRESS_AREA_WIDTH, PROGRESS_AREA_HEIGHT)];
        [rectSubview setHidden:YES];
        [rectSubview setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.8]];
        rectSubview.layer.cornerRadius = 2;
        self.progressBarBack = rectSubview;
        [rectView addSubview:rectSubview];
        
        // progress front
        rectSubview = [[UIView alloc] initWithFrame:CGRectMake((320 / 2) - (PROGRESS_AREA_WIDTH / 2),
                                                               (CELL_HEIGHT / 2) - (PROGRESS_AREA_HEIGHT / 2),
                                                               0, PROGRESS_AREA_HEIGHT)];
        [rectSubview setBackgroundColor:[UIColor colorWithRed:1 green:1 blue:0 alpha:1]];
        [rectSubview setHidden:YES];
        self.progressBar = rectSubview;
        [rectView addSubview:rectSubview];
        
        // spinner
        UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc]
                                            initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        spinner.frame = CGRectMake((320 / 2) - (36 / 2), (CELL_HEIGHT / 2) - (36 / 2), 37, 37);
        [spinner setHidden:YES];
        self.coverSpinner = spinner;
        [rectView addSubview:spinner];
        
        // loading message
        btn = [[UIButton alloc] initWithFrame:CGRectMake((320 / 2) - (PROGRESS_AREA_WIDTH / 2),
                                                               (CELL_HEIGHT / 2) - (PROGRESS_AREA_HEIGHT / 2),
                                                               PROGRESS_AREA_WIDTH, PROGRESS_AREA_HEIGHT)];
        
        [btn setHidden:YES];
        [btn setBackgroundColor:[UIColor clearColor]];
        [btn.titleLabel setTextAlignment:NSTextAlignmentCenter];
        [btn setTitle: @"Queued to download" forState:UIControlStateNormal];
        [btn setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:18]];
        [btn.titleLabel setTextColor:[UIColor whiteColor]];
        self.loadingMessage = btn;
        [btn addTarget:self action:@selector(retryDownload:) forControlEvents:UIControlEventTouchUpInside];
        [rectView addSubview:btn];
        
        // delete btn
        UIImageView *delImg = [[UIImageView alloc] initWithFrame:CGRectMake((30 / 2) - (24 / 2), (CELL_HEIGHT / 2) - (24 / 2), 24, 24)];
        [delImg setImage:[UIImage imageNamed: @"rem-but-1"]];
        rectControl = [[UIControl alloc] initWithFrame:CGRectMake(0, 0, 30, CELL_HEIGHT)];
        [rectControl addSubview:delImg];
        [rectControl setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.3]];
        [self.contentView addSubview:rectControl];
        [rectControl addTarget:self action:@selector(deleteCell) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return self;
}

-(void)retryDownload: (id) sender
{
    if (self.mixerViewController && [((UIButton *)sender).titleLabel.text isEqualToString:@"Retry Download"] && self.retryDownloadURL) {
        [sender setHidden:YES];
        [(PLYVideoMixerViewController *)self.mixerViewController retryDownload:self withURL:self.retryDownloadURL];
    }
}

- (void)longPressHandler:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        if (self.mixerViewController) {
            [(PLYVideoMixerViewController *)self.mixerViewController showActionSheetForCell:self];
        }
    }
}

-(void)deleteCell
{
    [(PLYVideoMixerViewController *)self.mixerViewController tapDeleteCell: self];
}

- (void) slideAlong:(id) sender withEvent:(UIEvent *) event
{
    UIControl *control = self.mainTrackView;
    
    UITouch *t = [[event allTouches] anyObject];
    CGPoint pPrev = [t previousLocationInView:control];
    CGPoint p = [t locationInView:control];
    
    CGPoint center = control.center;
    center.x += p.x - pPrev.x;
    control.center = center;

    self.outerStart = [self outerPxToCMTime:control.frame.origin.x + TRACK_MARGIN_PX];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    
//    [self debugReport];
}

#pragma mark some time utilities

-(CMTime) outerPxToCMTime: (float) pxValue
{
    return CMTimeMake((pxValue / TRACK_PX_WIDTH) * CMTimeGetSeconds(self.outerDuration) * 600, 600);
}

-(float) CMTimeToOuterPx: (CMTime) timeValue
{
    return ((CMTimeGetSeconds(timeValue) / CMTimeGetSeconds(self.outerDuration)) * TRACK_PX_WIDTH);
}

# pragma mark resizing logic

-(void)finishResizeLeft
{
    CMTime newTime = kCMTimeInvalid;
    CMTime innerChange = kCMTimeInvalid;
    
    if (self.currentXpx < self.minXpx) {
        newTime = self.minXtime;
    } else if (self.currentXpx > self.maxXpx) {
        newTime = self.maxXtime;
    } else {
        newTime = [self outerPxToCMTime: self.currentXpx];
    }

    innerChange = CMTimeSubtract(newTime, self.outerStart);

    self.outerStart = newTime;
    /* should ensure that inner time range duration is less than innerDuration, due to loss of precision */
    CMTime innerDurationClamped = CMTimeClampToRange(CMTimeSubtract(self.innerTimeRange.duration, innerChange),
                                                     CMTimeRangeMake(kCMTimeZero, self.innerDuration));
    self.innerTimeRange = CMTimeRangeMake(CMTimeAdd(self.innerTimeRange.start, innerChange), innerDurationClamped);
    
    
    [self resetResizeValues];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    
//    [self debugReport];
}

-(void)resizeLeft:(id)sender withEvent:(UIEvent *)event
{
    UIControl *control = sender;
    UIView *mainTrack = (UIControl *)[self viewWithTag:MAIN_TRACK_TAG];
    CGRect rect = mainTrack.frame;

    UITouch *t = [[event allTouches] anyObject];
    CGPoint pPrev = [t previousLocationInView:control];
    CGPoint p = [t locationInView:control];
    CGFloat sizeDiff = p.x - pPrev.x;
    
    float newX = 0;
    float finalDiff = 0;

    if (CMTIME_IS_INVALID(self.minXtime) || CMTIME_IS_INVALID(self.maxXtime)) {
        self.lastXpx = rect.origin.x + TRACK_MARGIN_PX;
        self.currentXpx = rect.origin.x + TRACK_MARGIN_PX;
        
        /* external times */
        CMTime minXtime = CMTimeSubtract(self.outerStart, self.innerTimeRange.start);
        CMTime maxXtime = kCMTimeInvalid;
        float minXpx;
        float maxXpx;
        
        /* already cropped tracks */
        if (CMTimeCompare(self.innerTimeRange.start, kCMTimeZero) == 0)
            minXpx = self.currentXpx;
        else
            minXpx = [self CMTimeToOuterPx: CMTimeSubtract(self.outerStart, self.innerTimeRange.start)];
        
        maxXpx = rect.origin.x + rect.size.width - MIN_CLIP_WIDTH;
        
        /* e.g. if a very narrow clip */
        if (maxXpx <= minXpx) {
            maxXpx = minXpx;
            maxXtime = minXtime;
        } else {
            maxXtime = [self outerPxToCMTime:maxXpx];
        }

        self.minXpx = minXpx;
        self.maxXpx = maxXpx;
        self.minXtime = minXtime;
        self.maxXtime = maxXtime;
    }
    
    self.currentXpx += sizeDiff;
    
    // constrain - clamp
    // track margin here captures the fact that resizers are inset in the parent view
    newX = MAX(MIN(self.maxXpx, self.currentXpx), self.minXpx) - TRACK_MARGIN_PX;
    finalDiff = newX - rect.origin.x;
    rect = CGRectMake(newX, rect.origin.y, rect.size.width - finalDiff, rect.size.height);
    [mainTrack setFrame:rect];

    // touch up
    [self correctRightResizerAndThumbnails:finalDiff];
   
    self.lastXpx = self.currentXpx;
}

-(void) correctRightResizerAndThumbnails: (float) finalDiff
{
    UIView *mainTrack = (UIControl *)[self viewWithTag:MAIN_TRACK_TAG];
    UIView *container = (UIView *)[self viewWithTag:TRACK_IMAGES_AREA_TAG];
    UIButton *btn = (UIButton *)[self viewWithTag:TRACK_RIGHT_RESIZE_TAG];
    
    CGRect rect = mainTrack.frame;
    [container setFrame:CGRectMake(TRACK_MARGIN_PX, 0, rect.size.width - (TRACK_MARGIN_PX * 2), rect.size.height)];
    
    rect = CGRectMake(rect.size.width - RESIZER_WIDTH, 0, RESIZER_WIDTH, RESIZER_HEIGHT);
    [btn setFrame: rect];
    
    for (UIImageView *thumb in container.subviews) {
        [thumb setFrame:CGRectMake(thumb.frame.origin.x - finalDiff, thumb.frame.origin.y, thumb.frame.size.width, thumb.frame.size.height)];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
}

-(void)finishResizeRight
{
    CMTime innerDuration = kCMTimeInvalid;
    
    if (self.currentXpx < self.minXpx) {
        innerDuration = self.minXtime;
    } else if (self.currentXpx > self.maxXpx) {
        innerDuration = self.maxXtime;
    } else {
        innerDuration = [self outerPxToCMTime: self.currentXpx];
        innerDuration = CMTimeSubtract(innerDuration, self.outerStart);
    }
    
    /* should ensure that inner time range duration is less than innerDuration, from loss of precision */
    innerDuration = CMTimeClampToRange(innerDuration, CMTimeRangeMake(kCMTimeZero, self.innerDuration));
    self.innerTimeRange = CMTimeRangeMake(self.innerTimeRange.start, innerDuration);
    
    [self resetResizeValues];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:PLYChangeMixerTrackNotification object:nil];
    
//    [self debugReport];
}

/* bug -> resize left partially, resize right: wrong inner duration */
-(void)resizeRight:(id)sender withEvent:(UIEvent *)event
{
    UIControl *control = sender;
    UIView *mainTrack = (UIControl *)[self viewWithTag:MAIN_TRACK_TAG];
    CGRect rect = mainTrack.frame;
    
    UITouch *t = [[event allTouches] anyObject];
    CGPoint pPrev = [t previousLocationInView:control];
    CGPoint p = [t locationInView:control];
    CGFloat sizeDiff = p.x - pPrev.x;
    
    float newX = 0;
    
    if (CMTIME_IS_INVALID(self.minXtime) || CMTIME_IS_INVALID(self.maxXtime)) {
        self.lastXpx = rect.origin.x + rect.size.width - TRACK_MARGIN_PX;
        self.currentXpx = rect.origin.x + rect.size.width - TRACK_MARGIN_PX;
        
        /* internal times */
        CMTime minXtime = kCMTimeInvalid;
        CMTime maxXtime = CMTimeSubtract(self.innerDuration, self.innerTimeRange.start);
        float minXpx;
        float maxXpx;
        
        /* already cropped tracks */
        if (CMTimeCompare(CMTimeAdd(self.innerTimeRange.start, self.innerTimeRange.duration), self.innerDuration) == 0)
            maxXpx = self.currentXpx;
        else {
            maxXpx = [self CMTimeToOuterPx: CMTimeAdd(self.outerStart, CMTimeSubtract(self.innerDuration, self.innerTimeRange.start))];
        }
        
        minXpx = [self CMTimeToOuterPx: self.outerStart] + MIN_CLIP_WIDTH - TRACK_MARGIN_PX;
        
        /* e.g. if a very narrow clip */
        if (maxXpx <= minXpx) {
            minXpx = maxXpx;
            minXtime = maxXtime;
        } else {
            minXtime = CMTimeSubtract([self outerPxToCMTime:minXpx], self.outerStart);
        }
        
        self.minXpx = minXpx;
        self.maxXpx = maxXpx;
        self.minXtime = minXtime;
        self.maxXtime = maxXtime;
    }
    
    self.currentXpx += sizeDiff;
    
    // constrain - clamp
    // track margin here captures the fact that resizers are inset in the parent view
    newX = MAX(MIN(self.maxXpx, self.currentXpx), self.minXpx) + TRACK_MARGIN_PX;
    rect = CGRectMake(rect.origin.x, rect.origin.y, newX - rect.origin.x, rect.size.height);
    [mainTrack setFrame:rect];
    
    // touch up
    [self correctRightThumbnailsAndResizer];
    
    self.lastXpx = self.currentXpx;
}

-(void) correctRightThumbnailsAndResizer
{
    UIView *mainTrack = (UIControl *)[self viewWithTag:MAIN_TRACK_TAG];
    UIView *container = (UIView *)[self viewWithTag:TRACK_IMAGES_AREA_TAG];
    UIButton *btn = (UIButton *)[self viewWithTag:TRACK_RIGHT_RESIZE_TAG];
    
    CGRect rect = mainTrack.frame;
    [container setFrame:CGRectMake(TRACK_MARGIN_PX, 0, rect.size.width - (TRACK_MARGIN_PX * 2), rect.size.height)];
    [btn setFrame:CGRectMake(rect.size.width - RESIZER_WIDTH, 0, RESIZER_WIDTH, RESIZER_HEIGHT)];
}

-(void) debugReport
{
    NSLog(@"%f ::: %f -> %f (%f)",
            CMTimeGetSeconds(self.outerStart),
            CMTimeGetSeconds(self.innerTimeRange.start),
            CMTimeGetSeconds(self.innerTimeRange.duration),
            CMTimeGetSeconds(self.innerDuration));
}

-(void)setThumbnails: (CGFloat)width
{
    [self setThumbsContainerWidth: width];
 //   CGFloat availableWidth = width - RESIZER_WIDTH;
}

- (void) configureCell:(NSDictionary *)config withContext:(NSDictionary *)context mixerVC: (UIViewController *) mixer
{
    self.mixerViewController = mixer;
//    self.editingAccessoryView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"move-icon-1"]];
//    UIImageView *img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"move-icon-1"]];
    
    self.currentConfig = [[NSMutableDictionary alloc] initWithDictionary:config];
    
    BOOL isRemote = [(NSNumber *)context[@"is_remote"] isEqualToValue:@YES];
    
    if (isRemote) {
        config = [self deserialiseCellConfig:config];

        self.innerDuration = CMTimeMake([(NSNumber *)config[@"innerDuration"] longLongValue], [(NSNumber *)config[@"innerDurationTimescale"] longValue]);
        self.innerTimeRange = CMTimeRangeMake(CMTimeMake([(NSNumber *)config[@"innerTimeRangeStart"] longLongValue],
                                                         [(NSNumber *)config[@"innerTimeRangeStartTimescale"] longValue]),
                                              CMTimeMake([(NSNumber *)config[@"innerTimeRangeDur"] longLongValue],
                                                         [(NSNumber *)config[@"innerTimeRangeDurTimescale"] longValue]));
        self.outerStart = CMTimeMake([(NSNumber *)config[@"globalStart"] longLongValue], [(NSNumber *)config[@"globalStartTimescale"] longValue]);
        self.outerDuration = CMTimeMake([(NSNumber *)config[@"outerDuration"] longLongValue], [(NSNumber *)config[@"outerDurationTimescale"] longValue]);
        
        self.videoTrackId = config[@"playoffvideotrack_id"];
        
    } else {
        
        NSNumber *start = (NSNumber *)self.currentConfig[@"inner_start"];
        NSNumber *end = (NSNumber *)self.currentConfig[@"inner_end"];
        int64_t dur = [(NSNumber *)self.currentConfig[@"inner_duration"] longLongValue];
        long timescale = [(NSNumber *)self.currentConfig[@"inner_timescale"] longValue];
        
        self.innerDuration = CMTimeMake(dur, timescale);
        self.innerTimeRange = CMTimeRangeMake(CMTimeMake(start ? [start longLongValue] : 0, timescale),
                                              CMTimeMake(end ? [end longLongValue] : dur, timescale));

        self.outerStart = CMTimeMake([(NSNumber *) config[@"start"] longLongValue],
                                     [(NSNumber *) config[@"outer_timescale"] longValue]);
        self.outerDuration = CMTimeMake([(NSNumber *) context[@"duration"] longLongValue],
                                        [(NSNumber *) context[@"duration_timescale"] longValue]);
    }
    
    [self configureTrackSimple];
}

-(void) configureTrackSimple
{
    if (self.outerStart.timescale == 0) self.outerStart = kCMTimeZero;
    
    float startPos = [self CMTimeToOuterPx:self.outerStart] - TRACK_MARGIN_PX;
    
    UIControl *rectControl;
    CGRect rect;
    CGFloat clipWidth = [self clipWidth];
    
    rectControl = (UIControl *)[self viewWithTag:MAIN_TRACK_TAG];
    rect = CGRectMake(startPos, 0, clipWidth, CELL_HEIGHT);
    [rectControl setFrame: rect];
    
    if (self.currentConfig[@"local"] && self.currentConfig[@"URL"]) {
        [self generateThumbs];
        [self setThumbnails:clipWidth];
    }
    
    [self setResizersAtEdges:clipWidth];
}

-(CGFloat)clipWidth
{
    CMTime outerEnd = CMTimeAdd(self.outerStart, self.innerTimeRange.duration);
    
    float startPos = [self CMTimeToOuterPx:self.outerStart] - TRACK_MARGIN_PX;
    float endPos = [self CMTimeToOuterPx:outerEnd] + TRACK_MARGIN_PX;
    
    CGFloat clipWidth = endPos - startPos;
    
    return clipWidth;
}

- (void) addLocalVideo: (NSURL *) videoURL
{
    self.currentConfig[@"URL"] = videoURL;
    self.currentConfig[@"local"] = @YES;

    [self generateThumbs];
    [self setThumbnails:[self clipWidth]];
}

-(void)generateThumbs
{
    BOOL valid = (self.currentConfig && self.currentConfig[@"local"] && self.currentConfig[@"URL"]);
    if (!valid) return;
    
    const CMTime frameWidthTime = CMTimeMakeWithSeconds(((float)CELL_HEIGHT / 320) * CMTimeGetSeconds(self.outerDuration), 1000);
    CGFloat thumbOffset = -CMTimeGetSeconds(self.innerTimeRange.start) / CMTimeGetSeconds(self.outerDuration) * TRACK_PX_WIDTH;
    
    CMTime maxVisible = self.innerDuration;
    CMTime currentFrameStart = kCMTimeZero;
    
    NSMutableArray *thumbs = [[NSMutableArray alloc] init];
    
    int i = 0;
    
    do {
        [thumbs addObject:[NSValue valueWithCMTime:currentFrameStart]];
        currentFrameStart = CMTimeAdd(currentFrameStart, frameWidthTime);
        
        i += 1;
    } while (CMTimeCompare(currentFrameStart, maxVisible) != 1 && i < 60 * 4);

    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:self.currentConfig[@"URL"] options:nil];
    AVAssetImageGenerator *generator = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    generator.appliesPreferredTrackTransform=TRUE;
    
    UIView *container = (UIView *)[self viewWithTag:TRACK_IMAGES_AREA_TAG];
    UIImageView __block *thumbImage;

    for (UIView *v in container.subviews) {[v removeFromSuperview]; }
    
    AVAssetImageGeneratorCompletionHandler handler = ^(CMTime requestedTime, CGImageRef im_,
                                                       CMTime actualTime, AVAssetImageGeneratorResult result, NSError *error){
        
        CGImageRef im = CGImageRetain(im_);
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            
            float width = CGImageGetWidth(im);
            float height = CGImageGetHeight(im);
            float trueWidth = width;
            float trueHeight = width;
            float xOffset = 0;
            float yOffset = 0;
            if (width > height) {
                trueWidth = (width / height) * width;
                xOffset = (((width / height) * CELL_HEIGHT) / 2) - (CELL_HEIGHT / 2);
            } else if (height > width) {
                trueHeight = (height / width) * height;
                yOffset = (((height / width) * CELL_HEIGHT) / 2) - (CELL_HEIGHT / 2);
            }
            
            if (result != AVAssetImageGeneratorSucceeded) {
                return;
            }
            
            CGFloat x = CMTimeGetSeconds(requestedTime) / CMTimeGetSeconds(self.outerDuration) * 320;
            
            thumbImage = [[UIImageView alloc] initWithFrame:CGRectMake(x + thumbOffset, 0, CELL_HEIGHT, CELL_HEIGHT)];
            thumbImage.contentMode = UIViewContentModeScaleAspectFill;
            [thumbImage setImage:[UIImage imageWithCGImage:im]];
            [container addSubview:thumbImage];
            
            CGImageRelease(im);
        });
    };
    
    CGSize maxSize = CGSizeMake(CELL_HEIGHT, CELL_HEIGHT);
    generator.maximumSize = maxSize;
    [generator generateCGImagesAsynchronouslyForTimes:thumbs completionHandler:handler];
    
}

/* actually fully inside parent to detect touches, but clips start at half RESIZER_WIDTH and clipWith - (RW / 2) */
-(void)setResizersAtEdges:(CGFloat)clipWidth
{
    UIButton *btn;
    CGRect rect;
    
    btn = (UIButton *)[self viewWithTag:TRACK_LEFT_RESIZE_TAG];
    rect = CGRectMake(0, 0, RESIZER_WIDTH, RESIZER_HEIGHT);
    [btn setFrame: rect];
    
    btn = (UIButton *)[self viewWithTag:TRACK_RIGHT_RESIZE_TAG];
    rect = CGRectMake(clipWidth - RESIZER_WIDTH, 0, RESIZER_WIDTH, RESIZER_HEIGHT);
    [btn setFrame: rect];
    
    [self setThumbsContainerWidth:clipWidth];
}

-(void)setThumbsContainerWidth:(CGFloat)width
{
    UIView *thumbsContainer = (UIImageView *)[self viewWithTag:TRACK_IMAGES_AREA_TAG];
    [thumbsContainer setFrame:CGRectMake(RESIZER_WIDTH / 2, 0, width - RESIZER_WIDTH, CELL_HEIGHT)];
}

-(void)setDragImage
{    
    for (UIView * view in self.subviews) {
        if ([NSStringFromClass([view class]) rangeOfString: @"Reorder"].location != NSNotFound) {
            for (UIView * subview in view.subviews) {
                if ([subview isKindOfClass: [UIImageView class]]) {
                    [subview setFrame:CGRectMake((44 / 2) - (26 / 2), (70 / 2) - (32 / 2), 26, 32)];
                    ((UIImageView *)subview).image = [UIImage imageNamed: @"move-icon-1"];
                }
            }
        }
    }
}

-(NSDictionary *)deserialiseCellConfig: (NSDictionary *) track
{
    return [PLYUtilities deserialiseAncillaryTrack:track];
}

-(void)setProgress:(float)newProgress
{
    [self.coverLayer setHidden:NO];
    [self.progressBarBack setHidden:NO];
    CGRect frame = self.progressBar.frame;
    [self.progressBarBack setFrame:CGRectMake(frame.origin.x,
                                              frame.origin.y,
                                              PROGRESS_AREA_WIDTH * newProgress,
                                              frame.size.height)];
    [self.progressBar setHidden:NO];
}

-(void) setSpinnerActive
{
    [self.coverSpinner startAnimating];
    [self.coverSpinner setHidden:NO];
    [self.coverLayer setHidden:NO];
}

- (void) setLoadingMessage
{
    [self.loadingMessage setHidden:NO];
    [self.coverLayer setHidden:NO];
}

- (void) setErrorMessageWithRetryURL: (NSString *)url;
{
    self.retryDownloadURL = url;
    [self stopLoaders];
    if (url) {
        [self.loadingMessage setEnabled:YES];
        [self.loadingMessage setTitle:@"Retry Download" forState:UIControlStateNormal];
    } else {
        [self.loadingMessage setEnabled:NO];
        [self.loadingMessage setTitle:@"Error Downloading" forState:UIControlStateNormal];
    }
    
    [self.loadingMessage setHidden:NO];
    [self.coverLayer setHidden:NO];
}

-(void) stopLoaders
{
    [self.coverLayer setHidden:YES];
    
    [self.coverSpinner stopAnimating];
    [self.coverSpinner setHidden:YES];
    [self.progressBar setHidden:YES];
    [self.progressBarBack setHidden:YES];
    [self.loadingMessage setHidden:YES];
}

-(void) deserialiseDirect: (NSDictionary *)config withMixerViewController: (UIViewController *)mixerVC
{
    self.mixerViewController = mixerVC;
    
    self.currentConfig = [[NSMutableDictionary alloc] initWithDictionary:config];
    
    self.soundVolume = [(NSNumber *)config[@"volume"] floatValue];
    self.outerStart = [(NSValue *)config[@"start"] CMTimeValue];
    self.innerTimeRange = [(NSValue *)config[@"inner_time_range"] CMTimeRangeValue];
    self.innerDuration = [(NSValue *)config[@"inner_duration"] CMTimeValue];
    self.outerDuration = [(NSValue *)config[@"outer_duration"] CMTimeValue];
    
    [self configureTrackSimple];
}

-(NSDictionary *)serialiseCellConfig
{
    if (self.inProgressDownload) return @{};
    
    NSMutableDictionary *ser = [[NSMutableDictionary alloc] initWithDictionary: @{
            @"local": @YES,
             @"volume": [[NSNumber alloc] initWithFloat: self.soundVolume],
             @"start": [NSValue valueWithCMTime:self.outerStart],
             @"inner_time_range": [NSValue valueWithCMTimeRange:self.innerTimeRange],
             @"inner_duration": [NSValue valueWithCMTime:self.innerDuration],
             @"outer_duration": [NSValue valueWithCMTime:self.outerDuration]
             }];
    
    if (self.videoTrackId != nil) ser[@"video_track_id"] = self.videoTrackId;
    if ([self.currentConfig valueForKey: @"URL"]) ser[@"URL"] = self.currentConfig[@"URL"];
    
    return ser;
}

@end
