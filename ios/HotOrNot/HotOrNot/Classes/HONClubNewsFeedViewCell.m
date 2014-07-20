//
//  HONClubNewsFeedViewCell.m
//  HotOrNot
//
//  Created by Matt Holcombe on 04/25/2014 @ 11:00 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "UIImageView+AFNetworking.h"
#import "UILabel+BoundingRect.m"
#import "UILabel+FormattedText.h"
#import "UIView+ReverseSubviews.h"

#import "HONClubNewsFeedViewCell.h"
#import "HONClubPhotoVO.h"
#import "HONEmotionVO.h"

@interface HONClubNewsFeedViewCell ()
@property (nonatomic, strong) HONClubPhotoVO *photoVO;
@property (nonatomic, strong) UIImageView *avatarImageView;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UILabel *timeLabel;
@property (nonatomic) HONClubNewsFeedCellType clubNewsFeedCellType;
@end

@implementation HONClubNewsFeedViewCell
//@synthesize timelineItemVO = _timelineItemVO;
@synthesize clubVO = _clubVO;
@synthesize delegate = _delegate;


+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}

- (id)init {
	if ((self = [super init])) {
		self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"viewCellBG_normal"]];
	}
	
	return (self);
}


#pragma mark - Public APIs
- (void)setClubVO:(HONUserClubVO *)clubVO {
	_clubVO = clubVO;
	
	_clubNewsFeedCellType = (_clubVO.clubEnrollmentType == HONClubEnrollmentTypeMember || (_clubVO.clubEnrollmentType == HONClubEnrollmentTypeOwner && [_clubVO.submissions count] > 0)) ? HONClubNewsFeedCellTypePhotoSubmission : HONClubNewsFeedCellTypeNonMember;
	
	_photoVO = (_clubNewsFeedCellType == HONClubNewsFeedCellTypePhotoSubmission) ? (HONClubPhotoVO *)[_clubVO.submissions firstObject] : nil;
	NSString *titleCaption = (_clubNewsFeedCellType == HONClubNewsFeedCellTypePhotoSubmission) ? [NSString stringWithFormat:@"%@ - in %@", _photoVO.username, _clubVO.clubName] : [_clubVO.clubName stringByAppendingString:@" - Join Now!"];

	UILabel *titleLabel = [[UILabel alloc] initWithFrame:(_clubNewsFeedCellType == HONClubNewsFeedCellTypePhotoSubmission) ? CGRectMake(69.0, 10.0, 210.0, 16.0) : CGRectMake(17.0, 7.0, 238.0, 16.0)];
	titleLabel.backgroundColor = [UIColor clearColor];
	titleLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:12];
	titleLabel.textColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
	titleLabel.attributedText = [[NSAttributedString alloc] initWithString:titleCaption attributes:@{}];
	[titleLabel setFont:[[[HONFontAllocator sharedInstance] helveticaNeueFontBold] fontWithSize:12] range:[titleCaption rangeOfString:_clubVO.clubName]];
	[titleLabel setTextColor:[UIColor blackColor] range:[titleCaption rangeOfString:(_clubNewsFeedCellType == HONClubNewsFeedCellTypePhotoSubmission) ? _photoVO.username : _clubVO.clubName]];
	[self.contentView addSubview:titleLabel];
	
	if (_clubNewsFeedCellType == HONClubNewsFeedCellTypePhotoSubmission) {
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(17.0, 16.0, 44.0, 44.0)];
		[self.contentView addSubview:imageView];
		[HONImagingDepictor maskImageView:imageView withMask:[UIImage imageNamed:@"thumbMask"]];
		
		void (^avatarImageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
			imageView.image = image;
		};
		
		void (^avatarImageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
			[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:[HONAppDelegate cleanImagePrefixURL:request.URL.absoluteString] forBucketType:(_clubNewsFeedCellType == HONClubNewsFeedCellTypePhotoSubmission) ? HONS3BucketTypeAvatars : HONS3BucketTypeClubs completion:nil];
			
			imageView.image = [HONImagingDepictor defaultAvatarImageAtSize:kSnapThumbSize];
			[UIView animateWithDuration:0.25 animations:^(void) {
				imageView.alpha = 1.0;
			} completion:nil];
		};
		
		[imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[_photoVO.imagePrefix stringByAppendingString:kSnapThumbSuffix]]
														   cachePolicy:kURLRequestCachePolicy
													   timeoutInterval:[HONAppDelegate timeoutInterval]]
						 placeholderImage:nil
								  success:avatarImageSuccessBlock
								  failure:avatarImageFailureBlock];
		
		UIButton *avatarButton = [UIButton buttonWithType:UIButtonTypeCustom];
		avatarButton.frame = imageView.frame;
		[avatarButton addTarget:self action:@selector(_goUserProfile) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:avatarButton];
		
		UIButton *usernameButton = [UIButton buttonWithType:UIButtonTypeCustom];
//		usernameButton.frame = [titleLabel boundingRectForCharacterRange:[titleCaption rangeOfString:_photoVO.username]];
		[usernameButton addTarget:self action:@selector(_goUserProfile) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:usernameButton];
		
		[titleLabel setFont:[[[HONFontAllocator sharedInstance] helveticaNeueFontBold] fontWithSize:12] range:[titleCaption rangeOfString:_photoVO.username]];
		
		_timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(270.0, 12.0, 35.0, 16.0)];
		_timeLabel.backgroundColor = [UIColor clearColor];
		_timeLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:12];
		_timeLabel.textColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
		_timeLabel.textAlignment = NSTextAlignmentRight;
		_timeLabel.text = [[HONDateTimeAlloter sharedInstance] intervalSinceDate:_clubVO.updatedDate];
		[self.contentView addSubview:_timeLabel];
		
		int cnt = 0;
		for (HONEmotionVO *emotionVO in [[HONClubAssistant sharedInstance] emotionsForClubPhoto:_photoVO]) {
			UIImageView *emotionImageView = [self _imageViewForEmotion:emotionVO];
			emotionImageView.frame = CGRectOffset(emotionImageView.frame, 69.0 + (cnt * 30), 34.0);
			[self.contentView addSubview:emotionImageView];
			
			if (++cnt == 7) {
				UILabel *elipsisLabel = [[UILabel alloc] initWithFrame:CGRectMake(289.0, 46.0, 15.0, 14.0)];
				elipsisLabel.backgroundColor = [UIColor clearColor];
				elipsisLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontBold] fontWithSize:14];
				elipsisLabel.textColor = [UIColor blackColor];
				elipsisLabel.text = @"…";
				[self.contentView addSubview:elipsisLabel];
				
				break;
			}
		}
		
	} else {
		UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, 25.0, 180.0, 16.0)];
		subtitleLabel.backgroundColor = [UIColor clearColor];
		subtitleLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:12];
		subtitleLabel.textColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
		[self.contentView addSubview:subtitleLabel];
		
		NSString *subtitleCaption = _clubVO.ownerName;
		if ([_clubVO.activeMembers count] > 0) {
			subtitleCaption = [subtitleCaption stringByAppendingString:@", "];
			int cnt = 0;
			for (HONTrivialUserVO *vo in _clubVO.activeMembers) {
				NSString *caption = ([_clubVO.activeMembers count] - cnt > 1) ? [subtitleCaption stringByAppendingFormat:@"%@, & %d more", vo.username, ([_clubVO.activeMembers count] - cnt)] : [subtitleCaption stringByAppendingString:vo.username];
				CGSize size = [caption boundingRectWithSize:subtitleLabel.frame.size
													options:NSStringDrawingTruncatesLastVisibleLine
												 attributes:@{NSFontAttributeName:subtitleLabel.font}
													context:nil].size;
				NSLog(@"SIZE:[%@](%@)", NSStringFromCGSize(size), caption);
				if (size.width >= subtitleLabel.frame.size.width)
					break;
				
				subtitleCaption = [subtitleCaption stringByAppendingFormat:@"%@, ", vo.username];
				cnt++;
			}
			
			subtitleCaption = [subtitleCaption substringToIndex:[subtitleCaption length] - 2];
			int remaining = [_clubVO.activeMembers count] - cnt;
			
			if (remaining > 0)
				subtitleCaption = [subtitleCaption stringByAppendingFormat:@", & %d more", remaining];
		}
		
		subtitleLabel.text = subtitleCaption;
		
		UIButton *createClubButton = [UIButton buttonWithType:UIButtonTypeCustom];
		createClubButton.frame = CGRectMake(253.0, 3.0, 64.0, 44.0);
		[createClubButton setBackgroundImage:[UIImage imageNamed:@"plusClubButton_nonActive"] forState:UIControlStateNormal];
		[createClubButton setBackgroundImage:[UIImage imageNamed:@"plusClubButton_Active"] forState:UIControlStateHighlighted];
		[createClubButton addTarget:self action:(_clubVO.clubEnrollmentType == HONClubEnrollmentTypeAutoGen) ? @selector(_goCreateClub) : @selector(_goJoinClub) forControlEvents:UIControlEventTouchUpInside];
		[self.contentView addSubview:createClubButton];
	}
}


#pragma mark - Navigation
- (void)_goCreateClub {
	if ([self.delegate respondsToSelector:@selector(clubNewsFeedViewCell:createClubWithProtoVO:)])
		[self.delegate clubNewsFeedViewCell:self createClubWithProtoVO:_clubVO];
}

- (void)_goUserProfile {
	if ([self.delegate respondsToSelector:@selector(clubNewsFeedViewCell:showUserProfileForClubPhoto:)])
		[self.delegate clubNewsFeedViewCell:self showUserProfileForClubPhoto:_photoVO];
}

- (void)_goJoinClub {
	if ([self.delegate respondsToSelector:@selector(clubNewsFeedViewCell:joinClub:)])
		[self.delegate clubNewsFeedViewCell:self joinClub:_clubVO];
}

- (void)_goLike {
	if ([self.delegate respondsToSelector:@selector(clubNewsFeedViewCell:upvoteClubPhoto:)])
		[self.delegate clubNewsFeedViewCell:self upvoteClubPhoto:_clubVO];
}

- (void)_goReply {
	if ([self.delegate respondsToSelector:@selector(clubNewsFeedViewCell:replyToClubPhoto:)])
		[self.delegate clubNewsFeedViewCell:self replyToClubPhoto:_clubVO];
}


#pragma mark - UI Presentation
- (UIImageView *)_imageViewForEmotion:(HONEmotionVO *)emotionVO {
	CGRect orgFrame = {0.0, 0.0, 150.0, 150.0};
	CGRect adjFrame = {0.0, 0.0, 25.0, 25.0};
	
	CGSize scaleSize = CGSizeMake(adjFrame.size.width / orgFrame.size.width, adjFrame.size.height / orgFrame.size.height);
	CGPoint offsetPt = CGPointMake(CGRectGetMidX(adjFrame) - CGRectGetMidX(orgFrame), CGRectGetMidY(adjFrame) - CGRectGetMidY(orgFrame));
	
	CGAffineTransform transform = CGAffineTransformMake(scaleSize.width, 0.0, 0.0, scaleSize.height, offsetPt.x, offsetPt.y);
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 150.0, 150.0)];
	imageView.transform = transform;
	[imageView setTag:emotionVO.emotionID];
	imageView.alpha = 0.0;
	
	void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		imageView.image = image;
		
		[UIView animateWithDuration:0.33 delay:0.0
			 usingSpringWithDamping:0.875 initialSpringVelocity:0.5
							options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent
		 
						 animations:^(void) {
							 imageView.alpha = 1.0;
						 } completion:^(BOOL finished) {
						 }];
	};
	
	[imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:emotionVO.smallImageURL]
													   cachePolicy:NSURLRequestReturnCacheDataElseLoad
												   timeoutInterval:[HONAppDelegate timeoutInterval]]
					 placeholderImage:nil
							  success:imageSuccessBlock
							  failure:nil];
	
	return (imageView);
}

@end
