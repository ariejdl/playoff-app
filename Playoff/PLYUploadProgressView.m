//
//  PLYUploadProgressView.m
//  Playoff
//
//  Created by Arie Lakeman on 06/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYUploadProgressView.h"
#import <QuartzCore/QuartzCore.h>
#import "PLYTheme.h"

#define MAIN_MARGIN_TOP 85
#define MAIN_MARGIN_SIDE 20

#define MAIN_PAD 20
#define TEXT_WIDTH 240
#define TITLE_HEIGHT 32
#define SPINNER_HEIGHT 37
#define LOADER_HEIGHT 26
#define LOADER_WIDTH 200
#define LOADER_PAD 4
#define DETAIL_LABEL_HEIGHT 25

#define CONTENT_ITEMS_HEIGHT (TITLE_HEIGHT + MAIN_PAD + SPINNER_HEIGHT + MAIN_PAD + LOADER_HEIGHT + MAIN_PAD + DETAIL_LABEL_HEIGHT)


@implementation PLYUploadProgressView

- (id)initWithFrame:(CGRect)rect
{
    self = [super initWithFrame:rect];
    if (self) {
        self.alpha = 0.0;
        [self setBackgroundColor:[UIColor clearColor]];
        [self setupWithRect:rect];
    }
    return self;
}

- (void)setupWithRect: (CGRect) rect
{
    CGRect backgroundFrame = CGRectMake(MAIN_MARGIN_SIDE, MAIN_MARGIN_TOP,
                                        rect.size.width - (MAIN_MARGIN_SIDE * 2),
                                        rect.size.height - (MAIN_MARGIN_TOP * 2));
    float startingY = (backgroundFrame.size.height / 2) - (CONTENT_ITEMS_HEIGHT / 2);
    float textX = (backgroundFrame.size.width / 2) - (TEXT_WIDTH / 2);
    UIView *background = [[UIView alloc] initWithFrame:backgroundFrame];
    background.layer.cornerRadius = 6;
    [background setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]];
    [self addSubview:background];
    
    UILabel *label;
    UIView *rectView;
    UIImageView *imageView;
    
    // title label
    label = [[UILabel alloc] initWithFrame:CGRectMake(textX, startingY, TEXT_WIDTH, TITLE_HEIGHT)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:22]];
    [background addSubview:label];
    self.titleLabel = label;
    
    // activity
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [activityIndicator setFrame: CGRectMake((backgroundFrame.size.width / 2) - (38 / 2),
                                            startingY + TITLE_HEIGHT + MAIN_PAD, SPINNER_HEIGHT, SPINNER_HEIGHT)];
    [background addSubview:activityIndicator];
    self.spinner = activityIndicator;
    
    
    // detail text
    label = [[UILabel alloc] initWithFrame:CGRectMake(textX,
                                                      startingY + TITLE_HEIGHT + MAIN_PAD + SPINNER_HEIGHT + MAIN_PAD,
                                                      TEXT_WIDTH, DETAIL_LABEL_HEIGHT)];
    [label setTextAlignment:NSTextAlignmentCenter];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor whiteColor]];
    [background addSubview:label];
    [label setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:14]];
    self.detailLabel = label;
    
    // background progress
    imageView = [[UIImageView alloc] initWithFrame:CGRectMake((backgroundFrame.size.width / 2) - (LOADER_WIDTH / 2),
                                                        startingY + TITLE_HEIGHT + MAIN_PAD + SPINNER_HEIGHT + MAIN_PAD + DETAIL_LABEL_HEIGHT + MAIN_PAD,
                                                        LOADER_WIDTH, LOADER_HEIGHT)];
    [imageView setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.2]];
    [imageView setHidden:YES];
    imageView.layer.cornerRadius = 2;
    self.progressBack = imageView;
    [background addSubview:imageView];
    
    // progress itself
    rectView = [[UIView alloc] init];
    [rectView setHidden:YES];
    [rectView setBackgroundColor:[UIColor whiteColor]];
    rectView.layer.cornerRadius = 2;
    self.progressBar = rectView;
    [background addSubview:rectView];
    
}

-(void) startWithTitle:(NSString *)title withDetailTitle:(NSString *)detailTitle
{
    [self.titleLabel setText:title];
    [self.detailLabel setText:detailTitle];
    [self.spinner startAnimating];
    [self fadeIn];
}

-(void)fadeIn
{
    self.alpha = 0.0;
    [UIView animateWithDuration:0.25 animations:^{self.alpha = 1.0;}];
}

-(void)finish
{
    [UIView animateWithDuration:0.25 animations:^{self.alpha = 0.0;} completion:^(BOOL finished) {
        [self.spinner stopAnimating];
        [self removeFromSuperview];
    }];
}

-(void)setTitle:(NSString *)title
{
    [self.titleLabel setText:title];
}

-(void)setDetailTitle:(NSString *)detailTitle
{
    [self.detailLabel setText:detailTitle];
}

-(void)hideProgress
{
    [self.progressBack setHidden:YES];
    [self.progressBar setHidden:YES];
}

-(void)setProgress:(float)newProgress
{
    [self.progressBack setHidden:NO];
    [self.progressBar setHidden:NO];
    
    CGRect baseFrame = self.progressBack.frame;
    [self.progressBar setFrame:CGRectMake(baseFrame.origin.x + LOADER_PAD,
                                          baseFrame.origin.y + LOADER_PAD,
                                          (baseFrame.size.width - LOADER_PAD - LOADER_PAD) * newProgress,
                                          baseFrame.size.height - LOADER_PAD * 2)];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
