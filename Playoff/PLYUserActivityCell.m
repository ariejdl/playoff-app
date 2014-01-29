//
//  PLYUserActivityCell.m
//  Playoff
//
//  Created by Arie Lakeman on 14/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYUserActivityCell.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"

#import <SDWebImage/UIImageView+WebCache.h>

#define MAIN_CELL_PAD 5
#define CELL_SPACE_TOP MAIN_CELL_PAD
#define CELL_HEIGHT 140
#define INNER_CELL_HEIGHT 130
#define MAIN_IMAGE_DIM (INNER_CELL_HEIGHT - CELL_SPACE_TOP - CELL_SPACE_TOP)
#define SEC_IMAGE_DIM 35
#define USER_IMAGE_DIM 25

#define ITEM_LIKE_PAD 2
#define ITEM_LIKE_IMG_DIM 12

/*********/

#define BACKGROUND_TAG 1
#define SHADOW_TAG 2

#define MAIN_IMAGE_TAG 3
#define PROFILE_IMAGE_TAG 4
#define USERNAME_TAG 5
#define TIMESTAMP_TAG 6
#define LIKE_COUNT_VIEW_TAG 7
#define LIKE_IMG_TAG 8
#define LIKE_COUNT_TAG 9
#define ACTIVITY_TEXT_TAG 10
#define SECONDARY_IMG_1_TAG 11
#define SECONDARY_IMG_2_TAG 12

@implementation PLYUserActivityCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *label;
        UIImageView *imageView;
        UIView *backView;
        UIView *simpleView;
        
        // back
        backView = [[UIView alloc] initWithFrame:CGRectMake(0, CELL_SPACE_TOP, 320, INNER_CELL_HEIGHT)];
        [backView setBackgroundColor:[UIColor whiteColor]];
        backView.tag = BACKGROUND_TAG;
        [self.contentView addSubview:backView];
        
        // back shadow
        simpleView = [[UIView alloc] initWithFrame:CGRectMake(0.0, INNER_CELL_HEIGHT + CELL_SPACE_TOP, 320.0, 2)];
        [simpleView setBackgroundColor:[UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:1]];
        simpleView.tag = SHADOW_TAG;
        [self.contentView addSubview:simpleView];
        
        // main image
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_CELL_PAD, MAIN_CELL_PAD, MAIN_IMAGE_DIM, MAIN_IMAGE_DIM)];
        [imageView setTag:MAIN_IMAGE_TAG];
        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [backView addSubview:imageView];

        // likes view
        simpleView = [[UIView alloc] init];
        [simpleView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.75]];
        [simpleView setTag:LIKE_COUNT_VIEW_TAG];
        [imageView addSubview:simpleView];
        [simpleView setHidden:YES];
        
        // likes icon
        imageView = [[UIImageView alloc] init];
        [imageView setImage:[UIImage imageNamed:@"like-tiny-1"]];
        [imageView setTag:LIKE_IMG_TAG];
        [simpleView addSubview:imageView];
        
        // likes count
        label = [[UILabel alloc] init];
        [label setTag:LIKE_COUNT_TAG];
        [simpleView addSubview:label];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[PLYTheme primaryColor]];
        
        // sec image 1
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_CELL_PAD + MAIN_IMAGE_DIM + MAIN_CELL_PAD,
                                                                  INNER_CELL_HEIGHT - MAIN_CELL_PAD - SEC_IMAGE_DIM,
                                                                  SEC_IMAGE_DIM, SEC_IMAGE_DIM)];
        [imageView setTag:SECONDARY_IMG_1_TAG];
        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [backView addSubview:imageView];
        [imageView setHidden:YES];
        
        // sec image 2
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_CELL_PAD + MAIN_IMAGE_DIM + MAIN_CELL_PAD + SEC_IMAGE_DIM + MAIN_CELL_PAD,
                                                                  INNER_CELL_HEIGHT - MAIN_CELL_PAD - SEC_IMAGE_DIM,
                                                                  SEC_IMAGE_DIM, SEC_IMAGE_DIM)];
        [imageView setTag:SECONDARY_IMG_2_TAG];
        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [backView addSubview:imageView];
        [imageView setHidden:YES];
        
        // user image
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_CELL_PAD + MAIN_IMAGE_DIM + MAIN_CELL_PAD,
                                                                  MAIN_CELL_PAD, USER_IMAGE_DIM, USER_IMAGE_DIM)];
//        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [imageView setImage:[UIImage imageNamed:@"prof-small-1"]];
        [imageView setTag:PROFILE_IMAGE_TAG];
        [backView addSubview:imageView];
        
        // username
        label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_CELL_PAD + MAIN_IMAGE_DIM + MAIN_CELL_PAD + USER_IMAGE_DIM + MAIN_CELL_PAD,
                                                          MAIN_CELL_PAD + MAIN_CELL_PAD - 5, 150, 20)];
        [label setTag:USERNAME_TAG];
        [label setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:14]];
        label.textColor = [PLYTheme primaryColor];
        [backView addSubview:label];
        
        // time
        label = [[UILabel alloc] initWithFrame:CGRectMake(320 - (100 + MAIN_CELL_PAD), MAIN_CELL_PAD + MAIN_CELL_PAD, 100, 14)];
        [label setTag:TIMESTAMP_TAG];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextAlignment:NSTextAlignmentRight];
        [label setFont:[PLYTheme mediumDefaultFont]];
        label.textColor = [UIColor grayColor];
        [backView addSubview: label];
        
        // caption
        label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_CELL_PAD + MAIN_IMAGE_DIM + MAIN_CELL_PAD,
                                                          MAIN_CELL_PAD + USER_IMAGE_DIM + MAIN_CELL_PAD,
                                                          320 - (MAIN_CELL_PAD + MAIN_IMAGE_DIM + MAIN_CELL_PAD + MAIN_CELL_PAD), 0)];
        
        label.font = [UIFont fontWithName:[PLYTheme defaultFontName] size:13];
        label.lineBreakMode = NSLineBreakByWordWrapping;

        label.numberOfLines = 0;
        [label setTag: ACTIVITY_TEXT_TAG];
        [backView addSubview: label];
        
        // cell itself
        [self setFrame:CGRectMake(0, 0, 320, CELL_HEIGHT)];
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureCell:(NSDictionary *)config
{
    UILabel *label;
    UIImageView *imageView;
    UIView *rectView;
    
    imageView = (UIImageView *)[self viewWithTag:MAIN_IMAGE_TAG];
    [imageView setImageWithURL:[NSURL URLWithString:config[@"preview_image_1"]]
              placeholderImage:[UIImage imageNamed:@"placeholder-vid-1"]
                     completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                     }];
    
    if ([config valueForKey:@"preview_image_2"]) {
        imageView = (UIImageView *)[self viewWithTag:SECONDARY_IMG_1_TAG];
        [imageView setHidden:NO];
        [imageView setImageWithURL:[NSURL URLWithString:config[@"preview_image_3"]]
                  placeholderImage:[UIImage imageNamed:@"placeholder-img-1"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                         }];
    }

    if ([config valueForKey:@"preview_image_3"]) {
        imageView = (UIImageView *)[self viewWithTag:SECONDARY_IMG_2_TAG];
        [imageView setHidden:NO];
        [imageView setImageWithURL:[NSURL URLWithString:config[@"preview_image_2"]]
                  placeholderImage:[UIImage imageNamed:@"placeholder-img-1"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                         }];
    }
    
    int likesCount = [(NSNumber *)config[@"likes_count"] intValue];
    if (likesCount > 0) {

        label = (UILabel *)[self viewWithTag:LIKE_COUNT_TAG];
        [label setTextAlignment:NSTextAlignmentCenter];
        NSString *text = [[NSString alloc] initWithFormat:@"%i", likesCount, nil];
        [label setText: text];
        [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
        CGSize size = [text sizeWithFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
        [label setFrame:CGRectMake(ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD, 0, size.width, size.height)];
        
        rectView = (UIView *)[self viewWithTag:LIKE_COUNT_VIEW_TAG];
//        [rectView setBackgroundColor:[UIColor whiteColor]];
        [rectView setFrame:CGRectMake(MAIN_IMAGE_DIM - (size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM),
                                      MAIN_IMAGE_DIM - (ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD),
                                      size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM,
                                      ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD)];
        
        imageView = (UIImageView *)[self viewWithTag:LIKE_IMG_TAG];
        [imageView setFrame:CGRectMake(ITEM_LIKE_PAD, ITEM_LIKE_PAD, ITEM_LIKE_IMG_DIM, ITEM_LIKE_IMG_DIM)];
        
        
        [rectView setHidden:NO];
    }
    
    NSDictionary *userInfo = config[@"user"];
    label = (UILabel *)[self viewWithTag:USERNAME_TAG];
    [label setText:[PLYUtilities usernameFromOwner: userInfo[@"username"]]];
    
    if ([userInfo valueForKey:@"profile_image"] != [NSNull null]) {
        imageView = (UIImageView *)[self viewWithTag:PROFILE_IMAGE_TAG];
        [imageView setImageWithURL:[NSURL URLWithString:[userInfo valueForKey:@"profile_image"]]
                  placeholderImage:[UIImage imageNamed:@"prof-medium-1"]
                         completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                         }];

    }
    
    label = (UILabel *)[self viewWithTag:TIMESTAMP_TAG];
    [label setText:[PLYUtilities millisToPrettyTime:[(NSNumber *)config[@"createddate"] doubleValue]]];
    
    // caption
    label = (UILabel *)[self viewWithTag:ACTIVITY_TEXT_TAG];
    NSString *captionText = (NSString *)config[@"caption"];
    NSString *visibleText;
    if ([captionText length] > 60) {
        visibleText = [[NSString alloc] initWithFormat: @"%@...", [captionText substringWithRange: NSMakeRange(0, 60)], nil];
    } else if ([captionText length] == 0) {
        visibleText = [[NSString alloc] initWithFormat: @"%@ created a new playoff!", userInfo[@"username"], nil];
    } else {
        visibleText = captionText;
    }
    [label setText: visibleText];
    [label sizeToFit];

}

@end
