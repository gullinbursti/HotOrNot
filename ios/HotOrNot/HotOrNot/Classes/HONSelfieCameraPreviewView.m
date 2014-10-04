//
//  HONCreateChallengePreviewView.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 06.15.13 @ 17:17 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "NSString+DataTypes.h"
#import "UIImage+ImageEffects.h"
#import "UIImageView+AFNetworking.h"

#import "PCCandyStorePurchaseController.h"

#import "HONSelfieCameraPreviewView.h"
#import "HONInsetOverlayView.h"
#import "HONHeaderView.h"
#import "HONUserVO.h"
#import "HONTrivialUserVO.h"
#import "HONEmotionsPickerDisplayView.h"
#import "HONEmotionsPickerView.h"

#define PREVIEW_SIZE 176.0f

@interface HONSelfieCameraPreviewView () <HONEmotionsPickerDisplayViewDelegate, HONEmotionsPickerViewDelegate, HONInsetOverlayViewDelegate, PCCandyStorePurchaseControllerDelegate>
@property (nonatomic, strong) UIImage *previewImage;
@property (nonatomic, strong) NSMutableArray *subjectNames;
@property (nonatomic, strong) NSMutableArray *emotionsPickerViews;

@property (nonatomic, strong) HONHeaderView *headerView;
@property (nonatomic, strong) HONInsetOverlayView *insetOverlayView;
//@property (nonatomic, strong) HONEmotionsPickerView *emotionsPickerView;

@property (nonatomic, strong) HONEmotionsPickerDisplayView *emotionsDisplayView;

@property (nonatomic, strong) dispatch_queue_t purchase_content_request_queue;
@end

@implementation HONSelfieCameraPreviewView
@synthesize delegate = _delegate;


- (id)initWithFrame:(CGRect)frame withPreviewImage:(UIImage *)image {
	if ((self = [super initWithFrame:frame])) {
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_reloadEmotionPicker:)
													 name:@"RELOAD_EMOTION_PICKER" object:nil];
		
		_subjectNames = [NSMutableArray array];
		_emotionsPickerViews = [NSMutableArray array];
		_previewImage = [[HONImageBroker sharedInstance] cropImage:[[HONImageBroker sharedInstance] scaleImage:image toSize:CGSizeMake(176.0, 224.0)] toRect:CGRectMake(0.0, 24.0, 176.0, 176.0)];
		
		NSLog(@"PREVIEW -- SRC IMAGE:[%@]\nZOOMED IMAGE:[%@]", NSStringFromCGSize(image.size), NSStringFromCGSize(_previewImage.size));
		
		_purchase_content_request_queue = dispatch_queue_create("com.builtinmenlo.selfieclub.content-request", 0);
		
		[self _adoptUI];
	}
	
	return (self);
}


#pragma mark - Puplic APIs
- (NSArray *)getSubjectNames {
	return (_subjectNames);
}

- (void)updateProcessedImage:(UIImage *)image {
	[_emotionsDisplayView updatePreview:[[HONImageBroker sharedInstance] cropImage:[[HONImageBroker sharedInstance] scaleImage:image toSize:CGSizeMake(852.0, kSnapLargeSize.height * 2.0)] toRect:CGRectMake(106.0, 0.0, kSnapLargeSize.width * 2.0, kSnapLargeSize.height * 2.0)]];
}

#pragma mark - UI Presentation
- (void)_adoptUI {
	
	//]~=~=~=~=~=~=~=~=~=~=~=~=~=~[]~=~=~=~=~=~=~=~=~=~=~=~=~=~[
	
	_emotionsDisplayView = [[HONEmotionsPickerDisplayView alloc] initWithFrame:self.frame withPreviewImage:_previewImage];
	_emotionsDisplayView.delegate = self;
	[self addSubview:_emotionsDisplayView];
	
	for (HONStickerGroupType i=HONStickerGroupTypeStickers; i<=HONStickerGroupTypeObjects; i++) {
		HONEmotionsPickerView *pickerView = [[HONEmotionsPickerView alloc] initWithFrame:CGRectMake(0.0, self.frame.size.height - 280.0, 320.0, 280.0) asEmotionGroupType:i];
		[pickerView setTag:(69 + i)];
		[_emotionsPickerViews addObject:pickerView];
	}
	
	HONEmotionsPickerView *pickerView = (HONEmotionsPickerView *)[_emotionsPickerViews firstObject];
	pickerView.delegate = self;
	[self addSubview:pickerView];
	
	//]~=~=~=~=~=~=~=~=~=~=~=~=~=~[]~=~=~=~=~=~=~=~=~=~=~=~=~=~[
	
	_headerView = [[HONHeaderView alloc] initWithTitleUsingCartoGothic:@""];
	_headerView.frame = CGRectOffset(_headerView.frame, 0.0, -10.0);
	[_headerView removeBackground];
	[self addSubview:_headerView];
	
	UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	closeButton.frame = CGRectMake(6.0, 2.0, 44.0, 44.0);
	[closeButton setBackgroundImage:[UIImage imageNamed:@"closeButton_nonActive"] forState:UIControlStateNormal];
	[closeButton setBackgroundImage:[UIImage imageNamed:@"closeButtonActive"] forState:UIControlStateHighlighted];
	[closeButton addTarget:self action:@selector(_goClose) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addButton:closeButton];
	
	UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
	nextButton.frame = CGRectMake(276.0, 2.0, 44.0, 44.0);
	[nextButton setBackgroundImage:[UIImage imageNamed:@"chevronNextButton_nonActive"] forState:UIControlStateNormal];
	[nextButton setBackgroundImage:[UIImage imageNamed:@"chevronNextButton_Active"] forState:UIControlStateHighlighted];
	[nextButton addTarget:self action:@selector(_goSubmit) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addButton:nextButton];
}


#pragma mark - Navigation
- (void)_goClose {
	[self _removeOverlayAndRemove:YES];
}

- (void)_goSubmit {
	if ([_subjectNames count] > 0) {
		if ([self.delegate respondsToSelector:@selector(cameraPreviewViewSubmit:withSubjects:)])
			[self.delegate cameraPreviewViewSubmit:self withSubjects:_subjectNames];
	
	} else {
		[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"alert_noemotions_title", @"No Emotions Selected!")
									message:NSLocalizedString(@"alert_noemotions_msg", @"You need to choose some emotions to make a status update.")
								   delegate:nil
						  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
						  otherButtonTitles:nil] show];
	}
}


#pragma mark - Notifications
- (void)_reloadEmotionPicker:(NSNotification *)notification {
//	HONEmotionsPickerView *pickerView = (HONEmotionsPickerView *)[_emotionsPickerViews firstObject];
//	[pickerView reload];
}


#pragma mark - UI Presentation
- (void)_removeOverlayAndRemove:(BOOL)isRemoved {
	if (isRemoved) {
		if ([self.delegate respondsToSelector:@selector(cameraPreviewViewCancel:)])
			[self.delegate cameraPreviewViewCancel:self];
	}
}


#pragma mark - CandyStorePurchaseController
- (void)purchaseController:(id)controller downloadedStickerWithId:(NSString *)contentId {
	NSLog(@"[*:*] purchaseController:downloadedStickerWithId:[%@]", contentId);
}

-(void)purchaseController:(id)controller downloadStickerWithIdFailed:(NSString *)contentId {
	NSLog(@"[*:*] purchaseController:downloadedStickerWithIdFailed:[%@]", contentId);
}

- (void)purchaseController:(id)controller purchasedStickerWithId:(NSString *)contentId userInfo:(NSDictionary *)userInfo {
	NSLog(@"[*:*] purchaseController:purchasedStickerWithId:[%@] userInfo:[%@]", contentId, userInfo);
}

- (void)purchaseController:(id)controller purchaseStickerWithIdFailed:(NSString *)contentId userInfo:(NSDictionary *)userInfo {
	NSLog(@"[*:*] purchaseController:purchaseStickerWithIdFailed:[%@] userInfo:[%@]", contentId, userInfo);
}

- (void)purchaseController:(id)controller downloadedStickerPackWithId:(NSString *)contentGroupId {
	NSLog(@"[*:*] purchaseController:downloadedStickerPackWithId:[%@]", contentGroupId);
}

- (void)purchaseController:(id)controller downloadStickerPackWithIdFailed:(NSString *)contentGroupId {
	NSLog(@"[*:*] purchaseController:downloadStickerPackWithIdFailed:[%@]", contentGroupId);
}

- (void)purchaseController:(id)controller purchasedStickerPackWithId:(NSString *)contentGroupId userInfo:(NSDictionary *)userInfo {
	NSLog(@"[*:*] purchaseController:downloadStickerPackWithIdFailed:[%@] userInfo:[%@]", contentGroupId, userInfo);
}

- (void)purchaseController:(id)controller purchaseStickerPackWithContentGroupFailed:(PCContentGroup *)contentGroup userInfo:(NSDictionary *)userInfo {
	NSLog(@"[*:*] purchaseController:purchaseStickerPackWithContentGroupFailed:[%@] userInfo:[%@]", contentGroup, userInfo);
}


#pragma mark - EmotionsPickerView Delegates
- (void)emotionsPickerView:(HONEmotionsPickerView *)emotionsPickerView selectedEmotion:(HONEmotionVO *)emotionVO {
	NSLog(@"[*:*] emotionItemView:(%@) selectedEmotion:(%@) [*:*]", self.class, emotionVO.emotionName);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Camera Step - Sticker Selected"
										withEmotion:emotionVO];
	
//	dispatch_async(dispatch_get_main_queue(), ^{
//		if ([[HONStickerAssistant sharedInstance] candyBoxContainsContentGroupForContentGroupID:emotionVO.contentGroupID]) {
//			NSLog(@"Content in CandyBox --(%@)", emotionVO.contentGroupID);
//			
////			PicoSticker *sticker = [[HONStickerAssistant sharedInstance] stickerFromCandyBoxWithContentID:emotionVO.emotionID];
////			[sticker use];
////			emotionVO.picoSticker = [[HONStickerAssistant sharedInstance] stickerFromCandyBoxWithContentID:emotionVO.emotionID];
////			[emotionVO.picoSticker use];
//	
//		} else {
////			NSLog(@"Purchasing ContentGroup --(%@)", emotionVO.contentGroupID);
////			[[HONStickerAssistant sharedInstance] purchaseStickerPakWithContentGroupID:emotionVO.contentGroupID usingDelegate:self];
//		}
//	});
	
	[_headerView transitionTitle:emotionVO.emotionName];
	[_subjectNames addObject:[emotionVO.emotionName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
	[_emotionsDisplayView addEmotion:emotionVO];
}

- (void)emotionsPickerView:(HONEmotionsPickerView *)emotionsPickerView deselectedEmotion:(HONEmotionVO *)emotionVO {
//	NSLog(@"[*:*] emotionItemView:(%@) deselectedEmotion:(%@) [*:*]", self.class, emotionVO.emotionName);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Camera Step - Sticker Deleted"
										withEmotion:emotionVO];
	
	[_subjectNames removeObject:emotionVO.emotionName inRange:NSMakeRange([_subjectNames count] - 1, 1)];
	[_emotionsDisplayView removeEmotion:emotionVO];
	
	[_headerView transitionTitle:([_subjectNames count] > 0) ? [_subjectNames lastObject] : @""];
}

- (void)emotionsPickerView:(HONEmotionsPickerView *)emotionsPickerView changeGroup:(HONStickerGroupType)groupType {
	NSLog(@"[*:*] emotionItemView:(%@) changeGroup:(%@) [*:*]", self.class, (groupType == HONStickerGroupTypeStickers) ? @"STICKERS" : (groupType == HONStickerGroupTypeFaces) ? @"FACES" : (groupType == HONStickerGroupTypeAnimals) ? @"ANIMALS" : (groupType == HONStickerGroupTypeObjects) ? @"OBJECTS" : @"OTHER");
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Camera Step - Change Emotion Group"
									 withProperties:@{@"type"	: (groupType == HONStickerGroupTypeStickers) ? @"stickers" : (groupType == HONStickerGroupTypeFaces) ? @"faces" : (groupType == HONStickerGroupTypeAnimals) ? @"animals" : (groupType == HONStickerGroupTypeObjects) ? @"objects" : @"other"}];
	
	for (UIView *view in self.subviews) {
		if (view.tag >= 69) {
			((HONEmotionsPickerView *)view).delegate = nil;
			[view removeFromSuperview];
		}
	}
	
	[_emotionsPickerViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		HONEmotionsPickerView *pickerView = (HONEmotionsPickerView *)obj;
		
		if (pickerView.stickerGroupType == groupType) {
			pickerView.delegate = self;
			[self addSubview:pickerView];
		}
		
//		pickerView.hidden = (pickerView.stickerGroupType != groupType);
//		[UIView animateWithDuration:0.25 animations:^(void) {
//			pickerView.alpha = (int)(pickerView.stickerGroupType == groupType);
//		} completion:^(BOOL finished) {
//		}];
	}];
}

- (void)emotionsPickerView:(HONEmotionsPickerView *)emotionsPickerView didChangeToPage:(int)page withDirection:(int)direction {
	NSLog(@"[*:*] emotionItemView:(%@) didChangeToPage:(%d) withDirection:(%d) [*:*]", self.class, page, direction);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:[@"Camera Step - Stickerboard Swipe " stringByAppendingString:(direction == 1) ? @"Right" : @"Left"]];
//	if ([[HONContactsAssistant sharedInstance] totalInvitedContacts] < [HONAppDelegate clubInvitesThreshold] && page == 2 && direction == 1) {
//		if (!_emotionsPickerView.hidden) {
//			[_emotionsPickerView disablePagesStartingAt:2];
//			[_emotionsPickerView scrollToPage:1];
//			
//			if (_insetOverlayView == nil)
//				_insetOverlayView = [[HONInsetOverlayView alloc] initAsType:HONInsetOverlayViewTypeUnlock];
//			_insetOverlayView.delegate = self;
//			
//			[[HONScreenManager sharedInstance] appWindowAdoptsView:_insetOverlayView];
//			[_insetOverlayView introWithCompletion:nil];
//		}
//	}
}


#pragma mark - EmotionsPickerDisplayView Delegates
- (void)emotionsPickerDisplayViewShowCamera:(HONEmotionsPickerDisplayView *)pickerDisplayView {
	if ([self.delegate respondsToSelector:@selector(cameraPreviewViewShowCamera:)])
		[self.delegate cameraPreviewViewShowCamera:self];
}

- (void)emotionsPickerDisplayView:(HONEmotionsPickerDisplayView *)pickerDisplayView scrolledEmotionsToIndex:(int)index fromDirection:(int)dir {
	NSLog(@"[*:*] emotionsPickerDisplayView:(%@) scrolledEmotionsToIndex:(%d) fromDirection:(%d) [*:*]", self.class, index, dir);
	
	int ind = MIN(MAX(0, index), [_subjectNames count] - 1);
	[_headerView transitionTitle:[_subjectNames objectAtIndex:ind]];
}


#pragma mark - InsetOverlay Delegates
- (void)insetOverlayViewDidClose:(HONInsetOverlayView *)view {
	[_insetOverlayView outroWithCompletion:^(BOOL finished) {
		[_insetOverlayView removeFromSuperview];
		_insetOverlayView = nil;
	}];
}

- (void)insetOverlayViewDidUnlock:(HONInsetOverlayView *)view {
	[_insetOverlayView outroWithCompletion:^(BOOL finished) {
		[_insetOverlayView removeFromSuperview];
		_insetOverlayView = nil;
		
		if ([self.delegate respondsToSelector:@selector(cameraPreviewViewShowInviteContacts:)])
			[self.delegate cameraPreviewViewShowInviteContacts:self];
	}];
}


@end
