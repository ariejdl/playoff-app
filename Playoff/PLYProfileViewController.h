//
//  PLYProfileViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 15/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLYProfileViewController : UITableViewController<UIAlertViewDelegate>

@property int currentPage;
@property NSMutableArray *currentData;
@property NSString *myUsername;
@property NSString *currentUsername;
@property NSDictionary *profileDict;
@property BOOL isSelf;
@property UIImageView *profileImageView;
@property UIView *loaderView;
@property UIButton *followButton;
@property (atomic) BOOL followingTransition;
@property (atomic) int initDownloadCount;
@property UIButton *loadMoreBut;

-(id) initWithUsername: (NSString *) username;
-(void)reloadUserInfo;

@end
