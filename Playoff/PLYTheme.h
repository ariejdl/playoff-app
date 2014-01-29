//
//  PLYTheme.h
//  Playoff
//
//  Created by Arie Lakeman on 17/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PLYTheme : NSObject

+(NSString *) defaultFontName;
+(NSString *) boldDefaultFontName;
+(int) smallFont;
+(int) mediumFont;
+(int) largeFont;

+(UIFont *) mediumDefaultFont;

+(UIColor *) primaryColor;
+(UIColor *) primaryColorLight;
+(UIColor *) primaryColorDark;
+(UIColor *) secondaryColor;
+(UIColor *) backgroundVeryLightColor;
+(UIColor *) backgroundLightColor;
+(UIColor *) backgroundMediumColor;
+(UIColor *) backgroundDarkColor;
+(UIBarButtonItem *) backButtonWithTarget: (id) target selector: (SEL) action;
+(UIBarButtonItem *) barButtonWithTarget: (id) target selector: (SEL) action img1: (NSString *) img1 img2: (NSString *) img2;
+(UIBarButtonItem *) textBarButtonWithTitle: (NSString *) title target: (id) target selector: (SEL) action;

+(void) setStandardButton: (UIButton *) but;
+(void) setGrayButton: (UIButton *) but;
+(void) setStandardButtonGrad: (UIButton *) but;
+(void) setGrayButtonGrad: (UIButton *) but;

+(void) containedExpandBut: (UIButton *) but cont: (UIView *) cont;
+(void) setActionSheetStyle: (UIActionSheet *) actionSheet warnButIdxs: (NSArray *) warnButIdxs;

+(void) setTopGroupedTableViewCell: (UITableViewCell *) cell;
+(void) setMidGroupedTableViewCell: (UITableViewCell *) cell;
+(void) setBotGroupedTableViewCell: (UITableViewCell *) cell;
+(void) setFullGroupedTableViewCell: (UITableViewCell *) cell;

@end
