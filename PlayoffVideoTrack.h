//
//  PlayoffVideoTrack.h
//  Playoff
//
//  Created by Arie Lakeman on 04/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlayoffItem;

@interface PlayoffVideoTrack : NSManagedObject

@property (nonatomic, retain) NSNumber * globalStart;
@property (nonatomic, retain) NSNumber * globalStartTimescale;
@property (nonatomic, retain) NSNumber * innerDuration;
@property (nonatomic, retain) NSNumber * innerDurationTimescale;
@property (nonatomic, retain) NSNumber * innerTimeRangeDur;
@property (nonatomic, retain) NSNumber * innerTimeRangeDurTimescale;
@property (nonatomic, retain) NSNumber * innerTimeRangeStart;
@property (nonatomic, retain) NSNumber * innerTimeRangeStartTimescale;
@property (nonatomic, retain) NSNumber * layerPosition;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * outerDuration;
@property (nonatomic, retain) NSNumber * outerDurationTimescale;
@property (nonatomic, retain) NSString * playoffVideoId;
@property (nonatomic, retain) NSString * playoffvideotrack_id;
@property (nonatomic, retain) NSString * videoHash;
@property (nonatomic, retain) NSNumber * volume;
@property (nonatomic, retain) NSString * payload_url;
@property (nonatomic, retain) PlayoffItem *playoff;

@end
