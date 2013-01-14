//
//  HONChallengeViewCell.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.07.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "UIImageView+WebCache.h"

#import "HONChallengeViewCell.h"
#import "HONAppDelegate.h"

@interface HONChallengeViewCell()
@end

@implementation HONChallengeViewCell
@synthesize challengeVO = _challengeVO;

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}

- (id)initAsGreyBottomCell:(BOOL)grey isEnabled:(BOOL)enabled {
	if ((self = [self initAsGreyCell:grey])) {
		UIButton *loadMoreButton = [UIButton buttonWithType:UIButtonTypeCustom];
		loadMoreButton.frame = CGRectMake(107.0, 18.0, 106.0, 34.0);
		[loadMoreButton setBackgroundImage:[UIImage imageNamed:@"loadMoreButton_nonActive"] forState:UIControlStateNormal];
		[loadMoreButton setBackgroundImage:[UIImage imageNamed:@"loadMoreButton_Active"] forState:UIControlStateHighlighted];
		
		if (enabled)
			[loadMoreButton addTarget:self action:@selector(_goLoadMore) forControlEvents:UIControlEventTouchUpInside];
		
		[self addSubview:loadMoreButton];
		[self hideChevron];
	}
	
	return (self);
}

- (id)initAsGreyChallengeCell:(BOOL)grey {
	if ((self = [self initAsGreyCell:grey])) {
	}
	
	return (self);
}


- (void)setChallengeVO:(HONChallengeVO *)challengeVO {
	_challengeVO = challengeVO;
	
	UIView *creatorImgHolderView = [[UIView alloc] initWithFrame:CGRectMake(14.0, 10.0, 50.0, 50.0)];
	creatorImgHolderView.clipsToBounds = YES;
	[self addSubview:creatorImgHolderView];
	
	UIImageView *creatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, -8.0, kThumb1W, kThumb1H)];
	creatorImageView.backgroundColor = [UIColor colorWithWhite:0.33 alpha:1.0];
	[creatorImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_t.jpg", _challengeVO.creatorImgPrefix]] placeholderImage:nil];
	[creatorImgHolderView addSubview:creatorImageView];
	
	UIImageView *creatorScoreBGImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 35.0, 50.0, 15.0)];
	creatorScoreBGImageView.image = [UIImage imageNamed:@"smallRowScore_Overlay"];
	[creatorImgHolderView addSubview:creatorScoreBGImageView];
	
	UILabel *creatorScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 35.0, 49.0, 16.0)];
	creatorScoreLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:14];
	creatorScoreLabel.textColor = [UIColor whiteColor];
	creatorScoreLabel.backgroundColor = [UIColor clearColor];
	creatorScoreLabel.shadowColor = [UIColor blackColor];
	creatorScoreLabel.shadowOffset = CGSizeMake(1.0, 1.0);
	creatorScoreLabel.textAlignment = NSTextAlignmentRight;
	creatorScoreLabel.text = [NSString stringWithFormat:@"%d", _challengeVO.creatorScore];
	[creatorImgHolderView addSubview:creatorScoreLabel];
	
	
	UILabel *challengeLabel = [[UILabel alloc] initWithFrame:CGRectMake(72.0, 18.0, 200.0, 16.0)];
	challengeLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:12];
	challengeLabel.textColor = [HONAppDelegate honGreyTxtColor];
	challengeLabel.backgroundColor = [UIColor clearColor];
	[self addSubview:challengeLabel];
	
	UILabel *subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(72.0, 36.0, 200.0, 16.0)];
	subjectLabel.font = [[HONAppDelegate freightSansBlack] fontWithSize:13];
	subjectLabel.textColor = [UIColor blackColor];
	subjectLabel.backgroundColor = [UIColor clearColor];
	subjectLabel.text = _challengeVO.subjectName;
	[self addSubview:subjectLabel];
	
	
	if ([_challengeVO.status isEqualToString:@"Created"]) {
		challengeLabel.text = @"You have challenged someone to…";
		
	} else if ([_challengeVO.status isEqualToString:@"Waiting"]) {
		challengeLabel.text = [NSString stringWithFormat:@"You have challenged %@ to…", _challengeVO.challengerName];
		
//		if (_challengeVO.hasViewed)
//			challengeLabel.text = [challengeLabel.text stringByAppendingString:@"\nOpened"];
		
	} else if ([_challengeVO.status isEqualToString:@"Accept"]) {
		challengeLabel.text = [NSString stringWithFormat:@"%@ has challenged you…", _challengeVO.creatorName];
		
//		if (_challengeVO.hasViewed)
//			challengeLabel.text = [challengeLabel.text stringByAppendingString:@"\nOpened"];
		
	} else if ([_challengeVO.status isEqualToString:@"Started"] || [_challengeVO.status isEqualToString:@"Completed"]) {
		challengeLabel.frame = CGRectOffset(challengeLabel.frame, 60.0, 0.0);
		challengeLabel.text = @"You are playing…";
		
		subjectLabel.frame = CGRectOffset(subjectLabel.frame, 60.0, 0.0);
		
		[creatorImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_t.jpg", _challengeVO.creatorImgPrefix]] placeholderImage:nil];
		
		UIView *challengerImgHolderView = [[UIView alloc] initWithFrame:CGRectMake(64.0, 10.0, 50.0, 50.0)];
		challengerImgHolderView.clipsToBounds = YES;
		[self addSubview:challengerImgHolderView];
		
		UIImageView *challengerImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, -8.0, kThumb1W, kThumb1H)];
		challengerImageView.backgroundColor = [UIColor colorWithWhite:0.85 alpha:1.0];
		[challengerImageView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@_t.jpg", _challengeVO.challengerImgPrefix]] placeholderImage:nil];
		[challengerImgHolderView addSubview:challengerImageView];
		
		UIImageView *challengerScoreBGImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 35.0, 50.0, 15.0)];
		challengerScoreBGImageView.image = [UIImage imageNamed:@"smallRowScore_Overlay"];
		[challengerImgHolderView addSubview:challengerScoreBGImageView];
				
		UILabel *challengerScoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 35.0, 49.0, 16.0)];
		challengerScoreLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:14];
		challengerScoreLabel.textColor = [UIColor whiteColor];
		challengerScoreLabel.shadowColor = [UIColor blackColor];
		challengerScoreLabel.shadowOffset = CGSizeMake(1.0, 1.0);
		challengerScoreLabel.backgroundColor = [UIColor clearColor];
		challengerScoreLabel.textAlignment = NSTextAlignmentRight;
		challengerScoreLabel.text = [NSString stringWithFormat:@"%d", _challengeVO.challengerScore];
		[challengerImgHolderView addSubview:challengerScoreLabel];
		
		//challengeLabel.text = (_challengeVO.creatorID == [[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue]) ? [NSString stringWithFormat:@"You have challenged %@ to \n%@\nOpened & Accepted", _challengeVO.challengerName, _challengeVO.subjectName] : [NSString stringWithFormat:@"%@ has challenged you to \n%@\nOpened & Accepted", _challengeVO.creatorName, _challengeVO.subjectName];
	}
}


//- (void)willTransitionToState:(UITableViewCellStateMask)state {
//	[super willTransitionToState:state];
//
//	NSLog(@"willTransitionToState");
//	
//	if ((state & UITableViewCellStateShowingDeleteConfirmationMask) == UITableViewCellStateShowingDeleteConfirmationMask) {
//		for (UIView *subview in self.subviews) {
//			if ([NSStringFromClass([subview class]) isEqualToString:@"UITableViewCellDeleteConfirmationControl"]) {
//				UIImageView *deleteBtn = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 80, 40)];
//				[deleteBtn setImage:[UIImage imageNamed:@"genericGrayButton_nonActive"]];
//				[[subview.subviews objectAtIndex:0] addSubview:deleteBtn];
//			}
//		}
//	}
//}

#pragma mark - Navigation
- (void)_goLoadMore {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NEXT_CHALLENGE_BLOCK" object:nil];
}

@end