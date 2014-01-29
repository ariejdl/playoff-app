//
//  PLYRefreshTableViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"

@interface PLYRefreshTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate, SSPullToRefreshViewDelegate>

@property (nonatomic, strong) SSPullToRefreshView *pullToRefreshView;

@end
