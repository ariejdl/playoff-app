//
//  PLYAppDelegate.m
//  Playoff
//
//  Created by Arie Lakeman on 28/04/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Parse/Parse.h>
#import <ASIHTTPRequest.h>
#import <ASIS3ObjectRequest.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "PLYAppDelegate.h"

#import "PLYHTTPClient.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"

#include "FileMD5Hash.h"

#import "PlayoffThread.h"
#import "PlayoffItem.h"
#import "PlayoffVideoTrack.h"
#import "User.h"

#import "PLYCustomTabBarController.h"
#import "PLYVideoMixerCell.h"
#import "PLYUploadProgressView.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "FileMD5Hash.h"

#import <ASIHTTPRequest.h>

#define CHUNK_SIZE_KB 500

NSString* const PLYPendingUploadDirectory = @"pendingUploads";
NSString* const PLYCacheDirectory = @"cachedDownloads";
NSString* const PLYThirdPartyVideoDirectory = @"thirdPartyVideos";

float const MainVideoDim = 360;

NSString* const emptyPlayoffThreadId = @"no_playoff_thread";

@implementation UIImage (Crop)

- (UIImage *)crop:(CGRect)rect {
    
    rect = CGRectMake(rect.origin.x*self.scale,
                      rect.origin.y*self.scale,
                      rect.size.width*self.scale,
                      rect.size.height*self.scale);
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([self CGImage], rect);
    UIImage *result = [UIImage imageWithCGImage:imageRef
                                          scale:self.scale
                                    orientation:self.imageOrientation];
    CGImageRelease(imageRef);
    return result;
}

@end

@implementation PLYAppDelegate


@synthesize loginViewController = _loginViewController;
@synthesize client = _client;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize coreDataStore = _coreDataStore;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self customizeAppearance];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults boolForKey:@"hasUsedFacebook"]) {
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            [self openSessionWithCanShowError:NO stateOpenBlock:^{} stateClosedBlock:^{}];
        }
    }
    
    NSDate *lastClearedCache = [defaults valueForKey:@"lastClearedCache"];
    if (lastClearedCache != nil) {
        /* delete all cached stuff */
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        NSDate *lastClearedCache = [defaults valueForKey:@"lastClearedCache"];
        NSDate *currentDate = [NSDate date];
        NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
        [dateComponents setDay:-5];
        NSDate *compareDate = [[NSCalendar currentCalendar] dateByAddingComponents:dateComponents toDate:currentDate options:0];
        
        if ([lastClearedCache compare:compareDate] == NSOrderedAscending)
            [self clearTmpDirectory];
    }
    
    [defaults setValue:[NSDate date] forKey:@"lastLogin"];
    
    [self checkAndCreateDefaultDirectories];
    
    NSBundle *mb = [NSBundle mainBundle];
    
//    self.client = [[SMClient alloc] initWithAPIVersion:@"0" publicKey:[mb objectForInfoDictionaryKey:@"StackMobPublicKey"]];
    self.client = [[SMClient alloc] initWithAPIVersion:@"1" publicKey:[mb objectForInfoDictionaryKey:@"StackMobPublicKeyProd"]];
    self.managedObjectModel = [self managedObjectModel];
    self.coreDataStore = [self.client coreDataStoreWithManagedObjectModel:self.managedObjectModel]; 

    /* end defaults */
    
    BOOL isLoggedIn = [self.client isLoggedIn];
//    BOOL isLoggedIn = NO;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    if (!isLoggedIn) {
        [self presentLogin: NO];
    } else {
        [self setupMainTabBar];
    }
    
    [self.window makeKeyAndVisible];
    
    [self setupReachabilityMonitor];

    return YES;
}
             
-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] cleanDisk];
    [[SDImageCache sharedImageCache] clearDisk];
}

- (void)customizeAppearance
{
    /* some defaults */
    [[UINavigationBar appearance] setBackgroundImage:[UIImage imageNamed:@"navigation-bar-1.png"] forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    [[UITabBar appearance] setBackgroundImage:[[UIImage alloc] init]];
    [[UITabBar appearance] setShadowImage:[[UIImage alloc] init]];
    
    [[UIButton appearance] setFont:[PLYTheme mediumDefaultFont]];
    [[UILabel appearance] setFont:[PLYTheme mediumDefaultFont]];
    [[UINavigationBar appearance] setTitleTextAttributes:
     @{UITextAttributeFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]],
                         UITextAttributeTextShadowColor : [UIColor clearColor],
                         UITextAttributeTextShadowOffset: [NSValue valueWithUIOffset:UIOffsetMake(0,0)],
     }];
    
    [[UIToolbar appearance] setBackgroundImage:[[UIImage alloc] init]
                            forToolbarPosition:UIToolbarPositionAny
                                    barMetrics:UIBarMetricsDefault];
    
    [[UIToolbar appearance] setBackgroundColor:[PLYTheme backgroundMediumColor]];
    [[UIToolbar appearance] setShadowImage:[[UIImage alloc] init] forToolbarPosition:UIToolbarPositionAny];
    
    [[UISwitch appearance] setOnTintColor:[UIColor colorWithRed:0.337 green:0.451 blue:0.569 alpha:1]];
    
    NSDictionary *attributes = @{ UITextAttributeTextColor:[UIColor whiteColor],
                                  UITextAttributeTextShadowColor:[UIColor clearColor],
                                  UITextAttributeFont: [UIFont fontWithName:[PLYTheme defaultFontName] size:14]};
     
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTitleTextAttributes:attributes forState:UIControlStateHighlighted];
    
    UIImage *bbImage1 = [UIImage imageNamed:@"bar-button-1"];
    bbImage1 = [bbImage1 resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3)];
    UIImage *bbImage2 = [UIImage imageNamed:@"bar-button-high-1"];
    bbImage2 = [bbImage2 resizableImageWithCapInsets:UIEdgeInsetsMake(3, 3, 3, 3)];
    
    [[UIBarButtonItem appearance] setBackgroundImage:bbImage1 forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackgroundImage:bbImage2 forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
    
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:bbImage1 forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
    [[UIBarButtonItem appearance] setBackButtonBackgroundImage:bbImage2 forState:UIControlStateHighlighted barMetrics:UIBarMetricsDefault];
}

-(void)setupMainTabBar
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    PLYCustomTabBarController *mainTabBar = (PLYCustomTabBarController *)[storyboard
                                                                          instantiateViewControllerWithIdentifier:@"MainTabBarIdentifier"];
    
    if ([defaults integerForKey:@"followingFeedItemCount"] < 3) {
        [mainTabBar beginWithExplore];
    }
    
//    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = mainTabBar;
}

-(void)presentLogin: (BOOL) aboveTabBar;
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    UIViewController *loginController = [storyboard instantiateViewControllerWithIdentifier:@"LoginIdentifier"];
    self.loginViewController = loginController;
    
    if (aboveTabBar) {
        [self.window.rootViewController presentViewController:loginController animated:YES completion:^(void){
            self.window.rootViewController = loginController;
        }];
    } else {
        self.window.rootViewController = loginController;
    }
}

-(void)completeUserLogin
{
    if (self.loginViewController) {
        [self setupMainTabBar];
        [self.window.rootViewController presentViewController:self.loginViewController animated:NO completion:^(void){
            [self.loginViewController dismissViewControllerAnimated:YES completion:nil];
            self.loginViewController = nil;
        }];
    }
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"playoff_data_model" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

# pragma mark network change stuff

-(void)setupReachabilityMonitor
{
    // http://stackoverflow.com/questions/15041631/afnetworking-checking-availability
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(networkChangeNotificationFromAFNetworking:)
                                                 name:AFNetworkingReachabilityDidChangeNotification object:nil];

}

- (void)networkChangeNotificationFromAFNetworking:(NSNotification *)notification
{
    self.currentReachabilityStatus = [[[notification userInfo] objectForKey:AFNetworkingReachabilityNotificationStatusItem] intValue];
}

# pragma mark facebook stuff

-(void)openSessionWithCanShowError:(BOOL)canShow
                stateOpenBlock:(void (^)(void))stateOpen
               stateClosedBlock:(void (^)(void))stateClosed
{
    [FBSession openActiveSessionWithReadPermissions:nil
                                       allowLoginUI:YES
                                  completionHandler:^(FBSession *session, FBSessionState status, NSError *error) {
                                      
        [self sessionStateChanged:session state:status error:error canShowError:canShow stateOpenBlock:stateOpen stateClosedBlock:stateClosed];
    }];
}

- (void)sessionStateChanged:(FBSession *)session
                      state:(FBSessionState) state
                      error:(NSError *)error
                      canShowError:(BOOL)canShow
             stateOpenBlock:(void (^)(void))stateOpen
             stateClosedBlock:(void (^)(void))stateClosed
{
    switch (state) {
        case FBSessionStateOpen:
            stateOpen();
            break;
        case FBSessionStateClosed:
            [FBSession.activeSession closeAndClearTokenInformation];
            stateClosed();
            break;
        case FBSessionStateClosedLoginFailed:
            [FBSession.activeSession closeAndClearTokenInformation];
            stateClosed();
            break;
        default:
            break;
    }
    
    if (error) {
        if (canShow) {
            UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"Error"
                                  message:error.localizedDescription
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
            [alertView show];
        }
    }
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    // attempt to extract a token from the url
    return [FBSession.activeSession handleOpenURL:url];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [FBSession.activeSession handleDidBecomeActive];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [FBSession.activeSession close];
    [self clearTmpDirectory];
}

-(void)clearTmpDirectory
{
    [self clearAllUploads];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDate *currentDate = [NSDate date];
    [defaults setValue:currentDate forKey:@"lastClearedCache"];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error;
    NSString *documentsDirectory = NSTemporaryDirectory();
    
    [[SDImageCache sharedImageCache] clearMemory];
    [[SDImageCache sharedImageCache] cleanDisk];
    [[SDImageCache sharedImageCache] clearDisk];
    
    NSArray *dirs = @[PLYPendingUploadDirectory, PLYCacheDirectory, PLYThirdPartyVideoDirectory];
    for (NSString *dir in dirs) {
        NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:dir];
        if ([fileMgr fileExistsAtPath: dataPath]) [fileMgr removeItemAtPath:dataPath error:&error];
    }
    
    /* general clear */
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}


# pragma mark upload persisted playoff info.

-(void)addPlayoffToUserDict: (NSString *)playoffId
               trackingDict: (NSString *) trackingDict
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:trackingDict]];
    item[playoffId] = @TRUE;
    [defaults setValue:item forKey:trackingDict];
}

-(BOOL)playoffInUserDict: (NSString *) playoffId
            trackingDict: (NSString *) trackingDict
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:trackingDict]];
    if ([item valueForKey:playoffId]) {
        return YES;
    } else {
        return NO;
    }
}

-(void)removePlayoffFromUserDict: (NSString *)playoffId
                    trackingDict: (NSString *) trackingDict
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:trackingDict]];
    if ([item valueForKey:playoffId]) {
        [item removeObjectForKey:playoffId];
        [defaults setValue:item forKey:trackingDict];
    }
}

-(void)addUploadToFacebookShare:(NSString *)playoffId
{
    [self addPlayoffToUserDict:playoffId trackingDict:@"uploadsToFacebookShare"];
}

-(void)addUploadToTwitterShare:(NSString *)playoffId
{
    [self addPlayoffToUserDict:playoffId trackingDict:@"uploadsToTwitterShare"];
}

-(void)addUploadToYouTubeShare:(NSString *)playoffId
{
    [self addPlayoffToUserDict:playoffId trackingDict:@"uploadsToYouTubeShare"];
}

-(void)uploadThumbnailsOnly: (NSManagedObjectContext *)managedObjectContext
              playoffThread: (PlayoffThread *) playoffThread
                 thumbnails: (NSArray *) thumbnails
                  playoffId: (NSString *) playoffId
                   callback: (void (^)(BOOL, NSString *, NSError *)) completeCallback
{
    PlayoffItem *playoffItem = [NSEntityDescription insertNewObjectForEntityForName:@"PlayoffItem" inManagedObjectContext:managedObjectContext];
    [playoffItem setValue: playoffId forKey:[playoffItem primaryKeyField]];
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSData *imageData;
    
    if ([thumbnails count] >= 1) {
        imageData = [fileMgr contentsAtPath:thumbnails[0]];
        [playoffItem setValue:[SMBinaryDataConversion stringForBinaryData:imageData name:@"thumb_image_1.png" contentType:@"image/png"]
                       forKey:@"thumbnail1"];
    }
    
    if ([thumbnails count] >= 2) {
        imageData = [fileMgr contentsAtPath:thumbnails[1]];
        [playoffItem setValue:[SMBinaryDataConversion stringForBinaryData:imageData name:@"thumb_image_2.png" contentType:@"image/png"]
                       forKey:@"thumbnail2"];
    }
    
    if ([thumbnails count] >= 3) {
        imageData = [fileMgr contentsAtPath:thumbnails[2]];
        [playoffItem setValue:[SMBinaryDataConversion stringForBinaryData:imageData name:@"thumb_image_3.png" contentType:@"image/png"]
                       forKey:@"thumbnail3"];
    }
    
    [playoffThread addPlayoffsObject:playoffItem];
    
    [managedObjectContext saveOnSuccess:^(void) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        
        completeCallback(YES, playoffId, nil);
    } onFailure:^(NSError *error) {
        completeCallback(NO, nil, error);
    }];
}

-(void)uploadThumbnailImages: (NSString *) playoffThreadId
                   playoffId: (NSString *) playoffId
                  thumbnails: (NSArray *) thumbnails
                    callback: (void (^)(BOOL, NSString *, NSError *)) completeCallback
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];
    
    PlayoffThread *playoffThread;
    if (!playoffThreadId || playoffThreadId == nil) {
        NSString *playoffThreadId = [PLYUtilities modelUUID];
        
        playoffThread = [NSEntityDescription insertNewObjectForEntityForName:@"PlayoffThread" inManagedObjectContext:managedObjectContext];
        [playoffThread setValue: playoffThreadId forKey:[playoffThread primaryKeyField]];
        
        [managedObjectContext saveOnSuccess:^(void) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            NSMutableDictionary *items = [[NSMutableDictionary alloc]
                                          initWithDictionary:(NSDictionary *)[defaults valueForKey:@"serialisedVideosToUpload"]];
            NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[items valueForKey:playoffId]];
            
            [item setValue:playoffThreadId forKey:@"playoffThreadId"];
            [items setValue:item forKey:playoffId];
            [defaults setValue:items forKey:@"serialisedVideosToUpload"];
            
            [self uploadThumbnailsOnly:managedObjectContext
                         playoffThread:playoffThread
                            thumbnails:thumbnails
                             playoffId:playoffId
                              callback:completeCallback];
            
        }onFailure:^(NSError *error) {
            completeCallback(NO, nil, error);
        }];
        
        
    } else {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffthread_id == %@", playoffThreadId]];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffThread" inManagedObjectContext:managedObjectContext]];
        
        [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
            if ([results count] > 0) {
                PlayoffThread *playoffThread = results[0];
                [self uploadThumbnailsOnly:managedObjectContext
                             playoffThread:playoffThread
                                thumbnails:thumbnails
                                 playoffId:playoffId
                                  callback:completeCallback];
            } else {
                completeCallback(NO, nil, nil);
            }
        } onFailure:^(NSError *error) {
            completeCallback(NO, nil, error);
        }];
        
    }
    


}

-(void)uploadChunkedVideoPlayoffItem: (NSString *) playoffThreadId
                           playoffId: (NSString *) playoffId
                           videoPath: (NSString *) videoPath
                    progressDelegate: (id) progressDelegate
                            callback: (void (^)(BOOL, NSString *, NSError *)) completeCallback
{

    NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];

    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id == %@", playoffId]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffItem" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest
     onSuccess:^(NSArray * results) {
         __block PlayoffItem *playoffItem;         
         if ([results count] > 0) {
             playoffItem = results[0];

             [self mainS3Upload:videoPath
               progressDelegate:progressDelegate
                      ancillary:NO
               completeCallback:^(BOOL success, NSString *serverURL, NSError *error) {
                   if (success && !error) {
                       [playoffItem setPayload_url:serverURL];
                       [managedObjectContext saveOnSuccess:^(void) {
                           completeCallback(YES, playoffId, nil);
                       } onFailure:^(NSError *error) {
                           completeCallback(NO, nil, error);
                       }];
                   } else {
                       completeCallback(NO, nil, error);
                   }
               }];
         } else {
             completeCallback(NO, nil, nil);
         }
     } onFailure:^(NSError *error){
     }];

}

-(void)addDeferredUpload: (NSString *)playoffThreadId
               playoffId: (NSString *)playoffId
           mainVideoPath: (NSString *)mainVideoPath
                  tracks: (NSArray *)ancillaryTracks
              thumbnails: (NSArray *)thumbnails
{
    [self moveVideoFilesFromTempDirectory: playoffThreadId
                                playoffId: playoffId
                            mainVideoPath:mainVideoPath
                          ancillaryTracks:ancillaryTracks
                               thumbnails:thumbnails
                        copyToNewLocation:NO];

}

-(PlayoffVideoTrack *)getVideoTrackForConfig: (NSDictionary *)track
                               layerPosition: (int) layerPosition
                                        hash: (NSString *) videoFileMD5Hash
                               objectContext: (NSManagedObjectContext *) managedObjectContext
{
    
    PlayoffVideoTrack *videoTrack = [NSEntityDescription insertNewObjectForEntityForName:@"PlayoffVideoTrack"
                                                                  inManagedObjectContext:managedObjectContext];

    
    [videoTrack setValue:[videoTrack assignObjectId] forKey:[videoTrack primaryKeyField]];
    [videoTrack setValue:videoFileMD5Hash forKey:@"videoHash"];
    [videoTrack setValue: [[NSNumber alloc] initWithInt:layerPosition] forKey:@"layerPosition"];
    [videoTrack setValue:track[@"volume"] forKey:@"volume"];
    
    [videoTrack setValue:track[@"globalStart"] forKey:@"globalStart"];
    [videoTrack setValue:track[@"globalStartTimescale"] forKey:@"globalStartTimescale"];
    [videoTrack setValue:track[@"innerTimeRangeStart"] forKey:@"innerTimeRangeStart"];
    [videoTrack setValue:track[@"innerTimeRangeStartTimescale"] forKey:@"innerTimeRangeStartTimescale"];
    [videoTrack setValue:track[@"innerTimeRangeDur"] forKey:@"innerTimeRangeDur"];
    [videoTrack setValue:track[@"innerTimeRangeDurTimescale"] forKey:@"innerTimeRangeDurTimescale"];
    [videoTrack setValue:track[@"innerDuration"] forKey:@"innerDuration"];
    [videoTrack setValue:track[@"innerDurationTimescale"] forKey:@"innerDurationTimescale"];
    [videoTrack setValue:track[@"outerDuration"] forKey:@"outerDuration"];
    [videoTrack setValue:track[@"outerDurationTimescale"] forKey:@"outerDurationTimescale"];
    [videoTrack setValue:@"" forKey:@"payload_url"];
    
    return videoTrack;
}

-(void)uploadChunkedPlayoffVideoTracksItems: (NSString *) playoffId
                             playoffVideoId: (NSString *) playoffVideoId
                                     tracks: (NSArray *) tracksRaw
                                   overWWAN: (BOOL) overWWAN
                                 uiProgress: (PLYUploadProgressView *) uiProgress
                                   callback: (void (^)(BOOL, NSString *, NSError *)) completeCallback
{
    __block NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];
    __block NSMutableArray *tracks = [[NSMutableArray alloc] initWithArray:[[tracksRaw reverseObjectEnumerator] allObjects]];
    
    __block NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id == %@", playoffVideoId]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffItem" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
        if ([results  count] == 0) {
            completeCallback(NO, nil, nil);
            return;
        }
        
        __block PlayoffItem *videoPlayoff = results[0];
        
        __block int layerPosition = 1;
        __block NSDictionary *track;
        
        const int trackCount = [tracks count];
        
        __block void (^RecurseTrack)(void) = ^(){
            if ([tracks count] > 0) {
                
                track = [tracks lastObject];
                [tracks removeLastObject];
                
                NSURL *videoURL;
                if ([(id) track[@"URL"] respondsToSelector:@selector(path)]) {
                    videoURL = track[@"URL"];
                } else {
                    videoURL = [NSURL URLWithString:track[@"URL"]];
                    if (videoURL == nil) videoURL = [NSURL fileURLWithPath:track[@"URL"]];
                }
                NSString *videoPath = [videoURL path];
                
                if (![[NSFileManager defaultManager] fileExistsAtPath:videoPath])
                    NSLog(@"file not here for upload!");
                
                CFStringRef fileMileMD5Hash = FileMD5HashCreateWithPath((__bridge CFStringRef)videoPath, FileHashDefaultChunkSizeForReadingData);
                NSString *videoFileMD5Hash = (__bridge NSString *)fileMileMD5Hash;
                if (fileMileMD5Hash) {
                    CFRelease(fileMileMD5Hash);
                }
                
                fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"videoHash == %@", videoFileMD5Hash]];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffVideoTrack" inManagedObjectContext:managedObjectContext]];
                
                [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
                    BOOL alreadyUploaded = [results count] > 0;
                    
                    if (uiProgress) {
                        [uiProgress setDetailTitle:[[NSString alloc] initWithFormat:@"Uploading track %i/%i", trackCount - [tracks count], trackCount]];
                    }
                    
                    if (!alreadyUploaded) {
                        
                        [self mainS3Upload:videoPath progressDelegate:uiProgress
                                 ancillary:YES
                          completeCallback:^(BOOL success, NSString * videoURL, NSError *error) {
                              if (success) {
                                  
                                  PlayoffVideoTrack *videoTrack = [self getVideoTrackForConfig:track
                                                                                 layerPosition:layerPosition
                                                                                          hash:videoFileMD5Hash
                                                                                 objectContext:managedObjectContext];
                                  [videoTrack setPayload_url:videoURL];
                                  
                                  [managedObjectContext saveOnSuccess:^(void) {
                                      
                                      [videoPlayoff addTracksObject:videoTrack];
                                      
                                      [managedObjectContext saveOnSuccess:^(void) {
                                          layerPosition += 1;
                                          RecurseTrack();
                                      } onFailure:^(NSError *error) {
                                          completeCallback(NO, nil, error);
                                      }];
                                      
                                  } onFailure:^(NSError *error) {
                                      completeCallback(NO, nil, error);
                                  }];
                                  
                              } else {
                                  completeCallback(NO, nil, error);
                              }
                              
                          }];
                        
                    } else {
                        [uiProgress hideProgress];
                        
                        PlayoffVideoTrack *videoTrack = [self getVideoTrackForConfig:track
                                                                       layerPosition:layerPosition
                                                                                hash:videoFileMD5Hash
                                                                       objectContext:managedObjectContext];
                        [managedObjectContext saveOnSuccess:^(void) {
                            
                            [videoPlayoff addTracksObject:videoTrack];
                            
                            [managedObjectContext saveOnSuccess:^(void) {
                                layerPosition += 1;
                                RecurseTrack();
                            } onFailure:^(NSError *error) {
                                completeCallback(NO, nil, error);
                            }];
                            
                        } onFailure:^(NSError *error) {
                            completeCallback(NO, nil, error);
                        }];
                    }
                    
                } onFailure:^(NSError *error) {
                    completeCallback(NO, nil, error);
                }];
                
                
            } else {
                
                [self addPlayoffToUserDict:playoffId trackingDict:@"completedAncillaryVideoUploads"];
                
                [videoPlayoff setValue:@TRUE forKey:@"hasAncillaryVideos"];
                [managedObjectContext saveOnSuccess:^(void) {
                    
                    completeCallback(YES, completeCallback, nil);
                    RecurseTrack = nil;
                    
                } onFailure:^(NSError *error) {
                    completeCallback(NO, nil, error);
                }];
            }
        };
        
        RecurseTrack();
    } onFailure:^(NSError *error) {
        completeCallback(NO, nil, error);
    }];
    
}

-(NSArray *)serialiseAncillaryTracks: (NSArray *)tracks {
    NSMutableArray *serTracks = [[NSMutableArray alloc] init];
    NSMutableDictionary *copiedTrack;
    
    for (NSDictionary *track in tracks) {
        copiedTrack = [[NSMutableDictionary alloc] init];
        
        [copiedTrack setValue:track[@"volume"] forKey:@"volume"];
        [copiedTrack setValue:[(NSURL *)track[@"URL"] path] forKey:@"URL"];

        CMTime globalStart = [(NSValue *)track[@"start"] CMTimeValue];
        CMTimeRange innerTimeRange = [(NSValue *)track[@"inner_time_range"] CMTimeRangeValue];
        CMTime innerDuration = [(NSValue *)track[@"inner_duration"] CMTimeValue];
        CMTime outerDuration = [(NSValue *)track[@"outer_duration"] CMTimeValue];
        
        [copiedTrack setValue:[[NSNumber alloc] initWithLongLong:globalStart.value] forKey:@"globalStart"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLong:globalStart.timescale] forKey:@"globalStartTimescale"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLongLong:innerTimeRange.start.value] forKey:@"innerTimeRangeStart"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLong:innerTimeRange.start.timescale] forKey:@"innerTimeRangeStartTimescale"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLongLong:innerTimeRange.duration.value] forKey:@"innerTimeRangeDur"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLong:innerTimeRange.duration.timescale] forKey:@"innerTimeRangeDurTimescale"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLongLong:innerDuration.value] forKey:@"innerDuration"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLong:innerDuration.timescale] forKey:@"innerDurationTimescale"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLongLong:outerDuration.value] forKey:@"outerDuration"];
        [copiedTrack setValue:[[NSNumber alloc] initWithLong:outerDuration.timescale] forKey:@"outerDurationTimescale"];

        [serTracks addObject:copiedTrack];
    }
    
    return serTracks;
}

-(NSArray *)deserialiseAncillaryTracks: (NSArray *)tracks {
    NSMutableArray *deserTracks = [[NSMutableArray alloc] init];
    
    for (NSDictionary *track in tracks) {
        [deserTracks addObject:[PLYUtilities deserialiseAncillaryTrack:track]];
    }
    
    return deserTracks;
}

-(void)serialiseNewVideoUpload: (NSString *) playoffThreadId
                     playoffId: (NSString *)playoffId
                 mainVideoPath: (NSString *)mainVideoPath
                        tracks: (NSArray *)ancillaryTracks
                        thumbnails: (NSArray *)thumbnails
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:@"serialisedVideosToUpload"]];
    
    NSMutableDictionary *thisPlayoff = [[NSMutableDictionary alloc] initWithDictionary:@{
                                        @"playoffThreadId": playoffThreadId ? playoffThreadId : emptyPlayoffThreadId,
                                        @"mainVideoPath": mainVideoPath,
                                        @"ancillaryTracks": [self serialiseAncillaryTracks: ancillaryTracks],
                                        @"thumbnails": thumbnails
                                        }];
    
    NSDictionary *existingConfig = [item valueForKey:playoffId];
    if (existingConfig) {
        NSEnumerator *enumerator = [existingConfig keyEnumerator];
        id key;
        while ((key = [enumerator nextObject])) {
            [thisPlayoff setValue:[existingConfig objectForKey:key] forKey:key];
        }
    }
    
    item[playoffId] = thisPlayoff;
    [defaults setValue:item forKey:@"serialisedVideosToUpload"];
}

-(void)addNewUpload: (NSString *) playoffThreadId
          playoffId: (NSString *) playoffId
      mainVideoPath: (NSString *)mainVidPath
             tracks: (NSArray *)ancillaries
         thumbnails: (NSArray *)thumbs
           overWWAN: (BOOL) overWWAN
  alreadySerialised: (BOOL) alreadySerialised
   completeCallback: (void(^)(BOOL, NSString *)) completeCallbackFull;
{
    
    void(^completeCallback)(BOOL, NSString *) = ^(BOOL success, NSString *msg) {
        if (success) {
            if (completeCallbackFull) completeCallbackFull(YES, msg);
        } else {
            if (completeCallbackFull) completeCallbackFull(NO, msg);
            UIAlertView *alertView = [[UIAlertView alloc]
                                      initWithTitle:@"Problem uploading"
                                      message:nil
                                      delegate:nil
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
            [alertView show];
        }
    };
    
    CGSize screenDim = [[UIScreen mainScreen] bounds].size;
    PLYUploadProgressView *uploadProgressView = [[PLYUploadProgressView alloc] initWithFrame:CGRectMake(0, 0, screenDim.width, screenDim.height)];
    [self.window addSubview:uploadProgressView];
    [uploadProgressView startWithTitle:@"Stage 1/3" withDetailTitle:@"uploading thumbnails"];
    
    if (!alreadySerialised) {
        [self moveVideoFilesFromTempDirectory:playoffThreadId
                                    playoffId:playoffId
                                mainVideoPath:mainVidPath
                              ancillaryTracks:ancillaries
                                   thumbnails:thumbs
                            copyToNewLocation:YES];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:@"serialisedVideosToUpload"]];

    __block NSArray *ancillaryTracks = item[playoffId][@"ancillaryTracks"];
    __block NSArray *thumbnails = item[playoffId][@"thumbnails"];
    __block NSString *mainVideoPath = item[playoffId][@"mainVideoPath"];
    [defaults setValue:item forKey:@"serialisedVideosToUpload"];

    __weak typeof(self) weakSelf = self;

    void (^finalUploadHandler)(BOOL, NSString *, NSError *) = ^(BOOL success, NSString *playoffVideoId, NSError *error) {
        if (success) {
            
            [uploadProgressView hideProgress];
            
            NSMutableDictionary *item = [[NSMutableDictionary alloc]
                                         initWithDictionary:(NSDictionary *)[defaults valueForKey:@"serialisedVideosToUpload"]];
            NSString *playoffThreadId = item[playoffId][@"playoffThreadId"];
            [self markMainVideoAsShareable:playoffThreadId playoffId:playoffId callback:^(BOOL success, NSError *error) {
                if (success) {
                    [self clearUpload:playoffId thumbnails:thumbnails mainVideo:mainVideoPath ancillaries:ancillaryTracks];
                    [uploadProgressView finish];
                    completeCallback(YES, nil);
                } else {
                    completeCallback(NO, nil);
                }
            }];
            
        } else {
            [uploadProgressView finish];
            completeCallback(NO, nil);
        }
    };
    
    void (^tracksStageUploadHandler)(BOOL, NSString *, NSError *) = ^(BOOL success, NSString *playoffVideoId, NSError *error) {
        if (success) {
            [uploadProgressView hideProgress];
            [uploadProgressView setTitle:@"Stage 3/3"];
            [uploadProgressView setDetailTitle:@""];
            [weakSelf uploadChunkedPlayoffVideoTracksItems:playoffId
                                            playoffVideoId:playoffVideoId
                                                    tracks:ancillaryTracks
                                                  overWWAN:overWWAN
                                                uiProgress:uploadProgressView
                                                  callback:finalUploadHandler];
            
        } else {
            [uploadProgressView finish];
            completeCallback(NO, nil);
            // since no error must have been explicitly cancelled - delete the playoff
        }
    };
    
    void (^thumbStageUploadHandler)(void) = ^{
        [self uploadThumbnailImages: playoffThreadId playoffId: playoffId thumbnails:thumbnails callback:^(BOOL success, NSString *playoffId, NSError *error) {
            if (success) {
                [uploadProgressView setTitle:@"Stage 2/3"];
                [uploadProgressView setDetailTitle:@"Uploading main video"];
                [self uploadChunkedVideoPlayoffItem: playoffThreadId
                                          playoffId:playoffId
                                          videoPath:mainVideoPath
                                   progressDelegate:uploadProgressView
                                           callback: tracksStageUploadHandler];
                
            } else {
                [uploadProgressView finish];
                completeCallback(NO, nil);
            }
        }];
    };
    
    if (alreadySerialised) {
        [self clearExistingPlayoffForReupload:playoffId completeCallback:^(BOOL success, NSString *msg) {
            if (success) {
                thumbStageUploadHandler();
            } else {
                completeCallback(NO, nil);
            }
        }];
    } else {
        thumbStageUploadHandler();
    }
}

-(void)clearExistingPlayoffForReupload: (NSString *)playoffId completeCallback: (void(^)(BOOL, NSString *)) complete
{

    void (^secondStage)(void) = ^{
        
        // playoffItem
        // playoffVideoTrack
        SMQuery *tracksQuery = [[SMQuery alloc] initWithSchema:@"PlayoffVideoTrack"];
        [tracksQuery where:@"playoffvideotrack_id" isEqualTo:playoffId];
        
        // set playoffvideotrack playoff id to null, don't delete in case lose reference to video (hashed)
        [self.client.dataStore performQuery:tracksQuery onSuccess:^(NSArray *results) {
            NSMutableArray *items = [[NSMutableArray alloc] initWithArray:results];
            void(^__block recurseRemoveItem)(void) = ^{
                if ([items count]) {
                    NSMutableDictionary *obj = [[NSMutableDictionary alloc] initWithDictionary: [items lastObject]];
                    [items removeLastObject];
                    if ([obj valueForKey:@"payload_url"]) {
                        [obj removeObjectForKey:@"payload_url"];
                        [self.client.dataStore updateObjectWithId:[obj valueForKey:@"playoffvideotrack_id"]
                                                         inSchema:@"PlayoffVideoTrack"
                                                           update:obj onSuccess:^(NSDictionary *obj, NSString *schema) {
                                                               recurseRemoveItem();
                                                           }
                                                        onFailure:^(NSError *err, NSDictionary *obj, NSString *schema) {
                                                            complete(YES, nil);
                                                            recurseRemoveItem = nil;
                                                        }];
                    } else {
                        [self.client.dataStore deleteObjectId:[obj valueForKey:@"playoffvideotrack_id"]
                                                     inSchema:@"PlayoffVideoTrack"
                                                    onSuccess:^(NSString *objId, NSString *schema) {
                                                        recurseRemoveItem();
                                                    }
                                                    onFailure:^(NSError *err, NSString *objId, NSString *schema) {
                                                        complete(YES, nil);
                                                        recurseRemoveItem = nil;
                                                    }];
                    }
                } else {
                    [self.client.dataStore deleteObjectId:playoffId inSchema:@"PlayoffItem" onSuccess:^(NSString *objId, NSString *schema) {
                        complete(YES, nil);
                        recurseRemoveItem = nil;
                    } onFailure:^(NSError *err, NSString *objId, NSString *schema) {
                        complete(YES, nil);
                        recurseRemoveItem = nil;
                    }];
                }
            };
            recurseRemoveItem();
        } onFailure:^(NSError *error) {
            complete(YES, nil);
        }];
        
    };
    
    SMQuery *threadsQuery = [[SMQuery alloc] initWithSchema:@"PlayoffThread"];
    [threadsQuery where:@"playoffs" isIn:@[playoffId]];

    [[self.client dataStore] performQuery:threadsQuery onSuccess:^(NSArray *results){
        if ([results count]) {
            NSMutableDictionary *thread = [[NSMutableDictionary alloc] initWithDictionary:results[0]];
            [thread removeObjectForKey:@"sm_owner"]; // otherwise complains about changing this
            NSMutableSet *playoffs = [[NSMutableSet alloc] initWithArray:thread[@"playoffs"]];
            __block id toRemove = nil;
            [playoffs enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
                if ([playoffId isEqualToString:obj]) toRemove = obj;
            }];
            if (toRemove != nil) {
                [playoffs removeObject:toRemove];
                [thread setValue:[playoffs allObjects] forKey:@"playoffs"];

                [self.client.dataStore updateObjectWithId:[thread valueForKey:@"playoffthread_id"] inSchema:@"PlayoffThread" update:thread onSuccess:^(NSDictionary *obj, NSString *schema) {
                    secondStage();
                }
                onFailure:^(NSError *err, NSDictionary *obj, NSString *schema) {
                    secondStage();
                }];
            } else {
                secondStage();
            }
        } else {
            secondStage();
        }
    } onFailure:^(NSError *error) {
        secondStage();
    }];
}

-(void)simpleWebRequest:(NSString *) url withBlock: (void (^)(BOOL, NSString *)) complete
{
   __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setCompletionBlock:^(void){ complete(YES, [self encodedStringWithContentsOfURL:[request responseData]]); request = nil; }];
    [request setFailedBlock:^(void) { complete(NO, nil); }];
    [request startAsynchronous];
}

- (NSString *)encodedStringWithContentsOfURL:(NSData *)data
{
    // response
    int enc_arr[] = {
        NSUTF8StringEncoding,           // UTF-8
        NSShiftJISStringEncoding,       // Shift_JIS
        NSJapaneseEUCStringEncoding,    // EUC-JP
        NSISO2022JPStringEncoding,      // JIS
        NSUnicodeStringEncoding,        // Unicode
        NSASCIIStringEncoding           // ASCII
    };
    NSString *data_str = nil;
    int max = sizeof(enc_arr) / sizeof(enc_arr[0]);
    for (int i=0; i<max; i++) {
        data_str = [
                    [NSString alloc]
                    initWithData : data
                    encoding : enc_arr[i]
                    ];
        if (data_str!=nil) {
            break;
        }
    }
    return data_str;
}

-(void(^)(void)) downloadWebVideo: (NSString *)url
                fileName: (NSString *) fileName
           withExtension: (NSString *) ext
               withBlock: (void (^)(BOOL, NSString *)) complete
   andProgressDelegate: (id) progressDelegate
{
    NSString *newPath;
    
    if (!fileName) {
        fileName = [[NSString alloc] initWithFormat:@"%@.%@", [PLYUtilities getUUID], ext];
        
        NSString *documentsDirectory = NSTemporaryDirectory();
        
        newPath = [documentsDirectory stringByAppendingPathComponent: PLYThirdPartyVideoDirectory];
        newPath = [newPath stringByAppendingPathComponent:fileName];
    } else {
        newPath = fileName;
    }
    
    [[NSFileManager defaultManager] createFileAtPath:newPath contents:[[NSData alloc] init] attributes:nil];
    
    __block ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:[NSURL URLWithString:url]];
    [request setDownloadDestinationPath:newPath];
    
    [request setTimeOutSeconds:15];
    [request setAllowResumeForFileDownloads:YES];
    [request setCompletionBlock:^(void){
        AVURLAsset *av = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:newPath] options:nil];
        if (CMTimeGetSeconds(av.duration)) {
            complete(YES, newPath);
        } else {
            complete(NO, nil);
        }
        request = nil;
    }];

    void (^cancelRequest)(void) = ^(void) {
        [request clearDelegatesAndCancel];
        request = nil;
    };
    
    if (progressDelegate) [request setDownloadProgressDelegate:progressDelegate];
    
    [request setFailedBlock:^(void) {
        complete(NO, nil);
        request = nil;
    }];
    
    [request startAsynchronous];
    
    return cancelRequest;
}

-(void)setUploadDetails:(NSString *)playoffId details:(NSDictionary *)details
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:@"serialisedVideosToUpload"]];
    NSMutableDictionary *serialisedUploads = [[NSMutableDictionary alloc] initWithDictionary:item[playoffId]];
    
    for (NSString *k in details) {
        [serialisedUploads setValue:details[k] forKey:k];
    }
    
    item[playoffId] = serialisedUploads;
    [defaults setValue:item forKey:@"serialisedVideosToUpload"];
}

-(void) moveVideoFilesFromTempDirectory: (NSString *) playoffThreadId
                              playoffId: (NSString *) playoffId
                          mainVideoPath: (NSString *) mainVideoPath
                        ancillaryTracks: (NSArray *) ancillaryTracks
                             thumbnails: (NSArray *) thumbnails
                      copyToNewLocation: (BOOL) copyToNewLocation
{
    NSArray *copiedThumbnails = [self copyThumbnailsToPermanentLocationAndCleanup:thumbnails];
    NSString *copiedMainVideoPath = [self copyMainVideoToNewLocation:mainVideoPath];
    NSArray *copiedAncillaryTracks = [self copyPlayoffTracksToPermanentLocationAndCleanup:ancillaryTracks];

    [self serialiseNewVideoUpload: playoffThreadId
                       playoffId :playoffId
                    mainVideoPath:copiedMainVideoPath
                           tracks:copiedAncillaryTracks
                           thumbnails:copiedThumbnails];
}

-(void)doFacebookShareWithMessage: (NSString *) message andLink: (NSString *) link;
{
    [FBSession openActiveSessionWithPublishPermissions:@[@"publish_actions"] defaultAudience:FBSessionDefaultAudienceEveryone allowLoginUI:YES completionHandler: ^(FBSession *session, FBSessionState status, NSError *error) {
        
        
                        [FBRequestConnection startWithGraphPath:@"me/feed"
//        [FBRequestConnection startWithGraphPath:@"me/crunch-playoff:create_a_playoff" // @"website": 'url'
                                     parameters:@{ @"link": link, @"name": @"new Playoff!", @"message": message }
                                     HTTPMethod:@"POST"
                              completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
                              }];
    }];
    
}

// TODO: make async
-(void)markMainVideoAsShareable: (NSString *) playoffThreadId
                      playoffId: (NSString *) playoffId
                       callback: (void (^)(BOOL, NSError *)) completeCallback;
{

    __block NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];
    
    void (^stageTwo)(void) = ^(void) {
        NSFetchRequest *fetchRequest2 = [[NSFetchRequest alloc] init];
        [fetchRequest2 setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id == %@", playoffId]];
        [fetchRequest2 setEntity:[NSEntityDescription entityForName:@"PlayoffItem" inManagedObjectContext:managedObjectContext]];
        
        [managedObjectContext executeFetchRequest:fetchRequest2 onSuccess:^(NSArray *results2) {
            if ([results2 count] > 0) {
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                NSMutableDictionary *item = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)[defaults valueForKey:@"serialisedVideosToUpload"]];
                NSDictionary *serialisedUploads = item[playoffId];
                NSString *caption = (NSString *)serialisedUploads[@"playoffCaption"];
                
                PlayoffItem *playoffItem = results2[0];
                [playoffItem setValue:@TRUE forKey:@"approved_for_sharing"];
                [playoffItem setValue:caption forKey:@"caption"];
                
                NSMutableDictionary *facebookShare = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)
                                                      [defaults valueForKey:@"uploadsToFacebookShare"]];
                
                NSString *linkURL = [PLYUtilities getPlayoffShareURL:playoffId];
                NSString *simpleStatusMessage = @"I created a playoff!";
                NSString *statusMessage = [[NSString alloc] initWithFormat: @"%@ %@", simpleStatusMessage, linkURL, nil];
                
                if ([facebookShare valueForKey:playoffId]) {
                    [self doFacebookShareWithMessage:simpleStatusMessage andLink:linkURL];
                    
                    [facebookShare removeObjectForKey:playoffId];
                    [defaults setValue:facebookShare forKey:@"uploadsToFacebookShare"];
                }
                
                NSMutableDictionary *twitterShare = [[NSMutableDictionary alloc] initWithDictionary:(NSDictionary *)
                                                      [defaults valueForKey:@"uploadsToTwitterShare"]];
                
                if ([twitterShare valueForKey:playoffId]) {
                    [self twitterSignInWithBlock:^(BOOL success, ACAccount *account) {
                        if (success) {
                            [self tweet:account withMessage:statusMessage];
                            
                            [twitterShare removeObjectForKey:playoffId];
                            [defaults setValue:facebookShare forKey:@"uploadsToTwitterShare"];
                        }
                    }];
                }
                
                [managedObjectContext saveOnSuccess:^(void) {
                    completeCallback(YES, nil);
                } onFailure:^(NSError *error) {
                    completeCallback(NO, nil);
                }];
                
            } else {
                completeCallback(NO, nil);
            }
            
        } onFailure:^(NSError *error) {
            completeCallback(NO, error);
        }];
    };
    
    if (playoffThreadId) {
        NSFetchRequest *fetchRequest1 = [[NSFetchRequest alloc] init];
        [fetchRequest1 setPredicate:[NSPredicate predicateWithFormat:@"playoffthread_id == %@", playoffThreadId]];
        [fetchRequest1 setEntity:[NSEntityDescription entityForName:@"PlayoffThread" inManagedObjectContext:managedObjectContext]];
        
        [managedObjectContext executeFetchRequest:fetchRequest1 onSuccess:^(NSArray *results1) {
            if ([results1 count] > 0) {
                PlayoffThread *playoffThread = results1[0];
                [playoffThread setValue:@TRUE forKey:@"approved_for_sharing"];
                stageTwo();
            } else {
                completeCallback(NO, nil);
            }
        } onFailure:^(NSError *error) {
            completeCallback(NO, error);
        }];
    } else {
        stageTwo();
    }


}

-(void)clearAllUploads
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *awaitingUpload = [defaults dictionaryForKey:@"serialisedVideosToUpload"];
    for (NSString *playoffId in awaitingUpload) {
        [self clearUpload:playoffId
               thumbnails:awaitingUpload[playoffId][@"thumbnails"]
                mainVideo:awaitingUpload[playoffId][@"mainVideoPath"]
              ancillaries:awaitingUpload[playoffId][@"ancillaries"]];
    }
}

-(void)clearUpload: (NSString *) playoffId thumbnails: (NSArray *) thumbnails mainVideo: (NSString *) mainVideoPath ancillaries: (NSArray *) ancillaries
{
    NSError *error;
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    for (NSString *path in thumbnails) {
        if ([fileMgr fileExistsAtPath:path]) {
            [fileMgr removeItemAtPath:path error:&error];
        }
    }
    
    if ([fileMgr fileExistsAtPath:mainVideoPath]) {
        [fileMgr removeItemAtPath:mainVideoPath error:&error];
    }
    
    for (NSDictionary *an in ancillaries) {
        if ([fileMgr fileExistsAtPath:an[@"URL"]]) {
            [fileMgr removeItemAtPath:an[@"URL"] error:&error];
        }
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *awaitingUpload = [[NSMutableDictionary alloc] initWithDictionary:[defaults dictionaryForKey:@"serialisedVideosToUpload"]];
    [awaitingUpload removeObjectForKey:playoffId];
    [defaults setValue:awaitingUpload forKey:@"serialisedVideosToUpload"];
}


#pragma mark file utility stuff

-(void)checkAndCreateDefaultDirectories
{
    NSString *documentsDirectory = NSTemporaryDirectory();
    NSError *error;
    NSString *dataPath;
    NSArray *dirs = @[PLYPendingUploadDirectory, PLYCacheDirectory, PLYThirdPartyVideoDirectory];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:documentsDirectory])
        [[NSFileManager defaultManager] createDirectoryAtPath:documentsDirectory withIntermediateDirectories:NO attributes:nil error:&error];
    
    if (error) {
        error = nil;
    }
    
    for (NSString *dir in dirs) {
        dataPath = [documentsDirectory stringByAppendingPathComponent:dir];
        if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath])
            [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error];
        
        if (error) {
            error = nil;
        }
    }
}

-(void) downloadVideoPlayoff: (NSString *) playoffId
                    videoURL: (NSString *) videoURL
            progressDelegate: (id) progressDelegate
                    callback: (void (^)(BOOL, NSString *, NSError *, NSString *)) completeCallback
           getCancelCallback: (GET_EMPTY_CALLBACK) emptyCallback
{
    [self downloadVideo:playoffId
               videoURL:videoURL
               callback:completeCallback
     mainVideoElseTrack:YES
              trackHash:nil
       progressDelegate:progressDelegate
      getCancelCallback:emptyCallback];
}


-(void) downloadVideo: (NSString *) playoffId
             videoURL: (NSString *) videoURL
             callback: (void (^)(BOOL, NSString *, NSError *, NSString *)) completeCallback
   mainVideoElseTrack: (BOOL) mainVideoElseTrack
            trackHash: (NSString *) trackHash
     progressDelegate: (id) progressDelegate
    getCancelCallback: (GET_EMPTY_CALLBACK) emptyCallback
{
    // 1) check if track already downloaded
    // 2) get chunks
    // 3) download chunks
    // 4) save in cache main-video-<id>.mov
    
    NSString *documentsDirectory = NSTemporaryDirectory();
    NSString *localName = mainVideoElseTrack ? @"main-video" : @"video-track";
    NSString *modelName = mainVideoElseTrack ? @"PlayoffItem" : @"PlayoffVideoTrack";
    NSString *fileExactName = mainVideoElseTrack ? playoffId : trackHash;
    
    SMQuery *mainQuery = [[SMQuery alloc] initWithSchema:modelName];
    
    if (mainVideoElseTrack) {
        [mainQuery where:@"playoffitem_id" isEqualTo:playoffId];
    } else {
        [mainQuery where:@"video_hash" isEqualTo:trackHash];
        [mainQuery where:@"payload_url" isNotEqualTo:@""];
    }
    
    __block NSString *mainVideoPathFinal = [documentsDirectory stringByAppendingPathComponent: PLYCacheDirectory];
    
    __block NSString *mainVideoPathTemp = [mainVideoPathFinal stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@-%@-temp.mov",
                                                                                               localName, fileExactName, nil]];
    mainVideoPathFinal = [mainVideoPathFinal stringByAppendingPathComponent: [[NSString alloc] initWithFormat:@"%@-%@.mov", localName, fileExactName, nil]];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    
    if ([fileMgr fileExistsAtPath: mainVideoPathFinal]) {
        completeCallback(YES, mainVideoPathFinal, nil, nil);
        return;
    }
    
    if (videoURL) {
        void(^cancelDownload)(void) = [self downloadWebVideo:videoURL fileName: mainVideoPathTemp withExtension:@"mov" withBlock:^(BOOL success, NSString *path) {
            if (success) {
                NSError *error;
                [fileMgr moveItemAtPath:mainVideoPathTemp toPath:mainVideoPathFinal error:&error];
                if (error) {
                    completeCallback(NO, nil, error, videoURL);
                } else {
                    completeCallback(YES, mainVideoPathFinal, nil, nil);
                }
            } else {
                completeCallback(NO, nil, nil, nil);
            }
        } andProgressDelegate:progressDelegate];
        emptyCallback(cancelDownload);
        return;
    }
    
    NSError *error;
    if ([fileMgr fileExistsAtPath: mainVideoPathFinal]) [fileMgr removeItemAtPath:mainVideoPathFinal error:&error];
    [fileMgr createFileAtPath:mainVideoPathTemp contents:nil attributes:nil];

    // set playoffvideotrack playoff id to null, don't delete in case lose reference to video (hashed)
    [self.client.dataStore performQuery:mainQuery onSuccess:^(NSArray *playoffs) {
        if ([playoffs count] == 0) {
            completeCallback(NO, nil, nil, nil);
            return;
        }
        id obj1 = playoffs[0];
        NSString *payloadURL = [[playoffs lastObject] valueForKey:@"payload_url"];
        
        void(^cancelDownload)(void) = [self downloadWebVideo:payloadURL fileName: mainVideoPathTemp withExtension:@"mov" withBlock:^(BOOL success, NSString *path) {
            if (success) {
                NSError *error;
                [fileMgr moveItemAtPath:mainVideoPathTemp toPath:mainVideoPathFinal error:&error];
                if (error) {
                    completeCallback(NO, nil, error, payloadURL);
                } else {
                    completeCallback(YES, mainVideoPathFinal, nil, nil);
                }
            } else {
                completeCallback(NO, nil, nil, payloadURL);
            }
        } andProgressDelegate:progressDelegate];
        emptyCallback(cancelDownload);
        
    } onFailure:^(NSError *error) {
        completeCallback(NO, nil, nil, nil);
    }];

}

-(void) downloadVideoPlayoffTracks: (NSString *)playoffId
                     trackCallback: (void (^)(BOOL, NSDictionary *, NSString *, NSError *, NSString *)) trackCallback
                     initialTracksCallback: (NSArray * (^)(BOOL, NSArray *)) initialTracksCallback
                     allTracksCallback: (void (^)(BOOL, NSError *)) allTracksCallback
{
    // 1) get all tracks
    // 2) call success/fail callback for each
    
    NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id = %@", playoffId]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffItem" inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *playoffItem) {
        if ([playoffItem count] == 0) {
            allTracksCallback(NO, nil);
            return;
        }
        
        PlayoffItem *videoItem = playoffItem[0];
        
        NSArray *tracksRaw = [[videoItem tracks] allObjects];
        
        if ([tracksRaw count] == 0) {
            allTracksCallback(NO, nil);
            return;
        }
        
        NSMutableArray *tracksFull = [[NSMutableArray alloc]init];
        for (PlayoffItem *track in tracksRaw) {
            [tracksFull addObject:[PLYUtilities toDict:track]];
        }
        
        tracksFull = [[NSMutableArray alloc] initWithArray: [tracksFull sortedArrayUsingComparator:^(id a, id b){
            return [(NSNumber *)[(NSDictionary *)a valueForKey: @"layerPosition"]
                    compare:(NSNumber *)[(NSDictionary *)b valueForKey: @"layerPosition"]];
        }]];

        __block NSArray *delegates = initialTracksCallback(YES, tracksFull);
        __block NSMutableArray *tracks = [[NSMutableArray alloc] initWithArray:[[tracksFull reverseObjectEnumerator] allObjects]];
        
        void (^__block recurseTrackDownload)(void) = ^(void) {
            if ([tracks count] > 0) {
                NSDictionary *track = [tracks lastObject];
                [tracks removeLastObject];
                
                PLYVideoMixerCell *cell;
                for (PLYVideoMixerCell *del in delegates) {
                    if (del.videoTrackId == [track valueForKey:@"playoffvideotrack_id"]) {
                        cell = del;
                        break;
                    }
                }
                
                [self downloadVideo:[track valueForKey: @"playoffvideotrack_id"] videoURL: nil callback:
                    ^(BOOL success, NSString *path, NSError *err, NSString *vidURL) {
                    if (success) {
                        trackCallback(YES, track, path, nil, vidURL);
                    } else {
                        trackCallback(NO, track, nil, err, vidURL);
                    }
                    recurseTrackDownload();
                } mainVideoElseTrack:NO trackHash:[track valueForKey: @"videoHash"] progressDelegate:cell getCancelCallback: ^(EMPTY_CALLBACK callback) {
                    
                }];
                
            } else {
                allTracksCallback(YES, nil);
                recurseTrackDownload = nil;
            }
        };
        
        recurseTrackDownload();
        
    } onFailure:^(NSError *error) {
        allTracksCallback(NO, nil);
    }];


}

-(NSString *)copyMainVideoToNewLocation: (NSString *)existingPath
{
    NSString *documentsDirectory = NSTemporaryDirectory();
    
    NSString *mainVideoURL = [documentsDirectory stringByAppendingPathComponent: PLYPendingUploadDirectory];
    mainVideoURL = [mainVideoURL stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@.%@",
                                                                 [PLYUtilities getUUID], existingPath.pathExtension]];
    
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    if ([fileMgr fileExistsAtPath:existingPath]) {
        NSError *error;
        [fileMgr moveItemAtPath:existingPath toPath:mainVideoURL error:&error];
        
        [self deleteFiles:[[NSSet alloc] initWithObjects:[[NSURL alloc] initWithString: existingPath], nil]];
        
        if (error) {
            error = nil;
        }
        
    }
    
    return mainVideoURL;
}

-(NSArray *)copyThumbnailsToPermanentLocationAndCleanup: (NSArray *)thumbnails
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSMutableSet *toRemove = [[NSMutableSet alloc] init];
    
    NSString *documentsDirectory = NSTemporaryDirectory();
    
    NSMutableArray *newThumbnails = [[NSMutableArray alloc] init];
    NSString *existingPath;
    NSString *newPath;
    NSError *error;
    
    for (existingPath in thumbnails) {
        newPath = [documentsDirectory stringByAppendingPathComponent: PLYPendingUploadDirectory];
        newPath = [newPath stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@.%@", [PLYUtilities getUUID], existingPath.pathExtension]];
        
        NSURL *u = [NSURL URLWithString:existingPath];
        if (u == nil) u = [NSURL fileURLWithPath:existingPath];
        
        if (u != nil) {
            [toRemove addObject:u];
            [fileMgr moveItemAtPath:existingPath toPath:newPath error:&error];
            [newThumbnails addObject:newPath];
            
            if (error) {
                error = nil;
            }
        }
    }
    
    [self deleteFiles:toRemove];
    
    return newThumbnails;
}

-(NSArray *)copyPlayoffTracksToPermanentLocationAndCleanup: (NSArray *)ancillaryTracks
{
    // put essential asset components in a permanent location, delete temporary located files
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSMutableSet *toRemove = [[NSMutableSet alloc] init];
    
    NSString *documentsDirectory = NSTemporaryDirectory();
    
    NSMutableArray *newTracks = [[NSMutableArray alloc] init];
    NSMutableDictionary *copiedTrack;
    NSString *existingPath;
    NSString *newPath;
    NSError *error;
    
    for (NSDictionary *track in ancillaryTracks) {
        copiedTrack = [[NSMutableDictionary alloc] initWithDictionary:[track copy]];
        existingPath = [(NSURL *)copiedTrack[@"URL"] path];
        newPath = [documentsDirectory stringByAppendingPathComponent: PLYPendingUploadDirectory];
        newPath = [newPath stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"%@.%@",
                                                           [PLYUtilities getUUID], existingPath.pathExtension]];
        
        [fileMgr copyItemAtPath:existingPath toPath:newPath error:&error];
        
        NSURL *u = [NSURL URLWithString:newPath];
        if (u == nil) u = [NSURL fileURLWithPath:newPath];
        
        copiedTrack[@"URL"] = u;
        [newTracks addObject:copiedTrack];
        
        [toRemove addObject:[NSURL fileURLWithPath:existingPath]];
        
        if (error) {
            error = nil;
        }
    }
    
    [self deleteFiles:toRemove];

    return newTracks;
}

-(void)deleteFiles: (NSSet *)toRemove
{
    NSFileManager *fileMgr = [NSFileManager defaultManager];
    NSError *error;
    
    // finally delete the temporary files
    for (NSURL *file in toRemove) {
        if ([fileMgr fileExistsAtPath:[file path]]) {
            [fileMgr removeItemAtURL:file error:&error];
            if (error) {
                error = nil;
            }
        }
    }
}

# pragma mark like playoff

-(void) likePlayoff: (NSString *)playoffId completeCallback: (void (^)(BOOL, BOOL, int, NSError *)) completeCallback
{
    
    NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];
    
    // need to check if have already liked
    
    [self.client getLoggedInUserOnSuccess:^(NSDictionary *result) {
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"username == %@", result[@"username"]]];
        [fetchRequest setEntity:[NSEntityDescription entityForName:@"User" inManagedObjectContext:managedObjectContext]];
        
        [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
            if ([results count] == 0) {
                completeCallback(NO, NO, 0, nil);
                return;
            }
            
            User *currentUser = results[0];
            BOOL alreadyLiked = NO;
            
            for (PlayoffItem *playoff  in [[[currentUser likes] objectEnumerator] allObjects]) {
                if ([(NSString *)[playoff valueForKey: @"playoffitem_id"] isEqualToString: playoffId]) {
                    alreadyLiked = YES;
                    break;
                }
            }
            
            if (alreadyLiked) {
                completeCallback(NO, YES, 0, nil);
                return;
            }
            
            [managedObjectContext saveOnSuccess:^(void) {
                
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id == %@", playoffId]];
                [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffItem"
                                                    inManagedObjectContext:managedObjectContext]];
                
                [managedObjectContext executeFetchRequest:fetchRequest onSuccess:^(NSArray *results) {
                    if ([results count] == 0) {
                        completeCallback(NO, NO, 0, nil);
                        return;
                    }
                    
                    PlayoffItem *playoff = results[0];
                    int newLikesCount = [[playoff likes_count] intValue] + 1;
                    PlayoffThread *thread = [playoff thread];

                    [currentUser addLikesObject:playoff];
                    
                    NSArray *pops1 = [[[thread most_popular1] objectEnumerator] allObjects];
                    NSArray *pops2 = [[[thread most_popular2] objectEnumerator] allObjects];
                    NSArray *pops3 = [[[thread most_popular3] objectEnumerator] allObjects];
                    PlayoffItem *pop1 = [pops1 count] > 0 ? pops1[0] : nil;
                    PlayoffItem *pop2 = [pops2 count] > 0 ? pops2[0] : nil;
                    PlayoffItem *pop3 = [pops3 count] > 0 ? pops3[0] : nil;

                    if (pop1 != nil && [[pop1 likes_count] intValue] < newLikesCount) {
                        [thread removeMost_popular1Object:pop1];
                        [thread addMost_popular1Object:playoff];

                        if (pop3 == nil && pop2 != nil) {
                            [thread removeMost_popular2Object:pop2];
                            [thread addMost_popular3Object:pop2];
                        }
                        
                        if (pop2 == nil) {
                            [thread addMost_popular2Object:pop1];
                            pop2 = pop1;
                        }
                        
                    } else if (pop2 != nil && [[pop2 likes_count] intValue] < newLikesCount) {
                        [thread removeMost_popular2Object:pop2];
                        [thread addMost_popular2Object:playoff];
                        
                        if (pop3 == nil && pop2 != nil) {
                            [thread removeMost_popular3Object:pop3];
                            [thread addMost_popular3Object:pop2];
                        }
                    } else if (pop3 != nil && [[pop3 likes_count] intValue] < newLikesCount) {
                        [thread removeMost_popular3Object:pop3];
                        [thread addMost_popular3Object:playoff];
                    } else if (pop1 == nil) {
                        [thread addMost_popular1Object:playoff];
                    }
                    
                    [playoff setValue:[NSNumber numberWithInt:newLikesCount] forKey:@"likes_count"];
                    
                    int threadLikes = [(NSNumber *)[thread valueForKey:@"likes_count"] intValue] + 1;
                    [thread setValue:[NSNumber numberWithInt:threadLikes] forKey:@"likes_count"];

                    
                    [managedObjectContext saveOnSuccess:^(void) {
                        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
     
                        // TODO: increment like count - put this on application in case user goes away
                        completeCallback(YES, NO, newLikesCount, nil);
                        
                    } onFailure:^(NSError *error) {
                        completeCallback(NO, NO, 0, error);
                    }];
                    
                } onFailure:^(NSError *error) {
                    completeCallback(NO, NO, 0, error);
                }];
            } onFailure:^(NSError *error) {
                completeCallback(NO, NO, 0, error);
            }];
            
        } onFailure:^(NSError *error) {
            completeCallback(NO, NO, 0, error);
        }];
        
    } onFailure:^(NSError *error) {
        completeCallback(NO, NO, 0, error);
    }];
}

-(BOOL) alreadyLikedPlayoff: (NSString *)playoffId
{
    return NO;
}

-(void) flagPlayoff: (NSString *)playoffId
{
    
    NSManagedObjectContext *managedObjectContext = [self.coreDataStore contextForCurrentThread];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"playoffitem_id == %@", playoffId]];
    [fetchRequest setEntity:[NSEntityDescription entityForName:@"PlayoffItem"
                                        inManagedObjectContext:managedObjectContext]];
    
    [managedObjectContext executeFetchRequest:fetchRequest onSuccess: ^(NSArray *results) {
      if ([results count] == 0) {
            return;
        }
        PlayoffItem *playoff = [results objectAtIndex:0];
        int flaggedCount = [[(NSNumber *)playoff valueForKey:@"flagged_count" ] intValue];
        [playoff setValue:[NSNumber numberWithInt: (flaggedCount + 1) ] forKey:@"flagged_count"];
        
        [managedObjectContext saveOnSuccess:^(void) {
        } onFailure:^(NSError *error) {
        }];
        
    } onFailure:^(NSError *error) {
    }];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

-(NSMutableDictionary *) getProcessedPlayoff: (NSDictionary *)p
{
    NSString *cap = @"";
    if ([p valueForKey: @"caption"]) {
        cap = (NSString *)[p valueForKey: @"caption"];
    }
    
    NSNumber *likesCount = [p valueForKey: @"likes_count"];
    if (!likesCount) {
        likesCount = [[NSNumber alloc] initWithInt: 0];
    }
    
    return [[NSMutableDictionary alloc] initWithDictionary:@{
            @"thread_id": [p valueForKey: @"thread"],
            @"id": [p valueForKey: @"playoffitem_id"],
            @"preview_image_1": [p valueForKey: @"thumbnail1"],
            @"preview_image_2": [p valueForKey: @"thumbnail2"],
            @"preview_image_3": [p valueForKey: @"thumbnail3"],
            @"has_video": @TRUE,
            @"video_url": [p valueForKey: @"payload_url"] ? [p valueForKey: @"payload_url"] : @"",
            @"likes": likesCount,
            @"createddate": [p valueForKey:@"createddate"],
            @"user": [p valueForKey:@"sm_owner"],
            @"summary_comments": [cap length] > 0 ? @[@{
                @"user": [p valueForKey:@"sm_owner"],
                @"body": cap
            }] : @[]
            }];
}

-(NSDictionary *) getProcessedThread: (PlayoffThread *) thread
                      threadCaptions: (NSArray *)threadCaptions
                      threadPlayoffs: (NSArray *)threadPlayoffs
{
    NSComparisonResult (^popSorter)(id a, id b) = ^(id a, id b) {
        return [(NSNumber *)[(NSDictionary *)b valueForKey: @"likes_count"]
                compare:(NSNumber *)[(NSDictionary *)a valueForKey: @"likes_count"]];
    };
    
    NSMutableDictionary *processedThread = [[NSMutableDictionary alloc] init];
    NSString *threadId = (NSString *)[thread valueForKey:@"playoffthread_id"];
    NSArray *sortedPs = [threadPlayoffs sortedArrayUsingComparator: popSorter];
    NSError *error;
    NSRegularExpression *titleRegex = [NSRegularExpression regularExpressionWithPattern:@"#([a-zA-Z]+)"
                                                                                options:NSRegularExpressionCaseInsensitive
                                                                                  error:&error];
    NSString *topUser = nil;
    NSString *title = nil;
    NSString *fallbackTitle = nil;
    NSMutableArray *processedPlayoffs = [[NSMutableArray alloc] init];
    
    for (PlayoffItem *p in sortedPs) {
        if (topUser == nil)
            topUser = [p valueForKey:@"sm_owner"];
        
        NSString *cap = (NSString *)[p valueForKey: @"caption"];
        
        if (fallbackTitle == nil && [cap length] > 0)
            fallbackTitle = cap;
        
        NSRange match = [titleRegex rangeOfFirstMatchInString:cap options:NSMatchingReportCompletion range:NSMakeRange(0, [cap length])];
        
        if (!NSEqualRanges(match, NSMakeRange(NSNotFound, 0)) && title == nil) {
            title = [cap substringWithRange:match];
        }
        
        [processedPlayoffs addObject:[self getProcessedPlayoff: p]];
    }
    
    if (title != nil) {
        [processedThread setValue:title forKey:@"title"];
    } else if (fallbackTitle != nil) {
        [processedThread setValue:fallbackTitle forKey:@"title"];
    }
    
    [processedThread setValue: topUser forKey:@"first_user"];
    [processedThread setValue: threadId forKey:@"id"];
    [processedThread setValue: threadCaptions forKey: @"summary_comments"];
    [processedThread setValue: processedPlayoffs forKey: @"items"];
    [processedThread setValue: title ? title : fallbackTitle forKey: @"title"];
    [processedThread setValue: [thread valueForKey:@"createddate"] forKey:@"createddate"];
    
    return processedThread;
}

-(void)setProfileImage: (NSString *)username imageView: (UIImageView *)imageView withBlock: (void (^)(BOOL)) complete;
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        
        NSArray *splitStr = [username componentsSeparatedByString:@"/"];
        NSString *queryUsername;
        if ([splitStr count] > 1) queryUsername = [splitStr lastObject];
        else queryUsername = username;
        
        if ([self.profileImageForUser valueForKey:queryUsername]) {
            NSURL *u = [NSURL URLWithString:[self.profileImageForUser valueForKey:queryUsername]];
            if (u == nil) u = [NSURL fileURLWithPath:[self.profileImageForUser valueForKey:queryUsername]];
            
            [imageView setImageWithURL:u
                      placeholderImage:[UIImage imageNamed:@"prof-small-1"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                 complete(!!error);
                             }];
             return;
        }
        
        SMQuery *fullUserQuery = [[SMQuery alloc] initWithSchema:@"User"];
        [fullUserQuery where:@"username" isEqualTo: queryUsername];
        

        [self.client.dataStore performQuery:fullUserQuery onSuccess:^(NSArray *results) {
            if ([results count] == 0) {
                complete(NO);
                return;
            }

            [self.profileImageForUser setValue:[results[0] valueForKey:@"profile_image"] forKey:queryUsername];
            [imageView setImageWithURL:[NSURL URLWithString:[results[0] valueForKey:@"profile_image"]]
                 placeholderImage:[UIImage imageNamed:@"prof-small-1"]
                        completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                            complete(!!error);
                        }];
            
        } onFailure:^(NSError *error) {
            complete(NO);
        }];
        
    });
}

-(void)mainS3Upload: (NSString *) filePath
   progressDelegate: (id) progressDelegate
   ancillary: (BOOL) ancillary
   completeCallback: (void (^)(BOOL, NSString *, NSError *)) completeCallback
{
    NSString *bucketName = @"playoff.assets";
    NSString *onServerLocation = [[NSString alloc] initWithFormat: ancillary ? @"ancillary-videos/%@.mov" : @"main-videos/%@.mov",
                                  [PLYUtilities getUUID], nil];
    
    ASIS3ObjectRequest *request = [ASIS3ObjectRequest PUTRequestForFile:filePath withBucket:bucketName key:onServerLocation];
    
    [ASIS3Request setSharedSecretAccessKey:@"YOUR KEY"];
    [ASIS3Request setSharedAccessKey:@"YOUR KEY"];
    
    [request setTimeOutSeconds:15];
    if (progressDelegate) [request setUploadProgressDelegate:progressDelegate];
    
    [request setCompletionBlock:^(void) {
        if ([request error]) {
            completeCallback(NO, nil, [request error]);
        } else {
            NSString *restingPlace = [[NSString alloc] initWithFormat:@"http://s3.amazonaws.com/%@/%@", bucketName, onServerLocation, nil];
            completeCallback(YES, restingPlace, nil);
        }
    }];
    
    [request setFailedBlock:^(void) {
        completeCallback(NO, nil, [request error]);
    }];
    
    [request startAsynchronous];
}

#pragma mark twitter stuff


- (void)twitterSignInWithBlock: (void (^)(BOOL, ACAccount*)) signinBlock
{
    ACAccountStore *store = [[ACAccountStore alloc] init]; // Long-lived
    ACAccountType *twitterType = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    [store requestAccessToAccountsWithType:twitterType withCompletionHandler:^(BOOL granted, NSError *error) {
        if(granted) {
            // Access has been granted, now we can access the accounts
            // Remember that twitterType was instantiated above
            NSArray *twitterAccounts = [store accountsWithAccountType:twitterType];
            
            // If there are no accounts, we need to pop up an alert
            if(twitterAccounts != nil && [twitterAccounts count] == 0) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"No Twitter Accounts"
                                                                message:@"There are no Twitter accounts configured. You can add or create a Twitter account in Settings."
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
                [alert show];
                signinBlock(NO, nil);
            } else {
                ACAccount *account = [twitterAccounts objectAtIndex:0];
                
                if (signinBlock != nil) {
                    signinBlock(YES, account);
                }
                
                //[self tweet:account];
                //http://stackoverflow.com/questions/12037571/is-auto-share-supported-in-ioss-twitter-framework
                
            }
        } else {
            signinBlock(NO, nil);
        }
        // Handle any error state here as you wish
    }];
}

-(void)tweet:(ACAccount *)acct withMessage: (NSString *) message {
    
    NSURL *url = [NSURL URLWithString:@"https://api.twitter.com/1/statuses/update.json"];
    //  Create a POST request for the target endpoint
    TWRequest *request = [[TWRequest alloc] initWithURL:url
                                             parameters:nil
                                          requestMethod:TWRequestMethodPOST];
    
    [request setAccount:acct];
    
    NSDictionary *p = @{ @"status": message	 };
    TWRequest *postRequest = [[TWRequest alloc]
                              initWithURL:   url
                              parameters:    p
                              requestMethod: TWRequestMethodPOST
                              ];
    
    // Post the request
    [postRequest setAccount:acct];
    
    // Block handler to manage the response
    [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *error) {
    }];
    
}

#pragma mark syncing playoffs

- (BOOL) availableUploadsToSync
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *awaitingUpload = [defaults dictionaryForKey:@"serialisedVideosToUpload"];
    return !![awaitingUpload count];
}

- (NSDictionary *) nextUploadToSync
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *awaitingUpload = [defaults dictionaryForKey:@"serialisedVideosToUpload"];
    if ([awaitingUpload count]) {
        return @{
                 @"outstandingCount": [[NSNumber alloc] initWithInt:[awaitingUpload count]],
                 @"playoffId": [[awaitingUpload allKeys] lastObject]
                 };
    } else {
        return nil;
    }
}

- (void) syncUpload: (NSString *) playoffId complete: (void(^)(BOOL, NSString *)) completeCallback
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *awaitingUpload = [[NSMutableDictionary alloc] initWithDictionary:[defaults dictionaryForKey:@"serialisedVideosToUpload"]];
    
    if (awaitingUpload[playoffId]) {
        NSDictionary *p = awaitingUpload[playoffId];

        /* if had previously failed will probably want to delete playoff records at beginning of this */
        [self addNewUpload:p[@"playoffThreadId"]
                 playoffId:playoffId
             mainVideoPath:p[@"mainVideoPath"]
                    tracks:p[@"ancillaryTracks"]
                thumbnails:p[@"ancillaryTracks"]
                  overWWAN:YES
         alreadySerialised:YES
          completeCallback:^(BOOL success, NSString *msg) {
              
            if (success) {
                completeCallback(YES, msg);
                [awaitingUpload removeObjectForKey: playoffId];
                [defaults setValue:defaults forKey:@"serialisedVideosToUpload"];
            } else {
                completeCallback(NO, nil);
            }
        }];
        
    } else {
        completeCallback(NO, nil);
    }
}

- (void) deleteUpload: (NSString *) playoffId
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *awaitingUpload = [[NSMutableDictionary alloc] initWithDictionary:[defaults dictionaryForKey:@"serialisedVideosToUpload"]];
    if (awaitingUpload[playoffId]) {
        NSDictionary *p = awaitingUpload[playoffId];
        
        [self clearUpload: playoffId thumbnails: p[@"thumbnails"] mainVideo:p[@"mainVideoPath"] ancillaries:p[@"ancillaryTracks"]];
    }
}

@end
