//
//  PLYAppDelegate.h
//  Playoff
//
//  Created by Arie Lakeman on 28/04/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StackMob.h>
#import <AVFoundation/AVFoundation.h>
#import <ASIHTTPRequest.h>
#import <Twitter/Twitter.h>

#import "PLYHTTPClient.h"
#import "PlayoffThread.h"

typedef void(^EMPTY_CALLBACK)(void);
typedef void(^GET_EMPTY_CALLBACK)(EMPTY_CALLBACK);

extern NSString* const PLYPendingUploadDirectory;
extern NSString* const PLYCacheDirectory;

extern float const MainVideoDim;

@interface PLYAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property UIViewController *loginViewController;

@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) SMCoreDataStore *coreDataStore;
@property (strong, nonatomic) SMClient *client;

@property AFNetworkReachabilityStatus currentReachabilityStatus;
@property BOOL currentlyEmptyingUploadList;

@property NSMutableDictionary *profileImageForUser;

/* playoff upload stuff */
-(void)addUploadToTwitterShare: (NSString *)playoffId;
-(void)addUploadToFacebookShare: (NSString *)playoffId;
-(void)addUploadToYouTubeShare: (NSString *)playoffId;

-(void)setUploadDetails: (NSString *)playoffId details:(NSDictionary *)details;

-(void) downloadVideoPlayoff: (NSString *) playoffId
                    videoURL: (NSString *) videoURL
            progressDelegate: (id) progressDelegate
                    callback: (void (^)(BOOL, NSString *, NSError *, NSString *)) completeCallback
           getCancelCallback: (GET_EMPTY_CALLBACK) emptyCallback;

-(void) downloadVideoPlayoffTracks: (NSString *)playoffId
                     trackCallback: (void (^)(BOOL, NSDictionary *, NSString *, NSError *, NSString *)) trackCallback
             initialTracksCallback: (NSArray * (^)(BOOL, NSArray *)) initialTracksCallback
                 allTracksCallback: (void (^)(BOOL, NSError *)) allTracksCallback;

-(void)addNewUpload: (NSString *) playoffThreadId
          playoffId: (NSString *) playoffId
      mainVideoPath: (NSString *)mainVideoPath
             tracks: (NSArray *)ancillaryTracks
         thumbnails: (NSArray *)thumbnails
           overWWAN: (BOOL) overWWAN
  alreadySerialised: (BOOL) alreadySerialised
   completeCallback: (void(^)(BOOL, NSString *)) completeCallback;

-(void)addDeferredUpload: (NSString *) playoffThreadId
               playoffId: (NSString *) playoffId
           mainVideoPath: (NSString *)mainVideoPath
                  tracks: (NSArray *)ancillaryTracks
              thumbnails: (NSArray *)thumbnails;

-(void)checkAndCreateDefaultDirectories;

-(void(^)(void)) downloadWebVideo: (NSString *)url
                fileName: (NSString *) fileName
           withExtension: (NSString *) ext
               withBlock: (void (^)(BOOL, NSString *)) complete
     andProgressDelegate: (id) progressDelegate;

-(void)simpleWebRequest:(NSString *) url withBlock: (void (^)(BOOL, NSString *)) complete;

/* get processed playoff thread */
-(NSMutableDictionary *) getProcessedPlayoff: (NSDictionary *)p;

-(NSDictionary *) getProcessedThread: (PlayoffThread *) thread
                      threadCaptions: (NSArray *)threadCaptions
                      threadPlayoffs: (NSArray *)threadPlayoffs;

/* like playoff */
-(void) likePlayoff: (NSString *)playoffId completeCallback: (void (^)(BOOL, BOOL, int, NSError *)) completeCallback;
-(BOOL) alreadyLikedPlayoff: (NSString *)playoffId;
-(void) flagPlayoff: (NSString *)playoffId;

/* facebook session stuff */
-(void)openSessionWithCanShowError:(BOOL)canShow
                    stateOpenBlock:(void (^)(void))stateOpen
                  stateClosedBlock:(void (^)(void))stateClosed;

/* user login stuff */
-(void)presentLogin: (BOOL) aboveTabBar;
-(void)completeUserLogin;
-(void)setProfileImage: (NSString *)username imageView: (UIImageView *)imageView withBlock: (void (^)(BOOL)) complete;

// twitter
- (void)twitterSignInWithBlock: (void (^)(BOOL, ACAccount*)) signinBlock;
- (void)tweet:(ACAccount *)acct withMessage: (NSString *) message;

// syncing uploads
- (BOOL) availableUploadsToSync;
- (NSDictionary *) nextUploadToSync;
- (void) syncUpload: (NSString *) playoffId complete: (void(^)(BOOL, NSString *)) completeCallback;
- (void) deleteUpload: (NSString *) playoffId;

@end
