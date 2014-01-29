//
//  PLYUserInformationView.m
//  Playoff
//
//  Created by Arie Lakeman on 03/08/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYUserInformationView.h"
#import "PLYTheme.h"

#import <QuartzCore/QuartzCore.h>

#define PAD_TOP 50
#define PAD_SIDE 5
#define PAD_BOT 54
#define MAIN_PAD 12

#define kTransitionDuration 0.3

@implementation PLYUserInformationView

@synthesize firstUseKey = _firstUseKey;

- (id)initWithImage:(NSString *)imageName andFirstUseKey: (NSString *) firstUseKey
{
    return [self initWithImage:imageName andFirstUseKey:firstUseKey white:NO];
}

- (id)initWithImage:(NSString *)imageName andFirstUseKey: (NSString *) firstUseKey white: (BOOL) white
{
    CGRect frame = [[UIScreen mainScreen] applicationFrame];
    
    self = [super initWithFrame:frame];
    [self setFrame:frame];
    
    if (self) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if (![defaults valueForKey:firstUseKey]) {
            self.firstUseKey = firstUseKey;
            [self setupImage:imageName white:white];
            return self;
        }
    }
    return nil;
}

-(void) setupImage: (NSString *) imageName white: (BOOL) white
{
    CGSize screenDim = [[UIScreen mainScreen] applicationFrame].size;
    CGRect frame = CGRectMake(PAD_SIDE, PAD_TOP, screenDim.width - (PAD_SIDE * 2), screenDim.height - (PAD_TOP + PAD_BOT));
    UIView *background = [[UIView alloc] initWithFrame:frame];
    
    [background setBackgroundColor:[UIColor colorWithWhite:white ? 1 : 0 alpha:0.5]];
    UIImage *img = [UIImage imageNamed:imageName];
    background.layer.cornerRadius = 4;
    
    CGFloat butWidth = 280;
    CGFloat butHeight = 40;

    UIImageView *mainImage = [[UIImageView alloc] initWithImage:img];
    [mainImage setFrame:CGRectMake((frame.size.width / 2) - (img.size.width / 2), MAIN_PAD, img.size.width, img.size.height)];
    [background addSubview:mainImage];
    
    UIButton *acknowledgeBut = [[UIButton alloc] initWithFrame:CGRectMake((frame.size.width / 2) - (butWidth / 2),
                                                                          frame.size.height - (MAIN_PAD + butHeight),
                                                                          butWidth, butHeight)];
    
    [acknowledgeBut setTitle:@"OK!" forState:UIControlStateNormal];
    [acknowledgeBut addTarget:self action:@selector(tapAcknowledgement) forControlEvents:UIControlEventTouchUpInside];
    
    UIImage *butImage1 = [UIImage imageNamed: @"info-but-white-1"];
    UIImage *butImage2 = [UIImage imageNamed: @"info-but-white-high-1"];
    
    butImage1 = [butImage1 resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    butImage2 = [butImage2 resizableImageWithCapInsets:UIEdgeInsetsMake(8, 8, 8, 8)];
    
    [acknowledgeBut setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:20]];
    
    [acknowledgeBut setBackgroundImage:butImage1 forState:UIControlStateNormal];
    [acknowledgeBut setBackgroundImage:butImage2 forState:UIControlStateHighlighted];
    
    [background addSubview:acknowledgeBut];
    
    [self addSubview:background];
    self.backgroundView = background;
    /* animation */

    self.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 0.4, 0.4);
    self.backgroundView.alpha = 0;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationDelegate:self];
    self.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
    self.backgroundView.alpha = 1.0;
    [UIView commitAnimations];
}

-(void) tapAcknowledgement
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setValue:@YES forKey:self.firstUseKey];
    
    self.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, 1);
    self.backgroundView.alpha = 1;
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:kTransitionDuration];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(finishAnimate)];
    self.backgroundView.transform = CGAffineTransformScale(CGAffineTransformIdentity, 1.4, 1.4);
    self.backgroundView.alpha = 0;
    [UIView commitAnimations];
}

-(void)finishAnimate
{
    [self removeFromSuperview];
}

@end
