//
//  HONBackNavButtonView.m
//  HotOrNot
//
//  Created by BIM  on 11/3/14.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "HONBackNavButtonView.h"

@interface HONBackNavButtonView()
@end

@implementation HONBackNavButtonView

- (id)initWithTarget:(id)target action:(SEL)action {
	if ((self = [super initWithTarget:target action:action])) {
		[self setFrame:CGRectOffset(self.frame, 9.0, 0.0)];
		
		[_button setBackgroundImage:[UIImage imageNamed:@"backButton_nonActive"] forState:UIControlStateNormal];
		[_button setBackgroundImage:[UIImage imageNamed:@"backButton_Active"] forState:UIControlStateHighlighted];
		_button.frame = CGRectResize(_button.frame, CGSizeAdd(_button.frame.size, CGSizeMake(2.0, 2.0)));
	}
	
	return (self);
}

@end
