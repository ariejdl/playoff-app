//
//  PLYCamCaptureManager.m
//  Playoff
//
//  Created by Arie Lakeman on 14/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYCamCaptureManager.h"
#import "PLYUtilities.h"

#import <MobileCoreServices/UTCoreTypes.h>
#import <AssetsLibrary/AssetsLibrary.h>

@interface PLYCamCaptureManager (AVCaptureFileOutputRecordingDelegate) <AVCaptureFileOutputRecordingDelegate>
@end

@interface PLYCamCaptureManager (Internal)

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition)position;
- (AVCaptureDevice *) frontFacingCamera;
- (AVCaptureDevice *) backFacingCamera;
- (AVCaptureDevice *) audioDevice;

@end

@interface PLYCamCaptureManager ()

@property (nonatomic,retain) AVCaptureSession *session;
@property (nonatomic,retain) AVCaptureDeviceInput *videoInput;
@property (nonatomic,retain) AVCaptureDeviceInput *audioInput;
@property (nonatomic,retain) AVCaptureMovieFileOutput *movieFileOutput;
@property (nonatomic,retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic,retain) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic,retain) AVCaptureAudioDataOutput *audioDataOutput;
@property (nonatomic,retain) id deviceConnectedObserver;
@property (nonatomic,retain) id deviceDisconnectedObserver;
@property (nonatomic,assign) UIBackgroundTaskIdentifier backgroundRecordingID;

@end


@implementation PLYCamCaptureManager

@synthesize session = _session;
@synthesize videoInput = _videoInput;
@synthesize audioInput = _audioInput;
@synthesize movieFileOutput = _movieFileOutput;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize videoDataOutput = _videoDataOutput;
@synthesize audioDataOutput = _audioDataOutput;
@synthesize backgroundRecordingID = _backgroundRecordingID;
@synthesize deviceConnectedObserver = _deviceConnectedObserver;
@synthesize deviceDisconnectedObserver = _deviceDisconnectedObserver;

- (BOOL) setupSessionWithPreset:(NSString *)sessionPreset error:(NSError **)error
{
    BOOL success = NO;
    
    // Init the device inputs
    AVCaptureDeviceInput *videoInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self backFacingCamera] error:error];
    [self setVideoInput:videoInput]; // stash this for later use if we need to switch cameras
    
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:[self audioDevice] error:error];
    [self setAudioInput:audioInput];
    
    // Setup the default file outputs
    AVCaptureStillImageOutput *stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys: AVVideoCodecJPEG, AVVideoCodecKey, nil];
    [stillImageOutput setOutputSettings:outputSettings];
    [self setStillImageOutput:stillImageOutput];
    
    AVCaptureMovieFileOutput *movieFileOutput = [[AVCaptureMovieFileOutput alloc] init];
    [self setMovieFileOutput:movieFileOutput];
    
    // Setup and start the capture session
    AVCaptureSession *session = [[AVCaptureSession alloc] init];
    
    if ([session canAddInput:videoInput]) {
        [session addInput:videoInput];
    }
    if ([session canAddInput:audioInput]) {
        [session addInput:audioInput];
    }
    if ([session canAddOutput:movieFileOutput]) {
        [session addOutput:movieFileOutput];
    }
    if ([session canAddOutput:stillImageOutput]) {
        [session addOutput:stillImageOutput];
    }
    
    [session setSessionPreset:sessionPreset];
    [session startRunning];
    
    [self setSession:session];
    
    success = YES;
    
    return success;
}

- (NSUInteger) cameraCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo] count];
}

- (NSUInteger) micCount
{
    return [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] count];
}

- (BOOL) isRecording
{
    return [[self movieFileOutput] isRecording];
}

- (void) startRecording
{
    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [self setBackgroundRecordingID:[[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{}]];
    }
    
    AVCaptureConnection *videoConnection = [PLYCamCaptureManager connectionWithMediaType:AVMediaTypeVideo
                                                                         fromConnections:[[self movieFileOutput] connections]];
    
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    [[self movieFileOutput] startRecordingToOutputFileURL:[PLYUtilities tempFileURL: @"mov"] recordingDelegate:self];
}

- (void) stopRecording
{
    [[self movieFileOutput] stopRecording];
}

- (void) captureStillImage
{
    AVCaptureConnection *videoConnection = [PLYCamCaptureManager connectionWithMediaType:AVMediaTypeVideo fromConnections:[[self stillImageOutput] connections]];
    if ([videoConnection isVideoOrientationSupported]) {
        [videoConnection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    }
    
    [[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection
                                                         completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                                                             if (imageDataSampleBuffer != NULL) {
                                                                 NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                                                                 UIImage *image = [[UIImage alloc] initWithData:imageData];
                                                                 ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                                                                 [library writeImageToSavedPhotosAlbum:[image CGImage]
                                                                                           orientation:(ALAssetOrientation)[image imageOrientation]
                                                                                       completionBlock:^(NSURL *assetURL, NSError *error){
                                                                                           if (error) {
                                                                                               id delegate = [self delegate];
                                                                                               if ([delegate respondsToSelector:@selector(captureStillImageFailedWithError:)]) {
                                                                                                   [delegate captureStillImageFailedWithError:error];
                                                                                               }
                                                                                           }
                                                                                       }];
                                                             } else if (error) {
                                                                 id delegate = [self delegate];
                                                                 if ([delegate respondsToSelector:@selector(captureStillImageFailedWithError:)]) {
                                                                     [delegate captureStillImageFailedWithError:error];
                                                                 }
                                                             }
                                                         }];
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (AVCaptureDevice *) frontFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionFront];
}

- (AVCaptureDevice *) backFacingCamera
{
    return [self cameraWithPosition:AVCaptureDevicePositionBack];
}

- (AVCaptureDevice *) audioDevice
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio];
    if ([devices count] > 0) {
        return [devices objectAtIndex:0];
    }
    return nil;
}

- (void) setConnectionWithMediaType:(NSString *)mediaType enabled:(BOOL)enabled;
{
    [[PLYCamCaptureManager connectionWithMediaType:mediaType fromConnections:[[self movieFileOutput] connections]] setEnabled:enabled];
}

+ (AVCaptureConnection *)connectionWithMediaType:(NSString *)mediaType fromConnections:(NSArray *)connections;
{
	for ( AVCaptureConnection *connection in connections ) {
		for ( AVCaptureInputPort *port in [connection inputPorts] ) {
			if ( [[port mediaType] isEqual:mediaType] ) {
				return connection;
			}
		}
	}
	return nil;
}

- (void)             captureOutput:(AVCaptureFileOutput *)captureOutput
didStartRecordingToOutputFileAtURL:(NSURL *)fileURL
                   fromConnections:(NSArray *)connections
{
    id delegate = [self delegate];
    if ([delegate respondsToSelector:@selector(recordingBegan)]) {
        [delegate recordingBegan];
    }
    
}

- (void)              captureOutput:(AVCaptureFileOutput *)captureOutput
didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL
                    fromConnections:(NSArray *)connections
                              error:(NSError *)error
{

    id delegate = [self delegate];
    if (error && [delegate respondsToSelector:@selector(someOtherError:)]) {
        [delegate someOtherError:error];
    }

    if ([[UIDevice currentDevice] isMultitaskingSupported]) {
        [[UIApplication sharedApplication] endBackgroundTask:[self backgroundRecordingID]];
    }
    
    if ([delegate respondsToSelector:@selector(recordingFinished)]) {
        [delegate recordingFinished];
    }

}

-(AVCaptureMovieFileOutput *) getMovieFileOutput { return [self movieFileOutput]; }
-(AVCaptureStillImageOutput *)getStillImageOutput { return [self stillImageOutput]; }
-(AVCaptureVideoDataOutput *)getVideoDataOutput { return [self videoDataOutput]; }
-(AVCaptureAudioDataOutput *) getAudioDataOutput { return [self audioDataOutput]; }

@end
