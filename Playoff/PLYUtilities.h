//
//  PLYUtilities.h
//  Playoff
//
//  Created by Arie Lakeman on 12/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface PLYUtilities : NSObject

+(BOOL) validEmail:(NSString *)string;
+(NSURL *) tempFileURL: (NSString *) extension;
+(NSString *)getUUID;
+(NSString *) modelUUID;
+(UIView *) getLoader;
+(void) setupCommentsLabel: (UILabel *)label comments: (NSArray *)comments frame: (CGRect) rect;
+(NSString *) millisToPrettyTime: (double) millis;
+(NSDictionary *)toDict:(NSManagedObject *) managedObj;
+(NSDictionary *)deserialiseAncillaryTrack:(NSDictionary *)ancillaryTrack;
+(void) videoAssetURLToTempFile:(NSURL*)url completion: (void (^)(BOOL, NSURL *, NSError *)) completion;
+(NSString *) usernameFromOwner: (NSString *) owner;
+(NSString *) getPlayoffURL;
+(NSString *) getPlayoffShareURL: (NSString *) playoffId;

@end
