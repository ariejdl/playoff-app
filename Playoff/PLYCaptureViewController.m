//
//  PLYCaptureViewController2.m
//  Playoff
//
//  Created by Arie Lakeman on 12/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYCaptureViewController.h"
#import "PLYVideoMixerViewController.h"

#import <AVFoundation/AVFoundation.h>
#import "PLYTheme.h"

#import "PLYCustomNavigationBar.h"

#import "PLYUserInformationView.h"

#define VIEW_WIDTH 320
#define MAIN_PAD 5
#define TOGGLE_BUTTON_WIDTH 120
#define TOGGLE_BUTTON_HEIGHT 10

#define CAPTURE_AREA_DIM 320
#define PROGRESS_HEIGHT 30
#define TRANSITION_VIEW_WIDTH 180

#define VIDEO_BTN_TAG 20
#define STILL_BTN_TAG 20

#define MAX_CAPTURE_SECONDS 15

static int navigationBarOffset = 44;
extern int const MaxTracksCount = 15;

@implementation PLYCaptureViewController

@synthesize captureManager = _captureManager;
@synthesize captureVideoPreviewLayer = _captureVideoPreviewLayer;
@synthesize mixerViewController = _mixerViewController;
@synthesize backView = _backView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:@"PLYCaptureViewController" bundle:[NSBundle mainBundle]];
    if (self) {
        // Custom initialization
        self.inVideoMode = YES;
        self.currentVideos = [[NSMutableArray alloc] init];
    }
    return self;
}

-(id)initAsStandalone: (UIViewController *) mixerViewController;
{
    self.isStandalone = TRUE;
    self.mixerViewController = mixerViewController;
    self = [self init];
    return self;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        self.currentSecondsRecorded = 0;
        [self setTitle:@"Capture"];
    }
    return self;
}

- (void)goBack
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)finishedCapturing
{
    PLYVideoMixerViewController *mixer = [[PLYVideoMixerViewController alloc]init];
    [mixer setRawTracks:self.currentVideos];
    [self.navigationController pushViewController:mixer animated:YES];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.captureView removeFromSuperview];
    self.captureManager = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationItem *navItem;
    CGFloat topOffset = 0;
    
    if (self.isStandalone) {
        UINavigationBar *navBar = [[UINavigationBar alloc]
                                   initWithFrame:CGRectMake(0, 0, 320, navigationBarOffset)];
        navItem = [[UINavigationItem alloc] init];
        [navBar setItems:@[navItem]];
        [self.view addSubview:navBar];
        topOffset = navigationBarOffset;
    } else {
        navItem = self.navigationItem;
    }
    
    UIBarButtonItem *backBtn = [PLYTheme barButtonWithTarget:self selector:@selector(goBack) img1:@"close-but-1" img2:@"close-but-sel-1"];
    
    navItem.leftBarButtonItem = backBtn;
    if (!self.isStandalone) {
        UIBarButtonItem *doneBtn = [PLYTheme textBarButtonWithTitle:@"done" target:self selector:@selector(finishedCapturing)];
        navItem.rightBarButtonItem = doneBtn;
    }
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage imageNamed:@"dark-navigation-bar-1"] forBarMetrics:UIBarMetricsDefault];
    
    /* core stuff */
    CGRect rect = self.view.frame;
    rect.size.height -= topOffset;
    rect.origin.y = topOffset;
    UIView *backView = [[UIView alloc] initWithFrame:rect];
    
    [backView setBackgroundColor:[PLYTheme backgroundDarkColor]];
    [self.view addSubview:backView];
    self.backView = backView;
    
    UIView *rectView;
    
    /* progress bar */
    rectView = [[UIView alloc] initWithFrame:CGRectMake(MAIN_PAD,
                                                        MAIN_PAD + TOGGLE_BUTTON_HEIGHT + MAIN_PAD +
                                                        CAPTURE_AREA_DIM + MAIN_PAD,
                                                        VIEW_WIDTH - MAIN_PAD - MAIN_PAD,PROGRESS_HEIGHT)];
    [rectView setBackgroundColor:[UIColor colorWithWhite:0.2 alpha:1]];
    [backView addSubview:rectView];
    self.progressBack = rectView;
    
    UIView *innerProgress = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0, PROGRESS_HEIGHT)];
    [innerProgress setBackgroundColor:[PLYTheme primaryColor]];
    [rectView addSubview:innerProgress];
    self.progressBar = innerProgress;
    
    /* placeholder video */
    rect = CGRectMake((VIEW_WIDTH / 2) - (CAPTURE_AREA_DIM / 2),
                      MAIN_PAD + TOGGLE_BUTTON_HEIGHT + MAIN_PAD,
                      CAPTURE_AREA_DIM, CAPTURE_AREA_DIM);
    
    rectView = [[UIView alloc] initWithFrame:rect];
    [rectView setBackgroundColor:[UIColor blackColor]];
    [backView addSubview:rectView];
}

-(void)dealloc
{
    if (self.captureView) [self.captureView removeFromSuperview];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.setupCaptureArea) return;
    
    CGRect rect;
    UIButton *btn;
    
    /* player + UIButton on top */
    rect = CGRectMake((VIEW_WIDTH / 2) - (CAPTURE_AREA_DIM / 2),
                      MAIN_PAD + TOGGLE_BUTTON_HEIGHT + MAIN_PAD,
                      CAPTURE_AREA_DIM, CAPTURE_AREA_DIM);
    
    UIView *rectView;
    
    rectView = [[UIView alloc] initWithFrame:rect];
    [rectView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.25]];
    [self.backView addSubview:rectView];
    self.captureView = rectView;
    
    rect = CGRectMake(0, 0, CAPTURE_AREA_DIM, CAPTURE_AREA_DIM);
    
    NSError *error;
    PLYCamCaptureManager *captureManager = [[PLYCamCaptureManager alloc] init];
    [captureManager setDelegate:self];
    
    if ([captureManager setupSessionWithPreset:AVCaptureSessionPresetMedium error:&error]) {
        [self setCaptureManager:captureManager];
        
        AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:[captureManager session]];
        
        UIView *view = rectView;
        CALayer *viewLayer = [view layer];
        [viewLayer setMasksToBounds:YES];
        
        [captureVideoPreviewLayer setFrame:rect];
        
        [captureVideoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        
        [self setCaptureVideoPreviewLayer:captureVideoPreviewLayer];
        
        NSUInteger cameraCount = [captureManager cameraCount];
        if (cameraCount < 1 && [captureManager micCount] < 1) {
            // nothing to capture with!
        }
        
        [viewLayer insertSublayer:captureVideoPreviewLayer below:[[viewLayer sublayers] objectAtIndex:0]];
    }
    
    /* preview touch responder */
    btn = [[UIButton alloc] initWithFrame:rect];
    [btn setBackgroundColor:[UIColor clearColor]];
    [rectView addSubview:btn];
    
    UILongPressGestureRecognizer *longPressGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(captureTouch:)];
    
    longPressGes.minimumPressDuration = 0.05;
    longPressGes.cancelsTouchesInView = FALSE;
    [longPressGes setDelegate:self];
    [btn addGestureRecognizer:longPressGes];
    [btn addTarget:self action:@selector(quickTouch) forControlEvents:UIControlEventTouchUpInside];
    
    [btn addTarget:self action:@selector(tapCapture) forControlEvents:UIControlEventTouchUpInside];
    
    /* transition and recording views */
    UIImageView *imView;
    
    imView = [[UIImageView alloc] initWithFrame:CGRectMake((CAPTURE_AREA_DIM / 2) - (TRANSITION_VIEW_WIDTH / 2), 4, TRANSITION_VIEW_WIDTH, 4)];
    [imView setBackgroundColor:[UIColor whiteColor]];
    [imView setHidden:YES];
    [rectView addSubview:imView];
    self.transitionIndicatorView = imView;
    
    self.setupCaptureArea = YES;
    
    /* first use note */
    PLYUserInformationView *firstUse = [[PLYUserInformationView alloc] initWithImage:@"user-info-capture-1" andFirstUseKey:@"firstUse_capture" white:YES];
    if (firstUse) {
        [self.navigationController.view addSubview:firstUse];
    }

}

-(void)setVideoState
{
    self.inVideoMode = YES;
    UIButton *btn = (id)[self.view viewWithTag:VIDEO_BTN_TAG];
    [btn setSelected:YES];
    
    btn = (id)[self.view viewWithTag:STILL_BTN_TAG];
    [btn setSelected:NO];
}

-(void)setStillState
{
    self.inVideoMode = NO;
    UIButton *btn = (id)[self.view viewWithTag:VIDEO_BTN_TAG];
    [btn setSelected:NO];
    
    btn = (id)[self.view viewWithTag:STILL_BTN_TAG];
    [btn setSelected:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

-(void)quickTouch
{
    self.stopImmediately = YES;
    self.transitionRecording = NO;
}

-(void)captureTouch:(UILongPressGestureRecognizer *)gesture {
    if (self.inVideoMode) {
        if (self.transitionRecording) return;
        
        if (gesture.state == UIGestureRecognizerStateBegan) {
            if (self.isRecording) return;
            
            if ([self.currentVideos count] >= MaxTracksCount) {
                UIAlertView *alertView = [[UIAlertView alloc]
                                          initWithTitle:[[NSString alloc] initWithFormat: @"You've captured the maximum %i clips", MaxTracksCount, nil]
                                          message:nil
                                          delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
                [alertView show];
                return;
            }
            
            self.transitionRecording = YES;
            [self.transitionIndicatorView setHidden:NO];
            
            self.stopImmediately = NO;
            [self.captureManager startRecording];
            if (![self.captureManager getMovieFileOutput].recording) {
                // probably out of space 1
            }
            // check if is recording
        } else if (gesture.state == UIGestureRecognizerStateEnded) {
            self.stopImmediately = YES;
            if (!self.isRecording) return;
            
            if (![self.captureManager getMovieFileOutput].recording) {
                // probably out of space 2
            }
            
            [self stopAndRecord];
        }
    }
}

-(void)stopAndRecord
{
    if (self.transitionRecording) return;
    
    [self.captureManager stopRecording];
    self.transitionRecording = YES;
    [self.transitionIndicatorView setHidden:NO];
    
    // TODO: check maxRecordedDuration of AVCaptureMovieFileOutput
    
    AVCaptureMovieFileOutput *vid = [self.captureManager getMovieFileOutput];
    
    CMTime t = vid.recordedDuration;

    if (t.value > 0 && t.timescale) {
        [self.currentVideos addObject:@{
         @"local": @TRUE,
         @"URL": [vid outputFileURL],
         @"inner_duration": [[NSNumber alloc] initWithLongLong:t.value],
         @"inner_timescale": [[NSNumber alloc] initWithLong:t.timescale]
         }];
    } else {
        self.transitionRecording = NO;
    }
    
}

-(void) tapCapture {
    if (!self.inVideoMode) {
        [self.captureManager captureStillImage];
    }
}

-(void)recordingBegan
{
    self.transitionRecording = NO;
    self.isRecording = YES;
    
    [self updateProgressView];
    
    [self.transitionIndicatorView setHidden:YES];
}

-(void)updateProgressView
{
    CGRect frame = self.progressBack.frame;
    float dynWidth = frame.size.width * (self.currentSecondsRecorded / MAX_CAPTURE_SECONDS);
    if (dynWidth > frame.size.width) dynWidth = frame.size.width;
    [self.progressBar setFrame:CGRectMake(0, 0, dynWidth, frame.size.height)];
    
    if (self.currentSecondsRecorded >= MAX_CAPTURE_SECONDS || self.stopImmediately) {
        self.transitionRecording = YES;
        [self.transitionIndicatorView setHidden:NO];
        [self stopAndRecord];
        self.stopImmediately = NO;
        return;
    }
    
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if (self.isRecording) {
            self.currentSecondsRecorded += 0.1;
            [self updateProgressView];
        }
    });
}

-(void)recordingFinished
{
    self.transitionRecording = NO;
    self.isRecording = NO;
    self.stopImmediately = NO;
    
    [self.transitionIndicatorView setHidden:YES];
    
    if (self.isStandalone && self.mixerViewController) {
        NSURL *vidURL = ((NSDictionary *)[self.currentVideos lastObject])[@"URL"];
        [(PLYVideoMixerViewController *)self.mixerViewController addFreshCapture:vidURL];
        [self goBack];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
