//
//  PLYUploadProgressView.h
//  Playoff
//
//  Created by Arie Lakeman on 06/07/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ASIHTTPRequest.h>

@interface PLYUploadProgressView : UIView<ASIProgressDelegate>

@property UIView *background;
@property UILabel *titleLabel;
@property UIActivityIndicatorView *spinner;
@property UIImageView *progressBack;
@property UIView *progressBar;
@property UILabel *detailLabel;

-(void) setTitle: (NSString *) title;
-(void) setDetailTitle: (NSString *) detailTitle;

-(void) startWithTitle: (NSString *) title withDetailTitle: (NSString *) detailTitle;
-(void) finish;
-(void) hideProgress;

@end
