//
//  PLYRegisterViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 29/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLYSimpleNotificationView.h"

@interface PLYRegisterViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property NSArray *rows;
@property PLYSimpleNotificationView *notificationView;
@property (atomic) BOOL startedLoading;
@property UIView *loaderView;

@end
