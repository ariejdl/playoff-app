//
//  PLYVideoComposer.m
//  Playoff
//
//  Created by Arie Lakeman on 07/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYVideoComposer.h"
#import "PLYUtilities.h"
#import "PLYAppDelegate.h"

NSString* const PLYChangeMixerTrackNotification = @"PLYChangeMixerTrackNotification";
NSString* const PLYEditCommandCompletionNotification = @"PLYEditCommandCompletionNotification";
NSString* const PLYPrepareExportCommandCompletionNotification = @"PLYPrepareExportCommandCompletionNotification";
NSString* const PLYExportCommandCompletionNotification = @"PLYExportCommandCompletionNotification";

@implementation PLYVideoComposer

@synthesize rawCompositionItems = _rawCompositionItems;
@synthesize processedAudioTracks = _processedAudioTracks;
@synthesize processedVideoTracks = _processedVideoTracks;

-(NSArray *)getProcessedVideoTracks: (NSArray *)tracks withTime: (CMTime) maxDuration
{
    NSMutableArray *processed = [[NSMutableArray alloc] init];
    NSDictionary *conf;

    CMTime currentPos = kCMTimeZero;
    NSDictionary *currentTrack = nil;
    
    CMTime start;
    int layerIndex;
    
    CMTime currentStart;
    CMTime currentEnd;
    CMTime diff;
    CMTimeRange innerRange;
    int currentLayerIndex;
    
    BOOL wasSuperseded;

    while (CMTimeCompare(currentPos, maxDuration) == -1) {
        
        wasSuperseded = FALSE;
        if (currentTrack == nil) {
            // get any tracks in progress
            for (conf in tracks) {
                currentStart = [(NSValue *)conf[@"absolute_start"] CMTimeValue];
                currentEnd = [(NSValue *)conf[@"absolute_end"] CMTimeValue];
                
                if (CMTimeCompare(currentPos, currentStart) != -1 && CMTimeCompare(currentPos, currentEnd) == -1) {
                    currentTrack = conf;
                    currentLayerIndex = [(NSNumber *)conf[@"layer_index"] intValue];
                    break;
                }
            }

            // if nothing: get the earliest track starting >= currentPosition
            if (currentTrack == nil) {
                for (conf in tracks) {
                    currentStart = [(NSValue *)conf[@"absolute_start"] CMTimeValue];
                    if (CMTimeCompare(currentPos, currentStart) != 1) {
                        currentPos = currentStart;
                        currentTrack = conf;
                        currentEnd = [(NSValue *)conf[@"absolute_end"] CMTimeValue];
                        currentLayerIndex = [(NSNumber *)conf[@"layer_index"] intValue];
                        break;
                    }
                }
            }
            // if can't find a track we're done
            if (currentTrack == nil) {
                break;
            }
        }
        // check to see if there are any other tracks that start after the current position and start before this one ends and that are a higher layer index
        for (conf in tracks) {
            start = [(NSValue *)conf[@"absolute_start"] CMTimeValue];
            layerIndex = [(NSNumber *)conf[@"layer_index"] intValue];
            if (CMTimeCompare(start, currentPos) == 1 && CMTimeCompare(currentEnd, start) == 1 && layerIndex < currentLayerIndex) {
                
                innerRange = [(NSValue *)currentTrack[@"inner_time_range"] CMTimeRangeValue];
                
                // must check inner_time_range to see if needs brought forward
                if (CMTimeCompare(currentPos, currentStart) == 1) {
                    // compute the diff
                    diff = CMTimeSubtract(currentPos, currentStart);
                    NSLog(@"1: %f", CMTimeGetSeconds(diff));
                    innerRange = CMTimeRangeMake(CMTimeAdd(innerRange.start, diff),
                                                 CMTimeSubtract(innerRange.duration, diff));
                }
                
                // must truncate the end of this inner time range
                diff = CMTimeSubtract(currentEnd, start);
                NSLog(@"2: %f", CMTimeGetSeconds(diff));
                innerRange = CMTimeRangeMake(innerRange.start, CMTimeSubtract(innerRange.duration, diff));
                
                
                [processed addObject:@{
                    @"URL": currentTrack[@"URL"],
                    @"flat_start": [NSValue valueWithCMTime: currentPos],
                    @"flat_end": [NSValue valueWithCMTime: start],
                    @"inner_time_range": [NSValue valueWithCMTimeRange:innerRange]
                 }];
                
                currentPos = start;
                currentTrack = conf;
                currentStart = start;
                currentEnd = [(NSValue *)conf[@"absolute_end"] CMTimeValue];
                currentLayerIndex = [(NSNumber *)conf[@"layer_index"] intValue];
                wasSuperseded = TRUE;
                break;
            }
        }
        if (!wasSuperseded) {
            
            innerRange = [(NSValue *)currentTrack[@"inner_time_range"] CMTimeRangeValue];
            
            // must check inner_time_range to see if needs brought forward
            if (CMTimeCompare(currentPos, currentStart) == 1) {
                // compute the diff
                diff = CMTimeSubtract(currentPos, currentStart);
                NSLog(@"3: %f", CMTimeGetSeconds(diff));
                innerRange = CMTimeRangeMake(CMTimeAdd(innerRange.start, diff),
                                             CMTimeSubtract(innerRange.duration, diff));
            }
            
            NSLog(@"4:");
            
            [processed addObject:@{
             @"URL": currentTrack[@"URL"],
             @"flat_start": [NSValue valueWithCMTime: currentPos],
             @"flat_end": [NSValue valueWithCMTime: currentEnd],
             @"inner_time_range": [NSValue valueWithCMTimeRange:innerRange]
             }];
            
            currentTrack = nil;
            currentPos = currentEnd;
        }
    }

    for (conf in processed) {
        NSLog(@"%f -> %f (%f -> %f)",
                        CMTimeGetSeconds([(NSValue *)conf[@"flat_start"] CMTimeValue]),
                        CMTimeGetSeconds([(NSValue *)conf[@"flat_end"] CMTimeValue]),
                        CMTimeGetSeconds([(NSValue *)conf[@"inner_time_range"] CMTimeRangeValue].start),
                        CMTimeGetSeconds([(NSValue *)conf[@"inner_time_range"] CMTimeRangeValue].duration)
              );
    }

    processed = [self insertMissingVideoTracks:processed maxDuration:maxDuration];
    
    return processed;
}

-(NSMutableArray *)insertMissingVideoTracks: (NSArray *)tracks maxDuration: (CMTime) maxDuration
{
    NSMutableArray *tracksFull = [[NSMutableArray alloc] init];
    
    NSDictionary *currentTrack = nil;
    for (NSDictionary *track in tracks) {
        if (currentTrack == nil) {
            currentTrack = track;
            [tracksFull addObject:track];
            continue;
        }
        
        CMTime lastEnd = [(NSValue *)currentTrack[@"flat_end"] CMTimeValue];
        CMTime curStart = [(NSValue *)track[@"flat_start"] CMTimeValue];
        
        if (CMTimeCompare(lastEnd, curStart) == -1) {
            NSLog(@"inserted track %f, %f", CMTimeGetSeconds(lastEnd), CMTimeGetSeconds(curStart));
            
            [tracksFull addObject:@{
             @"URL": [[NSBundle mainBundle] URLForResource:@"blank" withExtension:@"m4v"],
             @"flat_start": [NSValue valueWithCMTime: lastEnd],
             @"flat_end": [NSValue valueWithCMTime: curStart],
             @"inner_time_range": [NSValue valueWithCMTimeRange:CMTimeRangeMake(kCMTimeZero, CMTimeSubtract(curStart, lastEnd))]
             }];
        }
        
        currentTrack = track;
        [tracksFull addObject:track];
        
    }
    
    return tracksFull;
}

-(NSArray *)getProcessedAudioTracks: (NSArray *)tracks
{
    NSMutableArray *processed = [[NSMutableArray alloc] init];
    NSDictionary *conf;

    for (conf in tracks) {
        CMTime start = [(NSValue *)conf[@"absolute_start"] CMTimeValue];
        if (CMTimeCompare(start, kCMTimeZero) == -1) {
            start = kCMTimeZero;
        }
        
        [processed addObject:@{
         @"URL": conf[@"URL"],
         @"flat_start": [NSValue valueWithCMTime: start],
         @"flat_end": conf[@"absolute_end"],
         @"inner_time_range": conf[@"inner_time_range"],
         @"volume": conf[@"volume"]
         }];
    }

    /*
    for (conf in processed) {
        NSLog(@"%f:%f at %f", CMTimeGetSeconds([(NSValue *)conf[@"flat_start"] CMTimeValue]),
                              CMTimeGetSeconds([(NSValue *)conf[@"flat_end"] CMTimeValue]),
                              [(NSNumber *)conf[@"volume"] floatValue]);
    }*/
    
    return processed;
}

-(NSArray *)shiftFlatStartAndEndBack: (NSArray *) tracks amount: (CMTime) amount
{
    NSMutableArray *shiftedTracks = [[NSMutableArray alloc] init];
    
    for (NSDictionary *track in tracks) {
        NSMutableDictionary *shifted = [[NSMutableDictionary alloc] initWithDictionary:track];
        CMTime start = [(NSValue *)shifted[@"flat_start"] CMTimeValue];
        CMTime end = [(NSValue *)shifted[@"flat_end"] CMTimeValue];
        start = CMTimeSubtract(start, amount);
        end = CMTimeSubtract(end, amount);
        
        [shifted setValue:[NSValue valueWithCMTime:start] forKey:@"flat_start"];
        [shifted setValue:[NSValue valueWithCMTime:end] forKey:@"flat_end"];
        
        [shiftedTracks addObject:shifted];
    }
    
    return shiftedTracks;
}

-(NSArray *)getSimplifiedSortedTracks: (NSArray *)tracks withTime: (CMTime) maxDuration
{
    NSMutableArray *processed = [[NSMutableArray alloc] init];
    NSDictionary *conf;
    NSMutableDictionary *newConf;
    
    CMTime start;
    CMTimeRange inner_time_range;
    CMTime inner_start;
    CMTime inner_range_duration;
    CMTime inner_duration;
    CMTime end;
    
    int compare;

    /*
    CMTime maxDur = kCMTimeZero;
    for (conf in tracks) {
        CMTime outerDur = [(NSValue *)conf[@"outer_duration"] CMTimeValue];
        if (CMTimeCompare(maxDur, kCMTimeZero) == 0 || CMTimeCompare(outerDur, maxDur) == 1) {
            maxDur = outerDur;
        }
    }*/
    
    for (conf in tracks) {
        newConf = [[NSMutableDictionary alloc] init];
        [newConf setValue:conf[@"URL"] forKey:@"URL"];
        [newConf setValue:conf[@"volume"] forKey:@"volume"];
        
        start = [(NSValue *)conf[@"start"] CMTimeValue];
        inner_time_range = [(NSValue *)conf[@"inner_time_range"] CMTimeRangeValue];
        inner_range_duration = inner_time_range.duration;
        inner_start = inner_time_range.start;
        inner_duration = [(NSValue *)conf[@"inner_duration"] CMTimeValue];
        
        compare = CMTimeCompare(start, kCMTimeZero);
        
        if (compare == -1) {
            inner_start = CMTimeAdd(CMTimeMake(start.value * -1, start.timescale), inner_start);
            inner_duration = CMTimeSubtract(inner_duration, start);
            start = kCMTimeZero;
        }
        
        end = CMTimeAdd(start, inner_range_duration);
        
        compare = CMTimeCompare(start, end);
        
        // start less than end
        if (compare == -1) {
            compare = CMTimeCompare(end, maxDuration);

            // end < maxDuration
            if (compare == 1) {
                end = maxDuration;
                inner_range_duration = CMTimeSubtract(end, start);
            }
            
            compare = CMTimeCompare(inner_range_duration, kCMTimeZero);
            
            // inner_range_duration > 0
            if (compare != 1) {
                continue;
            }
            
            compare = CMTimeCompare(start, end);
             
            // final comparison since end may have changed
            if (compare == -1) {
                [newConf setValue:[NSValue valueWithCMTime:start] forKey:@"absolute_start"];
                [newConf setValue:[NSValue valueWithCMTime:end] forKey:@"absolute_end"];
                [newConf setValue:[NSValue valueWithCMTimeRange:CMTimeRangeMake(inner_start, inner_range_duration)] forKey:@"inner_time_range"];
                [newConf setValue:conf[@"outer_duration"] forKey:@"outer_duration"];
                [newConf setValue:conf[@"layer_index"] forKey:@"layer_index"];
                [newConf setValue:conf[@"volume"] forKey:@"volume"];

                [processed addObject:newConf];
            }
        }

    }
    
    NSArray *sorted = [processed sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
        NSDictionary *dict1 = (NSDictionary *)a;
        NSDictionary *dict2 = (NSDictionary *)b;
        
        CMTime start1 = [(NSValue *)dict1[@"absolute_start"] CMTimeValue];
        CMTime start2 = [(NSValue *)dict2[@"absolute_start"] CMTimeValue];
        int com = CMTimeCompare(start1, start2);
        
        if (com == -1) {
            return NSOrderedAscending;
        } else if (com == 1) {
            return NSOrderedDescending;
        }
        return NSOrderedSame;
    }];
    
    processed = [[NSMutableArray alloc] initWithArray:sorted];
    
    return processed;

}

-(void)setupComposition: (NSArray *)compositionItems
           withDuration: (CMTime)maxDuration
   withNotificationName: (NSString *)notificationName;

{
    self.rawCompositionItems = compositionItems;
    
    NSArray *simplifiedTracks = [self getSimplifiedSortedTracks:compositionItems withTime:maxDuration];
    NSArray *processedVideoTracks = [self getProcessedVideoTracks:simplifiedTracks withTime:maxDuration];
    NSArray *processedAudioTracks = [self getProcessedAudioTracks:simplifiedTracks];
    
    if ([processedVideoTracks count] > 0) {
        CMTime start = [(NSValue *)((NSDictionary *)processedVideoTracks[0])[@"flat_start"] CMTimeValue];
        if (CMTimeCompare(start, kCMTimeZero) == 1) {
            processedVideoTracks = [self shiftFlatStartAndEndBack:processedVideoTracks amount:start];
            processedAudioTracks = [self shiftFlatStartAndEndBack:processedAudioTracks amount:start];
        }
    }
    
    self.processedVideoTracks = processedVideoTracks;
    self.processedAudioTracks = processedAudioTracks;
    
    AVMutableComposition *mutableComposition = [AVMutableComposition composition];
    AVMutableAudioMix *mutableAudioMix = [AVMutableAudioMix audioMix];
    AVMutableVideoComposition *mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    
    mutableVideoComposition.renderSize = CGSizeMake(MainVideoDim, MainVideoDim);
    mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    
	AVAsset *videoAsset;
    AVAssetTrack *assetAudioTrack;
	AVAssetTrack *assetVideoTrack;
    
    NSMutableArray *videoInstructions = [[NSMutableArray alloc] init];
    NSMutableArray *audioMixParams = [[NSMutableArray alloc] init];
    
    CMTime startTime;
    CMTime endTime;
    CMTimeRange innerRange;
    float volume;
    
	NSError *error = nil;
    
    // MUST START AT ZERO
    
    AVMutableCompositionTrack *compositionVideoTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                                       preferredTrackID:kCMPersistentTrackID_Invalid];
    
	AVMutableVideoCompositionInstruction *instruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
	AVMutableVideoCompositionLayerInstruction *layerInstruction = [AVMutableVideoCompositionLayerInstruction
                                                                   videoCompositionLayerInstructionWithAssetTrack:compositionVideoTrack];
    CGAffineTransform t1;
	CGAffineTransform t2;

    for (NSDictionary *config in processedVideoTracks) {
        assetVideoTrack = nil;
        error = nil;
        
        videoAsset = [[AVURLAsset alloc] initWithURL:config[@"URL"] options:nil];
        
        if ([[videoAsset tracksWithMediaType:AVMediaTypeVideo] count] != 0)
            assetVideoTrack = [videoAsset tracksWithMediaType:AVMediaTypeVideo][0];
        
        startTime = [(NSValue *)config[@"flat_start"] CMTimeValue];
        innerRange = [(NSValue *)config[@"inner_time_range"] CMTimeRangeValue];
        
		if (assetVideoTrack != nil)
			[compositionVideoTrack insertTimeRange:innerRange ofTrack:assetVideoTrack atTime:startTime error:&error];
        
        // or http://stackoverflow.com/questions/4627940/how-to-detect-iphone-sdk-if-a-video-file-was-recorded-in-portrait-orientation/6046421#6046421
        CGAffineTransform txf = assetVideoTrack.preferredTransform;
        CGFloat videoAngleInRads = atan2(txf.b, txf.a);
        CGFloat videoAngleInDegrees = videoAngleInRads * 180 / M_PI;
        
        CGFloat trackW = assetVideoTrack.naturalSize.width;
        CGFloat trackH = assetVideoTrack.naturalSize.height;
        
        if (videoAngleInDegrees == 90.0) {
            // assuming comes from camera
            t1 = CGAffineTransformMakeTranslation(trackH, (MainVideoDim - trackW) / 2);
            t2 = CGAffineTransformRotate(t1, videoAngleInRads);
        } else {
            CGFloat widthRatio = trackW / MainVideoDim;
            CGFloat heightRatio = trackH / MainVideoDim;
            
            if (trackW > trackH) {
                t1 = CGAffineTransformMakeTranslation((MainVideoDim - (trackW / heightRatio)) / 2, 0);
                t2 = CGAffineTransformScale(t1, 1 / heightRatio, 1 / heightRatio);
            } else if (trackH > trackW) {
                t1 = CGAffineTransformMakeTranslation((MainVideoDim - (trackH / widthRatio)) / 2, 0);
                t2 = CGAffineTransformScale(t1, 1 / widthRatio, 1 / widthRatio);
            } else {
                t2 = CGAffineTransformMakeScale(heightRatio, heightRatio);
            }
        }
        
        [layerInstruction setTransform:t2 atTime:startTime];
        
        if (error) NSLog(@"Ups. Something went wrong (video)! %@", [error debugDescription]);
        
    }
    
    [instruction setLayerInstructions:@[layerInstruction]];
    [instruction setTimeRange:compositionVideoTrack.timeRange];

    for (NSDictionary *config in processedAudioTracks) {
        assetAudioTrack = nil;
        error = nil;
        
        videoAsset = [[AVURLAsset alloc] initWithURL:config[@"URL"] options:nil];
        
        if ([[videoAsset tracksWithMediaType:AVMediaTypeAudio] count] != 0)
            assetAudioTrack = [videoAsset tracksWithMediaType:AVMediaTypeAudio][0];
        
        startTime = [(NSValue *)config[@"flat_start"] CMTimeValue];
        endTime = [(NSValue *)config[@"flat_end"] CMTimeValue];
        innerRange = [(NSValue *)config[@"inner_time_range"] CMTimeRangeValue];
        volume = [(NSNumber *)config[@"volume"] floatValue];
        
		if (assetAudioTrack != nil) {
            AVMutableCompositionTrack *customAudioTrack = [mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
            [customAudioTrack insertTimeRange:innerRange ofTrack:assetAudioTrack atTime:startTime error:&error];
            
            AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:customAudioTrack];
            [mixParameters setVolume:volume atTime:innerRange.start];
            
            [audioMixParams addObject:mixParameters];
        }
        
        if (error) NSLog(@"Ups. Something went wrong (audio)! %@", [error debugDescription]);        
    }
    
    mutableAudioMix.inputParameters = audioMixParams;
    mutableVideoComposition.instructions = @[instruction];
    
    self.mutableAudioMix = mutableAudioMix;
    self.mutableVideoComposition = mutableVideoComposition;
    self.mutableComposition = mutableComposition;
    
    /* final step */
  	[[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:self];
    
}

-(NSSet *)getAllTrackURLs
{
    if (!self.processedAudioTracks || !self.processedVideoTracks)
        return [[NSSet alloc] init];
    
    NSMutableSet *tracks = [[NSMutableSet alloc] init];
    NSDictionary *track;
    
    for (track in self.processedAudioTracks) 
        [tracks addObject: track[@"URL"]];
    
    for (track in self.processedVideoTracks)
        [tracks addObject: track[@"URL"]];
    
    for (NSURL *u in tracks)
        NSLog(@"%@", u);
    
    return tracks;
}

- (void)exportComposition
{
    // step1
    NSURL *outputURL = [PLYUtilities tempFileURL: @"mov"];
    
	// Step 2
	// Create an export session with the composition and write the exported movie to the photo library
	AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:[self.mutableComposition copy] presetName:AVAssetExportPresetMediumQuality];
    
	exportSession.videoComposition = self.mutableVideoComposition;
	exportSession.audioMix = self.mutableAudioMix;
	exportSession.outputURL = outputURL;
	exportSession.outputFileType=AVFileTypeQuickTimeMovie;
    
	[exportSession exportAsynchronouslyWithCompletionHandler:^(void){
		switch (exportSession.status) {
			case AVAssetExportSessionStatusCompleted:
				[[NSNotificationCenter defaultCenter]
				 postNotificationName:PLYExportCommandCompletionNotification
                 object:@{
                    @"composer": self,
                    @"exportSession": exportSession
                 }];
				break;
			case AVAssetExportSessionStatusFailed:
				NSLog(@"Failed:%@", exportSession.error);
				break;
			case AVAssetExportSessionStatusCancelled:
				NSLog(@"Canceled:%@", exportSession.error);
				break;
			default:
				break;
		}
	}];
}

- (void)writeVideoToPhotoLibrary:(NSURL *)url
{
	ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
	
	[library writeVideoAtPathToSavedPhotosAlbum:url completionBlock:^(NSURL *assetURL, NSError *error){
		if (error) {
			NSLog(@"Video could not be saved");
		}
	}];
}

@end
