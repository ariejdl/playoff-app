//
//  PLYSlideDownButtonList.h
//  Playoff
//
//  Created by Arie Lakeman on 02/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLYSlideDownButtonList : NSObject

@property UIView *slideDownView;
@property UINavigationBar *customNavBar;
@property UINavigationController *navigationController;

@property(atomic) BOOL currentlyAnimating;
@property(atomic) BOOL currentlyShowing;

@property NSArray *tappableButtons;
@property int slideDownHeight;

-(id)initWithCustomNavBar: (UINavigationBar *)navBar
                  buttons: (NSArray *) buttons
          customTopOffset: (int) topOffset;

-(id)initWithNavigationController: (UINavigationController *) navController
                          buttons: (NSArray *) buttons
                  customTopOffset: (int) topOffset;

-(void)animateSlideDownButtons;
-(void)animateSlideUpButtons;

@end
