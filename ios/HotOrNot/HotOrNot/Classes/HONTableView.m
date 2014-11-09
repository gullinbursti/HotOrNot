//
//  HONTableView.m
//  HotOrNot
//
//  Created by Matt Holcombe on 06/16/2014 @ 20:57 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//


#import "HONTableView.h"

const CGFloat kOrthodoxTableCellHeight = 74.0f;
const UIEdgeInsets kOrthodoxTableViewEdgeInsets = {0.0, 0.0, 48.0, 0.0};

@interface HONTableView ()
@end

@implementation HONTableView

- (id)initWithFrame:(CGRect)frame style:(UITableViewStyle)style {
	if ((self = [super initWithFrame:frame style:style])) {
		[self setBackgroundColor:[UIColor clearColor]];
		[self setSeparatorStyle:UITableViewCellSeparatorStyleNone];
		[self setShowsHorizontalScrollIndicator:NO];
		[self setShowsVerticalScrollIndicator:NO];
		[self setAlwaysBounceVertical:YES];
		[self setSectionIndexMinimumDisplayRowCount:1];
	}
	
	return (self);
}

- (id)initWithFrame:(CGRect)frame {
	if ((self = [self initWithFrame:frame style:UITableViewStylePlain])) {
	}
	
	return (self);
}


#pragma mark - Overrides
- (void)setContentInset:(UIEdgeInsets)contentInset {
	if (self.tracking) {
		CGPoint translation = [self.panGestureRecognizer translationInView:self];
		translation.y -= ((contentInset.top - self.contentInset.top) * 1.5);
		[self.panGestureRecognizer setTranslation:translation inView:self];
	}
	
	[super setContentInset:contentInset];
}


#pragma mark - Navigation



@end
