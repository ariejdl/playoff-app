//
//  PLYSignInViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 28/04/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLYSimpleNotificationView.h"

@interface PLYSignInViewController : UIViewController<UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource>

@property NSArray *rows;
@property (atomic) BOOL startedLoading;
@property PLYSimpleNotificationView *notificationView;
@property UIView *loaderView;

@end
