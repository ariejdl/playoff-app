//
//  PLYUtilities.m
//  Playoff
//
//  Created by Arie Lakeman on 12/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#include <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#include <objc/runtime.h>

#import "PLYUtilities.h"
#import "PLYTheme.h"

#import "MHPrettyDate.h"

@implementation PLYUtilities

+(BOOL) validEmail:(NSString *)checkString;
{
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:checkString];
}

+ (NSURL *) tempFileURL: (NSString *) extension
{
    NSString *fileName = [[NSString alloc] initWithFormat: @"%@_output.%@", [[NSUUID UUID] UUIDString], extension, nil];
    NSString *outputPath = [[NSString alloc] initWithFormat:@"%@%@", NSTemporaryDirectory(), fileName];
    NSURL *outputURL = [[NSURL alloc] initFileURLWithPath:outputPath];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:outputPath]) {
        NSError *error;
        if ([fileManager removeItemAtPath:outputPath error:&error] == NO) {
            if (error) {
            }
        }
    }
    return outputURL;
}

+(NSString *)getUUID
{
    return [[NSProcessInfo processInfo] globallyUniqueString];
}

+(NSString *)modelUUID
{
    CFUUIDRef uuid = CFUUIDCreate(CFAllocatorGetDefault());
    return (__bridge_transfer NSString *)CFUUIDCreateString(CFAllocatorGetDefault(), uuid);
}

// e.g.
//    UIView *loading = [PLYUtilities getLoader];
//    [self.navigationController.view addSubview:loading];
+(UIView *) getLoader
{
    UIView *loading = [[UIView alloc] initWithFrame:CGRectMake(100, 200, 120, 120)];
    
    loading.layer.cornerRadius = 4;
    loading.opaque = NO;
    loading.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.6f];
    
    UIActivityIndicatorView *spinning = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    spinning.frame = CGRectMake(42, 30, 37, 37);
    [loading addSubview:spinning];
//    [spinning startAnimating];
    
    UILabel *loadLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 80, 81, 22)];
    loadLabel.text = @"loading...";
    loadLabel.font = [UIFont fontWithName:[PLYTheme boldDefaultFontName] size:18];
    loadLabel.textAlignment = NSTextAlignmentCenter;
    loadLabel.textColor = [UIColor colorWithWhite:1.0f alpha:1.0f];
    loadLabel.backgroundColor = [UIColor clearColor];
//    loadLabel.shadowOffset = CGSizeMake(0, -1);
//    loadLabel.shadowColor = [UIColor blackColor];
    
    [loading addSubview:loadLabel];
    
    loading.frame = CGRectMake(100, 200, 120, 120);
    
    return loading;
}

+(void) setupCommentsLabel: (UILabel *) label
                  comments: (NSArray *) rawComments
                     frame: (CGRect) rect;
{
    
    NSMutableArray *comments = [[NSMutableArray alloc] init];
    for (NSDictionary *c in rawComments) {
        if ([(NSString *)c[@"body"] length] > 0) {
            [comments addObject:c];
        }
    }
    
    NSMutableString *commentsString = [[NSMutableString alloc] init];
    NSDictionary *comment;
    for (int i = 0;i < [comments count];i++) {
        comment = [comments objectAtIndex:i];
        
        [commentsString appendString:[PLYUtilities usernameFromOwner: comment[@"user"]]];
        [commentsString appendString:@" "];
        [commentsString appendString:comment[@"body"]];
        
        if (i < [comments count] - 1)
            [commentsString appendString:@"\n"];
    }
    
    CGFloat currentIndex = 0;
    NSMutableAttributedString *attrCommentsString = [[NSMutableAttributedString alloc]
                                                     initWithString:commentsString];
    
    
    for (NSDictionary *comment in comments) {
        [attrCommentsString setAttributes: @{
           NSForegroundColorAttributeName: [PLYTheme primaryColor],
                      NSFontAttributeName: [UIFont fontWithName:[PLYTheme boldDefaultFontName] size:14]
         } range: NSMakeRange(currentIndex, [ [PLYUtilities usernameFromOwner:comment[@"user"]] length] + 1)];
        
        currentIndex += ([comment[@"user"] length] + [comment[@"body"] length] + 2);
    }
    
    [label setFrame:rect];
    [label setAttributedText:attrCommentsString];
    [label sizeToFit];
}

+(NSString *) millisToPrettyTime: (double) millis
{
    return [MHPrettyDate prettyDateFromDate:[NSDate dateWithTimeIntervalSince1970: millis / 1000]
                                 withFormat:MHPrettyDateShortRelativeTime];
}

+(NSDictionary *)toDict:(NSManagedObject *) managedObj
{
    unsigned int count;
    objc_property_t *properties = class_copyPropertyList([managedObj class], &count);
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionaryWithCapacity:16];
    
    for(int i = 0; i < count; i++) {
        objc_property_t property = properties[i];
        NSString *name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        id obj = [managedObj valueForKey:name];
        if (obj) {
            // Skip properties with nil values (optionally you can use: [dictionary setObject:((obj == nil) ? [NSNull null] : obj) forKey:name]; without any if-statement)
            [dictionary setObject:obj forKey:name];
        }
    }
    
    return dictionary;
}

+(NSDictionary *) deserialiseAncillaryTrack:(NSDictionary *)track
{
    NSMutableDictionary *copiedTrack = [[NSMutableDictionary alloc] init];
    
    [copiedTrack setValue:track[@"volume"] forKey:@"volume"];
    if ([track valueForKey:@"URL"]) [copiedTrack setValue:[[NSURL alloc] initWithString:(NSString *)track[@"URL"]] forKey:@"URL"];
    
    [copiedTrack setValue: [NSValue valueWithCMTime: CMTimeMake([(NSNumber *)[track valueForKey:@"globalStart"] longLongValue],
                                                                [(NSNumber *)[track valueForKey:@"globalStartTimescale"] longValue])] forKey:@"start"];
    
    [copiedTrack setValue: [NSValue valueWithCMTimeRange:CMTimeRangeMake(
                                                                         CMTimeMake([(NSNumber *)[track valueForKey:@"innerTimeRangeStart"] longLongValue],
                                                                                    [(NSNumber *)[track valueForKey:@"innerTimeRangeStartTimescale"] longLongValue]),
                                                                         CMTimeMake([(NSNumber *)[track valueForKey:@"innerTimeRangeDur"] longLongValue],
                                                                                    [(NSNumber *)[track valueForKey:@"innerTimeRangeDurTimescale"] longLongValue]))]
                   forKey:@"inner_time_range"];
    
    [copiedTrack setValue: [NSValue valueWithCMTime: CMTimeMake([(NSNumber *)[track valueForKey:@"innerDuration"] longLongValue],
                                                                [(NSNumber *)[track valueForKey:@"innerDurationTimescale"] longValue])] forKey:@"inner_duration"];
    
    [copiedTrack setValue: [NSValue valueWithCMTime: CMTimeMake([(NSNumber *)[track valueForKey:@"outerDuration"] longLongValue],
                                                                [(NSNumber *)[track valueForKey:@"outerDurationTimescale"] longValue])] forKey:@"outer_duration"];
    return track;
}

+(void) videoAssetURLToTempFile:(NSURL*)url completion: (void (^)(BOOL, NSURL *, NSError *)) completion
{
    NSString * surl = [url absoluteString];
    NSString * ext = [surl substringFromIndex:[surl rangeOfString:@"ext="].location + 4];
    NSTimeInterval ti = [[NSDate date]timeIntervalSinceReferenceDate];
    NSString * filename = [NSString stringWithFormat: @"%f.%@",ti,ext];
    NSString * tmpfile = [NSTemporaryDirectory() stringByAppendingPathComponent:filename];
    
    ALAssetsLibraryAssetForURLResultBlock resultblock = ^(ALAsset *myasset)
    {
        
        ALAssetRepresentation * rep = [myasset defaultRepresentation];
        
        NSUInteger size = [rep size];
        const int bufferSize = 8192;
        
        FILE* f = fopen([tmpfile cStringUsingEncoding:1], "wb+");
        if (f == NULL) {
            return;
        }
        
        Byte * buffer = (Byte*)malloc(bufferSize);
        int read = 0, offset = 0, written = 0;
        NSError* err;
        if (size != 0) {
            do {
                read = [rep getBytes:buffer
                          fromOffset:offset
                              length:bufferSize
                               error:&err];
                written = fwrite(buffer, sizeof(char), read, f);
                offset += read;
            } while (read != 0);
            
            
        }
        fclose(f);

        completion(YES, [NSURL fileURLWithPath:tmpfile], nil);
    };
    
    
    ALAssetsLibraryAccessFailureBlock failureblock  = ^(NSError *myerror)
    {
        completion(NO, nil, nil);
    };
    
    if(url)
    {
        ALAssetsLibrary* assetslibrary = [[ALAssetsLibrary alloc] init];
        [assetslibrary assetForURL:url
                       resultBlock:resultblock
                      failureBlock:failureblock];
    }
}


+(NSString *) usernameFromOwner: (NSString *) owner
{
    return [[owner componentsSeparatedByString:@"/"] lastObject];
}

+(NSString *) getPlayoffURL { return @"http://www.getPlayoff.com"; }
+(NSString *) getPlayoffShareURL: (NSString *) playoffId {
    return [[NSString alloc] initWithFormat:@"%@/#!/view/%@", [PLYUtilities getPlayoffURL], playoffId, nil];
}

@end
