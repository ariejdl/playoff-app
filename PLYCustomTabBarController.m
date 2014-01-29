//
//  PLYCustomTabBarController.m
//  Playoff
//
//  Created by Arie Lakeman on 28/04/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYCustomTabBarController.h"
#import "PLYCaptureViewController.h"

@implementation PLYCustomTabBarController

@synthesize homeButton = _homeButton;
@synthesize exploreButton = _exploreButton;

-(void)beginWithExplore {
    self.doBeginWithExplore = TRUE;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.delegate = self;
    
    /* custom center button stuff*/
    UIImage *captureImage = [UIImage imageNamed:@"capture-but-1"];
    UIImage *captureImageSel = [UIImage imageNamed:@"capture-but-sel-1"];
    
    UIButton* captureButton = [UIButton buttonWithType:UIButtonTypeCustom];
    captureButton.frame = CGRectMake(0.0, 0.0, captureImage.size.width, captureImage.size.height);
    [captureButton setBackgroundImage:captureImage forState:UIControlStateNormal];
    [captureButton setBackgroundImage:captureImageSel forState:UIControlStateHighlighted];
    
    CGFloat heightDifference = captureImage.size.height - self.tabBar.frame.size.height;
    if (heightDifference < 0)
        captureButton.center = self.tabBar.center;
    else {
        CGPoint center = self.tabBar.center;
        center.y = center.y - heightDifference/2.0;
        captureButton.center = center;
    }
    
    
    [captureButton addTarget:self action:@selector(captureButtonEvent) forControlEvents:UIControlEventTouchUpInside];
    
    //    [self setSelectedIndex:0];
    
    /* setting up custom icons */
    UIImage *homeImage = [UIImage imageNamed:@"home-but-1.png"];
    UIImage *homeImageHigh = [UIImage imageNamed:@"home-but-high-1.png"];
    UIImage *homeImageSel = [UIImage imageNamed:@"home-but-sel-1.png"];
    
    UIImage *expImage = [UIImage imageNamed:@"explore-but-1.png"];
    UIImage *expImageHigh = [UIImage imageNamed:@"explore-but-high-1.png"];
    UIImage *expImageSel = [UIImage imageNamed:@"explore-but-sel-1.png"];
    
    CGSize screenDim = [[UIScreen mainScreen] bounds].size;
    
    UIButton* homeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    homeButton.frame = CGRectMake(0.0, screenDim.height - homeImage.size.height, homeImage.size.width, homeImage.size.height);
    [homeButton setBackgroundImage:homeImage forState:UIControlStateNormal];
    [homeButton setBackgroundImage:homeImageSel forState:UIControlStateSelected];
    [homeButton setBackgroundImage:homeImageHigh forState:UIControlStateHighlighted];
    [homeButton setBackgroundImage:homeImageSel forState:UIControlStateSelected | UIControlStateHighlighted];
    
    UIButton* expButton = [UIButton buttonWithType:UIButtonTypeCustom];
    expButton.frame = CGRectMake(screenDim.width - homeImage.size.width,
                                 screenDim.height - homeImage.size.height,
                                 expImage.size.width, expImage.size.height);
    [expButton setBackgroundImage:expImage forState:UIControlStateNormal];
    [expButton setBackgroundImage:expImageSel forState:UIControlStateSelected];
    [expButton setBackgroundImage:expImageHigh forState:UIControlStateHighlighted];
    [expButton setBackgroundImage:expImageSel forState:UIControlStateSelected | UIControlStateHighlighted];

    [homeButton addTarget:self action:@selector(homeButtonEvent) forControlEvents:UIControlEventTouchUpInside];
    [expButton addTarget:self action:@selector(exploreButtonEvent) forControlEvents:UIControlEventTouchUpInside];
    
// old way
//    [self.view addSubview:captureButton];
//    [self.view addSubview:homeButton];
//    [self.view addSubview:expButton];
    
    [homeButton setFrame:CGRectMake(0, 0, homeImage.size.width, homeImage.size.height)];
    [self.tabBar insertSubview:homeButton aboveSubview:self.tabBar.subviews[[self.tabBar.subviews count] - 1]];
    
    [captureButton setFrame:CGRectMake(homeImage.size.width, 0, captureImage.size.width, captureImage.size.height)];
    [self.tabBar insertSubview:captureButton aboveSubview:self.tabBar.subviews[[self.tabBar.subviews count] - 1]];
    
    [expButton setFrame:CGRectMake(homeImage.size.width + captureImage.size.width, 0,
                                   expImage.size.width, expImage.size.height)];
    [self.tabBar insertSubview:expButton aboveSubview:self.tabBar.subviews[[self.tabBar.subviews count] - 1]];
    
    self.homeButton = homeButton;
    self.exploreButton = expButton;
    
    if (self.doBeginWithExplore) {
        [self exploreButtonEvent];
    } else {
        [self homeButtonEvent];
    }

}

-(void)homeButtonEvent
{
    [self.exploreButton setSelected:NO];
    [self.homeButton setSelected:YES];
    [self setSelectedIndex:0];
}

-(void)exploreButtonEvent
{
    [self.exploreButton setSelected:YES];
    [self.homeButton setSelected:NO];
    [self setSelectedIndex:2];
}

- (void) captureButtonEvent{
    UIViewController *capVC = [[PLYCaptureViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:capVC];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"startCapturingMain" object:nil];
    
    [self presentViewController:nav animated:YES completion:nil];
}

@end
