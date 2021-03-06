//
//  HONTimelineCellHeaderView.m
//  HotOrNot
//
//  Created by Matt Holcombe on 8/6/13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "UIImageView+AFNetworking.h"

#import "HONTimelineCellHeaderView.h"
#import "HONEmotionVO.h"

const CGSize kFeedItemAvatarSize = {55.0f, 55.0f};

@implementation HONTimelineCellHeaderView

- (id)initWithChallenge:(HONChallengeVO *)vo
{
	if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 320.0, 92.0)])) {
		self.challengeVO = vo;
	}
	return self;
}

- (void)setChallengeVO:(HONChallengeVO *)challengeVO
{
	_challengeVO = challengeVO;
	
	if (_challengeVO != nil) {
//		UIView *avatarsView = [self _avatarStackView];
//		[self addSubview:avatarsView];
//		
//		UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
//		avatarButton.frame = avatarsView.frame;
//		[avatarButton addTarget:self action:@selector(_goProfile) forControlEvents:UIControlEventTouchUpInside];
//		[self addSubview:avatarButton];
//		
//		UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15.0 + (avatarsView.frame.origin.x + avatarsView.frame.size.width), 21.0, 50.0, 12.0)];
//		timeLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontBold] fontWithSize:11];
//		timeLabel.textColor = [UIColor whiteColor];
//		timeLabel.backgroundColor = [UIColor clearColor];
//		timeLabel.shadowColor = [UIColor blackColor];
//		timeLabel.shadowOffset = CGSizeMake(0.0, 1.0);
//		timeLabel.text = [HONAppDelegate timeSinceDate:_challengeVO.addedDate];
//		[self addSubview:timeLabel];
		
		CGSize size;
		CGFloat maxNameWidth = 280.0;
		UILabel *nameLabel = [[UILabel alloc] initWithFrame:CGRectMake((320.0 - maxNameWidth) * 0.5, 71.0, maxNameWidth, 24.0)];
		nameLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontMedium] fontWithSize:19];
		nameLabel.textColor = [UIColor whiteColor];
		nameLabel.backgroundColor = [UIColor clearColor];
		nameLabel.shadowColor = [UIColor blackColor];
		nameLabel.shadowOffset = CGSizeMake(0.0, 1.0);
		nameLabel.textAlignment = NSTextAlignmentCenter;
		nameLabel.text = _challengeVO.creatorVO.username;
		[self addSubview:nameLabel];
		
		if ([[HONDeviceIntrinsics sharedInstance] isIOS7]) {
			size = [_challengeVO.creatorVO.username boundingRectWithSize:CGSizeMake(maxNameWidth, nameLabel.frame.size.height)
																 options:NSStringDrawingTruncatesLastVisibleLine
															  attributes:@{NSFontAttributeName:nameLabel.font}
																 context:nil].size;
		}
		
		nameLabel.frame = CGRectMake((320.0 - size.width) * 0.5, nameLabel.frame.origin.y, size.width, size.height);
		UIButton *profileButton = [UIButton buttonWithType:UIButtonTypeCustom];
		profileButton.frame = nameLabel.frame;
		[profileButton addTarget:self action:@selector(_goProfile) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:profileButton];
		
		/*
		 HONEmotionVO *emotionVO = [self _creatorEmotionVO];
		 CGFloat maxSubjectWidth = 320.0 - ((nameLabel.frame.size.width + 90.0) + ((int)(emotionVO != nil) * 22.0));
		 
		 UILabel *subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(nameLabel.frame.origin.x + (nameLabel.frame.size.width + 3.0), 9.0, maxSubjectWidth, 18.0)];
		 subjectLabel.font = [[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:14];
		 subjectLabel.textColor = [UIColor whiteColor];
		 subjectLabel.backgroundColor = [UIColor clearColor];
		 subjectLabel.text = _challengeVO.subjectName;
		 [self addSubview:subjectLabel];
		 
		 if ([[HONDeviceTraits sharedInstance] isIOS7]) {
		 size = [subjectLabel.text boundingRectWithSize:CGSizeMake(maxSubjectWidth, 18.0)
		 options:NSStringDrawingTruncatesLastVisibleLine
		 attributes:@{NSFontAttributeName:subjectLabel.font}
		 context:nil].size;
		 } //else
		 //			size = [subjectLabel.text sizeWithFont:subjectLabel.font constrainedToSize:CGSizeMake(maxSubjectWidth, CGFLOAT_MAX) lineBreakMode:NSLineBreakByClipping];
		 
		 subjectLabel.frame = CGRectMake(subjectLabel.frame.origin.x, subjectLabel.frame.origin.y, MIN(maxSubjectWidth, size.width), 18.0);
		 
		 //		NSLog(@"NAME:_[%@]_ <|> SUB:_[%@]_", NSStringFromCGSize(nameLabel.frame.size), NSStringFromCGSize(subjectLabel.frame.size));
		 
		 if (emotionVO != nil) {
		 UIImageView *emoticonImageView = [[UIImageView alloc] initWithFrame:CGRectMake(subjectLabel.frame.origin.x + subjectLabel.frame.size.width + 6.0, 10.0, 18.0, 18.0)];
		 emoticonImageView.image = [UIImage imageNamed:@"emoticon_white"];
		 [emoticonImageView setImageWithURL:[NSURL URLWithString:emotionVO.urlSmallWhite] placeholderImage:nil];
		 [self addSubview:emoticonImageView];
		 }
		 */
	}
}

#pragma mark - Navigation
- (void)_goProfile {
	[self.delegate timelineCellHeaderView:self showProfile:_challengeVO.creatorVO forChallenge:_challengeVO];
}


#pragma mark - UI Presentation
- (UIView *)_avatarStackView {
	NSMutableArray *avatars = [NSMutableArray arrayWithObject:_challengeVO.creatorVO.avatarPrefix];
	UIView *holderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, kFeedItemAvatarSize.width, kFeedItemAvatarSize.height)];
	
	if ([_challengeVO.challengers count] >= 2) {
		[avatars addObject:((HONOpponentVO *)[_challengeVO.challengers firstObject]).avatarPrefix];
		[avatars addObject:((HONOpponentVO *)[_challengeVO.challengers objectAtIndex:1]).avatarPrefix];
	
	} else if ([_challengeVO.challengers count] == 1) {
		[avatars addObject:((HONOpponentVO *)[_challengeVO.challengers firstObject]).avatarPrefix];
	}
	
	CGFloat width = kFeedItemAvatarSize.width + (([avatars count] - 1) * 30.0);
	holderView.frame = CGRectMake((320.0 - width) * 0.5, 0.0, width, kFeedItemAvatarSize.height);
	
	for (int i=[avatars count]-1; i>=0; i--) {
		UIImageView *avatarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0 + (i * 30.0), 0.0, kFeedItemAvatarSize.width, kFeedItemAvatarSize.height)];
		[holderView addSubview:avatarImageView];
		
		void (^successBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
			avatarImageView.image = image;
			[[HONViewDispensor sharedInstance] maskView:avatarImageView withMask:[UIImage imageNamed:@"avatarMask"]];
		};
		
		void (^failureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
			[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:[[HONAPICaller sharedInstance] normalizePrefixForImageURL:request.URL.absoluteString] forBucketType:HONS3BucketTypeAvatars completion:nil];
			avatarImageView.image = [[HONImageBroker sharedInstance] defaultAvatarImageAtSize:kSnapThumbSize];
		};
		
		[avatarImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[avatars objectAtIndex:i] stringByAppendingString:kSnapThumbSuffix]]
																 cachePolicy:kOrthodoxURLCachePolicy
															 timeoutInterval:[HONAppDelegate timeoutInterval]]
							   placeholderImage:nil
										success:successBlock
										failure:failureBlock];
	}
	
	return (holderView);
}

@end
