//
//  PLYSlideDownButtonList.m
//  Playoff
//
//  Created by Arie Lakeman on 02/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYSlideDownButtonList.h"
#import "PLYTheme.h"

#define NAVBAR_HEIGHT 44
#define BUTTON_HEIGHT 44

@implementation PLYSlideDownButtonList

@synthesize customNavBar = _customNavBar;
@synthesize navigationController = _navigationController;
@synthesize tappableButtons = _tappableButtons;

-(void)doSetup: (NSArray *) buttons customTopOffset: (int) topOffset
{
    if (self) {
        NSMutableArray *tappableButtons = [[NSMutableArray alloc] init];
        self.currentlyShowing = FALSE;
        self.currentlyAnimating = FALSE;
        
        self.slideDownHeight = [buttons count] * BUTTON_HEIGHT;
        
        UIView *slideDownView = [[UIView alloc] initWithFrame:CGRectMake(0, - self.slideDownHeight + NAVBAR_HEIGHT + topOffset,
                                                                         320, self.slideDownHeight)];
        UIButton *mainBtn;
        
        int btnIdx = 0;
        for (NSString *buttonName in buttons) {
            mainBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, btnIdx * BUTTON_HEIGHT, 320, BUTTON_HEIGHT)];
            
            [mainBtn setTitle:buttonName forState:UIControlStateNormal];
            [mainBtn setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
            [tappableButtons addObject:mainBtn];
            
            [slideDownView addSubview:mainBtn];
            
            if (btnIdx == [buttons count] - 1) {
                [mainBtn setBackgroundImage:[UIImage imageNamed:@"slide-but-high-last-1"] forState:UIControlStateHighlighted];
                [mainBtn setBackgroundImage:[UIImage imageNamed:@"slide-but-last-1"] forState:UIControlStateNormal];
            } else {
                [mainBtn setBackgroundImage:[UIImage imageNamed:@"slide-but-high-1"] forState:UIControlStateHighlighted];
                [mainBtn setBackgroundImage:[UIImage imageNamed:@"slide-but-1"] forState:UIControlStateNormal];
            }
            
            btnIdx += 1;
        }
        
        self.tappableButtons = tappableButtons;
        self.slideDownView = slideDownView;
        
        /* insertion */
        
        if (self.customNavBar) {
            [self.customNavBar.superview insertSubview:self.slideDownView
                                          belowSubview:self.customNavBar];
            
        } else if (self.navigationController &&
                   self.navigationController.navigationBar &&
                   !self.navigationController.navigationBar.isHidden) {
            
            [self.navigationController.navigationBar.superview insertSubview:self.slideDownView
                                                                belowSubview:self.navigationController.navigationBar];
            
        }
        
    }
}

-(id)initWithCustomNavBar: (UINavigationBar *)navBar
                  buttons: (NSArray *) buttons
          customTopOffset: (int) topOffset
{
    self = [super init];
    [self setCustomNavBar:navBar];
    [self doSetup:buttons customTopOffset:topOffset];
    return self;
}

-(id)initWithNavigationController: (UINavigationController *) navController
                          buttons: (NSArray *) buttons
                  customTopOffset: (int) topOffset
{
    self = [super init];
    [self setNavigationController:navController];
    [self doSetup:buttons customTopOffset:topOffset];
    return self;
}

-(void)animateSlideDownButtons
{
    if (self.currentlyShowing) {
        return;
    }
    
    if (self.currentlyAnimating) {
        return;
    }
    
    self.currentlyAnimating = TRUE;
    self.currentlyShowing = TRUE;
    
    CGPoint pt = self.slideDownView.center;
    
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){
                         [self.slideDownView setCenter: CGPointMake(pt.x, pt.y + self.slideDownHeight)];
                     }completion:^(BOOL finished){
                         self.currentlyAnimating = FALSE;
                     }];
    
}

-(void)animateSlideUpButtons
{
    if (!self.currentlyShowing) {
        return;
    }
    
    if (self.currentlyAnimating) {
        return;
    }
    self.currentlyAnimating = TRUE;
    self.currentlyShowing = FALSE;
    
    CGPoint pt = self.slideDownView.center;
    
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){
                         [self.slideDownView setCenter: CGPointMake(pt.x, pt.y - self.slideDownHeight)];
                     }completion:^(BOOL finished){
                         self.currentlyAnimating = FALSE;
                     }];
}


@end
