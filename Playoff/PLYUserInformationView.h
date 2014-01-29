//
//  PLYUserInformationView.h
//  Playoff
//
//  Created by Arie Lakeman on 03/08/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PLYUserInformationView : UIView

@property NSString *firstUseKey;
@property UIView *backgroundView;

- (id)initWithImage:(NSString *)imageName andFirstUseKey: (NSString *) firstUseKey;
- (id)initWithImage:(NSString *)imageName andFirstUseKey: (NSString *) firstUseKey white: (BOOL) white;

@end
