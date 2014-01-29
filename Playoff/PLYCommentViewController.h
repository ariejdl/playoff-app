//
//  PLYCommentViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 08/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLYCommentViewController : UIViewController<UITableViewDelegate, UITableViewDataSource>

@property int currentPage;
@property int pageOffset;
@property NSMutableArray *comments;
@property NSString *playoffId;
@property BOOL startShowKeyboard;
@property BOOL startingEmpty;
@property UIButton *loadMoreBut;

@property UITableView *tableView;
@property UIView *loadingView;
@property UITextField *textField;

-(id)initWithPlayoffId: (NSString *) playoffId withKeyboard: (BOOL) showKeyboard;

@end
