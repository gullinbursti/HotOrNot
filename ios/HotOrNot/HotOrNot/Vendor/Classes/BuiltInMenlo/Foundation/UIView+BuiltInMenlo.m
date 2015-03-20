//
//  UIView+BuiltInMenlo.m
//  HotOrNot
//
//  Created by Matt Holcombe on 06/20/2014.
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "UIView+BuiltInMenlo.h"

@implementation UIView (BuiltInMenlo)

- (UIImage *)createImageFromView {
	UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0f);
	[self.layer renderInContext:UIGraphicsGetCurrentContext()];
	
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return (image);
}

- (void)reverseSubviews {
	NSMutableArray *views = [NSMutableArray array];
	for (UIView *view in self.subviews)
		[views addObject:view];
	
	for (UIView *view in self.subviews)
		[view removeFromSuperview];
	
	for (UIView *view in [[views reverseObjectEnumerator] allObjects])
		[self addSubview:view];
	
	views = nil;
}

+ (instancetype)viewAtSize:(CGSize)size {
	return ([UIView viewAtSize:size withBGColor:[UIColor clearColor]]);
}

+ (instancetype)viewAtSize:(CGSize)size withBGColor:(UIColor *)bgColor {
	UIView *matteView = [[UIView alloc] initWithFrame:CGRectFromSize(size)];
	matteView.backgroundColor = bgColor;
	
	return (matteView);
}

- (id)initAtSize:(CGSize)size {
	return ([[UIView alloc] initAtSize:size withBGColor:[UIColor clearColor]]);
}

- (id)initAtSize:(CGSize)size withBGColor:(UIColor *)bgColor {
	return ([UIView viewAtSize:size withBGColor:bgColor]);
}

- (void)centerAlignWithinParentView {
	if (self.superview != nil) {
		[self centerHorizontalAlignWithRect:self.superview.frame];
		[self centerVerticalAlignWithRect:self.superview.frame];
	}
}

- (void)centerHorizontalAlignWithinParentView {
	if (self.superview != nil)
		[self centerHorizontalAlignWithRect:self.superview.frame];
}

- (void)centerVerticalAlignWithinParentView {
	if (self.superview != nil)
		[self centerVerticalAlignWithRect:self.superview.frame];
}

- (void)centerAlignWithRect:(CGRect)rect {
	[self centerHorizontalAlignWithRect:rect];
	[self centerVerticalAlignWithRect:rect];
}

- (void)centerHorizontalAlignWithRect:(CGRect)rect {
	self.frame = CGRectTranslateY(self.frame, (rect.size.width - self.frame.size.width) * 0.5);
}

- (void)centerVerticalAlignWithRect:(CGRect)rect {
	self.frame = CGRectTranslateY(self.frame, (rect.size.height - self.frame.size.height) * 0.5);
}



- (UIEdgeInsets)frameEdges {
	return (UIEdgeInsetsMake(self.frame.origin.y, self.frame.origin.x, self.frame.origin.y + self.frame.size.height, self.frame.origin.x + self.frame.size.width));
}

@end
