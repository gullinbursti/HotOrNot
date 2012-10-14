//
//  HONTabBarController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 10.04.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "HONTabBarController.h"

@interface HONTabBarController ()

@end

@implementation HONTabBarController

@synthesize btn1, btn2, btn3, btn4, btn5;

- (void)loadView {
	[super loadView];
	
	[self hideTabBar];
	[self addCustomElements];
	[self showNewTabBar];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)hideTabBar {
	for(UIView *view in self.view.subviews) {
		if([view isKindOfClass:[UITabBar class]]) {
			view.hidden = YES;
			break;
		}
	}
}

- (void)hideNewTabBar {
	self.btn1.hidden = YES;
	self.btn2.hidden = YES;
	self.btn3.hidden = YES;
	self.btn4.hidden = YES;
	self.btn5.hidden = YES;
}

- (void)showNewTabBar {
	self.btn1.hidden = NO;
	self.btn2.hidden = NO;
	self.btn3.hidden = NO;
	self.btn4.hidden = NO;
	self.btn5.hidden = NO;
}

-(void)addCustomElements {
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - 48.0, 320.0, 48.0)];
	bgImgView.image = [UIImage imageNamed:@"footerBackground.png"];
	[self.view addSubview:bgImgView];
	
	// Initialise our two images
	UIImage *btnImage = [UIImage imageNamed:@"tab01_nonActive.png"];
	UIImage *btnImageActive = [UIImage imageNamed:@"tab01_Active.png"];
	UIImage *btnImageSelected = [UIImage imageNamed:@"tab01_tapped.png"];
	
	self.btn1 = [UIButton buttonWithType:UIButtonTypeCustom]; //Setup the button
	btn1.frame = CGRectMake(0.0, self.view.frame.size.height - 48.0, 64.0, 48.0); // Set the frame (size and position) of the button)
	[btn1 setBackgroundImage:btnImage forState:UIControlStateNormal]; // Set the image for the normal state of the button
	[btn1 setBackgroundImage:btnImageActive forState:UIControlStateHighlighted]; // Set the image for the normal state of the button
	[btn1 setBackgroundImage:btnImageSelected forState:UIControlStateSelected]; // Set the image for the selected state of the button
	[btn1 setTag:0]; // Assign the button a "tag" so when our "click" event is called we know which button was pressed.
	[btn1 setSelected:true]; // Set this button as selected (we will select the others to false as we only want Tab 1 to be selected initially
	
	// Now we repeat the process for the other buttons
	btnImage = [UIImage imageNamed:@"tab02_nonActive.png"];
	btnImageActive = [UIImage imageNamed:@"tab02_Active.png"];
	btnImageSelected = [UIImage imageNamed:@"tab02_tapped.png"];
	self.btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
	btn2.frame = CGRectMake(64.0, self.view.frame.size.height - 48.0, 64.0, 48.0);
	[btn2 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn2 setBackgroundImage:btnImageActive forState:UIControlStateHighlighted];
	[btn2 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn2 setTag:1];
	
	btnImage = [UIImage imageNamed:@"tab03_nonActive.png"];
	btnImageActive = [UIImage imageNamed:@"tab03_Active.png"];
	btnImageSelected = [UIImage imageNamed:@"tab03_tapped.png"];
	self.btn3 = [UIButton buttonWithType:UIButtonTypeCustom];
	btn3.frame = CGRectMake(128.0, self.view.frame.size.height - 48.0, 64.0, 48.0);
	[btn3 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn3 setBackgroundImage:btnImageActive forState:UIControlStateHighlighted];
	[btn3 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn3 setTag:2];
	
	btnImage = [UIImage imageNamed:@"tab04_nonActive.png"];
	btnImageActive = [UIImage imageNamed:@"tab04_Active.png"];
	btnImageSelected = [UIImage imageNamed:@"tab04_tapped.png"];
	self.btn4 = [UIButton buttonWithType:UIButtonTypeCustom];
	btn4.frame = CGRectMake(192.0, self.view.frame.size.height - 48.0, 64.0, 48.0);
	[btn4 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn4 setBackgroundImage:btnImageActive forState:UIControlStateHighlighted];
	[btn4 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn4 setTag:3];
	
	btnImage = [UIImage imageNamed:@"tab05_nonActive.png"];
	btnImageActive = [UIImage imageNamed:@"tab05_Active.png"];
	btnImageSelected = [UIImage imageNamed:@"tab05_tapped.png"];
	self.btn5 = [UIButton buttonWithType:UIButtonTypeCustom];
	btn5.frame = CGRectMake(256.0, self.view.frame.size.height - 48.0, 64.0, 48.0);
	[btn5 setBackgroundImage:btnImage forState:UIControlStateNormal];
	[btn5 setBackgroundImage:btnImageActive forState:UIControlStateHighlighted];
	[btn5 setBackgroundImage:btnImageSelected forState:UIControlStateSelected];
	[btn5 setTag:4];
	
	// Add my new buttons to the view
	[self.view addSubview:btn1];
	[self.view addSubview:btn2];
	[self.view addSubview:btn3];
	[self.view addSubview:btn4];
	[self.view addSubview:btn5];
	
	// Setup event handlers so that the buttonClicked method will respond to the touch up inside event.
	[btn1 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn2 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn3 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn4 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[btn5 addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)buttonClicked:(id)sender {
	int tagNum = [sender tag];
	[self selectTab:tagNum];
}

- (void)selectTab:(int)tabID {
	[self.delegate tabBarController:self shouldSelectViewController:[self.viewControllers objectAtIndex:tabID]];
	
	switch(tabID) {
		case 0:
			[btn1 setSelected:true];
			[btn2 setSelected:false];
			[btn3 setSelected:false];
			[btn4 setSelected:false];
			[btn5 setSelected:false];
			break;
			
		case 1:
			[btn1 setSelected:false];
			[btn2 setSelected:true];
			[btn3 setSelected:false];
			[btn4 setSelected:false];
			[btn5 setSelected:false];
			break;
			
		case 2:
			[btn1 setSelected:(self.selectedIndex == 0)];
			[btn2 setSelected:(self.selectedIndex == 1)];
			[btn3 setSelected:false];
			[btn4 setSelected:(self.selectedIndex == 3)];
			[btn5 setSelected:(self.selectedIndex == 4)];
			break;
			
		case 3:
			[btn1 setSelected:false];
			[btn2 setSelected:false];
			[btn3 setSelected:false];
			[btn4 setSelected:true];
			[btn5 setSelected:false];
			break;
			
		case 4:
			[btn1 setSelected:false];
			[btn2 setSelected:false];
			[btn3 setSelected:false];
			[btn4 setSelected:false];
			[btn5 setSelected:true];
			break;
	}
	
	if (tabID == 2) {
		UINavigationController *navController = (UINavigationController *)[self selectedViewController];
		[navController popToRootViewControllerAnimated:YES];
	
	} else
		self.selectedIndex = tabID;
	
	[self.delegate tabBarController:self didSelectViewController:[self.viewControllers objectAtIndex:tabID]];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_LIST" object:nil];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

@end