//
//  PlayoffItem.h
//  Playoff
//
//  Created by Arie Lakeman on 04/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlayoffComment, PlayoffThread, PlayoffVideoTrack, User;

@interface PlayoffItem : NSManagedObject

@property (nonatomic, retain) NSNumber * approved_for_sharing;
@property (nonatomic, retain) NSString * caption;
@property (nonatomic, retain) NSDate * createddate;
@property (nonatomic, retain) NSNumber * flagged_count;
@property (nonatomic, retain) NSString * imageId;
@property (nonatomic, retain) NSNumber * likes_count;
@property (nonatomic, retain) NSString * playoffitem_id;
@property (nonatomic, retain) NSString * thread_id;
@property (nonatomic, retain) NSString * thumbnail1;
@property (nonatomic, retain) NSString * thumbnail2;
@property (nonatomic, retain) NSString * thumbnail3;
@property (nonatomic, retain) NSString * videoId;
@property (nonatomic, retain) NSNumber * hasAncillaryVideos;
@property (nonatomic, retain) NSNumber * isVideo;
@property (nonatomic, retain) NSString * payload_url;
@property (nonatomic, retain) NSSet *comments;
@property (nonatomic, retain) NSSet *likers;
@property (nonatomic, retain) PlayoffThread *thread;
@property (nonatomic, retain) NSSet *tracks;
@end

@interface PlayoffItem (CoreDataGeneratedAccessors)

- (void)addCommentsObject:(PlayoffComment *)value;
- (void)removeCommentsObject:(PlayoffComment *)value;
- (void)addComments:(NSSet *)values;
- (void)removeComments:(NSSet *)values;

- (void)addLikersObject:(User *)value;
- (void)removeLikersObject:(User *)value;
- (void)addLikers:(NSSet *)values;
- (void)removeLikers:(NSSet *)values;

- (void)addTracksObject:(PlayoffVideoTrack *)value;
- (void)removeTracksObject:(PlayoffVideoTrack *)value;
- (void)addTracks:(NSSet *)values;
- (void)removeTracks:(NSSet *)values;

@end
