//
//  PLYVideoComposer.h
//  Playoff
//
//  Created by Arie Lakeman on 07/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

extern NSString* const PLYChangeMixerTrackNotification;
extern NSString* const PLYEditCommandCompletionNotification;
extern NSString* const PLYPrepareExportCommandCompletionNotification;
extern NSString* const PLYExportCommandCompletionNotification;

@interface PLYVideoComposer : NSObject

@property AVMutableComposition *mutableComposition;
@property AVMutableVideoComposition *mutableVideoComposition;
@property AVMutableAudioMix *mutableAudioMix;

@property NSArray *rawCompositionItems;
@property NSArray *processedAudioTracks;
@property NSArray *processedVideoTracks;

-(void)setupComposition: (NSArray *)config withDuration: (CMTime)maxDuration withNotificationName: (NSString *)notificationName;
-(NSSet *)getAllTrackURLs;
- (void)exportComposition;

@end
