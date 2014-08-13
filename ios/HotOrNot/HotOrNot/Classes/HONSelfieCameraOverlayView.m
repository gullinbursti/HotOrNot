//
//  HONSelfieCameraOverlayView.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.27.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <AssetsLibrary/AssetsLibrary.h>
#import <QuartzCore/QuartzCore.h>

#import "NSString+DataTypes.h"
#import "UIImageView+AFNetworking.h"

#import "HONSelfieCameraOverlayView.h"
#import "HONUserVO.h"
#import "HONContactUserVO.h"

@interface HONSelfieCameraOverlayView()
@property (nonatomic, strong) UIImageView *infoImageView;
@property (nonatomic, strong) UIView *blackMatteView;
@property (nonatomic, strong) UIView *headerBGView;
@property (nonatomic, strong) UIButton *cancelButton;
@property (nonatomic, strong) UIButton *cameraRollButton;
@property (nonatomic, strong) UIButton *flipButton;
@property (nonatomic, strong) UIButton *changeTintButton;
@property (nonatomic, strong) UIButton *takePhotoButton;
@property (nonatomic, strong) UIImageView *lastCameraRollImageView;
@end

@implementation HONSelfieCameraOverlayView
@synthesize delegate = _delegate;

- (id)initWithFrame:(CGRect)frame {
	if ((self = [super initWithFrame:frame])) {
		_blackMatteView = [[UIView alloc] initWithFrame:self.frame];
		_blackMatteView.backgroundColor = [UIColor blackColor];
		_blackMatteView.hidden = YES;
		[self addSubview:_blackMatteView];
		
//		UIImageView *gradientImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cameraGradientOverlay"]];
//		gradientImageView.frame = self.frame;
//		[self addSubview:gradientImageView];
		
		_headerBGView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, 50.0)];
		[self addSubview:_headerBGView];
		
		_flipButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_flipButton.frame = CGRectMake(275.0, 0.0, 64.0, 64.0);
		[_flipButton setBackgroundImage:[UIImage imageNamed:@"cameraFlipButton_nonActive"] forState:UIControlStateNormal];
		[_flipButton setBackgroundImage:[UIImage imageNamed:@"cameraFlipButton_Active"] forState:UIControlStateHighlighted];
		[_flipButton addTarget:self action:@selector(_goFlipCamera) forControlEvents:UIControlEventTouchUpInside];
		[_headerBGView addSubview:_flipButton];
		
		_cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
//		_cancelButton.frame = CGRectMake(0.0, 0.0, 114.0, 64.0);
//		[_cancelButton setBackgroundImage:[UIImage imageNamed:@"cameraCancelButton_nonActive"] forState:UIControlStateNormal];
//		[_cancelButton setBackgroundImage:[UIImage imageNamed:@"cameraCancelButton_Active"] forState:UIControlStateHighlighted];
		_cancelButton.frame = CGRectMake(0.0, 0.0, 93.0, 44.0);
		[_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancelbuttonwhite_nonactive"] forState:UIControlStateNormal];
		[_cancelButton setBackgroundImage:[UIImage imageNamed:@"cancelbuttonwhite_active"] forState:UIControlStateHighlighted];

		[_cancelButton addTarget:self action:@selector(_goCloseCamera) forControlEvents:UIControlEventTouchUpInside];
		[_headerBGView addSubview:_cancelButton];
		
//		_changeTintButton = [UIButton buttonWithType:UIButtonTypeCustom];
//		_changeTintButton.frame = CGRectMake(-5.0, [UIScreen mainScreen].bounds.size.height - 60.0, 64.0, 64.0);
//		[_changeTintButton setBackgroundImage:[UIImage imageNamed:@"filterButton_nonActive"] forState:UIControlStateNormal];
//		[_changeTintButton setBackgroundImage:[UIImage imageNamed:@"filterButton_Active"] forState:UIControlStateHighlighted];
//		[_changeTintButton addTarget:self action:@selector(_goChangeTint) forControlEvents:UIControlEventTouchUpInside];
//		[self addSubview:_changeTintButton];
		
		_takePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_takePhotoButton.frame = CGRectMake(115.0, [UIScreen mainScreen].bounds.size.height - 113.0, 94.0, 94.0);
		[_takePhotoButton setBackgroundImage:[UIImage imageNamed:@"takePhotoButton_nonActive"] forState:UIControlStateNormal];
		[_takePhotoButton setBackgroundImage:[UIImage imageNamed:@"takePhotoButton_Active"] forState:UIControlStateHighlighted];
		[_takePhotoButton addTarget:self action:@selector(_goTakePhoto) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_takePhotoButton];
		
		_lastCameraRollImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cameraRollBG"]];
		_lastCameraRollImageView.frame = CGRectOffset(_lastCameraRollImageView.frame, 257.0, [UIScreen mainScreen].bounds.size.height - 60.0);
		[self addSubview:_lastCameraRollImageView];
		
		[[HONImageBroker sharedInstance] maskView:_lastCameraRollImageView withMask:[UIImage imageNamed:@"cameraRollMask"]];
		[self _retrieveLastImage];
		
		_cameraRollButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_cameraRollButton.frame = _lastCameraRollImageView.frame;
		[_cameraRollButton addTarget:self action:@selector(_goCameraRoll) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:_cameraRollButton];
	}
	
	return (self);
}


#pragma mark - Public API
- (void)submitStep:(HONSelfieCameraPreviewView *)previewView {
	[self addSubview:previewView];
	
	[UIView animateWithDuration:0.25 animations:^(void) {
		_blackMatteView.alpha = 0.0;
	} completion:^(BOOL finished) {
		_blackMatteView.hidden = YES;
	}];
}


#pragma mark - Navigation
- (void)_goFlipCamera {
	[self.delegate cameraOverlayViewChangeCamera:self];
}

- (void)_goToggleFlash {
	[self.delegate cameraOverlayViewChangeFlash:self];
}

- (void)_goCameraRoll {
	[self.delegate cameraOverlayViewShowCameraRoll:self];
}

- (void)_goCloseCamera {
	[self.delegate cameraOverlayViewCloseCamera:self];
}

- (void)_goTakePhoto {
	_blackMatteView.hidden = NO;
	[UIView animateWithDuration:0.125 animations:^(void) {
		_blackMatteView.alpha = 1.0;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.25 animations:^(void) {
			_blackMatteView.alpha = 0.0;
		}];
	}];
	
	[self.delegate cameraOverlayViewTakePhoto:self];
}

- (void)_retrieveLastImage {
	ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
	[assetsLibrary enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
		if (nil != group) {
			// be sure to filter the group so you only get photos
			[group setAssetsFilter:[ALAssetsFilter allPhotos]];
			
			[group enumerateAssetsWithOptions:NSEnumerationReverse usingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
				if (asset) {
					_lastCameraRollImageView.image = [UIImage imageWithCGImage:[[asset defaultRepresentation] fullResolutionImage]];
					*stop = YES;
				}
			}];
		}
		
		*stop = NO;
	} failureBlock:^(NSError *error) {
		NSLog(@"error: %@", error);
	}];
}


@end
