//
//  PLYMainCell.m
//  Playoff
//
//  Created by Arie Lakeman on 03/05/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYMainThreadCell.h"
#import "PLYUtilities.h"
#import "PLYTheme.h"

#import <SDWebImage/UIImageView+WebCache.h>

#import "PLYAppDelegate.h"

#define IMAGE_1_DIM 110
#define IMAGE_2_DIM 82
#define IMAGE_3_DIM 60
#define IMAGE_4_DIM 43
#define MAIN_PAD 5
#define COMMENT_INDENT MAIN_PAD
#define COMMENT_IMAGE_DIM 20
#define USER_IMAGE_DIM 25

#define ITEM_LIKE_PAD 2
#define ITEM_LIKE_IMG_DIM 12

#define IMAGE_SPACING 5

#define CELL_MARGIN 5
#define CELL_MARGIN_FULL (CELL_MARGIN * 2)
#define CELL_SPACE_TOP 5
#define CELL_SPACE_BOTTOM 10
#define TOP_OFFSET (CELL_SPACE_TOP + CELL_MARGIN)

#define INNER_CELL_HEIGHT (IMAGE_1_DIM + CELL_MARGIN_FULL)
#define CELL_HEIGHT (INNER_CELL_HEIGHT + CELL_MARGIN_FULL + CELL_SPACE_TOP)

#define IMAGE_1_TAG 1
#define IMAGE_2_TAG 2
#define IMAGE_3_TAG 3
#define IMAGE_4_TAG 4

#define IMAGE_1_LIKES_BACK_TAG 21
#define IMAGE_2_LIKES_BACK_TAG 22
#define IMAGE_3_LIKES_BACK_TAG 23
#define IMAGE_4_LIKES_BACK_TAG 24

#define IMAGE_1_LIKES_TAG 13
#define IMAGE_2_LIKES_TAG 14
#define IMAGE_3_LIKES_TAG 15
#define IMAGE_4_LIKES_TAG 16

#define IMAGE_1_LIKES_IMG_TAG 17
#define IMAGE_2_LIKES_IMG_TAG 18
#define IMAGE_3_LIKES_IMG_TAG 19
#define IMAGE_4_LIKES_IMG_TAG 20

#define TIME_TEXT_TAG 12
#define COMMENT_IMAGE_TAG 5
#define TITLE_TAG 6
#define COMMENTS_TAG 8
#define BACKGROUND_TAG 9
#define SHADOW_TAG 10

#define TOP_USERNAME_TAG 34
#define TOP_USER_IMG_TAG 31

@implementation PLYMainThreadCell

-(id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        UILabel *label;
        UIImageView *imageView;
        UIView *simpleView;
        UIView *backView;
        
        // back
        backView = [[UIView alloc] init];
        [backView setBackgroundColor:[UIColor whiteColor]];
        backView.tag = BACKGROUND_TAG;
        [self.contentView addSubview:backView];
        
        // back shadow
        simpleView = [[UIView alloc] init];
        [simpleView setBackgroundColor:[UIColor colorWithRed:0.83 green:0.83 blue:0.83 alpha:1]];
        simpleView.tag = SHADOW_TAG;
        [self.contentView addSubview:simpleView];
        
        // images + likes
        // 1
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_1_TAG;
        [self.contentView addSubview:imageView];
        
        simpleView = [[UIImageView alloc] init];
        simpleView.tag = IMAGE_1_LIKES_BACK_TAG;
        [imageView addSubview:simpleView];
        
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_1_LIKES_IMG_TAG;
//        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [imageView setImage:[UIImage imageNamed:@"like-tiny-1"]];
        [simpleView addSubview:imageView];
        
        label = [[UILabel alloc] init];
        label.tag = IMAGE_1_LIKES_TAG;
        [simpleView addSubview:label];
        
        // 2
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_2_TAG;
        [self.contentView addSubview:imageView];
        
        simpleView = [[UIImageView alloc] init];
        simpleView.tag = IMAGE_2_LIKES_BACK_TAG;
        [imageView addSubview:simpleView];
        
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_2_LIKES_IMG_TAG;
        [imageView setImage:[UIImage imageNamed:@"like-tiny-1"]];
        [simpleView addSubview:imageView];
        
        label = [[UILabel alloc] init];
        label.tag = IMAGE_2_LIKES_TAG;
        [simpleView addSubview:label];
        
        // 3
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_3_TAG;
        [self.contentView addSubview:imageView];
        
        simpleView = [[UIImageView alloc] init];
        simpleView.tag = IMAGE_3_LIKES_BACK_TAG;
        [imageView addSubview:simpleView];
        
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_3_LIKES_IMG_TAG;
        [imageView setImage:[UIImage imageNamed:@"like-tiny-1"]];
        [simpleView addSubview:imageView];
        
        label = [[UILabel alloc] init];
        label.tag = IMAGE_3_LIKES_TAG;
        [simpleView addSubview:label];
        
        // 4
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_4_TAG;
        [self.contentView addSubview:imageView];
        
        simpleView = [[UIImageView alloc] init];
        simpleView.tag = IMAGE_4_LIKES_BACK_TAG;
        [imageView addSubview:simpleView];
        
        imageView = [[UIImageView alloc] init];
        imageView.tag = IMAGE_4_LIKES_IMG_TAG;
        [imageView setImage:[UIImage imageNamed:@"like-tiny-1"]];
        [simpleView addSubview:imageView];
        
        label = [[UILabel alloc] init];
        label.tag = IMAGE_4_LIKES_TAG;
        [simpleView addSubview:label];
        
        // time text
        label = [[UILabel alloc] initWithFrame:CGRectMake(320 - (100 + MAIN_PAD), MAIN_PAD + MAIN_PAD, 100, 14)];
        label.tag = TIME_TEXT_TAG;
        [label setTextAlignment:NSTextAlignmentRight];
        [backView addSubview:label];
        [label setFont: [PLYTheme mediumDefaultFont]];
        label.textColor = [UIColor grayColor];
        
        // comment image
        imageView = [[UIImageView alloc] init];
        imageView.tag = COMMENT_IMAGE_TAG;
        [self.contentView addSubview:imageView];
        
        // title
        label = [[UILabel alloc] init];
        label.tag = TITLE_TAG;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [UIFont fontWithName:[PLYTheme defaultFontName] size:[PLYTheme largeFont]];
        label.numberOfLines = 0;
        [self.contentView addSubview:label];
        label.opaque = NO;
        label.backgroundColor = [UIColor clearColor];
        
        // body
        label = [[UILabel alloc] init];
        label.tag = COMMENTS_TAG;
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [PLYTheme mediumDefaultFont];
        label.numberOfLines = 0;
        [self.contentView addSubview:label];
        label.opaque = NO;
        label.backgroundColor = [UIColor clearColor];
        
        // top user image
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_PAD + IMAGE_1_DIM + MAIN_PAD,
                                                                  MAIN_PAD + MAIN_PAD, USER_IMAGE_DIM, USER_IMAGE_DIM)];
        [imageView setImage:[UIImage imageNamed:@"prof-small-1"]];
        imageView.tag = TOP_USER_IMG_TAG;
        imageView.hidden = YES;
        [self.contentView addSubview:imageView];
        
        // top user name
        label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_PAD + IMAGE_1_DIM + MAIN_PAD + USER_IMAGE_DIM + MAIN_PAD,
                                                          MAIN_PAD + MAIN_PAD - 5, 200, USER_IMAGE_DIM + 5)];
        label.tag = TOP_USERNAME_TAG;
        label.hidden = YES;
        [label setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:14]];
        label.textColor = [PLYTheme primaryColor];
        [label setBackgroundColor:[UIColor clearColor]];
        [self.contentView addSubview:label];
        
    }
    return self;
}

-(void)configureCell:(NSDictionary *) config
{
  
    CGRect rect;
    
    NSString *title = config[@"title"];
    NSArray *items = config[@"items"];
    NSDictionary *item;
    NSArray *comments = config[@"summary_comments"];
    NSInteger itemCount = [items count];
    
    UILabel *label;
    UIImageView *imageView;
    UIView *rectView;
    
    label = (UILabel *)[self viewWithTag:TITLE_TAG];
    [label setFrame:CGRectMake(CELL_MARGIN + IMAGE_1_DIM + IMAGE_SPACING, TOP_OFFSET, 320 - (IMAGE_1_DIM + IMAGE_SPACING + 40), 30)];
    
    if (itemCount == 1) {
        // add a profile image
        PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
        imageView = (UIImageView *)[self viewWithTag:TOP_USER_IMG_TAG];
        [imageView setHidden:NO];
        [appDelegate setProfileImage:config[@"first_user"] imageView:imageView withBlock:^(BOOL success){}];

        UILabel *usernameLabel = (UILabel *)[self viewWithTag:TOP_USERNAME_TAG];
        [usernameLabel setText: [PLYUtilities usernameFromOwner: config[@"first_user"]]];
        [usernameLabel setHidden:NO];
        
        [label setFrame:CGRectMake(CELL_MARGIN + IMAGE_1_DIM + IMAGE_SPACING, MAIN_PAD + USER_IMAGE_DIM + MAIN_PAD + MAIN_PAD, 200, 30)];
        
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(320 - 140 - MAIN_PAD, IMAGE_1_DIM + MAIN_PAD - 40, 140, 40)];
        [imageView setImage: [UIImage imageNamed:@"entice-img-1"]];
        [self.contentView addSubview:imageView];
    }
    
    if (itemCount >= 1) {
        imageView = (UIImageView *)[self viewWithTag:IMAGE_1_TAG];
        item = (NSDictionary *)items[0];

        [label setText:title];
        
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        rect = CGRectMake(CELL_MARGIN, CELL_SPACE_TOP + CELL_MARGIN, IMAGE_1_DIM, IMAGE_1_DIM);
        [imageView setFrame: rect];

        NSString *previewImage = [item valueForKey:@"preview_image_1"];
        if (previewImage) {
            [imageView setImageWithURL:[NSURL URLWithString:previewImage]
                                           placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {

                             }];
        }
        
        if ([item[@"likes"] intValue] > 0) {
            // likes count
            label = (UILabel *)[self viewWithTag:IMAGE_1_LIKES_TAG];
            [label setTextAlignment:NSTextAlignmentCenter];
            NSString *text = [[NSString alloc] initWithFormat:@"%@", item[@"likes"], nil];
            [label setText: text];
            [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            CGSize size = [text sizeWithFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            [label setFrame:CGRectMake(ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD, 0, size.width, size.height)];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextColor:[PLYTheme primaryColor]];
            
            rectView = (UIView *)[self viewWithTag:IMAGE_1_LIKES_BACK_TAG];
            [rectView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.75]];
            [rectView setFrame:CGRectMake(IMAGE_1_DIM - (size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM),
                                          IMAGE_1_DIM - (ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD),
                                          size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM,
                                          ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD)];
            
            imageView = (UIImageView *)[self viewWithTag:IMAGE_1_LIKES_IMG_TAG];
            [imageView setFrame:CGRectMake(ITEM_LIKE_PAD, ITEM_LIKE_PAD, ITEM_LIKE_IMG_DIM, ITEM_LIKE_IMG_DIM)];
        }
        
    }
    
    // TODO: add dice with 1 & 2 around here
    
    if (itemCount >= 2) {
        imageView = (UIImageView *)[self viewWithTag:IMAGE_2_TAG];
        item = (NSDictionary *)items[1];
        
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        rect = CGRectMake(CELL_MARGIN + IMAGE_1_DIM + IMAGE_SPACING,
                          IMAGE_1_DIM - IMAGE_2_DIM + CELL_SPACE_TOP + CELL_MARGIN,
                          IMAGE_2_DIM, IMAGE_2_DIM);
        
        [imageView setFrame: rect];
        
        NSString *previewImage = [item valueForKey:@"preview_image_1"];
        if (previewImage) {
            [imageView setImageWithURL:[NSURL URLWithString:previewImage]
                      placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                 
                             }];
        }
        
        if ([item[@"likes"] intValue] > 0) {
            // likes count
            label = (UILabel *)[self viewWithTag:IMAGE_2_LIKES_TAG];
            [label setTextAlignment:NSTextAlignmentCenter];
            NSString *text = [[NSString alloc] initWithFormat:@"%@", item[@"likes"], nil];
            [label setText: text];
            [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            CGSize size = [text sizeWithFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            [label setFrame:CGRectMake(ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD, 0, size.width, size.height)];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextColor:[PLYTheme primaryColor]];
            
            rectView = (UIView *)[self viewWithTag:IMAGE_2_LIKES_BACK_TAG];
            [rectView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.75]];
            [rectView setFrame:CGRectMake(IMAGE_2_DIM - (size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM),
                                          IMAGE_2_DIM - (ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD),
                                          size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM,
                                          ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD)];
            
            imageView = (UIImageView *)[self viewWithTag:IMAGE_2_LIKES_IMG_TAG];
            [imageView setFrame:CGRectMake(ITEM_LIKE_PAD, ITEM_LIKE_PAD, ITEM_LIKE_IMG_DIM, ITEM_LIKE_IMG_DIM)];
        }
    }

    if (itemCount >= 3) {
        imageView = (UIImageView *)[self viewWithTag:IMAGE_3_TAG];
        item = (NSDictionary *)items[2];
        
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        rect = CGRectMake(CELL_MARGIN + IMAGE_1_DIM + IMAGE_SPACING + IMAGE_2_DIM + IMAGE_SPACING,
                          IMAGE_1_DIM - IMAGE_3_DIM + CELL_SPACE_TOP + CELL_MARGIN,
                          IMAGE_3_DIM, IMAGE_3_DIM);
        
        [imageView setFrame: rect];
        
        NSString *previewImage = [item valueForKey:@"preview_image_1"];
        if (previewImage) {
            [imageView setImageWithURL:[NSURL URLWithString:previewImage]
                      placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                 
                             }];
        }
        
        if ([item[@"likes"] intValue] > 0) {
            // likes count
            label = (UILabel *)[self viewWithTag:IMAGE_3_LIKES_TAG];
            [label setTextAlignment:NSTextAlignmentCenter];
            NSString *text = [[NSString alloc] initWithFormat:@"%@", item[@"likes"], nil];
            [label setText: text];
            [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            CGSize size = [text sizeWithFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            [label setFrame:CGRectMake(ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD, 0, size.width, size.height)];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextColor:[PLYTheme primaryColor]];
            
            rectView = (UIView *)[self viewWithTag:IMAGE_3_LIKES_BACK_TAG];
            [rectView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.75]];
            [rectView setFrame:CGRectMake(IMAGE_3_DIM - (size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM),
                                          IMAGE_3_DIM - (ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD),
                                          size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM,
                                          ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD)];
            
            imageView = (UIImageView *)[self viewWithTag:IMAGE_3_LIKES_IMG_TAG];
            [imageView setFrame:CGRectMake(ITEM_LIKE_PAD, ITEM_LIKE_PAD, ITEM_LIKE_IMG_DIM, ITEM_LIKE_IMG_DIM)];
        }
    }
    
    if (itemCount >= 4) {
        imageView = (UIImageView *)[self viewWithTag:IMAGE_4_TAG];
        item = (NSDictionary *)items[3];
        
        imageView.contentMode = UIViewContentModeScaleAspectFill;
        rect = CGRectMake(CELL_MARGIN + IMAGE_1_DIM + IMAGE_SPACING + IMAGE_2_DIM + IMAGE_SPACING + IMAGE_3_DIM + IMAGE_SPACING,
                          IMAGE_1_DIM - IMAGE_4_DIM + CELL_SPACE_TOP + CELL_MARGIN,
                          IMAGE_4_DIM, IMAGE_4_DIM);
        
        [imageView setFrame: rect];
        
        NSString *previewImage = [item valueForKey:@"preview_image_1"];
        if (previewImage) {
            [imageView setImageWithURL:[NSURL URLWithString:previewImage]
                      placeholderImage:[UIImage imageNamed:@"placeholder-vid-small-1"]
                             completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType) {
                                 
                             }];
        }
        
        if ([item[@"likes"] intValue] > 0) {
            // likes count
            label = (UILabel *)[self viewWithTag:IMAGE_4_LIKES_TAG];
            [label setTextAlignment:NSTextAlignmentCenter];
            NSString *text = [[NSString alloc] initWithFormat:@"%@", item[@"likes"], nil];
            [label setText: text];
            [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            CGSize size = [text sizeWithFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:13]];
            [label setFrame:CGRectMake(ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD, 0, size.width, size.height)];
            [label setBackgroundColor:[UIColor clearColor]];
            [label setTextColor:[PLYTheme primaryColor]];
            
            rectView = (UIView *)[self viewWithTag:IMAGE_4_LIKES_BACK_TAG];
            [rectView setBackgroundColor:[UIColor colorWithWhite:1 alpha:0.75]];
            [rectView setFrame:CGRectMake(IMAGE_4_DIM - (size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM),
                                          IMAGE_4_DIM - (ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD),
                                          size.width + ITEM_LIKE_PAD + ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM,
                                          ITEM_LIKE_PAD + ITEM_LIKE_IMG_DIM + ITEM_LIKE_PAD)];
            
            imageView = (UIImageView *)[self viewWithTag:IMAGE_4_LIKES_IMG_TAG];
            [imageView setFrame:CGRectMake(ITEM_LIKE_PAD, ITEM_LIKE_PAD, ITEM_LIKE_IMG_DIM, ITEM_LIKE_IMG_DIM)];
        }
    }
    
    if (itemCount >= 5) {
        imageView = (UIImageView *)[self viewWithTag:IMAGE_4_TAG];
        item = (NSDictionary *)items[4];
    }
    
    // time text
    label = (UILabel *)[self viewWithTag:TIME_TEXT_TAG];
    [label setText: [PLYUtilities millisToPrettyTime:[(NSNumber *)[config valueForKey: @"createddate"] doubleValue]]];
    
    if ([comments count] == 0) {
        // background
        rectView = (UIView *)[self viewWithTag:BACKGROUND_TAG];
        rect = CGRectMake(0.0, CELL_SPACE_TOP, 320.0, INNER_CELL_HEIGHT);
        [rectView setFrame:rect];
        
        // background shadow
        rectView = (UIView *)[self viewWithTag:SHADOW_TAG];
        rect = CGRectMake(0.0, INNER_CELL_HEIGHT + CELL_SPACE_TOP, 320.0, 2);
        [rectView setFrame:rect];
        
        // cell frame
        rect = [self frame];
        rect.size.height = CELL_HEIGHT;
        [self setFrame:rect];
    } else {
        // comments text
        label = (UILabel *)[self viewWithTag:COMMENTS_TAG];
        [PLYUtilities setupCommentsLabel: label
                                comments: comments
                                   frame: CGRectMake(COMMENT_IMAGE_DIM + COMMENT_INDENT + COMMENT_INDENT,
                                                     INNER_CELL_HEIGHT + COMMENT_INDENT,
                                                     320 - COMMENT_IMAGE_DIM - COMMENT_INDENT - COMMENT_INDENT, 0)];
        
        // comment image
        imageView = (UIImageView *)[self viewWithTag:COMMENT_IMAGE_TAG];
//        [imageView setImage: [[UIImage alloc] init]];
        [imageView setImage:[UIImage imageNamed:@"comment-small-1"]];
        rect = CGRectMake(COMMENT_INDENT,
                          INNER_CELL_HEIGHT + COMMENT_INDENT,
                          COMMENT_IMAGE_DIM, COMMENT_IMAGE_DIM);
//        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [imageView setFrame: rect];
        
        CGFloat additionalCellHeight;
        if (label.frame.size.height > 15) {
            additionalCellHeight = label.frame.size.height;
        } else {
            additionalCellHeight = 0;
            [imageView setHidden:YES];
        }
        
        // background
        rectView = (UIView *)[self viewWithTag:BACKGROUND_TAG];
        rect = CGRectMake(0.0, CELL_SPACE_TOP, 320.0,
                          INNER_CELL_HEIGHT + COMMENT_INDENT + 2 + additionalCellHeight);
        [rectView setFrame:rect];
        
        // background shadow
        rectView = (UIView *)[self viewWithTag:SHADOW_TAG];
        rect = CGRectMake(0.0,
                          INNER_CELL_HEIGHT + CELL_SPACE_TOP + COMMENT_INDENT + 2 + additionalCellHeight,
                          320.0, 2);
        [rectView setFrame:rect];
        
        // cell frame
        rect = [self frame];
        rect.size.height = CELL_HEIGHT + COMMENT_INDENT + additionalCellHeight;
        [self setFrame:rect];
    }
    

}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
