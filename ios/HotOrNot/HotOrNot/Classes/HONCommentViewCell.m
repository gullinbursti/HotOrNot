//
//  HONCommentViewCell.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 02.20.13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"

#import "HONCommentViewCell.h"
#import "HONAppDelegate.h"

@implementation HONCommentViewCell

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}

- (void)setCommentVO:(HONCommentVO *)commentVO {
	_commentVO = commentVO;
	
	UIImageView *userImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14.0, 12.0, 38.0, 38.0)];
	userImageView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
	[userImageView setImageWithURL:[NSURL URLWithString:_commentVO.avatarURL] placeholderImage:nil];
	userImageView.layer.cornerRadius = 4.0;
	userImageView.clipsToBounds = YES;
	[self addSubview:userImageView];
	
//	UIImageView *creatorScoreBGImageView = [[UIImageView alloc] initWithFrame:CGRectMake(14.0, 45.0, 50.0, 15.0)];
//	creatorScoreBGImageView.image = [UIImage imageNamed:@"smallRowScore_Overlay"];
//	[self addSubview:creatorScoreBGImageView];
//	
//	UILabel *scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(14.0, 45.0, 50.0, 15.0)];
//	scoreLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:11];
//	scoreLabel.textColor = [UIColor whiteColor];
//	scoreLabel.backgroundColor = [UIColor clearColor];
//	scoreLabel.textAlignment = NSTextAlignmentCenter;
//	scoreLabel.shadowColor = [UIColor blackColor];
//	scoreLabel.shadowOffset = CGSizeMake(1.0, 1.0);
//	scoreLabel.text = [NSString stringWithFormat:@"%d", _commentVO.userScore];
//	[self addSubview:scoreLabel];
	
	UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(240.0, 24.0, 60.0, 16.0)];
	timeLabel.font = [[HONAppDelegate honHelveticaNeueFontMedium] fontWithSize:11];
	timeLabel.textColor = [HONAppDelegate honGreyTxtColor];
	timeLabel.backgroundColor = [UIColor clearColor];
	timeLabel.textAlignment = NSTextAlignmentRight;
	timeLabel.text = [HONAppDelegate timeSinceDate:_commentVO.addedDate];
	[self addSubview:timeLabel];
		
	UILabel *usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(61.0, 15.0, 200.0, 12.0)];
	usernameLabel.font = [[HONAppDelegate honHelveticaNeueFontMedium] fontWithSize:10];
	usernameLabel.textColor = [HONAppDelegate honGreyTxtColor];
	usernameLabel.backgroundColor = [UIColor clearColor];
	usernameLabel.text = [NSString stringWithFormat:@"@%@", _commentVO.username];
	[self addSubview:usernameLabel];
	
	CGSize size = [_commentVO.content sizeWithFont:[[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:14] constrainedToSize:CGSizeMake(200.0, CGFLOAT_MAX) lineBreakMode:NSLineBreakByClipping];
	UILabel *contentLabel = [[UILabel alloc] initWithFrame:CGRectMake(61.0, 30.0, 200.0, size.height)];
	contentLabel.font = [[HONAppDelegate honHelveticaNeueFontMedium] fontWithSize:14];
	contentLabel.textColor = [HONAppDelegate honBlueTxtColor];
	contentLabel.backgroundColor = [UIColor clearColor];
	contentLabel.numberOfLines = 0;
	contentLabel.text = _commentVO.content;
	[self addSubview:contentLabel];
	
	[self hideChevron];
}

@end
