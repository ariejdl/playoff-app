//
//  PLYSplashViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 29/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYSplashViewController.h"
#import "PLYTheme.h"
#import "PLYRegisterViewController.h"
#import "PLYSignInViewController.h"

#define MAIN_PAD 0
#define BUT_HEIGHT 50

@implementation PLYSplashViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setBackgroundColor:[PLYTheme primaryColor]];
    
    UIImage *butImage1 = [UIImage imageNamed:@"block-white-1"];
    UIImage *butImageMed = [UIImage imageNamed:@"block-white-med-1"];
    UIImage *butImage2 = [UIImage imageNamed:@"block-white-high-1"];
    butImage1 = [butImage1 resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    butImage2 = [butImage2 resizableImageWithCapInsets:UIEdgeInsetsMake(6, 6, 6, 6)];
    
    CGFloat screenHeight = [[UIScreen mainScreen] applicationFrame].size.height;
    UIButton *registerBut = [[UIButton alloc] initWithFrame:
                             CGRectMake(MAIN_PAD, screenHeight - (MAIN_PAD + BUT_HEIGHT + MAIN_PAD + BUT_HEIGHT), 320 - (MAIN_PAD * 2), BUT_HEIGHT)];

    [registerBut setBackgroundImage: butImageMed forState:UIControlStateNormal];
    [registerBut setBackgroundImage: butImage2 forState:UIControlStateHighlighted];
    
    [registerBut setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
    [registerBut setTitle:@"Register" forState:UIControlStateNormal];
    [registerBut addTarget:self action:@selector(registerTap) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:registerBut];
    
    UIButton *signInBut = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD, screenHeight - (MAIN_PAD + BUT_HEIGHT), 320 - (MAIN_PAD * 2), BUT_HEIGHT)];
    
    [signInBut setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
    [signInBut setTitle:@"Sign In" forState:UIControlStateNormal];
    [signInBut addTarget:self action:@selector(signInTap) forControlEvents:UIControlEventTouchUpInside];
    
    [signInBut setBackgroundImage: butImage1 forState:UIControlStateNormal];
    [signInBut setBackgroundImage: butImage2 forState:UIControlStateHighlighted];
    
    [self.view addSubview:signInBut];
    
    /* splash image */
    CGFloat splashHeight = screenHeight - (MAIN_PAD * 3 + BUT_HEIGHT * 2);
    UIImageView *splashImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, splashHeight)];

    if (screenHeight == 460) {
        [splashImage setImage: [UIImage imageNamed: @"splash-image-1"]];
    } else {
        [splashImage setImage: [UIImage imageNamed: @"splash-image-tall-1"]];
    }
    
    [self.view addSubview:splashImage];

}

-(void)registerTap
{
    [self.navigationController pushViewController:[[PLYRegisterViewController alloc] init] animated:YES];
}

-(void)signInTap
{
    [self.navigationController pushViewController:[[PLYSignInViewController alloc] init] animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
