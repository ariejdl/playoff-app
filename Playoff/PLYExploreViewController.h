//
//  PLYExploreViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <StackMob.h>

#import "PLYRefreshTableViewController.h"
#import "PLYSlideDownButtonList.h"

@interface PLYExploreViewController : PLYRefreshTableViewController

@property (nonatomic, retain) NSMutableArray *currentData;
@property PLYSlideDownButtonList *slideDownButtons;
@property UIButton *loadMoreBut;

@property int currentPage;
@property NSString *currentExploreCategory;

@end
