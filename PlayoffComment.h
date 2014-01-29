//
//  PlayoffComment.h
//  Playoff
//
//  Created by Arie Lakeman on 05/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class PlayoffItem, User;

@interface PlayoffComment : NSManagedObject

@property (nonatomic, retain) NSString * body;
@property (nonatomic, retain) NSString * playoffcomment_id;
@property (nonatomic, retain) NSString * playoff_item_id;
@property (nonatomic, retain) User *user;
@property (nonatomic, retain) PlayoffItem *playoff;
@property (nonatomic, retain) NSDate *createddate;

@end
