//
//  PLYHomeViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYRefreshTableViewController.h"

#import "PLYSlideDownButtonList.h"

@interface PLYHomeViewController : PLYRefreshTableViewController<UIAlertViewDelegate>

@property (nonatomic, retain) NSMutableArray *currentData;
@property int currentPage;
@property UIButton *loadMoreBut;


@end
