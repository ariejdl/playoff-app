//
//  PLYCustomTabBarController.h
//  Playoff
//
//  Created by Arie Lakeman on 28/04/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLYCustomTabBarController : UITabBarController<UITabBarControllerDelegate>

@property UIButton *homeButton;
@property UIButton *exploreButton;

@property BOOL doBeginWithExplore;

-(void)beginWithExplore;
-(void)exploreButtonEvent;

@end
