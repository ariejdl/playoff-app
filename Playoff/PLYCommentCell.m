//
//  PLYCommentCell.m
//  Playoff
//
//  Created by Arie Lakeman on 09/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#define USERPROFILE_IMG_TAG 1
#define USERNAME_TAG 2
#define TEXT_TAG 3
#define TIME_TAG 4

#define MAIN_PAD 5
#define PROFILE_IMAGE_DIM 30
#define USERNAME_TEXT_WIDTH 140
#define USERNAME_TEXT_HEIGHT 20
#define TIME_TEXT_WIDTH 80

#import "PLYCommentCell.h"
#import "PLYAppDelegate.h"

#import "PLYUtilities.h"
#import "PLYTheme.h"

@implementation PLYCommentCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
        UIImageView *imageView;
        UILabel *label;
        
        // user profile image
        imageView = [[UIImageView alloc] initWithFrame:CGRectMake(MAIN_PAD, MAIN_PAD, PROFILE_IMAGE_DIM, PROFILE_IMAGE_DIM)];
        [imageView setTag:USERPROFILE_IMG_TAG];
//        [imageView setBackgroundColor:[PLYTheme primaryColor]];
        [imageView setImage:[UIImage imageNamed:@"prof-smal-1"]];
        [self.contentView addSubview:imageView];
        
        // profile name
        label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD, 0,
                                                          USERNAME_TEXT_WIDTH, USERNAME_TEXT_HEIGHT)];
        [label setFont:[UIFont fontWithName:[PLYTheme boldDefaultFontName] size:14]];
        label.textColor = [PLYTheme primaryColor];
        [label setTag:USERNAME_TAG];
        [self.contentView addSubview:label];
        
        // body text
        label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD, USERNAME_TEXT_HEIGHT,
                                                          320 - (MAIN_PAD + PROFILE_IMAGE_DIM + MAIN_PAD), 0)];
        label.lineBreakMode = NSLineBreakByWordWrapping;
        label.font = [PLYTheme mediumDefaultFont];
        label.numberOfLines = 0;
        [self.contentView addSubview:label];
        [label setTag:TEXT_TAG];
        [self.contentView addSubview:label];
        
        // formatted time
        label = [[UILabel alloc] initWithFrame:CGRectMake(320 - (MAIN_PAD + TIME_TEXT_WIDTH), 0, TIME_TEXT_WIDTH, 20)];
        [label setTextAlignment:NSTextAlignmentRight];
        label.font = [PLYTheme mediumDefaultFont];
        label.textColor = [UIColor grayColor];
        [label setTag:TIME_TAG];
        [self.contentView addSubview:label];
        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

-(void)configureCell: (NSDictionary *) config
{
    UIImageView *imageView;
    UILabel *label;
    CGFloat dynHeight;
    
    // profile image
    imageView = (UIImageView *)[self.contentView viewWithTag:USERPROFILE_IMG_TAG];
    PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate setProfileImage:[config valueForKey: @"sm_owner"] imageView:imageView withBlock:^(BOOL success) {}];
    
    // profile name
    label = (UILabel *)[self.contentView viewWithTag:USERNAME_TAG];
    [label setText: [PLYUtilities usernameFromOwner:[config valueForKey: @"sm_owner"]]];
    
    // body text
    label = (UILabel *)[self.contentView viewWithTag:TEXT_TAG];
    [label setText: [config valueForKey:@"body"]];
    [label sizeToFit];
    
    dynHeight = label.frame.size.height > 14 ? label.frame.size.height : 14;
    
    // formatted time
    label = (UILabel *)[self.contentView viewWithTag:TIME_TAG];
    [label setText: [PLYUtilities millisToPrettyTime:[(NSNumber *)[config valueForKey: @"createddate"] doubleValue]]];
    
    [self setFrame:CGRectMake(0, 0, 320, USERNAME_TEXT_HEIGHT + dynHeight + MAIN_PAD)];
}

@end
