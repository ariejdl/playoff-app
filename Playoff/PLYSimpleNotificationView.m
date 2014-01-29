//
//  PLYSimpleNotificationViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 12/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYSimpleNotificationView.h"
#import "PLYCustomNavigationBar.h"
#import "PLYTheme.h"

#define NOTIFICATION_HEIGHT 44
#define LABEL_TAG 100

@implementation PLYSimpleNotificationView

@synthesize customNavBar;
@synthesize navigationController;

-(void)doSetup
{
    if (self) {
        self.currentlyShowing = FALSE;
        self.currentlyAnimating = FALSE;
        
        UIView *notification = [[UIView alloc]
                                initWithFrame:CGRectMake(0, 0, 320, NOTIFICATION_HEIGHT)];
        UILabel *text = [[UILabel alloc] initWithFrame:CGRectMake(8, 2, 300, 40)];
        [text setBackgroundColor:[UIColor clearColor]];
        [text setTextColor:[UIColor whiteColor]];
        [text setTextAlignment:NSTextAlignmentCenter];
        [text setTag:LABEL_TAG];
        [text setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:16]];
        
        [notification setBackgroundColor:[UIColor colorWithRed:0.906 green:0.063 blue:0.333 alpha:0.75]];
        
        [notification addSubview:text];
        self.notification = notification;
        
        if (self.customNavBar) {
            [self.customNavBar.superview insertSubview:self.notification
                                          belowSubview:self.customNavBar];
            
        } else if (self.navigationController &&
                   self.navigationController.navigationBar &&
                   !self.navigationController.navigationBar.isHidden) {
            
            [self.navigationController.navigationBar.superview insertSubview:self.notification
                                                                belowSubview:self.navigationController.navigationBar];
            
        }
    }
}

-(id)initWithCustomNavBar: (UINavigationBar *)navBar
{
    self = [super init];
    [self setCustomNavBar:navBar];
    [self doSetup];
    return self;
}

-(id)initWithNavigationController: (UINavigationController *) navController
{
    self = [super init];
    [self setNavigationController:navController];
    [self doSetup];
    return self;
}

-(void)animateInNotificationWithMessage:(NSString *)msg
{
    if (self.currentlyShowing) {
        return;
    }
    
    if (self.currentlyAnimating) {
        return;
    }
    
    self.currentlyAnimating = TRUE;
    self.currentlyShowing = TRUE;
    
    [(UILabel *)[self.notification viewWithTag:LABEL_TAG] setText:msg];
    
    CGPoint pt = self.notification.center;
    
    [UIView animateWithDuration: 0.4
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){
        [self.notification setCenter: CGPointMake(pt.x, pt.y + NOTIFICATION_HEIGHT)];
    }completion:^(BOOL finished){
        self.currentlyAnimating = FALSE;
        //this code is called after the aminations have completed
        double delayInSeconds = 2.0;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self animateOutNotification];
        });
    }];

}

-(void)animateOutNotification
{
    if (!self.currentlyShowing) {
        return;
    }
    
    if (self.currentlyAnimating) {
        return;
    }
    self.currentlyAnimating = TRUE;
    self.currentlyShowing = FALSE;
    
    CGPoint pt = self.notification.center;
    
    [UIView animateWithDuration: 0.4
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){
                         [self.notification setCenter: CGPointMake(pt.x, pt.y - NOTIFICATION_HEIGHT)];
                     }completion:^(BOOL finished){
                         self.currentlyAnimating = FALSE;
                     }];
}



@end
