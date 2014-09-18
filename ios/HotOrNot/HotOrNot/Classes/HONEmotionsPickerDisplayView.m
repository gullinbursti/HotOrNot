//
//  HONEmotionsPickerDisplayView.m
//  HotOrNot
//
//  Created by Matt Holcombe on 04/23/2014 @ 00:03 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "UIImageView+AFNetworking.h"
#import "UILabel+BoundingRect.h"
#import "UILabel+FormattedText.h"

#import "PicoSticker.h"

#import "HONEmotionsPickerDisplayView.h"
#import "HONImageLoadingView.h"

#define COLS_PER_ROW 6
#define SPACING

//NSString * const kBaseCaption = @"- is feeling…";
const CGSize kImageSize = {188.0f, 188.0f};
const CGSize kImagePaddingSize = {0.0f, 0.0f};

const CGRect kEmotionIntroFrame = {88.0f, 88.0f, 12.0f, 12.0f};
const CGRect kEmotionNormalFrame = {0.0f, 0.0f, 188.0f, 188.0f};

@interface HONEmotionsPickerDisplayView () <PicoStickerDelegate>
@property (nonatomic, strong) NSMutableArray *emotions;
@property (nonatomic, strong) UIView *loaderHolderView;
@property (nonatomic, strong) UIView *emotionHolderView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIImageView *previewThumbImageView;
@property (nonatomic, strong) UIImageView *emptyImageView;
@property (nonatomic) CGPoint prevPt;
@property (nonatomic) BOOL isDragging;
@end

@implementation HONEmotionsPickerDisplayView
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame withPreviewImage:(UIImage *)image {
	if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor whiteColor];
		
		_emotions = [NSMutableArray array];
		_isDragging = NO;
		
		[self addSubview:[[UIImageView alloc] initWithImage:image]];
		
		_previewImageView = [[UIImageView alloc] initWithFrame:frame];
		_previewImageView.userInteractionEnabled = YES;
		[self addSubview:_previewImageView];
		
		UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
		cameraButton.frame = self.frame;
		[cameraButton setTag:0];
		[cameraButton addTarget:self action:@selector(_goCamera:) forControlEvents:UIControlEventTouchDown];
		[_previewImageView addSubview:cameraButton];
		
		_emptyImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dottedBackground"]];
		_emptyImageView.frame = CGRectOffset(_emptyImageView.frame, 63.0, 63.0);
		[self addSubview:_emptyImageView];
		
		UILabel *emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0, 67.0, 194.0, 46.0)];
		emptyLabel.backgroundColor = [UIColor clearColor];
		emptyLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:18];
		emptyLabel.textColor = [UIColor lightGrayColor];
		emptyLabel.textAlignment = NSTextAlignmentCenter;
		emptyLabel.numberOfLines = 2;
		emptyLabel.text = @"select a sticker\nor take selfie";
		[_emptyImageView addSubview:emptyLabel];
		
		
		_loaderHolderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 69.0, 0.0, 0.0)];
		[self addSubview:_loaderHolderView];
		
		_emotionHolderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 69.0, 0.0, 0.0)];
		[self addSubview:_emotionHolderView];
		
		
		_previewThumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(271.0, 239.0, 39.0, 39.0)];
		_previewThumbImageView.image = [UIImage imageNamed:@"addSelfieButtonB_nonActive"];
//		_previewThumbImageView.backgroundColor = [[HONColorAuthority sharedInstance] honDebugDefaultColor];
		_previewThumbImageView.userInteractionEnabled = YES;
//		_previewThumbImageView.alpha = 0.0;
//		_previewThumbImageView.hidden = YES;
		[self addSubview:_previewThumbImageView];
		
		[[HONImageBroker sharedInstance] maskView:_previewThumbImageView withMask:[UIImage imageNamed:@"selfiePreviewMask"]];
		
		UIButton *previewThumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
		previewThumbButton.frame = CGRectMake(0.0, 0.0, 44.0, 44.0);
		[previewThumbButton setTag:1];
		[previewThumbButton addTarget:self action:@selector(_goCamera:) forControlEvents:UIControlEventTouchDown];
		 [_previewThumbImageView addSubview:previewThumbButton];
		
		[self _updateDisplay];
	}
	
	return (self);
}


#pragma mark - Public APIs
- (void)addEmotion:(HONEmotionVO *)emotionVO {
//	NSLog(@"STICKER:[%@]", emotionVO.pcContent);
	
	[_emotions addObject:emotionVO];
	[self _addImageEmotion:emotionVO];
	
	[HONAppDelegate cafPlaybackWithFilename:@"badminton_racket_fast_movement_swoosh_002"];
}

- (void)removeEmotion:(HONEmotionVO *)emotionVO {
	[_emotions removeLastObject];
	[self _removeImageEmotion];
}

- (void)updatePreview:(UIImage *)previewImage {
//	_previewImageView.image = previewImage;
	
//	UIImageView *holderImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, -25.0, 150.0, 200.0)];
//	holderImageView.image = previewImage;
//	[_previewImageView addSubview:holderImageView];
	
	for (UIView *view in _previewThumbImageView.subviews) {
		if (view.tag != 1)
			[view removeFromSuperview];
	}
	
	UIImageView *thumbImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, -15.0, 39.0, 69.0)];
	thumbImageView.image = previewImage;
	[_previewThumbImageView addSubview:thumbImageView];
}


#pragma mark - Navigation
- (void)_goCamera:(id)sender {
	UIButton *button = (UIButton *)sender;
	if ([self.delegate respondsToSelector:@selector(emotionsPickerDisplayView:showCameraFromLargeButton:)])
		[self.delegate emotionsPickerDisplayView:self showCameraFromLargeButton:(button.tag == 0)];
}


#pragma mark - UI Presentation
- (void)_addImageEmotion:(HONEmotionVO *)emotionVO {
	if ([_emotions count] == 1) {
		[UIView animateWithDuration:0.125 animations:^(void) {
			_emptyImageView.alpha = 0.0;
		}];
	}
	
	_emotionHolderView.frame = CGRectMake(_emotionHolderView.frame.origin.x, _emotionHolderView.frame.origin.y, [_emotions count] * (kImageSize.width + kImagePaddingSize.width), (kImageSize.height + kImagePaddingSize.height));
	_loaderHolderView.frame = _emotionHolderView.frame;
	
	CGSize scaleSize = CGSizeMake(kEmotionIntroFrame.size.width / kEmotionNormalFrame.size.width, kEmotionIntroFrame.size.height / kEmotionNormalFrame.size.height);
	CGPoint offsetPt = CGPointMake(CGRectGetMidX(kEmotionIntroFrame) - CGRectGetMidX(kEmotionNormalFrame), CGRectGetMidY(kEmotionIntroFrame) - CGRectGetMidY(kEmotionNormalFrame));
	CGAffineTransform transform = CGAffineTransformMake(scaleSize.width, 0.0, 0.0, scaleSize.height, offsetPt.x, offsetPt.y);
	
	UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(([_emotions count] - 1) * (kImageSize.width + kImagePaddingSize.width), 0.0, (kImageSize.width + kImagePaddingSize.width), (kImageSize.height + kImagePaddingSize.height))];
	imageView.alpha = 0.0;
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.transform = transform;
	[_emotionHolderView addSubview:imageView];
	
		
//	if (emotionVO.picoSticker == nil) {
		HONImageLoadingView *imageLoadingView = [[HONImageLoadingView alloc] initInViewCenter:imageView asLargeLoader:NO];
		imageLoadingView.frame = CGRectOffset(imageLoadingView.frame, (kImageSize.width - imageLoadingView.frame.size.width) * 0.5, (kImageSize.height - imageLoadingView.frame.size.height) * 0.5);
		imageLoadingView.alpha = 0.667;
		[imageLoadingView startAnimating];
		[_loaderHolderView addSubview:imageLoadingView];
		
		void (^imageSuccessBlock)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) = ^void(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
			imageView.image = image;
			
			[UIView animateWithDuration:0.200 delay:0.125
				 usingSpringWithDamping:0.750 initialSpringVelocity:0.000
								options:(UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent)
			 
							 animations:^(void) {
								 imageView.alpha = 1.0;
								 imageView.transform = CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
							 } completion:^(BOOL finished) {
								 HONImageLoadingView *loadingView = [[_loaderHolderView subviews] lastObject];
								 [loadingView stopAnimating];
								 [loadingView removeFromSuperview];
							 }];
		};
		
		[imageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:emotionVO.largeImageURL]
														   cachePolicy:NSURLRequestReturnCacheDataElseLoad
													   timeoutInterval:[HONAppDelegate timeoutInterval]]
						 placeholderImage:nil
								  success:imageSuccessBlock
								  failure:nil];
//
//	} else {
//	UIView *holderView = [[UIView alloc] initWithFrame:CGRectMake(([_emotions count] - 1) * (kImageSize.width + kImagePaddingSize.width), 0.0, (kImageSize.width + kImagePaddingSize.width), (kImageSize.height + kImagePaddingSize.height))];
//	holderView.alpha = 0.0;
//	holderView.contentMode = UIViewContentModeScaleAspectFit;
//	holderView.transform = transform;
//	[_emotionHolderView addSubview:holderView];
//	PicoSticker *picoSticker = [[PicoSticker alloc] initWithPCContent:emotionVO.pcContent];
//	picoSticker.frame = CGRectMake(([_emotions count] - 1) * (kImageSize.width + kImagePaddingSize.width), 0.0, (kImageSize.width + kImagePaddingSize.width), (kImageSize.height + kImagePaddingSize.height));
//	picoSticker.alpha = 0.0;
//	picoSticker.contentMode = UIViewContentModeScaleAspectFit;
//	picoSticker.transform = transform;
//	[_emotionHolderView addSubview:picoSticker];

		
//		[UIView animateWithDuration:0.200 delay:0.125
//			 usingSpringWithDamping:0.750 initialSpringVelocity:0.000
//							options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent
//		 
//						 animations:^(void) {
//							 picoSticker.alpha = 1.0;
//							 picoSticker.transform = CGAffineTransformMake(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
//						 } completion:^(BOOL finished) {}];
//	}
	
	[self _updateDisplay];
}

- (void)_removeImageEmotion {
	UIImageView *imageView = [_emotionHolderView.subviews lastObject];
	
	if ([imageView.layer.animationKeys count] > 0) {
		[imageView.layer removeAllAnimations];
		[imageView removeFromSuperview];
		
		imageView = [_emotionHolderView.subviews lastObject];
	}
		
	
	[UIView animateWithDuration:0.125 delay:0.000
		 usingSpringWithDamping:1.000 initialSpringVelocity:0.250
						options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent
	 
					 animations:^(void) {
						 imageView.alpha = 0.0;
						 imageView.transform = CGAffineTransformMake(1.333, 0.0, 0.0, 1.333, 0.0, 0.0);
						 
					 } completion:^(BOOL finished) {
						[imageView removeFromSuperview];
											  
						 _emotionHolderView.frame = CGRectMake(_emotionHolderView.frame.origin.x, _emotionHolderView.frame.origin.y, ([_emotions count] * (kImageSize.width + kImagePaddingSize.width)), (kImageSize.height + kImagePaddingSize.height));
						 [self _updateDisplay];
					 }];
}


- (void)_updateDisplay {
	int offset = 0.0 - (([_emotions count] >= 1) ? (kImageSize.width + kImagePaddingSize.width) : 0);
	int orgX = ((320.0 - offset) * 0.5) - (_emotionHolderView.frame.size.width + (([_emotions count] > 0) ? 3.0 : 0.0));
	
	[UIView animateWithDuration:0.333 delay:0.000
		 usingSpringWithDamping:0.875 initialSpringVelocity:0.125
						options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent
	 
					 animations:^(void) {
//						 _previewImageView.frame = CGRectMake(orgX, _previewImageView.frame.origin.y, _previewImageView.frame.size.width, _previewImageView.frame.size.height);
						 _emotionHolderView.frame = CGRectMake(orgX + 3.0, _emotionHolderView.frame.origin.y, [_emotions count] * (kImageSize.width + kImagePaddingSize.width), (kImageSize.height + kImagePaddingSize.height));
						 _loaderHolderView.frame = _emotionHolderView.frame;
						 
					 } completion:^(BOOL finished) {
						 [UIView animateWithDuration:0.25 animations:^(void) {
							 _emptyImageView.alpha = ([_emotions count] == 0);
						 }];
					 }];
	
			 
//	NSLog(@"\n\t\t|--|--|--|--|--|--|:|--|--|--|--|--|--|");
//	NSLog(@"FONT ATTRIBS:[%@]", _label.font.fontDescriptor.fontAttributes);
//	NSLog(@"--// %@ @ (%d) //--", [_label.font.fontDescriptor.fontAttributes objectForKey:@"NSFontNameAttribute"], (int)_label.font.pointSize);
//	NSLog(@"DRAW SIZE:[%@] ATTR SIZE:[%@]", NSStringFromCGSize(_captionSize), NSStringFromCGSize(_label.attributedText.size));
//	NSLog(@"X-HEIGHT:[%f]", _label.font.xHeight);
//	NSLog(@"CAP:[%f]", _label.font.capHeight);
//	NSLog(@"ASCENDER:[%f] DESCENDER:[%f]", _label.font.ascender, _label.font.descender);
//	NSLog(@"LINE HEIGHT:[%f]", _label.font.lineHeight);
//	NSLog(@"[=-=-=-=-=-=-=-=-=|=-=-=-=-=-=-=-=-=|:|=-=-=-=-=-=-=-=-=|=-=-=-=-=-=-=-=-=]");
}


#pragma mark - PicoSticker Delegates
- (void)picoSticker:(id)sticker tappedWithContentId:(NSString *)contentId {
	NSLog(@"[*:*] sticker.tag:[%d] (%@)", ((PicoSticker *)sticker).tag, contentId);
}

@end
