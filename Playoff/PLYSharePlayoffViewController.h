//
//  PLYSharePlayoffViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 19/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <StackMob.h>

#import "PLYAppDelegate.h"
#import "PLYSimpleNotificationView.h"

#import "PLYVideoComposer.h"

@interface PLYSharePlayoffViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource,
                    UIAlertViewDelegate, UITextViewDelegate>

@property NSString *playoffThreadId;

@property PLYSimpleNotificationView *notificationView;
@property NSArray *thumbnails;
@property NSArray *inputCells;
@property BOOL useVideo;
@property AVAssetExportSession *assetExportSession;
@property NSArray *rawCompositionItems;
@property UIBarButtonItem *shareButton;

@property UITextView *captionArea;
@property UILabel *captionPlaceholder;

@property UIImageView *thumbnailPreview;

@property NSString *currentlyUploadingPlayoffId;

-(id)initWithImage: (NSURL *) imageURL;
-(id)initWithVideo;

@end
