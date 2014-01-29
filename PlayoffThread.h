//
//  PlayoffThread.h
//  Playoff
//
//  Created by Arie Lakeman on 11/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlayoffItem;

@interface PlayoffThread : NSManagedObject

@property (nonatomic, retain) NSNumber * approved_for_sharing;
@property (nonatomic, retain) NSNumber * likes_count;
@property (nonatomic, retain) NSString * playoffthread_id;
@property (nonatomic, retain) NSString * popular1;
@property (nonatomic, retain) NSString * popular2;
@property (nonatomic, retain) NSString * popular3;
@property (nonatomic, retain) NSManagedObject *curated_item;
@property (nonatomic, retain) NSSet *most_popular1;
@property (nonatomic, retain) NSSet *most_popular2;
@property (nonatomic, retain) NSSet *most_popular3;
@property (nonatomic, retain) NSSet *playoffs;
@end

@interface PlayoffThread (CoreDataGeneratedAccessors)

- (void)addMost_popular1Object:(PlayoffItem *)value;
- (void)removeMost_popular1Object:(PlayoffItem *)value;
- (void)addMost_popular1:(NSSet *)values;
- (void)removeMost_popular1:(NSSet *)values;

- (void)addMost_popular2Object:(PlayoffItem *)value;
- (void)removeMost_popular2Object:(PlayoffItem *)value;
- (void)addMost_popular2:(NSSet *)values;
- (void)removeMost_popular2:(NSSet *)values;

- (void)addMost_popular3Object:(PlayoffItem *)value;
- (void)removeMost_popular3Object:(PlayoffItem *)value;
- (void)addMost_popular3:(NSSet *)values;
- (void)removeMost_popular3:(NSSet *)values;

- (void)addPlayoffsObject:(PlayoffItem *)value;
- (void)removePlayoffsObject:(PlayoffItem *)value;
- (void)addPlayoffs:(NSSet *)values;
- (void)removePlayoffs:(NSSet *)values;

@end
