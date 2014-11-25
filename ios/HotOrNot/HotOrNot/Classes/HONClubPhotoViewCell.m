//
//  HONClubPhotoViewCell.m
//  HotOrNot
//
//  Created by Matt Holcombe on 06/14/2014 @ 21:59 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSDate+Operations.h"
#import "NSString+DataTypes.h"
#import "UIImageView+AFNetworking.h"
#import "UILabel+BoundingRect.h"
#import "UILabel+FormattedText.h"

#import "PicoSticker.h"

#import "HONClubPhotoViewCell.h"
#import "HONStickerSummaryView.h"
#import "HONEmotionVO.h"
#import "HONImageLoadingView.h"

@interface HONClubPhotoViewCell () <HONStickerSummaryViewDelegate>
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) HONImageLoadingView *imageLoadingView;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UIButton *upvoteButton;
@property (nonatomic, strong) UIButton *downVoteButton;
@property (nonatomic, strong) HONStickerSummaryView *stickerSummaryView;

@property (nonatomic, strong) NSMutableArray *emotionViews;
@property (nonatomic, strong) NSMutableArray *emotions;

@property (nonatomic) CGFloat emotionInsetAmt;
@property (nonatomic) CGSize emotionSpacingSize;
@property (nonatomic) UIOffset indHistory;
@property (nonatomic, strong) NSTimer *tintTimer;
@property (nonatomic, strong) NSTimer *stickerTimer;
@end

@implementation HONClubPhotoViewCell
@synthesize clubVO = _clubVO;
@synthesize clubPhotoVO = _clubPhotoVO;

const CGFloat kStickerTimerInterval = 0.875f;

const CGRect kEmotionInitFrame = {80.0f, 80.0f, 53.0f, 53.0f};
const CGRect kEmotionLoadedFrame = {0.0f, 0.0f, 320.0f, 320.0f};
const CGRect kEmotionOutroFrame = {-6.0f, -6.0f, 224.0f, 224.0f};

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}


- (id)init {
	if ((self = [super init])) {
		//self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgComposeUnderlay"]];
		self.backgroundColor = [UIColor blackColor];
		
		_emotions = [NSMutableArray array];
		_emotionViews = [NSMutableArray array];
		_indHistory = UIOffsetZero;
		_emotionSpacingSize = CGSizeMake(kEmotionLoadedFrame.size.width + 0.0, kEmotionLoadedFrame.size.height + 0.0);
		_emotionInsetAmt = 0.5 * (320.0 - kEmotionLoadedFrame.size.width);
	}
	
	return (self);
}

- (void)dealloc {
	_scrollView.delegate = nil;
	_stickerSummaryView.delegate = nil;
	
	if (_tintTimer != nil) {
		[_tintTimer invalidate];
		_tintTimer = nil;
	}
	
	if (_stickerTimer != nil) {
		[_stickerTimer invalidate];
		_stickerTimer = nil;
	}
}

- (void)destroy {
	_scrollView.delegate = nil;
	_stickerSummaryView.delegate = nil;
	
	if (_tintTimer != nil) {
		[_tintTimer invalidate];
		_tintTimer = nil;
	}
	
	if (_stickerTimer != nil) {
		[_stickerTimer invalidate];
		_stickerTimer = nil;
	}
}

- (void)toggleImageLoading:(BOOL)isLoading {
	if (isLoading) {
		[self _loadEmotionAtIndex:0];
	}
}

- (void)setClubPhotoVO:(HONClubPhotoVO *)clubPhotoVO {
	_clubPhotoVO = clubPhotoVO;
	
	[self hideChevron];
	
	_imageLoadingView = [[HONImageLoadingView alloc] initInViewCenter:self.contentView asLargeLoader:NO];
	[self.contentView addSubview:_imageLoadingView];
	
	_imgView = [[UIImageView alloc] initWithFrame:self.frame];
	_imgView.backgroundColor = [UIColor blackColor];
	[self.contentView addSubview:_imgView];
	
	void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
		_imgView.image = image;
		[_imageLoadingView stopAnimating];
		[_imageLoadingView removeFromSuperview];
		_imageLoadingView = nil;
		
		[_imgView addSubview:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"selfieGradientOverlay"]]];
	};
	
	void (^imageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
		[_imgView setImageWithURL:[NSURL URLWithString:[[[HONClubAssistant sharedInstance] defaultClubPhotoURL] stringByAppendingString:kSnapLargeSuffix]]];
		[_imageLoadingView stopAnimating];
		[_imageLoadingView removeFromSuperview];
		_imageLoadingView = nil;
		
//		[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:[[HONAPICaller sharedInstance] normalizePrefixForImageURL:request.URL.absoluteString] forBucketType:HONS3BucketTypeClubs completion:nil];
	};
	
	NSString *url = [_clubPhotoVO.imagePrefix stringByAppendingString:kSnapLargeSuffix];
//	NSLog(@"URL:[%@]", url);
	[_imgView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]
													  cachePolicy:kOrthodoxURLCachePolicy
												  timeoutInterval:[HONAppDelegate timeoutInterval]]
					placeholderImage:nil
							 success:imageSuccessBlock
							 failure:imageFailureBlock];
	
	
//	if ([_clubPhotoVO.imagePrefix rangeOfString:@"defaultClubPhoto"].location != NSNotFound) {
//		
//	} else {
//		if (_clubPhotoVO.photoType == HONClubPhotoTypeGIF) {
//			FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
//			animatedImageView.frame = CGRectMakeFromSize(CGSizeMake(320.0, 271.0)); //CGRectMake(0.0, 0.0, 320.0, 271.0);
//			animatedImageView.contentMode = UIViewContentModeScaleToFill; // fills frame w/o proprotions
//			animatedImageView.clipsToBounds = YES;
//			[_imgView addSubview:animatedImageView];
//			
//			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//				NSURL *url = [NSURL URLWithString:_clubPhotoVO.imagePrefix];
//				NSLog(@"IMG URL:[%@]", url);
//				FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
//				
//				dispatch_async(dispatch_get_main_queue(), ^{
//					animatedImageView.animatedImage = animatedImage;
//				});
//			});
//			
//		} else {
//			void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
//				_imgView.image = image;
//			};
//			
//			void (^imageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
//				[_imgView setImageWithURL:[NSURL URLWithString:[[HONClubAssistant sharedInstance] rndCoverImageURL]]];
//				[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:[[HONAPICaller sharedInstance] normalizePrefixForImageURL:request.URL.absoluteString] forBucketType:HONS3BucketTypeClubs completion:nil];
//			};
//			
//			[_imgView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[[[HONClubAssistant sharedInstance] rndCoverImageURL] stringByAppendingString:([[HONDeviceIntrinsics sharedInstance] isRetina4Inch]) ? kSnapLargeSuffix : kSnapTabSuffix]]
//																cachePolicy:kOrthodoxURLCachePolicy
//															timeoutInterval:[HONAppDelegate timeoutInterval]]
//							  placeholderImage:nil
//									   success:imageSuccessBlock
//									   failure:imageFailureBlock];
//		}
//	}
	
	
//	NSLog(@"FRAME:[%@][%@]", NSStringFromCGRect(self.frame), NSStringFromCGRect(self.contentView.frame));
	
	_scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, kEmotionLoadedFrame.size.height)];
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
	_scrollView.alwaysBounceHorizontal = YES;
	_scrollView.delegate = self;
	_scrollView.pagingEnabled = YES;
	//[self.contentView addSubview:_scrollView];
	
	UIButton *nextPageButton = [UIButton buttonWithType:UIButtonTypeCustom];
	nextPageButton.frame = self.frame;
	[nextPageButton addTarget:self action:@selector(_goNextPhoto) forControlEvents:UIControlEventTouchUpInside];
	[self.contentView addSubview:nextPageButton];
	
	
	UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(246.0, 77.0, 60.0, 20.0)];
	timeLabel.backgroundColor = [UIColor clearColor];
	timeLabel.textColor = [UIColor whiteColor];
	timeLabel.textAlignment = NSTextAlignmentRight;
	timeLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:16];
	timeLabel.text = [[HONDateTimeAlloter sharedInstance] intervalSinceDate:_clubPhotoVO.addedDate];
	[self.contentView addSubview:timeLabel];
	
	NSLog(@"SUBJECT:[%d]", [[_clubPhotoVO.dictionary objectForKey:@"text"] length]);
	if ([[_clubPhotoVO.dictionary objectForKey:@"text"] length] > 0) {
		UIView *subjectBGView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 262.0, 320.0, 44.0)];
		subjectBGView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.75];
		[self.contentView addSubview:subjectBGView];
		
		UILabel *subjectLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 7.0, 280.0, 24.0)];
		subjectLabel.backgroundColor = [UIColor clearColor];
		subjectLabel.textColor = [UIColor whiteColor];
		subjectLabel.textAlignment = NSTextAlignmentCenter;
		subjectLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:18];
		subjectLabel.text = [_clubPhotoVO.dictionary objectForKey:@"text"];
		[subjectBGView addSubview:subjectLabel];
	}
	
	UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height - 44.0, 320.0, 44.0)];
	footerView.backgroundColor = [UIColor whiteColor];
	[self.contentView addSubview:footerView];
	
	_stickerSummaryView = [[HONStickerSummaryView alloc] initWithFrame:CGRectFromSize(CGSizeMake(320.0, 64.0))];
	
	_scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(198.0, 12.0, 80.0, 20.0)];
	_scoreLabel.backgroundColor = [UIColor clearColor];
	_scoreLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:16];
	_scoreLabel.textAlignment = NSTextAlignmentCenter;
	_scoreLabel.textColor = [[HONColorAuthority sharedInstance] honBlueTextColor];
	_scoreLabel.text = @"…";
	[footerView addSubview:_scoreLabel];
	
	[[HONAPICaller sharedInstance] retrieveVoteTotalForChallengeWithChallengeID:_clubPhotoVO.challengeID completion:^(NSString *result) {
		_clubPhotoVO.score = [result intValue];
		_scoreLabel.text = [@"" stringFromInt:_clubPhotoVO.score];
	}];
	
	_upvoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_upvoteButton.frame = CGRectMake(157.0, 0.0, 44.0, 44.0);
	[_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvoteButton_nonActive"] forState:UIControlStateNormal];
	[_upvoteButton setBackgroundImage:[UIImage imageNamed:@"upvoteButton_Active"] forState:UIControlStateHighlighted];
	[footerView addSubview:_upvoteButton];
	
	_downVoteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_downVoteButton.frame = CGRectMake(274.0, 0.0, 44.0, 44.0);
	[_downVoteButton setBackgroundImage:[UIImage imageNamed:@"downvoteButton_nonActive"] forState:UIControlStateNormal];
	[_downVoteButton setBackgroundImage:[UIImage imageNamed:@"downvoteButton_Active"] forState:UIControlStateHighlighted];
	[footerView addSubview:_downVoteButton];
	
//	NSLog(@"HAS VOTED:[%@]", [@"" stringFromBOOL:[[HONClubAssistant sharedInstance] hasVotedForClubPhoto:_clubPhotoVO]]);
	if (![[HONClubAssistant sharedInstance] hasVotedForClubPhoto:_clubPhotoVO]) {
		[_upvoteButton addTarget:self action:@selector(_goUpvote) forControlEvents:UIControlEventTouchUpInside];
		[_downVoteButton addTarget:self action:@selector(_goDownVote) forControlEvents:UIControlEventTouchUpInside];
	}
}


#pragma mark - Navigation
- (void)_goUserProfile {
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:showUserProfileForClubPhoto:)])
		[self.delegate clubPhotoViewCell:self showUserProfileForClubPhoto:_clubPhotoVO];
}

- (void)_goReply {
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:replyToPhoto:)])
		[self.delegate clubPhotoViewCell:self replyToPhoto:_clubPhotoVO];
}

- (void)_goNextPhoto {
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:advancePhoto:)])
		[self.delegate clubPhotoViewCell:self advancePhoto:_clubPhotoVO];
}

- (void)_goUpvote {
	[_upvoteButton removeTarget:self action:@selector(_goUpvote) forControlEvents:UIControlEventTouchUpInside];
	[_downVoteButton removeTarget:self action:@selector(_goDownVote) forControlEvents:UIControlEventTouchUpInside];
	
	_scoreLabel.text = [@"" stringFromInt:_clubPhotoVO.score + 1];
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:upvotePhoto:)])
		[self.delegate clubPhotoViewCell:self upvotePhoto:_clubPhotoVO];
}

- (void)_goDownVote {
	[_upvoteButton removeTarget:self action:@selector(_goUpvote) forControlEvents:UIControlEventTouchUpInside];
	[_downVoteButton removeTarget:self action:@selector(_goDownVote) forControlEvents:UIControlEventTouchUpInside];
	
	_scoreLabel.text = [@"" stringFromInt:_clubPhotoVO.score - 1];
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:downVotePhoto:)])
		[self.delegate clubPhotoViewCell:self downVotePhoto:_clubPhotoVO];
}

- (void)_goNextSticker {
	int offset = (_scrollView.contentOffset.x >= (_scrollView.contentSize.width - _scrollView.frame.size.width)) ? 0 : _scrollView.contentOffset.x + self.frame.size.width;
	//int offset = (_scrollView.contentOffset.x + self.frame.size.width == _scrollView.contentSize.width) ? 0 : _scrollView.contentOffset.x + self.frame.size.width;
	int ind = MIN(MAX(0, offset / _scrollView.frame.size.width), (int)[_emotions count] - 1);
	
	NSLog(@"IND:[%d]", ind);
	
//	[_stickerSummaryView selectStickerAtIndex:ind];
//	[UIView animateWithDuration:0.000250 delay:0.000
//		 usingSpringWithDamping:0.875 initialSpringVelocity:0.125
//						options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent)
	
//					 animations:^(void) {
//						 [_scrollView setContentOffset:CGPointMake(offset, 0.0) animated:NO];
	
//					 } completion:^(BOOL finish=ed) {
//					 }];
}


#pragma mark - UI Presentation
- (void)_populateEmotions {
	int cnt = 0;
	for (HONEmotionVO *emotionVO in [[HONClubAssistant sharedInstance] emotionsForClubPhoto:_clubPhotoVO]) {
		UIView *emotionView = [self _viewForEmotion:emotionVO atIndex:cnt];
		emotionView.frame = CGRectOffset(emotionView.frame, _emotionInsetAmt + (cnt * _emotionSpacingSize.width), 0.0);
		[_scrollView addSubview:emotionView];
		[_emotionViews addObject:emotionView];
		[_emotions addObject:emotionVO];
		
		UIButton *nextPageButton = [UIButton buttonWithType:UIButtonTypeCustom];
		nextPageButton.frame = emotionView.frame;
		[nextPageButton addTarget:self action:@selector(_goNextPhoto) forControlEvents:UIControlEventTouchUpInside];
		[_scrollView addSubview:nextPageButton];
		
		cnt++;
	}
	
//	[self _loadEmotionAtIndex:0];
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * [_emotions count], _scrollView.frame.size.height);
}

- (void)_changeTint {
	UIColor *color = [[HONColorAuthority sharedInstance] honRandomColorWithStartingBrightness:0.50 andSaturation:0.50];// [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
	
	[UIView animateWithDuration:2.0 animations:^(void) {
		_imgView.layer.backgroundColor = color.CGColor;
	} completion:nil];
}

- (UIView *)_viewForEmotion:(HONEmotionVO *)emotionVO atIndex:(int)index {
	UIView *holderView = [[UIView alloc] initWithFrame:kEmotionLoadedFrame];
	
	HONImageLoadingView *imageLoadingView = [[HONImageLoadingView alloc] initInViewCenter:holderView asLargeLoader:NO];
	imageLoadingView.alpha = 0.000667;
	[imageLoadingView startAnimating];
	[holderView addSubview:imageLoadingView];
	
//	PicoSticker *picoSticker = [[PicoSticker alloc] initWithPCContent:emotionVO.pcContent];
//	[holderView addSubview:picoSticker];
	
//	PicoSticker *picoSticker = [[HONStickerAssistant sharedInstance] stickerFromCandyBoxWithContentID:emotionVO.emotionID];
//	[holderView addSubview:picoSticker];
	
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:kEmotionLoadedFrame];
	CGAffineTransform transform = [[HONViewDispensor sharedInstance] affineTransformView:imageView toSize:kEmotionInitFrame.size];
	
	if (emotionVO.imageType == HONEmotionImageTypePNG) {
		//[imageView setTintColor:[UIColor whiteColor]];
		[imageView setTag:[emotionVO.emotionID intValue]];
		imageView.alpha = 0.0;
		imageView.transform = transform;
		[holderView addSubview:imageView];
	
	} else {
		FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
		animatedImageView.contentMode = UIViewContentModeScaleToFill;//UIViewContentModeScaleAspectFit; // centers in frame
		animatedImageView.clipsToBounds = YES;
		animatedImageView.frame = kEmotionLoadedFrame;
		animatedImageView.alpha = 0.0;
		animatedImageView.transform = transform;
		[holderView addSubview:animatedImageView];
	}
	
	return (holderView);
}

- (void)_loadEmotionAtIndex:(int)index {
	if (index < [_emotions count]) {
		HONEmotionVO *emotionVO = (HONEmotionVO *)[_emotions objectAtIndex:index];
		UIView *holderView = (UIView *)[_emotionViews objectAtIndex:index];
		HONImageLoadingView *imageLoadingView = (HONImageLoadingView *)[holderView.subviews firstObject];
		
		if (emotionVO.imageType == HONEmotionImageTypePNG) {
			UIImageView *imageView = [holderView.subviews lastObject];
			
			void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
				imageView.image = image;
				
				[imageLoadingView stopAnimating];
				imageLoadingView.hidden = YES;
				[imageLoadingView removeFromSuperview];
				
				emotionVO.image = image;
				[_stickerSummaryView appendSticker:emotionVO];
				
				[UIView animateWithDuration:0.250 delay:0.000
					 usingSpringWithDamping:0.750 initialSpringVelocity:0.125
									options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationCurveEaseInOut)
				 
								 animations:^(void) {
									 imageView.alpha = 1.0;
									 imageView.transform = CGAffineTransformMakeNormal();
								 } completion:^(BOOL finished) {
									 if (index == 0 && _stickerTimer == nil) {
										 [_stickerSummaryView selectStickerAtIndex:0];
										 //_stickerTimer = [NSTimer scheduledTimerWithTimeInterval:kStickerTimerInterval target:self selector:@selector(_goNextSticker) userInfo:nil repeats:YES];
									 }
									 
									 if (index < [_emotions count] - 1) {
										 [self _loadEmotionAtIndex:index + 1];
									 }
								 }];
				
			};
			
			void (^imageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
				[imageLoadingView stopAnimating];
				imageLoadingView.hidden = YES;
				[imageLoadingView removeFromSuperview];
			};
			
			//	NSLog(@"emotionVO.largeImageURL:[%@]", emotionVO.largeImageURL);
			[imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:emotionVO.largeImageURL]
															   cachePolicy:kOrthodoxURLCachePolicy
														   timeoutInterval:[HONAppDelegate timeoutInterval]]
							 placeholderImage:nil
									  success:imageSuccessBlock
									  failure:imageFailureBlock];
			
			
		
		} else if (emotionVO.imageType == HONEmotionImageTypeGIF) {
			FLAnimatedImageView *animatedImageView = (FLAnimatedImageView *)[holderView.subviews lastObject];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:[NSURL URLWithString:emotionVO.smallImageURL]]];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					animatedImageView.animatedImage = animatedImage;
					
					FLAnimatedImageView *animatedThumbImageView = [[FLAnimatedImageView alloc] init];
					animatedThumbImageView.frame = CGRectFromSize(CGSizeMake(64.0, 64.0));
					animatedThumbImageView.contentMode = UIViewContentModeScaleAspectFit;
					animatedThumbImageView.clipsToBounds = YES;
					animatedThumbImageView.animatedImage = animatedImage;
					
					emotionVO.animatedImageView = animatedThumbImageView;
					[_stickerSummaryView appendSticker:emotionVO];
					
					[UIView animateWithDuration:0.250 delay:0.000
						 usingSpringWithDamping:0.750 initialSpringVelocity:0.125
										options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationCurveEaseInOut)
					 
									 animations:^(void) {
										 animatedImageView.alpha = 1.0;
										 animatedImageView.transform = CGAffineTransformMakeNormal();
									 } completion:^(BOOL finished) {
										 if (index == 0 && _stickerTimer == nil) {
											 [_stickerSummaryView selectStickerAtIndex:0];
											 //_stickerTimer = [NSTimer scheduledTimerWithTimeInterval:kStickerTimerInterval target:self selector:@selector(_goNextSticker) userInfo:nil repeats:YES];
										 }
										 
										 if (index < [_emotions count] - 1) {
											 [self _loadEmotionAtIndex:index + 1];
										 }
									 }];
				});
			});
		}
	}
}


#pragma mark - StickerSummaryView Delegates
- (void)stickerSummaryView:(HONStickerSummaryView *)stickerSummaryView didSelectThumb:(HONEmotionVO *)emotionVO atIndex:(int)index {
	NSLog(@"[*:*] stickerSummaryView:didSelectThumb[%@ - %@] (%d)", emotionVO.emotionID, emotionVO.emotionName, index);
	
	int offset = MIN(MAX(0.0, index * _scrollView.frame.size.width), _scrollView.frame.size.width * ([_emotions count] - 1));
	[UIView animateWithDuration:0.333 delay:0.000
		 usingSpringWithDamping:0.875 initialSpringVelocity:0.0625
						options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent)

					 animations:^(void) {
						[_scrollView setContentOffset:CGPointMake(offset, 0.0) animated:NO];

					 } completion:^(BOOL finished) {
					 }];
}


#pragma mark - ScrollView Delegates
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//	NSLog(@"[*:*] scrollViewDidScroll:[%@] (%@)", NSStringFromCGSize(scrollView.contentSize), NSStringFromCGPoint(scrollView.contentOffset));
	
	int currInd = _indHistory.horizontal;
	
//	int axisInd = (_emotionInsetAmt + scrollView.contentOffset.x) / _emotionSpacingSize.width;
	int updtInd = MAX(0, MIN([_emotions count], (_emotionInsetAmt + scrollView.contentOffset.x) / _emotionSpacingSize.width));
	int axisCoord = (updtInd * _emotionSpacingSize.width) - _emotionInsetAmt;
	
	if (updtInd == currInd) {
//		NSLog(@"‹~|≈~~¡~≈~!~≈~¡~≈~!~≈~¡~≈~!~≈~¡~≈~|[ EQL ]|~≈~¡~≈~!~≈~¡~≈~!~≈~¡~≈~!~≈~¡~~≈|~›");
		
	} else if (updtInd < currInd) {
//		NSLog(@"‹~|≈~~¡~≈~!~≈~¡~≈~!~≈~¡~≈~!~≈~¡~≈~|[ DEC ]|~≈~¡~≈~!~≈~¡~≈~!~≈~¡~≈~!~≈~¡~~≈|~›");
//		NSLog(@"LOWER:[%.02f] COORD:[%d] UPPER:[%.02f] contentOffset:[%d] updtInd:[%d]", (axisCoord - _emotionInsetAmt), axisCoord, (axisCoord + _emotionInsetAmt), scrollView.contentOffset.x, updtInd);
		
		if (scrollView.contentOffset.x < (axisCoord + _emotionInsetAmt) && scrollView.contentOffset.x > (axisCoord - _emotionInsetAmt)) {
			_indHistory = UIOffsetMake(updtInd, currInd);
//			_emotionLabel.text = ((HONEmotionVO *)[_emotions objectAtIndex:updtInd]).emotionName;
		} else
			return;
		
	} else if (updtInd > currInd) {
//		NSLog(@"‹~|≈~~¡~≈~!~≈~¡~≈~!~≈~¡~≈~!~≈~¡~≈~|[ INC ]|~≈~¡~≈~!~≈~¡~≈~!~≈~¡~≈~!~≈~¡~~≈|~›");
//		NSLog(@"LOWER:[%.02f] COORD:[%d] UPPER:[%.02f] contentOffset:[%d] updtInd:[%d]", (axisCoord - _emotionInsetAmt), axisCoord, (axisCoord + _emotionInsetAmt), scrollView.contentOffset.x, updtInd);
		
		if (scrollView.contentOffset.x > (axisCoord - _emotionInsetAmt) && scrollView.contentOffset.x < (axisCoord + _emotionInsetAmt)) {
			_indHistory = UIOffsetMake(updtInd, currInd);
//			_emotionLabel.text = ((HONEmotionVO *)[_emotions objectAtIndex:updtInd]).emotionName;
			
		} else
			return;
	}
}

@end
