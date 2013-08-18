//
//  HONPrivacyViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.28.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "HONPrivacyViewController.h"


@interface HONPrivacyViewController () <UIWebViewDelegate>
@end

@implementation HONPrivacyViewController

- (id)init {
	if ((self = [super initWithURL:[NSString stringWithFormat:@"%@/privacy.htm", [HONAppDelegate customerServiceURL]] title:@"Privacy Policy"])) {
	}
	
	return (self);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	
}

- (BOOL)shouldAutorotate {
	return (NO);
}


#pragma mark - View Lifecycle
- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor whiteColor];;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	[HONAppDelegate offsetSubviewsForIOS7:self.view];
}


#pragma mark - Navigation


#pragma mark - WebView Delegates
@end
