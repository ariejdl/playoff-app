//
//  PLYVideoWebBrowserViewController.h
//  Playoff
//
//  Created by Arie Lakeman on 17/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ASIHTTPRequest.h>

#import "PLYVideoMixerViewController.h"

@interface PLYVideoWebBrowserViewController : UIViewController <UITextFieldDelegate, NSURLConnectionDelegate, UIWebViewDelegate>

@property (weak) UIViewController *mixerViewController;

@property UIWebView *webView;
@property UILabel *titleLabel;
@property UIView *buttonBar;
@property UIView *textFieldCont;
@property UITextField *urlField;
@property UIButton *cancelURLFieldBtn;
@property UIButton *downloadButton;
@property NSString *availableURL;
@property NSString *availableURLExtension;

@property(atomic) BOOL currentlyLoading;
@property(atomic) BOOL currentlyShowingButtonBar;
@property(atomic) BOOL currentlyShowingCancelButton;


@end
