//
//  PLYEditProfileViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 16/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLYEditProfileViewController : UITableViewController<UIAlertViewDelegate, UIImagePickerControllerDelegate,
        UINavigationControllerDelegate, UITextViewDelegate>

@property NSArray *fields;
@property NSArray *cells;
@property NSDictionary *currentUserDict;
@property UIView *loaderView;
@property UILabel *placeholderBio;

-(id)initWithUserDict: (NSDictionary *) profile;

@end
