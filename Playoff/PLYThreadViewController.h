//
//  PLYThreadViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 04/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PLYRefreshTableViewController.h"
#import "PLYExpandedViewCell.h"

@interface PLYThreadViewController : PLYRefreshTableViewController<UITableViewDelegate, UIAlertViewDelegate>

@property NSMutableArray *currentData;
@property (nonatomic, weak) PLYExpandedViewCell *currentCell;
@property NSString *singlePlayoffId;
@property NSString *playoffThreadId;
@property int maxOffset;
@property int currentPage;
@property UIButton *loadMoreBut;

@property BOOL singlePlayoff;
@property BOOL startingEmpty;

//-(id)initWithThread: (NSDictionary *)playoff;
-(id)initWithSinglePlayoffId: (NSString *) playoffId;
-(id)initWithThreadId: (NSString *)threadId;

-(void)highlightMostVisible;
-(void)startCurrent;

@end
