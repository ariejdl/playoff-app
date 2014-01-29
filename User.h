//
//  User.h
//  Playoff
//
//  Created by Arie Lakeman on 15/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import <SMUserManagedObject.h>

@class PlayoffComment, PlayoffItem, User;

@interface User : SMUserManagedObject

@property (nonatomic, retain) NSString * email;
@property (nonatomic, retain) NSString * password;
@property (nonatomic, retain) NSNumber * superuser;
@property (nonatomic, retain) NSString * username;
@property (nonatomic, retain) NSString * profile_image;
@property (nonatomic, retain) NSSet *playoffComment;
@property (nonatomic, retain) NSSet *likes;
@property (nonatomic, retain) NSSet *following;
@property (nonatomic, retain) NSSet *followers;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addPlayoffCommentObject:(PlayoffComment *)value;
- (void)removePlayoffCommentObject:(PlayoffComment *)value;
- (void)addPlayoffComment:(NSSet *)values;
- (void)removePlayoffComment:(NSSet *)values;

- (void)addLikesObject:(PlayoffItem *)value;
- (void)removeLikesObject:(PlayoffItem *)value;
- (void)addLikes:(NSSet *)values;
- (void)removeLikes:(NSSet *)values;

- (void)addFollowingObject:(User *)value;
- (void)removeFollowingObject:(User *)value;
- (void)addFollowing:(NSSet *)values;
- (void)removeFollowing:(NSSet *)values;

- (void)addFollowersObject:(User *)value;
- (void)removeFollowersObject:(User *)value;
- (void)addFollowers:(NSSet *)values;
- (void)removeFollowers:(NSSet *)values;

@end
