//
//  PLYCustomRefreshView.m
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYCustomRefreshView.h"
#import "PLYTheme.h"

@implementation PLYCustomRefreshView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _barColor = [UIColor lightGrayColor];
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_indicator setHidesWhenStopped:YES];
        [self addSubview:_indicator];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _indicator.center = CGPointMake(floorf(self.bounds.size.width / 2.0f),
                                    floorf(self.bounds.size.height / 2.0f - 10));
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[PLYTheme backgroundVeryLightColor] set];
    CGContextFillRect(context, self.bounds);
    [_barColor set];
    
    CGFloat width = self.bounds.size.width;
    CGFloat height = self.bounds.size.height;
    
    _progress = MIN(1.0, _progress);
    
    CGFloat barHeight = 10;
    CGFloat barPad = 1;

    CGFloat bar1Width = exp(_progress * 2) * 1.2;
    CGFloat bar2Width = exp(_progress * 3.5) * 3;
    CGFloat bar3Width = exp(_progress * 4) * 5.6;
    
    CGRect rect1 = CGRectMake(width / 2 - bar1Width / 2, height - (barHeight * 3 + barPad * 2), bar1Width, barHeight);
    CGRect rect2 = CGRectMake(width / 2 - bar2Width / 2, height - (barHeight * 2 + barPad * 1), bar2Width, barHeight);
    CGRect rect3 = CGRectMake(width / 2 - bar3Width / 2, height - (barHeight * 1 + barPad * 0), bar3Width, barHeight);
    
    CGContextFillRect(context, rect1);
    CGContextFillRect(context, rect2);
    CGContextFillRect(context, rect3);
}

/**
 The pull to refresh view's state has changed. The content view must update itself. All content view's must implement
 this method.
 */
- (void)setState:(SSPullToRefreshViewState)state withPullToRefreshView:(SSPullToRefreshView *)view {
    switch (state) {
        case SSPullToRefreshViewStateNormal:
            _barColor = [PLYTheme primaryColorLight];
            break;
            
        case SSPullToRefreshViewStateLoading:
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
            [_indicator startAnimating];
            _barColor = [PLYTheme backgroundMediumColor];
            break;
            
        case SSPullToRefreshViewStateReady:
            _barColor = [PLYTheme primaryColorDark];
            break;
            
        case SSPullToRefreshViewStateClosing:
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            [_indicator stopAnimating];
            _barColor = [UIColor whiteColor];
            break;
            
        default:
            break;
    }
}

- (void)setPullProgress:(CGFloat)pullProgress {
    _progress = pullProgress;
    [self setNeedsDisplay];
}

@end
