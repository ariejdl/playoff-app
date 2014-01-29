//
//  PLYTheme.m
//  Playoff
//
//  Created by Arie Lakeman on 17/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYTheme.h"

@implementation PLYTheme

// http://support.apple.com/kb/HT5484?viewlocale=en_US&locale=en_US
+(NSString *) defaultFontName { return @"HelveticaNeue-Light"; }
+(NSString *) boldDefaultFontName  { return @"HelveticaNeue-Light"; }

+(int) smallFont { return 10; }
+(int) mediumFont { return 14; }
+(int) largeFont { return 20; }

+(UIFont *) mediumDefaultFont { return [UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme mediumFont]]; }

+(UIColor *) primaryColor { return [UIColor colorWithRed:0.906 green:0.063 blue:0.333 alpha:1]; }
+(UIColor *) primaryColorLight { return [UIColor colorWithRed:0.937 green:0.290 blue:0.529 alpha:1]; }
+(UIColor *) primaryColorDark { return [UIColor colorWithRed:0.714 green:0.145 blue:0.357 alpha:1]; }
+(UIColor *) secondaryColor { return [UIColor colorWithRed:0.973 green:0.176 blue:0.396 alpha:1]; }

+(UIColor *) backgroundVeryLightColor { return [UIColor colorWithRed:0.95 green:0.95 blue:0.95 alpha:1]; }
+(UIColor *) backgroundLightColor { return [UIColor colorWithRed:0.929 green:0.929 blue:0.929 alpha:1]; }
+(UIColor *) backgroundMediumColor { return [UIColor colorWithRed:0.8 green:0.8 blue:0.8 alpha:1]; }
+(UIColor *) backgroundDarkColor { return [UIColor colorWithRed:0.31 green:0.31 blue:0.31 alpha:1]; }

+(UIBarButtonItem *) backButtonWithTarget: (id) target selector: (SEL) action
{
    UIButton *backBut = [[UIButton alloc] initWithFrame:CGRectMake(0,0,40,40)];
    [backBut addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [backBut setBackgroundImage:[UIImage imageNamed:@"back-but-1.png"] forState:UIControlStateNormal];
    [backBut setBackgroundImage:[UIImage imageNamed:@"back-but-sel-1.png"] forState:UIControlStateHighlighted];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:backBut];
    [backButton setCustomView:backBut];
    return backButton;
}

+(UIBarButtonItem *) barButtonWithTarget: (id) target selector: (SEL) action img1: (NSString *) img1 img2: (NSString *) img2
{
    UIButton *backBut = [[UIButton alloc] initWithFrame:CGRectMake(0,0,40,40)];
    [backBut addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    [backBut setBackgroundImage:[UIImage imageNamed:img1] forState:UIControlStateNormal];
    [backBut setBackgroundImage:[UIImage imageNamed:img2] forState:UIControlStateHighlighted];
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithCustomView:backBut];
    [backButton setCustomView:backBut];
    return backButton;
}

+(UIBarButtonItem *) textBarButtonWithTitle: (NSString *) title target: (id) target selector: (SEL) action
{
    UIControl *innerBut = [[UIControl alloc] initWithFrame:CGRectMake(0,0,45,30)];
    [innerBut addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *but = [[UIBarButtonItem alloc] initWithCustomView:innerBut];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 45, 30)];
    [label setText:title];
    [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
    [label setBackgroundColor:[UIColor clearColor]];
    [label setTextColor:[UIColor whiteColor]];
    [label setTextAlignment:NSTextAlignmentCenter];
    [innerBut addSubview:label];
    
    [but setCustomView:innerBut];
    return but;
}

+(void) setStandardButton: (UIButton *) but
{
    UIImage *bgImage1 = [UIImage imageNamed:@"primary-but-1"];
    UIImage *bgImage2 = [UIImage imageNamed:@"primary-but-high-1"];
    UIImage *bgImage3 = [UIImage imageNamed:@"primary-but-dis-1"];
    
    bgImage1 = [bgImage1 resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    bgImage2 = [bgImage2 resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    bgImage3 = [bgImage3 resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    
    [but setBackgroundImage: bgImage1 forState:UIControlStateNormal];
    [but setBackgroundImage: bgImage2 forState:UIControlStateHighlighted];
    [but setBackgroundImage: bgImage3 forState:UIControlStateDisabled];
    
    [but setTitleColor:[UIColor colorWithWhite:1 alpha:0.75] forState:UIControlStateDisabled];
}

+(void) setGrayButton: (UIButton *) but
{
    UIImage *bgImage1 = [UIImage imageNamed:@"sec-but-1"];
    UIImage *bgImage2 = [UIImage imageNamed:@"sec-but-high-1"];
    UIImage *bgImage3 = [UIImage imageNamed:@"sec-but-dis-1"];
    
    bgImage1 = [bgImage1 resizableImageWithCapInsets:UIEdgeInsetsMake(2, 2, 2, 2)];
    bgImage2 = [bgImage2 resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    bgImage3 = [bgImage3 resizableImageWithCapInsets:UIEdgeInsetsMake(4, 4, 4, 4)];
    
    [but setBackgroundImage: bgImage1 forState:UIControlStateNormal];
    [but setBackgroundImage: bgImage2 forState:UIControlStateHighlighted];
    [but setBackgroundImage: bgImage3 forState:UIControlStateDisabled];
    
    [but setTitleColor:[UIColor colorWithWhite:1 alpha:0.75] forState:UIControlStateDisabled];
}

+(void) setStandardButtonGrad: (UIButton *) but
{
    UIImage *bgImage1 = [UIImage imageNamed:@"primary-but-grad-1"];
    UIImage *bgImage2 = [UIImage imageNamed:@"primary-but-grad-high-1"];
    
    bgImage1 = [bgImage1 stretchableImageWithLeftCapWidth:4 topCapHeight:4];
    bgImage2 = [bgImage2 stretchableImageWithLeftCapWidth:4 topCapHeight:4];
    
    [but.titleLabel setShadowOffset:CGSizeMake(0, 0)];
    
    [but setBackgroundImage: bgImage1 forState:UIControlStateNormal];
    [but setBackgroundImage: bgImage2 forState:UIControlStateHighlighted];
    
    [but setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [but setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
}

+(void) setGrayButtonGrad: (UIButton *) but
{
    UIImage *bgImage1 = [UIImage imageNamed:@"sec-but-grad-1"];
    UIImage *bgImage2 = [UIImage imageNamed:@"sec-but-grad-high-1"];
    
    bgImage1 = [bgImage1 stretchableImageWithLeftCapWidth:4 topCapHeight:4];
    bgImage2 = [bgImage2 stretchableImageWithLeftCapWidth:4 topCapHeight:4];
    
    [but.titleLabel setShadowOffset:CGSizeMake(0, 0)];

    [but setBackgroundImage: bgImage1 forState:UIControlStateNormal];
    [but setBackgroundImage: bgImage2 forState:UIControlStateHighlighted];

    [but setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [but setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
}

+(void) containedExpandBut: (UIButton *) but cont: (UIView *) cont
{
    [cont setFrame:CGRectMake(0, 0, 320, 45)];
    [cont setHidden:YES];
    
    [but setFrame:CGRectMake(5, 5, 310, 35)];
    [but setTitle:@"load more" forState:UIControlStateNormal];
    [PLYTheme setStandardButton:but];
    [cont addSubview:but];
}

/* iOS6 overrides to appear more like iOS7 */

+(void) setActionSheetStyle: (UIActionSheet *) actionSheet warnButIdxs: (NSArray *) warnButIdxs
{
    return;
    int idx = 0;
    if (warnButIdxs == nil) warnButIdxs = @[];
    
    for (UIView *but in [actionSheet subviews]) {
        if ([but isKindOfClass:[UIButton class]]) {
            BOOL standard = YES;
            
            for (NSNumber *num in warnButIdxs) {
                if ([num integerValue] == idx) {
                    standard = NO;
                    break;
                }
            }
            
            if (standard) {
                [PLYTheme setGrayButtonGrad:but];
            } else {
                [PLYTheme setStandardButtonGrad:but];
            }
            
            idx += 1;
        } else if ([but isKindOfClass:[UIImageView class]]) {
            /* shadow */
            [(UIImageView *)but setImage:[[UIImage alloc] init]];
        }
    }
}


+(void) setTopGroupedTableViewCell: (UITableViewCell *) cell
{
    return;
    UIImage *img = [UIImage imageNamed: @"cell-grouped-top-1"];
    img = [img stretchableImageWithLeftCapWidth:6 topCapHeight:6];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    [cell setBackgroundView:imgView];
}

+(void) setMidGroupedTableViewCell: (UITableViewCell *) cell
{
    return;
    UIImage *img = [UIImage imageNamed: @"cell-grouped-mid-1"];
    img = [img stretchableImageWithLeftCapWidth:6 topCapHeight:6];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    [cell setBackgroundView:imgView];
}

+(void) setBotGroupedTableViewCell: (UITableViewCell *) cell;
{
    return;
    UIImage *img = [UIImage imageNamed: @"cell-grouped-bot-1"];
    img = [img stretchableImageWithLeftCapWidth:6 topCapHeight:6];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    [cell setBackgroundView:imgView];
}

+(void) setFullGroupedTableViewCell: (UITableViewCell *) cell;
{
    return;
    UIImage *img = [UIImage imageNamed: @"cell-grouped-full-1"];
    img = [img stretchableImageWithLeftCapWidth:6 topCapHeight:6];
    UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
    [cell setBackgroundView:imgView];
}

@end
