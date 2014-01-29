//
//  PLYCamCaptureManager.h
//  Playoff
//
//  Created by Arie Lakeman on 14/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol PLYCamCaptureManagerDelegate
@optional
- (void) captureStillImageFailedWithError:(NSError *)error;
- (void) acquiringDeviceLockFailedWithError:(NSError *)error;
- (void) cannotWriteToAssetLibrary;
- (void) assetLibraryError:(NSError *)error forURL:(NSURL *)assetURL;
- (void) someOtherError:(NSError *)error;
- (void) recordingBegan;
- (void) recordingFinished;
- (void) deviceCountChanged;
@end

@interface PLYCamCaptureManager : NSObject

@property (nonatomic,readonly,retain) AVCaptureSession *session;
@property (nonatomic,readonly,retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic,assign) AVCaptureFlashMode flashMode;
@property (nonatomic,assign) AVCaptureTorchMode torchMode;
@property (nonatomic,assign) AVCaptureFocusMode focusMode;
@property (nonatomic,assign) AVCaptureExposureMode exposureMode;
@property (nonatomic,assign) AVCaptureWhiteBalanceMode whiteBalanceMode;
@property (nonatomic,readonly,getter=isRecording) BOOL recording;
@property (nonatomic,assign) id <PLYCamCaptureManagerDelegate> delegate;
@property (weak) UIViewController *captureViewController;

- (BOOL) setupSessionWithPreset:(NSString *)sessionPreset error:(NSError **)error;
- (NSUInteger) cameraCount;
- (NSUInteger) micCount;
- (void) setConnectionWithMediaType:(NSString *)mediaType enabled:(BOOL)enabled;
+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
- (void) captureStillImage;
- (void)startRecording;
- (void)stopRecording;

-(AVCaptureMovieFileOutput *)getMovieFileOutput;
-(AVCaptureStillImageOutput *)getStillImageOutput;
-(AVCaptureVideoDataOutput *)getVideoDataOutput;
-(AVCaptureAudioDataOutput *) getAudioDataOutput;

@end
