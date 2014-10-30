//
//  HONClubPhotoViewCell.m
//  HotOrNot
//
//  Created by Matt Holcombe on 06/14/2014 @ 21:59 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSString+DataTypes.h"
#import "UIImageView+AFNetworking.h"
#import "UILabel+BoundingRect.h"
#import "UILabel+FormattedText.h"

#import "PicoSticker.h"

#import "HONClubPhotoViewCell.h"
#import "HONEmotionVO.h"
#import "HONImageLoadingView.h"

@interface HONClubPhotoViewCell ()
@property (nonatomic, strong) UIImageView *imgView;
@property (nonatomic, strong) HONImageLoadingView *imageLoadingView;
@property (nonatomic, strong) UILabel *scoreLabel;
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UIScrollView *emotionThumbsHolderView;

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

const CGRect kEmotionInitFrame = {80.0f, 80.0f, 53.0f, 53.0f};
const CGRect kEmotionLoadedFrame = {0.0f, 0.0f, 320.0f, 320.0f};
const CGRect kEmotionOutroFrame = {-6.0f, -6.0f, 224.0f, 224.0f};
const CGSize kStickerPaddingSize = {0.0f, 0.0f};

+ (NSString *)cellReuseIdentifier {
	return (NSStringFromClass(self));
}


- (id)init {
	if ((self = [super init])) {
		self.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgComposeUnderlay"]];
		self.backgroundColor = [UIColor whiteColor];
		
		_emotions = [NSMutableArray array];
		_emotionViews = [NSMutableArray array];
		_indHistory = UIOffsetZero;
		_emotionSpacingSize = CGSizeMake(kEmotionLoadedFrame.size.width + kStickerPaddingSize.width, kEmotionLoadedFrame.size.height + kStickerPaddingSize.height);
		_emotionInsetAmt = 0.5 * (320.0 - kEmotionLoadedFrame.size.width);
	}
	
	return (self);
}

- (void)dealloc {
	_scrollView.delegate = nil;
	
	if (_tintTimer != nil) {
		[_tintTimer invalidate];
		_tintTimer = nil;
	}
	
	if (_stickerTimer != nil) {
		[_stickerTimer invalidate];
		_stickerTimer = nil;
	}
}

- (void)setClubPhotoVO:(HONClubPhotoVO *)clubPhotoVO {
	_clubPhotoVO = clubPhotoVO;
	
	if ([_clubPhotoVO.imagePrefix rangeOfString:@"defaultClubPhoto"].location == NSNotFound) {
		_imageLoadingView = [[HONImageLoadingView alloc] initInViewCenter:self.contentView asLargeLoader:NO];
		[self.contentView addSubview:_imageLoadingView];
	}
	
	_imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 320.0)];
	[self.contentView addSubview:_imgView];
	
	
	NSLog(@"IMG SIZE:[%@]", NSStringFromCGSize(_imgView.frame.size));
	if ([_clubPhotoVO.imagePrefix rangeOfString:@"defaultClubPhoto"].location != NSNotFound) {
		
	} else {
		if (_clubPhotoVO.photoType == HONClubPhotoTypeGIF) {
			FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
			animatedImageView.frame = CGRectMake(0.0, 0.0, 320.0, 320.0);
			animatedImageView.contentMode = UIViewContentModeScaleToFill; // fills frame w/o proprotions
			animatedImageView.clipsToBounds = YES;
			[_imgView addSubview:animatedImageView];
			
			dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
				NSURL *url = [NSURL URLWithString:_clubPhotoVO.imagePrefix];
				NSLog(@"IMG URL:[%@]", url);
				FLAnimatedImage *animatedImage1 = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
				
				dispatch_async(dispatch_get_main_queue(), ^{
					animatedImageView.animatedImage = animatedImage1;
				});
			});
			
		} else {
			void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
				_imgView.image = image;
			};
			
			void (^imageFailureBlock)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) = ^void((NSURLRequest *request, NSHTTPURLResponse *response, NSError *error)) {
				[_imgView setImageWithURL:[NSURL URLWithString:[[HONClubAssistant sharedInstance] rndCoverImageURL]]];
				[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:[[HONAPICaller sharedInstance] normalizePrefixForImageURL:request.URL.absoluteString] forBucketType:HONS3BucketTypeClubs completion:nil];
			};
			
			[_imgView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[_clubPhotoVO.imagePrefix stringByAppendingString:([[HONDeviceIntrinsics sharedInstance] isRetina4Inch]) ? kSnapLargeSuffix : kSnapTabSuffix]]
																cachePolicy:kOrthodoxURLCachePolicy
															timeoutInterval:[HONAppDelegate timeoutInterval]]
							  placeholderImage:nil
									   success:imageSuccessBlock
									   failure:imageFailureBlock];
		}
	}
	
	
	NSLog(@"FRAME:[%@][%@]", NSStringFromCGRect(self.frame), NSStringFromCGRect(self.contentView.frame));
	
	_scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, kEmotionLoadedFrame.size.height)];
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width, _scrollView.frame.size.height);
	_scrollView.showsHorizontalScrollIndicator = NO;
	_scrollView.showsVerticalScrollIndicator = NO;
	_scrollView.alwaysBounceHorizontal = YES;
	_scrollView.delegate = self;
	_scrollView.pagingEnabled = YES;
	[self.contentView addSubview:_scrollView];
	
	[self _loadEmotions];
	
	UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 320.0, 320.0, self.frame.size.height - 320.0)];
	bgView.backgroundColor = [UIColor whiteColor];
	[self.contentView addSubview:bgView];
	
	_emotionThumbsHolderView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 320.0, 320.0, 50.0)];
	_emotionThumbsHolderView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.00];
	_emotionThumbsHolderView.contentSize = CGSizeMake(_emotionThumbsHolderView.frame.size.width, _emotionThumbsHolderView.frame.size.height);
	_emotionThumbsHolderView.showsHorizontalScrollIndicator = NO;
	_emotionThumbsHolderView.showsVerticalScrollIndicator = NO;
	_emotionThumbsHolderView.alwaysBounceHorizontal = YES;
	[self addSubview:_emotionThumbsHolderView];
	
	UIButton *replyButton = [UIButton buttonWithType:UIButtonTypeCustom];
	replyButton.frame = CGRectMake(0.0, self.frame.size.height - 50.0, 320.0, 50.0);
	[replyButton setBackgroundImage:[UIImage imageNamed:@"replyButton_nonActive"] forState:UIControlStateNormal];
	[replyButton setBackgroundImage:[UIImage imageNamed:@"replyButton_Active"] forState:UIControlStateHighlighted];
	[replyButton addTarget:self action:@selector(_goReply) forControlEvents:UIControlEventTouchUpInside];
	[self.contentView addSubview:replyButton];
	
	UILabel *participantsLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 370.0, 150.0, 30.0)];
	participantsLabel.backgroundColor = [UIColor clearColor];
	participantsLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:18];
	participantsLabel.textColor = [[HONColorAuthority sharedInstance] honLightGreyTextColor];
	participantsLabel.text = [NSString stringWithFormat:@"Seen: 1/%d", _clubVO.totalMembers];//[NSString stringWithFormat:@"1/%d", _clubVO.totalMembers];
	[self.contentView addSubview:participantsLabel];
	
	UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(160.0, 370.0, 150.0, 30.0)];
	timeLabel.backgroundColor = [UIColor clearColor];
	timeLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:18];
	timeLabel.textColor = [[HONColorAuthority sharedInstance] honLightGreyTextColor];
	timeLabel.textAlignment = NSTextAlignmentRight;
	timeLabel.text = [[[HONDateTimeAlloter sharedInstance] intervalSinceDate:_clubPhotoVO.addedDate] stringByAppendingString:@""];
	[self.contentView addSubview:timeLabel];


	[[HONAPICaller sharedInstance] retrieveSeenTotalForChallengeWithChallengeID:_clubPhotoVO.challengeID completion:^(NSDictionary *result) {
		if ([[result objectForKey:@"results"] count] > 0)
			participantsLabel.text = [NSString stringWithFormat:@"Seen: %d/%d", [[result objectForKey:@"results"] count], _clubVO.totalMembers];
	}];
	
	
	_scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(135.0, [UIScreen mainScreen].bounds.size.height - 50.0, 50.0, 16.0)];
	_scoreLabel.backgroundColor = [UIColor clearColor];
	_scoreLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontBold] fontWithSize:14];
	_scoreLabel.textColor = [UIColor blackColor];
	_scoreLabel.textAlignment = NSTextAlignmentCenter;
	_scoreLabel.text = @"0";
//	[self.contentView addSubview:_scoreLabel];
}


#pragma mark - Navigation
- (void)_goUserProfile {
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:showUserProfileForClubPhoto:)])
		[self.delegate clubPhotoViewCell:self showUserProfileForClubPhoto:_clubPhotoVO];
}

- (void)_goLike {
	_scoreLabel.text = [@"" stringFromInt:++_clubPhotoVO.score];
	
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:upvotePhoto:)])
		[self.delegate clubPhotoViewCell:self upvotePhoto:_clubPhotoVO];
}

- (void)_goReply {
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:replyToPhoto:)])
		[self.delegate clubPhotoViewCell:self replyToPhoto:_clubPhotoVO];
}

- (void)_goNextPhoto {
	if ([self.delegate respondsToSelector:@selector(clubPhotoViewCell:advancePhoto:)])
		[self.delegate clubPhotoViewCell:self advancePhoto:_clubPhotoVO];
}

- (void)_goNextSticker {
	int offset = (_scrollView.contentOffset.x + self.frame.size.width == _scrollView.contentSize.width) ? 0 : _scrollView.contentOffset.x + self.frame.size.width;
	
	[UIView animateWithDuration:0.000250 delay:0.000
		 usingSpringWithDamping:0.875 initialSpringVelocity:0.125
						options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent)
	 
					 animations:^(void) {
						 [_scrollView setContentOffset:CGPointMake(offset, 0.0) animated:NO];
						 
					 } completion:^(BOOL finished) {
					 }];
}


#pragma mark - UI Presentation
- (void)_loadEmotions {
	int cnt = 0;
	for (HONEmotionVO *emotionVO in [[HONClubAssistant sharedInstance] emotionsForClubPhoto:_clubPhotoVO]) {
		UIView *emotionView = [self _viewForEmotion:emotionVO atIndex:cnt];
		emotionView.frame = CGRectOffset(emotionView.frame, _emotionInsetAmt + (cnt * (kEmotionLoadedFrame.size.width + kStickerPaddingSize.width)), 0.0);
		[_scrollView addSubview:emotionView];
		[_emotionViews addObject:emotionView];
		[_emotions addObject:emotionVO];
		
		UIButton *nextPageButton = [UIButton buttonWithType:UIButtonTypeCustom];
		nextPageButton.frame = emotionView.frame;
		[nextPageButton addTarget:self action:@selector(_goNextPhoto) forControlEvents:UIControlEventTouchUpInside];
		[_scrollView addSubview:nextPageButton];
		
		cnt++;
	}
	
	_scrollView.contentSize = CGSizeMake(_scrollView.frame.size.width * [_emotions count], _scrollView.frame.size.height);
}

- (void)_changeTint {
	CGFloat hue = (arc4random() % 256 / 256.0);
	CGFloat saturation = (arc4random() % 128 / 256.0) + 0.5;
	CGFloat brightness = (arc4random() % 128 / 256.0) + 0.5;
	UIColor *color = [UIColor colorWithHue:hue saturation:saturation brightness:brightness alpha:1];
	
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
	
	CGSize scaleSize = CGSizeMake(kEmotionInitFrame.size.width / kEmotionLoadedFrame.size.width, kEmotionInitFrame.size.height / kEmotionLoadedFrame.size.height);
	CGPoint offsetPt = CGPointMake(CGRectGetMidX(kEmotionInitFrame) - CGRectGetMidX(kEmotionLoadedFrame), CGRectGetMidY(kEmotionInitFrame) - CGRectGetMidY(kEmotionLoadedFrame));
	CGAffineTransform transform = CGAffineTransformMake(scaleSize.width, 0.0, 0.0, scaleSize.height, offsetPt.x, offsetPt.y);
	
	if (emotionVO.imageType == HONEmotionImageTypePNG) {
		UIImageView *imageView = [[UIImageView alloc] initWithFrame:kEmotionLoadedFrame];
		[imageView setTintColor:[UIColor whiteColor]];
		[imageView setTag:[emotionVO.emotionID intValue]];
		imageView.alpha = 0.0;
		imageView.transform = transform;
		[holderView addSubview:imageView];
	
		void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
			imageView.image = image;
			
			[imageLoadingView stopAnimating];
			imageLoadingView.hidden = YES;
			[imageLoadingView removeFromSuperview];
			
			UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(index * 50.0, 0.0, 50.0, 50.0)];
			thumbImageView.image = image;
			[_emotionThumbsHolderView addSubview:thumbImageView];
			
			[UIView beginAnimations:@"fade" context:nil];
			[UIView setAnimationDuration:0.250];
			[UIView setAnimationDelay:0.125];
			[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
			[imageView setTintColor:[UIColor clearColor]];
			[UIView commitAnimations];
			
			[UIView animateWithDuration:0.250 delay:0.500 + (0.125 * index)
				 usingSpringWithDamping:0.750 initialSpringVelocity:0.125
								options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationCurveEaseInOut)
			 
							 animations:^(void) {
								 imageView.alpha = 1.0;
								 imageView.transform = CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
							 } completion:^(BOOL finished) {
								 if (index == 0) {
									 _stickerTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_goNextSticker) userInfo:nil repeats:YES];
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
		
	} else {
		FLAnimatedImageView *animatedImageView = [[FLAnimatedImageView alloc] init];
		animatedImageView.contentMode = UIViewContentModeScaleToFill;//UIViewContentModeScaleAspectFit; // centers in frame
		animatedImageView.clipsToBounds = YES;
		animatedImageView.frame = kEmotionLoadedFrame;
		animatedImageView.alpha = 0.0;
		animatedImageView.transform = transform;
		[holderView addSubview:animatedImageView];
		
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			NSURL *url = [NSURL URLWithString:emotionVO.smallImageURL];
			FLAnimatedImage *animatedImage1 = [[FLAnimatedImage alloc] initWithAnimatedGIFData:[NSData dataWithContentsOfURL:url]];
			
			dispatch_async(dispatch_get_main_queue(), ^{
				animatedImageView.animatedImage = animatedImage1;
				
				FLAnimatedImageView *animatedThumbImageView = [[FLAnimatedImageView alloc] init];
				animatedThumbImageView.frame = CGRectMake(index * 50.0, 0.0, 50.0, 50.0);
				animatedThumbImageView.contentMode = UIViewContentModeScaleAspectFit;
				animatedThumbImageView.clipsToBounds = YES;
				animatedThumbImageView.animatedImage = animatedImage1;
				[_emotionThumbsHolderView addSubview:animatedThumbImageView];
				
				[UIView animateWithDuration:0.250 delay:0.500 + (0.125 * index)
					 usingSpringWithDamping:0.750 initialSpringVelocity:0.125
									options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationCurveEaseInOut)
				 
								 animations:^(void) {
									 animatedImageView.alpha = 1.0;
									 animatedImageView.transform = CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
								 } completion:^(BOOL finished) {
									 _stickerTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(_goNextSticker) userInfo:nil repeats:YES];
								 }];
			});
		});
	}
	
	return (holderView);
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
