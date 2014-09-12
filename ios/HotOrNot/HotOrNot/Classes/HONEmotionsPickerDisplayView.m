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
const CGSize kImageSize = {128.0f, 128.0f};
const CGSize kImagePaddingSize = {0.0f, 0.0f};

const CGRect kEmotionIntroFrame = {50.0f, 50.0f, 24.0f, 24.0f};
const CGRect kEmotionNormalFrame = {0.0f, 0.0f, 128.0f, 128.0f};

@interface HONEmotionsPickerDisplayView () <PicoStickerDelegate>
@property (nonatomic, strong) NSMutableArray *emotions;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIButton *cameraThumbButton;
@property (nonatomic, strong) UIView *loaderHolderView;
@property (nonatomic, strong) UIView *emotionHolderView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIImageView *cursorImageView;
@property (nonatomic) CGPoint prevPt;
@property (nonatomic) BOOL isDragging;
@end

@implementation HONEmotionsPickerDisplayView
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame withPreviewImage:(UIImage *)image {
	if ((self = [super initWithFrame:frame])) {
		self.backgroundColor = [UIColor whiteColor];
		
		_isDragging = NO;
		_previewImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10.0, 49.0, 88.0, 88.0)];
		_previewImageView.userInteractionEnabled = YES;
		_previewImageView.image = image;
		[self addSubview:_previewImageView];
		
		UIButton *cameraButton = [UIButton buttonWithType:UIButtonTypeCustom];
		cameraButton.frame = CGRectMake(0.0, 0.0, 134.0, 134.0);
		[cameraButton setBackgroundImage:[UIImage imageNamed:@"addSelfieButton_nonActive"] forState:UIControlStateNormal];
		[cameraButton setBackgroundImage:[UIImage imageNamed:@"addSelfieButton_Active"] forState:UIControlStateHighlighted];
		[cameraButton addTarget:self action:@selector(_goCamera) forControlEvents:UIControlEventTouchDown];
		[_previewImageView addSubview:cameraButton];
		
		[[HONImageBroker sharedInstance] maskView:_previewImageView withMask:[UIImage imageNamed:@"selfiePreviewMask"]];
		
		_emotions = [NSMutableArray array];
		
		_label = [[UILabel alloc] initWithFrame:CGRectMake(_previewImageView.frame.origin.x + _previewImageView.frame.size.width + 10.0, 82.0, 101.0, 22.0)];
		_label.backgroundColor = [UIColor whiteColor];
		_label.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:18];
		_label.textColor = [UIColor blackColor];
		_label.text = NSLocalizedString(@"is_feeling", nil);
		[self addSubview:_label];
		
		_cursorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(_label.frame.origin.x + _label.frame.size.width + 3.0, 22.0, 3.0, 144.0)];
		_cursorImageView.animationImages = @[[UIImage imageNamed:@"emojiCursor_off"], [UIImage imageNamed:@"emojiCursor_on"]];
		_cursorImageView.animationDuration = 0.875;
		_cursorImageView.animationRepeatCount = 0;
		[self addSubview:_cursorImageView];
		[_cursorImageView startAnimating];
		
		_loaderHolderView = [[UIView alloc] initWithFrame:CGRectMake(_label.frame.origin.x + _label.frame.size.width + 5.0, 25.0, 0.0, 0.0)];
		[self addSubview:_loaderHolderView];
		
		_emotionHolderView = [[UIView alloc] initWithFrame:CGRectMake(_label.frame.origin.x + _label.frame.size.width + 5.0, 25.0, 0.0, 0.0)];
		[self addSubview:_emotionHolderView];
		
		
		_cameraThumbButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_cameraThumbButton.frame = CGRectMake(250.0, 200.0, 44.0, 64.0);
		[_cameraThumbButton setBackgroundImage:[UIImage imageNamed:@"addSelfieButtonB_nonActive"] forState:UIControlStateNormal];
		[_cameraThumbButton setBackgroundImage:[UIImage imageNamed:@"addSelfieButtonB_Active"] forState:UIControlStateHighlighted];
		[_cameraThumbButton addTarget:self action:@selector(_goCamera) forControlEvents:UIControlEventTouchDown];
		_cameraThumbButton.hidden = YES;
		[self addSubview:_cameraThumbButton];
		
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


#pragma mark - Navigation
- (void)_goCamera {
	if ([self.delegate respondsToSelector:@selector(emotionsPickerDisplayViewShowCamera:)])
		[self.delegate emotionsPickerDisplayViewShowCamera:self];
}


#pragma mark - UI Presentation
- (void)_addImageEmotion:(HONEmotionVO *)emotionVO {
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
		imageLoadingView.frame = CGRectMake(imageView.frame.origin.x - 11.0, 55.0, imageLoadingView.frame.size.width, imageLoadingView.frame.size.height);
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
	int offset = 215.0 - (([_emotions count] >= 1) ? (kImageSize.width + kImagePaddingSize.width) : 0);
	int orgX = ((320.0 - offset) * 0.5) - (_emotionHolderView.frame.size.width + (([_emotions count] > 0) ? 3.0 : 0.0));
	
	[UIView animateWithDuration:0.333 delay:0.000
		 usingSpringWithDamping:0.875 initialSpringVelocity:0.125
						options:UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionAllowAnimatedContent
	 
					 animations:^(void) {
						 _previewImageView.frame = CGRectMake(orgX, _previewImageView.frame.origin.y, _previewImageView.frame.size.width, _previewImageView.frame.size.height);
						 _label.frame = CGRectMake(_previewImageView.frame.origin.x + _previewImageView.frame.size.width + 10.0, _label.frame.origin.y, _label.frame.size.width, _label.frame.size.height);
						 _emotionHolderView.frame = CGRectMake(_label.frame.origin.x + _label.frame.size.width + 3.0, _emotionHolderView.frame.origin.y, [_emotions count] * (kImageSize.width + kImagePaddingSize.width), (kImageSize.height + kImagePaddingSize.height));
						 _loaderHolderView.frame = _emotionHolderView.frame;
						 _cursorImageView.frame = CGRectMake(_emotionHolderView.frame.origin.x + _emotionHolderView.frame.size.width + 3.0, _cursorImageView.frame.origin.y, _cursorImageView.frame.size.width, _cursorImageView.frame.size.height);
						 
					 } completion:^(BOOL finished) {
						 _cameraThumbButton.hidden = ([_emotions count] == 0);
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
