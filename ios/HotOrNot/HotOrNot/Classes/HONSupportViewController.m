//
//  HONSupportViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 10.23.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "Mixpanel.h"
#import "MBProgressHUD.h"

#import "HONSupportViewController.h"
#import "HONAppDelegate.h"
#import "HONHeaderView.h"

@interface HONSupportViewController () <UIWebViewDelegate>
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@end

@implementation HONSupportViewController

- (id)init {
	if ((self = [super init])) {
		[[Mixpanel sharedInstance] track:@"Support"
									 properties:[NSDictionary dictionaryWithObjectsAndKeys:
													 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
		
		self.view.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
	}
	
	return (self);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}


#pragma mark - View Lifecycle
- (void)loadView {
	[super loadView];
	
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
	bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h" : @"mainBG"];
	[self.view addSubview:bgImgView];
	
	HONHeaderView *headerView = [[HONHeaderView alloc] initWithTitle:@"SUPPORT"];
	[self.view addSubview:headerView];
	
	UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
	cancelButton.frame = CGRectMake(253.0, 5.0, 64.0, 34.0);
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"cancelButton_nonActive"] forState:UIControlStateNormal];
	[cancelButton setBackgroundImage:[UIImage imageNamed:@"cancelButton_Active"] forState:UIControlStateHighlighted];
	[cancelButton addTarget:self action:@selector(_goCancel) forControlEvents:UIControlEventTouchUpInside];
	[headerView addSubview:cancelButton];
	
	UIWebView *webView = [[UIWebView alloc] initWithFrame:CGRectMake(0.0, 45.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 45.0)];
	[webView setBackgroundColor:[UIColor clearColor]];
	webView.delegate = self;
	[webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@/support.htm", [HONAppDelegate apiServerPath]]]]];
	[self.view addSubview:webView];
	
	if (!_progressHUD) {
		_progressHUD = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
		_progressHUD.mode = MBProgressHUDModeIndeterminate;
		_progressHUD.taskInProgress = YES;
		_progressHUD.minShowTime = kHUDTime;
		
		[self performSelector:@selector(_removeHUD) withObject:nil afterDelay:8.0];
	}
	
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

#pragma mark - Navigation
- (void)_goCancel {
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)_removeHUD {
	if (_progressHUD != nil) {
		_progressHUD.taskInProgress = NO;
		[_progressHUD hide:YES];
		_progressHUD = nil;
	}
}


#pragma mark - WebView Delegates
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	return (YES);
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[self _removeHUD];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
	NSLog(@"didFailLoadWithError:[%@]", error);
	
	[self _removeHUD];
	
	if ([error code] == NSURLErrorCancelled)
		return;
}

@end
