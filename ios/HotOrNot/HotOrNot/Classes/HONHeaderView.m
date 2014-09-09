//
//  HONHeaderView.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 10.14.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "HONHeaderView.h"

@interface HONHeaderView()
@property (nonatomic, strong) UIImageView *bgImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@end

@implementation HONHeaderView
@synthesize title = _title;

- (id)initWithBranding {
	if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, kNavHeaderHeight)])) {
		_bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navHeaderBrandingBG"]];
		[self addSubview:_bgImageView];
	}
	
	return (self);
}

- (id)initWithTitle:(NSString *)title {
	if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, kNavHeaderHeight)])) {
		_bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"navHeaderBG"]];
		[self addSubview:_bgImageView];
		
		_title = title;
		_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(75.0, 33.0, 170.0, 19.0)];
		_titleLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontBold] fontWithSize:17];
		_titleLabel.textColor = [UIColor whiteColor];
		_titleLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		_titleLabel.textAlignment = NSTextAlignmentCenter;
		_titleLabel.text = _title;
		[self addSubview:_titleLabel];
	}
	
	return (self);
}

//- (id)initWithTitle:(NSString *)title hasBackground:(BOOL)withBG {
//	if ((self = [self initWithTitle:title])) {
//	}
//	
//	return (self);
//}


- (void)setTitle:(NSString *)title {
	_title = title;
	_titleLabel.text = _title;
}


- (void)addButton:(UIView *)buttonView {
	buttonView.frame = CGRectOffset(buttonView.frame, 0.0, 19.0);
	[self addSubview:buttonView];
}

- (void)leftAlignTitle {
	_titleLabel.textAlignment = NSTextAlignmentLeft;
}


@end
