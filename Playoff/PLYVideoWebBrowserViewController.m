//
//  PLYVideoWebBrowserViewController.m
//  Playoff
//
//  Created by Arie Lakeman on 17/06/2013.
//  Copyright (c) 2013 Arie Lakeman. All rights reserved.
//

#import "PLYVideoWebBrowserViewController.h"

#import "PLYAppDelegate.h"
#import "PLYTheme.h"
#import <QuartzCore/QuartzCore.h>
#import "PLYUserInformationView.h"

#define NAV_BAR_HEIGHT 60
#define LINK_BAR_HEIGHT 44
#define TOOL_BAR_HEIGHT 44
#define MAIN_PAD 5
#define SEC_BTN_DIM 34
#define CANCEL_BTN_OFFSCREEN 10
#define CANCEL_BTN_WIDTH 70

#define CLOSE_BTN_DIM SEC_BTN_DIM
#define URL_FIELD_HEIGHT    CLOSE_BTN_DIM
#define BACK_BTN_DIM        CLOSE_BTN_DIM
#define FWD_BTN_DIM         CLOSE_BTN_DIM
#define DOWNLOAD_BTN_HEIGHT CLOSE_BTN_DIM
#define DOWNLOAD_BTN_WIDTH  200
#define LINK_BTN_HEIGHT     CLOSE_BTN_DIM
#define LINK_BTN_WIDTH      150

#define NAV_BAR_TAG 1
#define LINK_BAR_TAG 2
#define TOOL_BAR_TAG 3
#define NAV_BAR_TITLE_TAG 4

@implementation PLYVideoWebBrowserViewController

@synthesize webView = _webView;
@synthesize titleLabel = _titleLabel;
@synthesize urlField = _urlField;
@synthesize mixerViewController = _mixerViewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.currentlyShowingButtonBar = YES;
        self.currentlyShowingCancelButton = NO;
        
        // Custom initialization
        UIView *baseView;
        UIView *rectView;
        UILabel *label;
        UITextField *textField;
        UIButton *btn;
        CGFloat screenHeight = [[UIScreen mainScreen] applicationFrame].size.height;
        
        // toolbar
        rectView = [[UIView alloc] initWithFrame:CGRectMake(0, screenHeight - TOOL_BAR_HEIGHT, 320, TOOL_BAR_HEIGHT)];
        [self.view addSubview:rectView];
        [rectView setBackgroundColor:[UIColor colorWithRed:0.72 green:0.72 blue:0.75 alpha:1]];
        
        // toolbar buttons
        // back btn
        btn = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD, MAIN_PAD, BACK_BTN_DIM, BACK_BTN_DIM)];
        [btn addTarget:self action:@selector(navigateBack) forControlEvents:UIControlEventTouchUpInside];
        [PLYTheme setGrayButton: btn];
        [btn setImage:[UIImage imageNamed:@"tri-back-1"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"tri-back-1"] forState:UIControlStateHighlighted];
        [rectView addSubview:btn];
        
        // forward btn
        btn = [[UIButton alloc] initWithFrame:CGRectMake(320 - (MAIN_PAD + FWD_BTN_DIM), MAIN_PAD, FWD_BTN_DIM, FWD_BTN_DIM)];
        [btn addTarget:self action:@selector(navigateForward) forControlEvents:UIControlEventTouchUpInside];
        [PLYTheme setGrayButton: btn];
        [btn setImage:[UIImage imageNamed:@"tri-for-1"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"tri-for-1"] forState:UIControlStateHighlighted];
        [rectView addSubview:btn];
        
        // download btn
        btn = [[UIButton alloc] initWithFrame:CGRectMake((320 / 2) - (DOWNLOAD_BTN_WIDTH / 2), MAIN_PAD, DOWNLOAD_BTN_WIDTH, DOWNLOAD_BTN_HEIGHT)];
        [btn setTitle:@"Download" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(doDownload) forControlEvents:UIControlEventTouchUpInside];
        [PLYTheme setGrayButton: btn];
        [rectView addSubview:btn];
        [btn setHidden:YES];
        self.downloadButton = btn;
        
        // webview
        UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, 320, screenHeight - (NAV_BAR_HEIGHT + TOOL_BAR_HEIGHT))];
        [self.view addSubview:webView];
        [webView setDelegate:self];
        self.webView = webView;
        
        // nav bar
        rectView = [[UIView alloc] initWithFrame:CGRectMake(0, NAV_BAR_HEIGHT, 320, LINK_BAR_HEIGHT)];
        [rectView setTag: LINK_BAR_TAG];
        [self.view addSubview:rectView];
        [rectView setBackgroundColor:[UIColor colorWithRed:0.82 green:0.82 blue:0.85 alpha:0.75]];
        self.buttonBar = rectView;
        
        // video links
        // link 1
        btn = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD, MAIN_PAD, LINK_BTN_WIDTH, LINK_BTN_HEIGHT)];
        [btn setTitle:@"MetaCafe" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(linkButtonNavigate:) forControlEvents:UIControlEventTouchUpInside];
        [[btn titleLabel] setFont:[PLYTheme mediumDefaultFont]];
        [PLYTheme setGrayButton: btn];
        [rectView addSubview:btn];
        
        // link 2
        btn = [[UIButton alloc] initWithFrame:CGRectMake(320 - (MAIN_PAD + LINK_BTN_WIDTH), MAIN_PAD, LINK_BTN_WIDTH, LINK_BTN_HEIGHT)];
        [btn setTitle:@"Daily Motion" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(linkButtonNavigate:) forControlEvents:UIControlEventTouchUpInside];
        [[btn titleLabel] setFont:[PLYTheme mediumDefaultFont]];
        [PLYTheme setGrayButton: btn];
        [rectView addSubview:btn];
        
        
        // nav bar
        baseView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, NAV_BAR_HEIGHT)];
        [baseView setTag: NAV_BAR_TAG];
        [self.view addSubview:baseView];
        [baseView setBackgroundColor:[UIColor colorWithRed:0.72 green:0.72 blue:0.75 alpha:1]];
        
        // nav bar title
        label = [[UILabel alloc] initWithFrame:CGRectMake(MAIN_PAD, MAIN_PAD, 320 - (MAIN_PAD + MAIN_PAD), 14)];
        [label setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:12]];
        [label setText:@"browse and download videos"];
        [label setTag:NAV_BAR_TITLE_TAG];
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setBackgroundColor:[UIColor clearColor]];
        [label setTextColor:[UIColor colorWithWhite:1 alpha:1]];
        [baseView addSubview:label];
        self.titleLabel = label;
        
        CGRect topBars = CGRectMake(MAIN_PAD + CLOSE_BTN_DIM + MAIN_PAD,
                                    NAV_BAR_HEIGHT - MAIN_PAD - URL_FIELD_HEIGHT,
                                    320 - (MAIN_PAD + CLOSE_BTN_DIM + MAIN_PAD + MAIN_PAD),
                                    URL_FIELD_HEIGHT);

        
        // url box
        rectView = [[UIView alloc] initWithFrame:topBars];
        [rectView setBackgroundColor:[UIColor whiteColor]];
        [baseView addSubview:rectView];
        rectView.layer.cornerRadius = 2;
        self.textFieldCont = rectView;
        
        topBars = CGRectMake(MAIN_PAD, MAIN_PAD, topBars.size.width - (MAIN_PAD * 2), topBars.size.height - (MAIN_PAD * 2));
        
        // main url nav
        textField = [[UITextField alloc] initWithFrame:topBars];
        [textField setBackgroundColor:[UIColor clearColor]];
        [textField setFont:[UIFont fontWithName:[PLYTheme defaultFontName] size:18]];
        [rectView addSubview:textField];
        [textField setDelegate:self];
        [textField setReturnKeyType:UIReturnKeyGo];
        self.urlField = textField;
        
        
        // cancel text btn
        btn = [[UIButton alloc] initWithFrame:CGRectMake(320 - MAIN_PAD + CANCEL_BTN_OFFSCREEN,
                                                         NAV_BAR_HEIGHT - MAIN_PAD - SEC_BTN_DIM, CANCEL_BTN_WIDTH, SEC_BTN_DIM)];
        [btn setTitle:@"cancel" forState:UIControlStateNormal];
        [btn addTarget:self action:@selector(tapCancelEditing) forControlEvents:UIControlEventTouchUpInside];
        [PLYTheme setGrayButton: btn];
        [baseView addSubview:btn];
        self.cancelURLFieldBtn = btn;
        
        // close btn
        btn = [[UIButton alloc] initWithFrame:CGRectMake(MAIN_PAD, NAV_BAR_HEIGHT - MAIN_PAD - CLOSE_BTN_DIM, CLOSE_BTN_DIM, CLOSE_BTN_DIM)];
        [btn addTarget:self action:@selector(finishVideoCapturing) forControlEvents:UIControlEventTouchUpInside];
        [PLYTheme setGrayButton: btn];
        [btn setImage:[UIImage imageNamed:@"close-but-white-1"] forState:UIControlStateNormal];
        [btn setImage:[UIImage imageNamed:@"close-but-white-1"] forState:UIControlStateHighlighted];
        [baseView addSubview:btn];
        
    }
    return self;
}

/*
 * next: 
 *
 * - wire up done button to query for url
 * - wire up 3 link buttons to 1) set uiwebview url 2) set textview string
 */

-(void)tapCancelEditing
{
    [self hideButtonBar];
    [self hideCancelButton];
    [self.urlField resignFirstResponder];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *url = [[request URL] absoluteString];
    
    if (navigationType == UIWebViewNavigationTypeLinkClicked) {
        [self.urlField setText:url];
    }
    
    return YES;
}

-(void)setURLFieldAndNavigate: (NSString *) stringURL
{
    if (stringURL != nil) {
        [self.urlField setText:stringURL];
    } else {
        stringURL = [self.urlField text];
    }
    
    
    [self.urlField resignFirstResponder];
    [self hideButtonBar];
    [self hideCancelButton];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

    NSURL *url = [NSURL URLWithString:stringURL];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:requestObj];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    [self.downloadButton setHidden:YES];
    self.availableURL = nil;
    self.availableURLExtension = nil;
    
    NSString *url = webView.request.URL.absoluteString;

//    NSString *aTitle = [webView stringByEvaluatingJavaScriptFromString:@"$('.user-infos-container')[$('.user-infos-container').length - 1].innerHTML"];

    if (url && [url length])
        [self.urlField setText:url];
    

    if ([url rangeOfString:@"mp4"].location != NSNotFound && [url rangeOfString:@"youtube"].location == NSNotFound) {
        self.availableURL = url;
        self.availableURLExtension = @"mp4";
    }
    
    if ([url rangeOfString:@"youtube"].location != NSNotFound) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:@"YouTube download not permitted"
                                  message:nil
                                  delegate:nil
                                  cancelButtonTitle:@"OK"
                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    if ([url rangeOfString:@"dailymotion"].location != NSNotFound) {
        
        NSError *error = nil;
        NSRegularExpression *resourceRegex = [NSRegularExpression regularExpressionWithPattern:@"video/(.+)"
                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                         error:&error];
        
        if (error != nil) {
            return;
        }
        
        NSTextCheckingResult *res = [resourceRegex firstMatchInString:url options:NSRegularExpressionCaseInsensitive range:NSMakeRange(0, [url length])];
        
        if ([res numberOfRanges] > 1) {

            NSString *requestURL = [[NSString alloc] initWithFormat: @"http://www.dailymotion.com/embed/video/%@",
                                    [url substringWithRange:[res rangeAtIndex:1]], nil];
            
            if (requestURL) {
                
                PLYAppDelegate *appDelegate = (PLYAppDelegate *)[[UIApplication sharedApplication] delegate];

                [appDelegate simpleWebRequest:requestURL withBlock:^(BOOL success, NSString *html) {
                    if (success) {
                        NSError *error = nil;
                        NSRegularExpression *resourceRegex = [NSRegularExpression regularExpressionWithPattern:@"\"[^\"]+ld[^\"]*\":\s?\"([^\"]+\\.mp4[^\"]*)\""
                                                                                                       options:NSRegularExpressionCaseInsensitive
                                                                                                         error:&error];
                        
                        if (error != nil) {
                            return;
                        }
                        
                        NSArray *matches = [resourceRegex matchesInString:html options:NSMatchingReportCompletion range:NSMakeRange(0, [html length])];
                        
                        NSMutableArray *validURLs = [[NSMutableArray alloc] init];
                        
                        if ([matches count] > 0) {
                            for (NSTextCheckingResult *m in matches) {
                                if ([m numberOfRanges] == 2) {
                                    [validURLs addObject: [html substringWithRange:[m rangeAtIndex:1]]];
                                }
                            }
                        }
                        
                        if ([validURLs count] > 0) {
                            NSString *rawURL = [validURLs lastObject];
                            NSString *processedURL = [[rawURL componentsSeparatedByString:@"\\/"] componentsJoinedByString:@"/"];
                            weakSelf.availableURL = processedURL;
                            weakSelf.availableURLExtension = @"mp4";
                            [weakSelf.downloadButton setHidden:NO];
                        }
                    }
                }];

                
            }
        }
        
    } else if ([url rangeOfString:@"metacafe"].location != NSNotFound) {
        
        NSString *srcUrl = [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByTagName('video')[0].getAttribute('src')"];
        if ([srcUrl rangeOfString:@"metacafe"].location != NSNotFound) {
            self.availableURL = srcUrl;
            self.availableURLExtension = @"mp4";
            [self.downloadButton setHidden:NO];
        }
        
    } else {

    }
    
  [self.webView stringByEvaluatingJavaScriptFromString:@" \
     \
   "];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self setURLFieldAndNavigate:nil];
    return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self showButtonBar];
    [self showCancelButton];
}

-(void)linkButtonNavigate:(id)sender
{
    NSString *linkName = [(UIButton *)sender titleLabel].text;
    if ([linkName isEqualToString:@"MetaCafe"]) {
        [self setURLFieldAndNavigate:@"http://www.metacafe.com"];
    } else if ([linkName isEqualToString:@"Daily Motion"]) {
        [self setURLFieldAndNavigate:@"http://www.dailymotion.com"];
    } else if ([linkName isEqualToString:@"Vimeo"]) {
        [self setURLFieldAndNavigate:@"http://www.vimeo.com"];
    }
}

-(void)doDownload
{
    if (self.availableURL && self.availableURLExtension) {
        [(PLYVideoMixerViewController *)self.mixerViewController addThirdPartyVideoDownloadTrack:self.availableURL withPath:self.availableURLExtension];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)navigateBack
{
    if ([self.webView canGoBack])
        [self.webView goBack];
}

-(void)navigateForward
{
    if ([self.webView canGoForward])
        [self.webView goForward];
}

-(void)finishVideoCapturing
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    /* first use note */
    PLYUserInformationView *firstUse = [[PLYUserInformationView alloc] initWithImage:@"user-info-web-download-1" andFirstUseKey:@"firstUse_webDownload"];
    if (firstUse) {
        [self.view addSubview:firstUse];
    }
}


-(void)showCancelButton
{
    if (self.currentlyShowingCancelButton) return;
    self.currentlyShowingCancelButton = YES;
    
    CGPoint pt = self.cancelURLFieldBtn.center;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.cancelURLFieldBtn setCenter: CGPointMake(pt.x - (CANCEL_BTN_WIDTH + CANCEL_BTN_OFFSCREEN), pt.y)]; }
                     completion:nil];
    
    CGPoint origin = self.textFieldCont.frame.origin;
    CGSize size = self.textFieldCont.frame.size;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.textFieldCont
                                           setFrame:CGRectMake(origin.x, origin.y,
                                                               size.width - (CANCEL_BTN_WIDTH + MAIN_PAD), size.height) ]; }
                     completion:nil];
    
    origin = self.urlField.frame.origin;
    size = self.urlField.frame.size;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.urlField
                                           setFrame:CGRectMake(origin.x, origin.y,
                                                               size.width - (CANCEL_BTN_WIDTH + MAIN_PAD), size.height) ]; }
                     completion:nil];
    
    

}

-(void)hideCancelButton
{
    if (!self.currentlyShowingCancelButton) return;
    self.currentlyShowingCancelButton = NO;
    
    CGPoint pt = self.cancelURLFieldBtn.center;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.cancelURLFieldBtn setCenter: CGPointMake(pt.x + CANCEL_BTN_WIDTH + CANCEL_BTN_OFFSCREEN, pt.y)]; }
                     completion:nil];
    
    CGPoint origin = self.textFieldCont.frame.origin;
    CGSize size = self.textFieldCont.frame.size;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.textFieldCont
                                           setFrame:CGRectMake(origin.x, origin.y,
                                                               size.width + (CANCEL_BTN_WIDTH + MAIN_PAD), size.height) ]; }
                     completion:nil];
    
    origin = self.urlField.frame.origin;
    size = self.urlField.frame.size;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.urlField
                                           setFrame:CGRectMake(origin.x, origin.y,
                                                               size.width + (CANCEL_BTN_WIDTH + MAIN_PAD), size.height) ]; }
                     completion:nil];
    
    
    
}

-(void)showButtonBar
{
    if (self.currentlyShowingButtonBar) return;
    self.currentlyShowingButtonBar = YES;
    
    CGPoint pt = self.buttonBar.center;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.buttonBar setCenter: CGPointMake(pt.x, pt.y + TOOL_BAR_HEIGHT)]; }
                     completion:nil];
}

-(void)hideButtonBar
{
    if (!self.currentlyShowingButtonBar) return;
    self.currentlyShowingButtonBar = NO;
    
    
    CGPoint pt = self.buttonBar.center;
    [UIView animateWithDuration: 0.25
                          delay: 0
                        options: UIViewAnimationOptionCurveEaseInOut
                     animations: ^(void){ [self.buttonBar setCenter: CGPointMake(pt.x, pt.y - TOOL_BAR_HEIGHT)]; }
                     completion:nil];

}

@end
