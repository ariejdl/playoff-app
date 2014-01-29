//
//  PLYCaptureViewController2.h
//  Playoff
//
//  Created by Arie Lakeman on 12/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

#import "PLYCamCaptureManager.h"

extern int const MaxTracksCount;

@interface PLYCaptureViewController : UIViewController <UIGestureRecognizerDelegate, PLYCamCaptureManagerDelegate>

@property BOOL isStandalone;
@property (weak) UIViewController *mixerViewController;

-(id)initAsStandalone: (UIViewController *) mixerViewController;

@property PLYCamCaptureManager *captureManager;
@property (nonatomic, retain) AVCaptureVideoPreviewLayer *captureVideoPreviewLayer;
@property BOOL setupCaptureArea;
@property BOOL inVideoMode;
@property UIView *backView;
@property UIView *captureView;
@property UIView *progressBack;
@property UIView *progressBar;
@property float currentSecondsRecorded;

@property UIImageView *transitionIndicatorView;

@property (atomic) BOOL stopImmediately;
@property (atomic) BOOL transitionRecording;
@property (atomic) BOOL isRecording;

@property NSMutableArray *currentVideos;
@property NSURL *lastSnap;

@end
