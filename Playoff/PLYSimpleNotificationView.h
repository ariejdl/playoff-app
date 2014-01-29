//
//  PLYSimpleNotificationViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 12/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>

// TODO: in future implement with a delegate

@interface PLYSimpleNotificationView : NSObject

@property UIView *notification;
@property UINavigationBar *customNavBar;
@property UINavigationController *navigationController;

@property(atomic) BOOL currentlyAnimating;
@property(atomic) BOOL currentlyShowing;

-(id)initWithCustomNavBar: (UINavigationBar *)navBar;
-(id)initWithNavigationController: (UINavigationController *) navController;

-(void)animateInNotificationWithMessage:(NSString *)msg;
-(void)animateOutNotification;

@end