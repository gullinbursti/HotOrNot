//
//  HONComposeViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 9/6/13 @ 12:01 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <AWSiOSSDKv2/AWSS3.h>
#import <AWSiOSSDKv2/AWSS3TransferManager.h>
#import <AWSiOSSDKv2/S3.h>

#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

#import "NSCharacterSet+AdditionalSets.h"
#import "NSDate+Operations.h"
#import "NSMutableDictionary+Replacements.h"
#import "NSString+DataTypes.h"
#import "NSString+Formatting.h"
#import "UIImage+fixOrientation.h"
#import "UIImage+ImageEffects.h"
#import "UIImage+Transmute.h"
#import "UIImageView+AFNetworking.h"

#import "Flurry.h"
#import "ImageFilter.h"
#import "TSTapstream.h"

#import "HONComposeViewController.h"
#import "HONCameraOverlayView.h"
#import "HONTrivialUserVO.h"

@interface HONComposeViewController () <HONCameraOverlayViewDelegate>
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic, assign, readonly) HONSelfieSubmitType selfieSubmitType;
@property (nonatomic, strong) HONChallengeVO *challengeVO;
@property (nonatomic, strong) HONUserClubVO *userClubVO;
@property (nonatomic, strong) HONTrivialUserVO *trivialUserVO;
@property (nonatomic, strong) HONContactUserVO *contactUserVO;
@property (nonatomic, strong) NSMutableArray *selectedUsers;
@property (nonatomic, strong) NSMutableArray *selectedContacts;
@property (nonatomic, strong) HONCameraOverlayView *cameraOverlayView;
@property (nonatomic, strong) UIImageView *previewImageView;
@property (nonatomic, strong) UIImage *processedImage;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSMutableDictionary *submitParams;
@property (nonatomic) BOOL isUploadComplete;
@property (nonatomic) int uploadCounter;

@property (nonatomic, strong) AWSS3PutObjectRequest *por1;
@property (nonatomic, strong) AWSS3PutObjectRequest *por2;
@property (nonatomic, strong) AWSS3TransferManagerUploadRequest *uploadReq1;
@property (nonatomic, strong) AWSS3TransferManagerUploadRequest *uploadReq2;

@property (nonatomic, strong) NSString *subject;
@property (nonatomic, strong) NSMutableArray *subjectNames;
@property (nonatomic, strong) NSMutableArray *selectedEmotions;
@property (nonatomic, strong) UIButton *submitButton;
@property (nonatomic, strong) UIButton *cameraBackButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) UIButton *nextButton;

@property (nonatomic, strong) UIView *textBGView;
@property (nonatomic, strong) UITextField *subjectTextField;

@property (nonatomic, strong) UIView *uploadView;
@property (nonatomic, strong) UIImageView *maskImageView;
@property (nonatomic, strong) UIImageView *filteredImageView;
@property (nonatomic) CGPoint prevPt;
@property (nonatomic) CGPoint currPt;
@end


@implementation HONComposeViewController

- (id)init {
	if ((self = [super init])) {
		[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - enter_compose"];
		
		_totalType = HONStateMitigatorTotalTypeCompose;
		_viewStateType = HONStateMitigatorViewStateTypeCompose;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_reloadEmotionPicker:)
													 name:@"RELOAD_EMOTION_PICKER" object:nil];
		
		_filename = [NSString stringWithFormat:@"%@/%@", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeClubsSource], [[HONClubAssistant sharedInstance] rndCoverImageURL]];
		
		_subject = @"";
		_selectedEmotions = [NSMutableArray array];
		_subjectNames = [NSMutableArray array];
	}
	
	return (self);
}

- (void)dealloc {
	_cameraOverlayView.delegate = nil;
	
	[super destroy];
}

- (id)initWithContact:(HONContactUserVO *)contactUserVO {
	NSLog(@"%@ - initWithContact", [self description]);
	if ((self = [self init])) {
		_contactUserVO = contactUserVO;
		_selfieSubmitType = HONSelfieSubmitTypeSearchContact;
	}
	
	return (self);
}

- (id)initWithUser:(HONTrivialUserVO *)trivialUserVO {
	NSLog(@"%@ - initWithUser", [self description]);
	if ((self = [self init])) {
		_trivialUserVO = trivialUserVO;
		_selfieSubmitType = HONSelfieSubmitTypeSearchUser;
	}
	
	return (self);
}

- (id)initWithClub:(HONUserClubVO *)clubVO {
	NSLog(@"%@ - initWithClub:[%d] (%@)", [self description], clubVO.clubID, clubVO.clubName);
	
	if ((self = [self init])) {
		_userClubVO = clubVO;
		_selfieSubmitType = HONSelfieSubmitTypeReply;
	}
	
	return (self);
}


- (id)initAsNewStatusUpdate {
	NSLog(@"%@ - initAsNewChallenge", [self description]);
	if ((self = [self init])) {
		_selfieSubmitType = HONSelfieSubmitTypeCreate;
	}
	
	return (self);
}


#pragma mark - Data Calls
- (void)_uploadPhotos {
	_isUploadComplete = NO;
	_uploadCounter = 0;
	
	NSString *coords = [@"" stringFromCLLocation:[[HONDeviceIntrinsics sharedInstance] deviceLocation]];
	coords = [coords stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	_filename = [NSString stringWithFormat:@"%@/%@_%@_%d", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeClubsSource], [[[HONDeviceIntrinsics sharedInstance] identifierForVendorWithoutSeperators:YES] lowercaseString], coords, [NSDate elapsedUTCSecondsSinceUnixEpoch]];
	NSLog(@"FILE PATH:%@", _filename);
	
	UIImage *largeImage = _processedImage;
	UIImage *scaledImage = [[HONImageBroker sharedInstance] scaleImage:_processedImage toSize:CGSizeMake(320.0, 284.0) preserveRatio:YES];
	UIImage *squareImage = [[HONImageBroker sharedInstance] cropImage:scaledImage toFillSize:CGSizeFromLength(320.0)];
	
//	NSLog(@"LARGE IMAGE:[%@] (%@)", NSStringFromCGSize(largeImage.size), NSStringFromUIImageOrientation(largeImage.imageOrientation));
//	NSLog(@"SCALED IMAGE:[%@] (%@)", NSStringFromCGSize(scaledImage.size), NSStringFromUIImageOrientation(scaledImage.imageOrientation));
//	NSLog(@"SQUARE IMAGE:[%@] (%@)", NSStringFromCGSize(squareImage.size), NSStringFromUIImageOrientation(squareImage.imageOrientation));
	
	NSString *largeURL = [[[_filename componentsSeparatedByString:@"/"] lastObject] stringByAppendingString:kSnapLargeSuffix];
	NSString *squareURL = [[[_filename componentsSeparatedByString:@"/"] lastObject] stringByAppendingString:kSnapMediumSuffix];
	
	
	BFTask *task = [BFTask taskWithResult:nil];
	[[task continueWithBlock:^id(BFTask *task) {
		NSData *data1 = UIImageJPEGRepresentation(largeImage, [HONAppDelegate compressJPEGPercentage]);
		[data1 writeToURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kSnapLargeSuffix]] atomically:YES];
		
		NSData *data2 = UIImageJPEGRepresentation(squareImage, [HONAppDelegate compressJPEGPercentage]);
		[data2 writeToURL:[NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kSnapMediumSuffix]] atomically:YES];
		
		return (nil);
		
	}] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
		// done
//		NSLog(@"[BFTask mainThreadExecutor");
		return (nil);
	}];
	
	
	_uploadReq1 = [AWSS3TransferManagerUploadRequest new];
	_uploadReq1.bucket = @"hotornot-challenges";
	_uploadReq1.contentType = @"image/jpeg";
	_uploadReq1.key = largeURL;
	_uploadReq1.body = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kSnapLargeSuffix]];
	_uploadReq1.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
		dispatch_sync(dispatch_get_main_queue(), ^{
//			NSLog(@"%lld", totalBytesSent);
		});
	};

	_uploadReq2 = [AWSS3TransferManagerUploadRequest new];
	_uploadReq2.bucket = @"hotornot-challenges";
	_uploadReq2.contentType = @"image/jpeg";
	_uploadReq2.key = squareURL;
	_uploadReq2.body = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:kSnapMediumSuffix]];
	_uploadReq2.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend){
		dispatch_sync(dispatch_get_main_queue(), ^{
//			NSLog(@"%lld", totalBytesSent);
		});
	};

	
	AWSS3TransferManager *transferManager = [AWSS3TransferManager defaultS3TransferManager];
	[[transferManager upload:_uploadReq1] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
		if (task.error != nil) {
			if (task.error.code != AWSS3TransferManagerErrorCancelled && task.error.code != AWSS3TransferManagerErrorPaused) {
				// failed
//				NSLog(@"[AWSS3TransferManager FAILED:[%@]", task.error.description);
			}
			
		} else {
//			NSLog(@"[AWSS3TransferManager COMPLETE:[%@]", _uploadReq1.key);
			_uploadReq1 = nil;
			if (++_uploadCounter == 2) {
				// complete
				
				_isUploadComplete = YES;
				if (_isUploadComplete) {
//					[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:_filename forBucketType:HONS3BucketTypeSelfies completion:^(NSObject *result) {
//					}];
				}
			}
		}
		
		return (nil);
	}];
	
	[[transferManager upload:_uploadReq2] continueWithExecutor:[BFExecutor mainThreadExecutor] withBlock:^id(BFTask *task) {
		if (task.error != nil) {
			if (task.error.code != AWSS3TransferManagerErrorCancelled && task.error.code != AWSS3TransferManagerErrorPaused) {
				// failed
				NSLog(@"[AWSS3TransferManager FAILED:[%@]", task.error.description);
			}
			
		} else {
			NSLog(@"[AWSS3TransferManager COMPLETE:[%@]", _uploadReq2.key);
			_uploadReq2 = nil;
			if (++_uploadCounter == 2) {
				// complete
				
				_isUploadComplete = YES;
				if (_isUploadComplete) {
//					[[HONAPICaller sharedInstance] notifyToCreateImageSizesForPrefix:_filename forBucketType:HONS3BucketTypeSelfies completion:^(NSObject *result) {
//					}];
				}
			}
		}
		
		return (nil);
	}];
}

- (void)_modifySubmitParamsAndSubmit:(NSArray *)subjectNames {
//	if (![[HONClubAssistant sharedInstance] isMemberOfClub:[[HONClubAssistant sharedInstance] orthodoxMemberClub] includePending:NO]) {
	if ([[HONClubAssistant sharedInstance] currentLocationClub].clubID == [[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue]) {
		[[[UIAlertView alloc] initWithTitle:@"Not in range!"
									message:[NSString stringWithFormat:@"Must be within %@ miles", [[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"radius"]]
								   delegate:nil
						  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
						  otherButtonTitles:nil] show];
		
	} else {
		[[HONAnalyticsReporter sharedInstance] trackEvent:@"DETAILS - flag"];
		
		NSError *error;
		NSString *jsonString = [[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:subjectNames options:0 error:&error]
													 encoding:NSUTF8StringEncoding];
		
		_submitParams = [@{@"user_id"		: [[HONAppDelegate infoForUser] objectForKey:@"id"],
						   @"img_url"		: _filename,
						   @"club_id"		: [@"" stringFromInt:(_selfieSubmitType == HONSelfieSubmitTypeReply) ? _userClubVO.clubID : 0],
						   @"owner_id"		: [@"" stringFromInt:(_selfieSubmitType == HONSelfieSubmitTypeReply) ? _userClubVO.ownerID : 0],
						   @"subject"		: _subject,
						   @"subjects"		: jsonString,
						   @"challenge_id"	: [@"" stringFromInt:0],
						   @"recipients"	: @"",
						   @"api_endpt"		: kAPICreateChallenge} mutableCopy];
		NSLog(@"|:|◊≈◊~~◊~~◊≈◊~~◊~~◊≈◊| SUBMIT PARAMS:[%@]", _submitParams);

		
		UIView *overlayView = [[UIView alloc] initWithFrame:self.view.frame];
		overlayView.backgroundColor = [UIColor colorWithWhite:0.00 alpha:0.667];
		[self.view addSubview:overlayView];
		
//		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.labelText = @"";//NSLocalizedString(@"hud_loading", nil);
		_progressHUD.mode = MBProgressHUDModeIndeterminate;
		_progressHUD.minShowTime = kProgressHUDMinDuration;
		_progressHUD.taskInProgress = YES;
			
			NSLog(@"*^*|~|*|~|*|~|*|~|*|~|*|~| SUBMITTING -=- [%@] |~|*|~|*|~|*|~|*|~|*|~|*^*", _submitParams);
			[[HONAPICaller sharedInstance] submitClubPhotoWithDictionary:_submitParams completion:^(NSDictionary *result) {
				if ([[result objectForKey:@"result"] isEqualToString:@"fail"]) {
					if (_progressHUD == nil)
						_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
					_progressHUD.minShowTime = kProgressHUDMinDuration;
					_progressHUD.mode = MBProgressHUDModeCustomView;
					_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hudLoad_fail"]];
					_progressHUD.labelText = @"Error!";
					[_progressHUD show:NO];
					[_progressHUD hide:YES afterDelay:kProgressHUDErrorDuration];
					_progressHUD = nil;
					
				} else {
					//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Send Club Reply Invites"
//													   withProperties:[self _trackingProps]];
					
					[Flurry logEvent:@"resume"];
					[[HONClubAssistant sharedInstance] sendClubInvites:_userClubVO toInAppUsers:_selectedUsers toNonAppContacts:_selectedContacts completion:^(BOOL success) {
						if (_progressHUD != nil) {
							[_progressHUD hide:YES];
							_progressHUD = nil;
						}
						
						[overlayView removeFromSuperview];
						[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:^(void) {
							[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_HOME_TAB" object:@"Y"];
							[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_CLUB_TIMELINE" object:@"Y"];
						}];
					}];
				}
			}];
//		}
	}
}

- (void)_cancelUpload {
	_isUploadComplete = NO;
	_uploadCounter = 0;
	
	if (_por1 != nil) {
		_por1 = nil;
	}
	
	if (_por2 != nil) {
		_por2 = nil;
	}
}

- (void)_uploadTimeout {
	[self _cancelUpload];
	
	if (_progressHUD == nil)
		_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	
	_progressHUD.minShowTime = kProgressHUDMinDuration;
	_progressHUD.mode = MBProgressHUDModeCustomView;
	_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"hudLoad_fail"]];
	_progressHUD.labelText = NSLocalizedString(@"hud_uploadFail", nil);
	[_progressHUD show:NO];
	[_progressHUD hide:YES afterDelay:kProgressHUDErrorDuration];
	_progressHUD = nil;
}


#pragma mark - Data Handling
- (NSDictionary *)_trackingProps {
	NSMutableArray *users = [NSMutableArray array];
	for (HONTrivialUserVO *vo in _selectedUsers)
		[users addObject:[[HONAnalyticsReporter sharedInstance] propertyForTrivialUser:vo]];
	
	NSMutableArray *contacts = [NSMutableArray array];
	for (HONContactUserVO *vo in _selectedContacts)
		[contacts addObject:[[HONAnalyticsReporter sharedInstance] propertyForContactUser:vo]];
	
	NSMutableDictionary *props = [NSMutableDictionary dictionary];
	[props setValue:[[HONAnalyticsReporter sharedInstance] propertyForUserClub:_userClubVO] forKey:@"clubs"];
	[props setValue:users forKey:@"members"];
	[props setValue:contacts forKey:@"contacts"];
	
	return ([props copy]);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	if (touch.tapCount == 2) {
		if (_maskImageView != nil) {
			[_maskImageView removeFromSuperview];
			_maskImageView = nil;
		}
	}
	
	if (_maskImageView == nil)
		_maskImageView = [[UIImageView alloc] initWithFrame:_previewImageView.frame];
	[self.view addSubview:_maskImageView];
	
	_prevPt = [touch locationInView:self.view];
	[super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touch = [touches anyObject];
	
	_currPt = [touch locationInView:self.view];
	
	UIGraphicsBeginImageContext([UIScreen mainScreen].bounds.size);
	[_maskImageView.image drawInRect:[UIScreen mainScreen].bounds];
	CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);
	CGContextSetLineWidth(UIGraphicsGetCurrentContext(), 32.0);
	CGContextSetRGBStrokeColor(UIGraphicsGetCurrentContext(), 0.0, 0.0, 0.0, 1.0);
	CGContextBeginPath(UIGraphicsGetCurrentContext());
	CGContextMoveToPoint(UIGraphicsGetCurrentContext(), _prevPt.x, _prevPt.y);
	CGContextAddLineToPoint(UIGraphicsGetCurrentContext(), _currPt.x, _currPt.y);
	CGContextStrokePath(UIGraphicsGetCurrentContext());
	
	_maskImageView.frame = [UIScreen mainScreen].bounds;
	_maskImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	_prevPt = _currPt;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[super touchesEnded:touches withEvent:event];
	
	[_maskImageView removeFromSuperview];
	[[HONViewDispensor sharedInstance] maskView:_filteredImageView withMask:_maskImageView.image];
	_processedImage = [[HONImageBroker sharedInstance] createImageFromView:_uploadView];
//	[self _uploadPhotos];
}



#pragma mark - View lifecycle
- (void)loadView {
	ViewControllerLog(@"[:|:] [%@ loadView] [:|:]", self.class);
	[super loadView];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
	
	_uploadView = [[UIView alloc] initWithFrame:self.view.frame];
	[self.view addSubview:_uploadView];
	
	_previewImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
	_previewImageView.frame = CGRectInset(_previewImageView.frame, -25.0, -48.0);
	_previewImageView.frame = CGRectOffset(_previewImageView.frame, 10.0, 20.0);
	[_uploadView addSubview:_previewImageView];
	
	_filteredImageView = [[UIImageView alloc] initWithFrame:_previewImageView.frame];
	[_uploadView addSubview:_filteredImageView];
	
	NSLog(@"PREVIEW:[%@] FILTER:[%@]", NSStringFromCGRect(_previewImageView.frame), NSStringFromCGRect(_filteredImageView.frame));
	
	UIButton *keyboardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	keyboardButton.frame = self.view.frame;
	[keyboardButton addTarget:self action:@selector(_goDropKeyboard) forControlEvents:UIControlEventTouchUpInside];
	//[self.view addSubview:keyboardButton];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:@""];
	[_headerView removeBackground];
	_headerView.hidden = YES;
	[self.view addSubview:_headerView];
	
	
	_cameraBackButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_cameraBackButton.frame = CGRectMake(0.0, 20.0, 44.0, 44.0);
	[_cameraBackButton setBackgroundImage:[UIImage imageNamed:@"cameraBackButton_nonActive"] forState:UIControlStateNormal];
	[_cameraBackButton setBackgroundImage:[UIImage imageNamed:@"cameraBackButton_Active"] forState:UIControlStateHighlighted];
	[_cameraBackButton addTarget:self action:@selector(_goCamera) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addSubview:_cameraBackButton];
	
	
	_textBGView = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - 113.0, 320.0, 44.0)];
	_textBGView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
	_textBGView.hidden = YES;
	[self.view addSubview:_textBGView];
	
	_subjectTextField = [[UITextField alloc] initWithFrame:CGRectMake(10.0, 11.0, 300.0, 22.0)];
	[_subjectTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[_subjectTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
	_subjectTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
	[_subjectTextField setReturnKeyType:UIReturnKeyDone];
	[_subjectTextField setTextColor:[UIColor whiteColor]];
	[_subjectTextField addTarget:self action:@selector(_onTextEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
	[_subjectTextField addTarget:self action:@selector(_onTextEditingDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
	_subjectTextField.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:17];
	_subjectTextField.keyboardType = UIKeyboardTypeASCIICapable;
	_subjectTextField.textAlignment = NSTextAlignmentCenter;
	_subjectTextField.text = @"Say something";
	_subjectTextField.delegate = self;
	[_textBGView addSubview:_subjectTextField];
	
	_submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_submitButton.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 44.0, 320.0, 44.0);
	[_submitButton setBackgroundImage:[UIImage imageNamed:@"submitButton_nonActive"] forState:UIControlStateNormal];
	[_submitButton setBackgroundImage:[UIImage imageNamed:@"submitButton_Active"] forState:UIControlStateHighlighted];
	[_submitButton addTarget:self action:@selector(_goSubmit) forControlEvents:UIControlEventTouchUpInside];
	_submitButton.hidden = YES;
	[self.view addSubview:_submitButton];
}

- (void)viewDidLoad {
	ViewControllerLog(@"[:|:] [%@ viewDidLoad] [:|:]", self.class);
	[super viewDidLoad];
	
//	_panGestureRecognizer.enabled = YES;
	[self _showImagePickerForSourceType:([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)viewWillAppear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewWillAppear:animated:%@] [:|:]", self.class, [@"" stringFromBOOL:animated]);
	[super viewWillAppear:animated];
	
	[_nextButton addTarget:self action:@selector(_goSubmit) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - Navigation
- (void)_goCancel {
	NSLog(@"[*:*] _goCancel");
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - exit_button"];
	
	[self _cancelUpload];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	[self dismissViewControllerAnimated:NO completion:^(void) {
		[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:^(void) {
		}];
	}];
}

- (void)_goSubmit {
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - submit_compose"];
	[self _modifySubmitParamsAndSubmit:_subjectNames];
}

- (void)_goCamera {
	[self _showImagePickerForSourceType:([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)_goDropKeyboard {
	if ([_subjectTextField isFirstResponder])
		[_subjectTextField resignFirstResponder];
}

- (void)_goDelete {
//	HONEmotionVO *emotionVO = (HONEmotionVO *)[_selectedEmotions lastObject];
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Sticker Deleted"
//										  withEmotion:emotionVO];
	
	if ([_subjectNames count] > 0)
		[_subjectNames removeLastObject];
	
	if ([_subjectNames count] == 0) {
		[_subjectNames removeAllObjects];
		_subjectNames = nil;
		_subjectNames = [NSMutableArray array];
	}
	
//	[_composeDisplayView removeLastEmotion];
	[_headerView transitionTitle:([_subjectNames count] > 0) ? [_subjectNames lastObject] : @"Create"];
}

- (void)_goPanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
//	NSLog(@"[:|:] _goPanGesture:[%@]-=(%@)=-", NSStringFromCGPoint([gestureRecognizer velocityInView:self.view]), (gestureRecognizer.state == UIGestureRecognizerStateBegan) ? @"BEGAN" : (gestureRecognizer.state == UIGestureRecognizerStateCancelled) ? @"CANCELED" : (gestureRecognizer.state == UIGestureRecognizerStateEnded) ? @"ENDED" : (gestureRecognizer.state == UIGestureRecognizerStateFailed) ? @"FAILED" : (gestureRecognizer.state == UIGestureRecognizerStatePossible) ? @"POSSIBLE" : (gestureRecognizer.state == UIGestureRecognizerStateChanged) ? @"CHANGED" : (gestureRecognizer.state == UIGestureRecognizerStateRecognized) ? @"RECOGNIZED" : @"N/A");
	[super _goPanGesture:gestureRecognizer];
	
	if ([gestureRecognizer velocityInView:self.view].y >= 2000 || [gestureRecognizer velocityInView:self.view].x >= 2000) {
		//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Dismiss SWIPE"];
		
		[self _cancelUpload];
		[self dismissViewControllerAnimated:NO completion:^(void) {
		}];
	}
	
	if ([gestureRecognizer velocityInView:self.view].x <= -2000 && !_isPushing) {
		//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Next SWIPE"];
//		[self _modifySubmitParamsAndSubmit:_subjectNames];
	}
}


#pragma mark - Notifications
- (void)_reloadEmotionPicker:(NSNotification *)notification {
//	HONEmotionsPickerView *pickerView = (HONEmotionsPickerView *)[_emotionsPickerViews firstObject];
//	[pickerView reload];
}

- (void)_textFieldTextDidChangeChange:(NSNotification *)notification {
	NSLog(@"UITextFieldTextDidChangeNotification:[%@]", [notification object]);
}


#pragma mark - UI Presentation
- (void)_showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
	if (self.imagePickerController != nil)
		self.imagePickerController = nil;
	
	UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
	imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
	imagePickerController.view.backgroundColor = [UIColor blackColor];
	imagePickerController.sourceType = sourceType;
	imagePickerController.delegate = self;
	
	if (sourceType == UIImagePickerControllerSourceTypeCamera) {
		float scale = ([[HONDeviceIntrinsics sharedInstance] isRetina4Inch]) ? ([[HONDeviceIntrinsics sharedInstance] isIOS8]) ? 1.65f : 1.55f : 1.25f;
		
		imagePickerController.showsCameraControls = NO;
//		imagePickerController.cameraViewTransform = CGAffineTransformMakeTranslation(24.0, 90.0);
		imagePickerController.cameraViewTransform = CGAffineTransformMakeTranslation(0.0, 90.0);
		imagePickerController.cameraViewTransform = CGAffineTransformScale(imagePickerController.cameraViewTransform, scale, scale);
		imagePickerController.cameraDevice = ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
		
		_cameraOverlayView = [[HONCameraOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
		_cameraOverlayView.delegate = self;
		imagePickerController.cameraOverlayView = _cameraOverlayView;
		
		[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	}
	
	self.imagePickerController = imagePickerController;
	[self presentViewController:self.imagePickerController animated:NO completion:^(void) {
	}];
}

- (void)_enableSubmitButton {
	[_nextButton addTarget:self action:@selector(_goSubmit) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - CameraOverlay Delegates
- (void)cameraOverlayViewShowCameraRoll:(HONCameraOverlayView *)cameraOverlayView {
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Camera Roll"
//									 withProperties:@{@"state"	: @"open"}];
	
	self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
}

- (void)cameraOverlayViewChangeCamera:(HONCameraOverlayView *)cameraOverlayView {
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - flip_button"];
	
	self.imagePickerController.cameraDevice = (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront) ? UIImagePickerControllerCameraDeviceRear : UIImagePickerControllerCameraDeviceFront;
	
	if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear)
		self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
}

- (void)cameraOverlayViewCloseCamera:(HONCameraOverlayView *)cameraOverlayView {
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Close Camera"
//								   withCameraDevice:self.imagePickerController.cameraDevice];
	
	[self _cancelUpload];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	[self.imagePickerController dismissViewControllerAnimated:NO completion:^(void) {
		self.imagePickerController.delegate = nil;
		[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:^(void) {
		}];
	}];
}

- (void)cameraOverlayViewTakePhoto:(HONCameraOverlayView *)cameraOverlayView {
	//[[HONAnalyticsReporter sharedInstance] trackEvent:[NSString stringWithFormat:@"Camera Step - %@ Photo", (isFiltered) ? @"Blur" : @"Take"]];
	
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"STATUS - take_photo"];
	
//	if (_progressHUD == nil)
//		_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
//	_progressHUD.labelText = NSLocalizedString(@"hud_loading", @"Loading…");
//	_progressHUD.mode = MBProgressHUDModeIndeterminate;
//	_progressHUD.minShowTime = kProgressHUDMinDuration;
//	_progressHUD.taskInProgress = YES;
	
	[self.imagePickerController takePicture];
}


#pragma mark - NavigationController Delegates
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
	navigationController.navigationBar.barStyle = UIBarStyleDefault;
}


#pragma mark - ImagePicker Delegates
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - take_photo"];
	BOOL isSourceImageMirrored = (picker.sourceType == UIImagePickerControllerSourceTypeCamera && picker.cameraDevice == UIImagePickerControllerCameraDeviceFront);
	NSLog(@"MIRRORED:[%@]", NSStringFromBOOL(isSourceImageMirrored));
	
	UIImage *srcImage = [info objectForKey:UIImagePickerControllerOriginalImage];
//	NSLog(@"SRC IMAGE:[%@] (%@)", NSStringFromCGSize(srcImage.size), NSStringFromUIImageOrientation(srcImage.imageOrientation));
	
	if (_maskImageView != nil) {
		[_maskImageView removeFromSuperview];
		_maskImageView = nil;
	}
	
	_processedImage = (isSourceImageMirrored) ? [[HONImageBroker sharedInstance] mirrorImage:[[HONImageBroker sharedInstance] prepForUploading:srcImage]] : [[HONImageBroker sharedInstance] prepForUploading:srcImage];
//	NSLog(@"PROCESSED IMAGE:[%@] (%@)", NSStringFromCGSize(_processedImage.size), NSStringFromUIImageOrientation(_processedImage.imageOrientation));
	
	UIImage *previewImage = [[HONImageBroker sharedInstance] scaleImage:_processedImage toSize:kSnapLargeSize preserveRatio:YES];
//	NSLog(@"PREVIEW IMAGE:[%@] (%@)", NSStringFromCGSize(previewImage.size), NSStringFromUIImageOrientation(_processedImage.imageOrientation));
	
	_previewImageView.image = previewImage;
	if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"taken_photo"] isEqualToString:NSStringFromBOOL(YES)]) {
		[[[UIAlertView alloc] initWithTitle:@"Touch to pixelate"
									message:@"Use the pixelate tool to protect the identity who you are, or what you are doing."
								   delegate:nil cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
						  otherButtonTitles:nil] show];
		
		[[NSUserDefaults standardUserDefaults] setObject:NSStringFromBOOL(YES) forKey:@"taken_photo"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[[HONViewDispensor sharedInstance] maskView:_filteredImageView withMask:_maskImageView.image];
	_filteredImageView.image = [_processedImage imageWithMosaic:48.0];
	
	_headerView.hidden = NO;
	_textBGView.hidden = NO;
	_submitButton.hidden = NO;
	
	[self dismissViewControllerAnimated:NO completion:^(void) {
		[self _uploadPhotos];
		[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - enter_step_2"];
	}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	NSLog(@"imagePickerControllerDidCancel:[%@]", (self.imagePickerController.sourceType == UIImagePickerControllerSourceTypeCamera) ? @"CAMERA" : @"LIBRARY");
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Camera Step - Camera Roll"
//									 withProperties:@{@"state"	: @"cancel"}];
	
	[self dismissViewControllerAnimated:NO completion:^(void) {
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
			[self _showImagePickerForSourceType:UIImagePickerControllerSourceTypeCamera];
		
		else {
			self.imagePickerController.delegate = nil;
			[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:^(void) {
			}];
		}
	}];
}


#pragma mark - TextField Delegates
-(void)textFieldDidBeginEditing:(UITextField *)textField {
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_textFieldTextDidChangeChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:textField];
	
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"COMPOSE - add_subject"];
	
	_subjectTextField.text = @"";
	[UIView animateWithDuration:0.25
					 animations:^(void) {
						 _textBGView.frame = CGRectTranslateY(_textBGView.frame, self.view.frame.size.height - 329.0);
						 _submitButton.frame = CGRectTranslateY(_submitButton.frame, self.view.frame.size.height - 260.0);
					 } completion:^(BOOL finished) {
					 }];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return (YES);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSLog(@"textField:[%@] shouldChangeCharactersInRange:[%@] replacementString:[%@] -- (%@)", textField.text, NSStringFromRange(range), string, NSStringFromRange([string rangeOfCharacterFromSet:[NSCharacterSet invalidCharacterSet]]));
	
	if ([string rangeOfCharacterFromSet:[NSCharacterSet invalidCharacterSet]].location != NSNotFound)
		return (NO);
	
	return ([textField.text length] <= 80 || [string isEqualToString:@""]);
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
	[textField resignFirstResponder];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UITextFieldTextDidChangeNotification"
												  object:textField];
	
	_subject = textField.text;
	textField.text = ([textField.text length] == 0) ? @"Same something…" : textField.text;
	[UIView animateWithDuration:0.25
					 animations:^(void) {
						 _textBGView.frame = CGRectTranslateY(_textBGView.frame, (self.view.frame.size.height - 44.0) - _textBGView.frame.size.height);
						 _submitButton.frame = CGRectTranslateY(_submitButton.frame, self.view.frame.size.height - 44.0);
					 } completion:^(BOOL finished) {
					 }];

}

- (void)_onTextEditingDidEnd:(id)sender {
}

- (void)_onTextEditingDidEndOnExit:(id)sender {
}

@end
