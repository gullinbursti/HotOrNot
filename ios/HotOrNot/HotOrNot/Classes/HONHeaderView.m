//
//  HONHeaderView.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 10.14.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "HONHeaderView.h"

#import "HONActivityNavButtonView.h"
#import "HONBackNavButtonView.h"
#import "HONCloseNavButtonView.h"
#import "HONComposeNavButtonView.h"
#import "HONDoneNavButtonView.h"
#import "HONNextNavButtonView.h"

@interface HONHeaderView()
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UIImageView *titleImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) HONActivityNavButtonView *activityNavButtonView;
@end

@implementation HONHeaderView
@synthesize title = _title;

- (id)initWithBranding {
	if ((self = [self initWithTitleImage:[UIImage imageNamed:@"branding"]])) {
		_titleImageView.frame = CGRectOffset(_titleImageView.frame, 84.0, 21.0);
	}
	
	return (self);
}

- (id)init {
	if ((self = [super initWithFrame:CGRectFromSize(CGSizeMake(320.0, kNavHeaderHeight))])) {
		_bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navHeaderBackground"]];
		[self addSubview:_bgImageView];
		
		_title = @"";
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(75.0, 30.0, 170.0, 24.0)];
		_titleLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontMedium] fontWithSize:18];
		_titleLabel.textColor = [UIColor whiteColor];
		_titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		_titleLabel.textAlignment = NSTextAlignmentCenter;
		_titleLabel.text = _title;
		[self addSubview:_titleLabel];
	}
	
	return (self);
}

- (id)initWithTitle:(NSString *)title {
	if ((self = [self init])) {
		_title = title;
		_titleLabel.text = _title;
	}
	
	return (self);
}

- (id)initWithTitle:(NSString *)title asLightStyle:(BOOL)isLightStyle {
	if ((self = [self initWithTitle:title])) {
		_titleLabel.textColor = [UIColor whiteColor];
	}
	
	return (self);
}

- (id)initWithTitleImage:(UIImage *)image {
	if ((self = [self init])) {
		[self addTitleImage:image];
	}
	
	return (self);
}


- (void)addButton:(UIView *)buttonView {
	buttonView.frame = CGRectOffset(buttonView.frame, 0.0, 20.0);
	[self addSubview:buttonView];
}

- (void)addActivityButtonWithTarget:(id)target action:(SEL)action {
	_activityNavButtonView = [[HONActivityNavButtonView alloc] initWithTarget:target action:action];
	[self addButton:_activityNavButtonView];
}

- (void)addBackButtonWithTarget:(id)target action:(SEL)action {
	[self addButton:[[HONBackNavButtonView alloc] initWithTarget:target action:action]];
}

- (void)addCloseButtonWithTarget:(id)target action:(SEL)action {
	[self addButton:[[HONCloseNavButtonView alloc] initWithTarget:target action:action]];
}

- (void)addComposeButtonWithTarget:(id)target action:(SEL)action {
	[self addButton:[[HONComposeNavButtonView alloc] initWithTarget:target action:action]];
}

- (void)addDoneButtonWithTarget:(id)target action:(SEL)action {
	[self addButton:[[HONDoneNavButtonView alloc] initWithTarget:target action:action]];
}

- (void)addNextButtonWithTarget:(id)target action:(SEL)action {
	[self addButton:[[HONNextNavButtonView alloc] initWithTarget:target action:action]];
}

- (void)setTitle:(NSString *)title {
	_title = title;
	
	_titleLabel.text = _title;
	_titleLabel.hidden = ([_title length] == 0);
	_titleImageView.hidden = ([_title length] > 0);
}

- (void)leftAlignTitle {
	_titleLabel.textAlignment = NSTextAlignmentLeft;
}

- (void)transitionTitle:(NSString *)title {
	if (![_title isEqualToString:title]) {
		UILabel *outroLabel = [[UILabel alloc] initWithFrame:_titleLabel.frame];
		outroLabel.font = _titleLabel.font;
		outroLabel.textColor = _titleLabel.textColor;
		outroLabel.shadowColor = _titleLabel.shadowColor;
		outroLabel.shadowOffset = _titleLabel.shadowOffset;
		outroLabel.textAlignment = _titleLabel.textAlignment;
		[self addSubview:outroLabel];
		
		_titleLabel.alpha = 0.0;
		_title = title;
		_titleLabel.text = _title;
		
		[UIView animateWithDuration:0.25 animations:^(void) {
			outroLabel.alpha = 0.0;
			_titleLabel.alpha = 1.0;
		} completion:^(BOOL finished) {
			[outroLabel removeFromSuperview];
		}];
	}
}

- (void)addTitleImage:(UIImage *)image {
	[self setTitle:@""];
	
	_titleImageView = [[UIImageView alloc] initWithImage:image];
	_titleImageView.frame = CGRectOffset(_titleImageView.frame, (self.frame.size.width - image.size.width) * 0.5, 22.0);
	[self addSubview:_titleImageView];
}

- (void)refreshActivity {
	if (_activityNavButtonView != nil)
		[_activityNavButtonView updateActivityBadge];
}

- (void)removeBackground {
	_bgImageView.hidden = YES;
}

@end
