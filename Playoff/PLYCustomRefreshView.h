//
//  PLYCustomRefreshView.h
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SSPullToRefresh.h"

@interface PLYCustomRefreshView : UIView <SSPullToRefreshContentView>

{
    CGFloat _progress;
    UIColor *_barColor;
    UIActivityIndicatorView *_indicator;
}

@end
