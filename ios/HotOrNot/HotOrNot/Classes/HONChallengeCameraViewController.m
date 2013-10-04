//
//  HONChallengeCameraViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 9/6/13 @ 12:01 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//


#import <AWSiOSSDK/S3/AmazonS3Client.h>
#import <CoreImage/CoreImage.h>
#import <QuartzCore/QuartzCore.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "MBProgressHUD.h"
#import "UIImage+fixOrientation.h"

#import "HONChallengeCameraViewController.h"
#import "HONImagingDepictor.h"
#import "HONSnapCameraOverlayView.h"
#import "HONCreateChallengePreviewView.h"


@interface HONChallengeCameraViewController () <AmazonServiceRequestDelegate, HONSnapCameraOverlayViewDelegate, HONCreateChallengePreviewViewDelegate>
@property (nonatomic) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) HONSnapCameraOverlayView *cameraOverlayView;
@property (nonatomic, strong) HONCreateChallengePreviewView *previewView;
@property (readonly, nonatomic, assign) HONVolleySubmitType volleySubmitType;
@property (nonatomic, strong) NSMutableArray *subscribers;
@property (nonatomic, strong) NSMutableArray *subscriberIDs;
@property (nonatomic, strong) HONChallengeVO *challengeVO;
@property (nonatomic, strong) NSString *subjectName;
@property (nonatomic) int uploadCounter;
@property (nonatomic, strong) NSArray *s3Uploads;
@property (nonatomic, strong) UIImage *rawImage;
@property (nonatomic, strong) UIImage *processedImage;
@property (nonatomic, strong) NSMutableArray *usernames;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) NSDictionary *challengeParams;
@property (nonatomic, strong) UIImageView *submitImageView;
@property (nonatomic) BOOL hasSubmitted;
@property (nonatomic) BOOL isFirstAppearance;
@property (nonatomic) BOOL isMainCamera;
@property (nonatomic) BOOL isFirstCamera;
@property (nonatomic) int selfieAttempts;
@end


@implementation HONChallengeCameraViewController

- (id)initAsNewChallenge {
	NSLog(@"%@ - initAsNewChallenge", [self description]);
	if ((self = [super init])) {
		_volleySubmitType = HONVolleySubmitTypeMatch;
		
		_subscribers = [NSMutableArray array];
		_subscriberIDs = [NSMutableArray array];
		_subjectName = @"";
		_selfieAttempts = 0;
		_isFirstAppearance = YES;
	}
	
	return (self);
}

- (id)initAsJoinChallenge:(HONChallengeVO *)challengeVO {
	NSLog(@"%@ - initAsJoinChallenge:[%d] (%d/%d)", [self description], challengeVO.challengeID, challengeVO.creatorVO.userID, ((HONOpponentVO *)[challengeVO.challengers lastObject]).userID);
	if ((self = [super init])) {
		_volleySubmitType = HONVolleySubmitTypeJoin;
		
		_subscribers = [NSMutableArray array];
		_subscriberIDs = [NSMutableArray array];
		_challengeVO = challengeVO;
		_subjectName = challengeVO.subjectName;
		_selfieAttempts = 0;
		_isFirstAppearance = YES;
	}
	
	return (self);
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	
}

- (BOOL)shouldAutorotate {
	return (NO);
}


#pragma mark - Data Calls
- (void)_retrieveUser {
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"%d", 5], @"action",
							[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
							nil];
	
	VolleyJSONLog(@"%@ —/> (%@/%@?action=%@)", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [params objectForKey:@"action"]);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:kAPIUsers parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSDictionary *userResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
		} else {
			VolleyJSONLog(@"AFNetworking [-] %@: %@", [[self class] description], userResult);
			[HONAppDelegate writeUserInfo:userResult];
			
			for (HONUserVO *vo in [HONAppDelegate friendsList]) {
				if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != vo.userID) {
					BOOL isFound = NO;
					for (NSNumber *userID in _subscriberIDs) {
						if ([userID intValue] == vo.userID) {
							isFound = YES;
							break;
						}
					}
					
					if (!isFound) {
						[_subscribers addObject:[HONUserVO userWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																			   [NSString stringWithFormat:@"%d", vo.userID], @"id",
																			   [NSString stringWithFormat:@"%d", 0], @"points",
																			   [NSString stringWithFormat:@"%d", 0], @"votes",
																			   [NSString stringWithFormat:@"%d", 0], @"pokes",
																			   [NSString stringWithFormat:@"%d", 0], @"pics",
																			   [NSString stringWithFormat:@"%d", 0], @"age",
																			   vo.username, @"username",
																			   vo.fbID, @"fb_id",
																			   vo.imageURL, @"avatar_url", nil]]];
						[_subscriberIDs addObject:[NSNumber numberWithInt:vo.userID]];
					}
				}
			}
			
			[_cameraOverlayView updateChallengers:[_subscribers copy] asJoining:(_volleySubmitType == HONVolleySubmitTypeJoin)];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
	}];
}

- (void)_uploadPhotos {
	AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:[[HONAppDelegate s3Credentials] objectForKey:@"key"] withSecretKey:[[HONAppDelegate s3Credentials] objectForKey:@"secret"]];
	_uploadCounter = 0;
	
	_filename = [NSString stringWithFormat:@"%@_%@", [HONAppDelegate deviceToken], [[NSNumber numberWithLongLong:[[NSDate date] timeIntervalSince1970]] stringValue]];
	NSLog(@"FILE PREFIX: %@/%@", [HONAppDelegate s3BucketForType:@"challenges"], _filename);
	
	@try {
				
		// preview - full size
		UIImage *oImage = _processedImage;//(_rawImage.size.width >= 1936.0) ? [HONImagingDepictor scaleImage:_rawImage toSize:CGSizeMake(960.0, 1280.0)] : _rawImage;
		UIImage *largeImage = [HONImagingDepictor cropImage:[HONImagingDepictor scaleImage:oImage toSize:CGSizeMake(852.0, 1136.0)] toRect:CGRectMake(106.0, 0.0, 640.0, 1136.0)];
//		UIImage *exploreImage = [HONImagingDepictor cropImage:[HONImagingDepictor scaleImage:largeImage toSize:CGSizeMake(320.0, 568.0)] toRect:CGRectMake(0.0, 124.0, 320.0, 320.0)];
//		UIImage *gridImage = [HONImagingDepictor scaleImage:exploreImage toSize:CGSizeMake(160.0, 160.0)];
		
		[s3 createBucket:[[S3CreateBucketRequest alloc] initWithName:@"hotornot-challenges"]];
		
//		S3PutObjectRequest *por1 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@Small_160x160.jpg", _filename] inBucket:@"hotornot-challenges"];
//		por1.delegate = self;
//		por1.contentType = @"image/jpeg";
//		por1.data = UIImageJPEGRepresentation(gridImage, kSnapJPEGCompress);
//		[s3 putObject:por1];
//		
//		S3PutObjectRequest *por2 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@Medium_320x320.jpg", _filename] inBucket:@"hotornot-challenges"];
//		por2.delegate = self;
//		por2.contentType = @"image/jpeg";
//		por2.data = UIImageJPEGRepresentation(exploreImage, kSnapJPEGCompress);
//		[s3 putObject:por2];
		
		S3PutObjectRequest *por3 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@Large_640x1136.jpg", _filename] inBucket:@"hotornot-challenges"];
		por3.delegate = self;
		por3.contentType = @"image/jpeg";
		por3.data = UIImageJPEGRepresentation(largeImage, kSnapJPEGCompress);
		[s3 putObject:por3];
		
		S3PutObjectRequest *por4 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@_o.jpg", _filename] inBucket:@"hotornot-challenges"];
		por4.delegate = self;
		por4.contentType = @"image/jpeg";
		por4.data = UIImageJPEGRepresentation(oImage, kSnapJPEGCompress);
		[s3 putObject:por4];
		
		_s3Uploads = [NSArray arrayWithObjects:por3, por4, nil];
		
	} @catch (AmazonClientException *exception) {
		//[[[UIAlertView alloc] initWithTitle:@"Upload Error" message:exception.message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_uploadFail", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:kHUDErrorTime];
		_progressHUD = nil;
	}
}

- (void)_submitChallenge {
	_submitImageView = [[UIImageView alloc] initWithFrame:CGRectMake(133.0, ([UIScreen mainScreen].bounds.size.height - 14.0) * 0.5, 54.0, 14.0)];
	_submitImageView.animationImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"cameraUpload_001"],
										[UIImage imageNamed:@"cameraUpload_002"],
										[UIImage imageNamed:@"cameraUpload_003"], nil];
	_submitImageView.animationDuration = 0.5f;
	_submitImageView.animationRepeatCount = 0;
	_submitImageView.alpha = 0.0;
	[_submitImageView startAnimating];
	[[[UIApplication sharedApplication] delegate].window addSubview:_submitImageView];
	
	[UIView animateWithDuration:0.25 animations:^(void) {
		_submitImageView.alpha = 1.0;
	} completion:nil];
	
	VolleyJSONLog(@"%@ —/> (%@/%@?action=%@)", [[self class] description], [HONAppDelegate apiServerPath], (_volleySubmitType == HONVolleySubmitTypeJoin) ? kAPIJoinChallenge : kAPIChallenges, [_challengeParams objectForKey:@"action"]);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:(_volleySubmitType == HONVolleySubmitTypeJoin) ? kAPIJoinChallenge : kAPIChallenges parameters:_challengeParams success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_dlFailed", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			NSDictionary *challengeResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			VolleyJSONLog(@"AFNetworking [-] %@ %@", [[self class] description], challengeResult);
			
			if (_uploadCounter == [_s3Uploads count]) {
				[UIView animateWithDuration:0.5 animations:^(void) {
					_submitImageView.alpha = 0.0;
				} completion:^(BOOL finished) {
					[_submitImageView removeFromSuperview];
					_submitImageView = nil;
				}];
			}
			
			if ([[challengeResult objectForKey:@"result"] isEqualToString:@"fail"]) {
				if (_progressHUD == nil)
					_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
				_progressHUD.minShowTime = kHUDTime;
				_progressHUD.mode = MBProgressHUDModeCustomView;
				_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
				_progressHUD.labelText = @"Error!";
				[_progressHUD show:NO];
				[_progressHUD hide:YES afterDelay:kHUDErrorTime];
				_progressHUD = nil;
				
			} else {
				_hasSubmitted = YES;
				if (_uploadCounter == [_s3Uploads count]) {
//					if (_isFirstCamera) {
//						
//						UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share Volley"
//																			message:@"Great! You have just completed your first Volley update, would you like to share Volley with friends on Instagram?"
//																		   delegate:self
//																  cancelButtonTitle:@"No"
//																  otherButtonTitles:@"Yes", nil];
//						[alertView show];
						
//					} else {
						[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:^(void) {
							[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_ALL_TABS" object:@"Y"];
							[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
							
//							if (_isFirstCamera && [HONAppDelegate switchEnabledForKey:@"share_volley"])
//								[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_SHARE_SELF" object:(_rawImage.size.width >= 1936.0) ? [HONImagingDepictor scaleImage:_rawImage toSize:CGSizeMake(960.0, 1280.0)] : _rawImage];
						}];
//					}
				}
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIChallenges, [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:kHUDErrorTime];
		_progressHUD = nil;
	}];
}


#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
//	[self showImagePickerForSourceType:([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (_isFirstAppearance) {
		_isFirstAppearance = NO;
		[self showImagePickerForSourceType:([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) ? UIImagePickerControllerSourceTypeCamera : UIImagePickerControllerSourceTypePhotoLibrary];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


#pragma mark - UI Presentation
- (void)showImagePickerForSourceType:(UIImagePickerControllerSourceType)sourceType {
	if (_volleySubmitType == HONVolleySubmitTypeJoin) {
		if ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] != _challengeVO.creatorVO.userID) {
			[_subscribers addObject:[HONUserVO userWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																   [NSString stringWithFormat:@"%d", _challengeVO.creatorVO.userID], @"id",
																   [NSString stringWithFormat:@"%d", 0], @"points",
																   [NSString stringWithFormat:@"%d", 0], @"votes",
																   [NSString stringWithFormat:@"%d", 0], @"pokes",
																   [NSString stringWithFormat:@"%d", 0], @"pics",
																   [NSString stringWithFormat:@"%d", 0], @"age",
																   _challengeVO.creatorVO.username, @"username",
																   _challengeVO.creatorVO.fbID, @"fb_id",
																   _challengeVO.creatorVO.avatarURL, @"avatar_url", nil]]];
			[_subscriberIDs addObject:[NSNumber numberWithInt:_challengeVO.creatorVO.userID]];
		}
		
		for (HONOpponentVO *vo in _challengeVO.challengers) {
			if ([vo.imagePrefix length] > 0 && vo.userID != [[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue]) {
				
				BOOL isFound = NO;
				for (NSNumber *userID in _subscriberIDs) {
					if ([userID intValue] == vo.userID) {
						isFound = YES;
						break;
					}
				}
				
				if (!isFound) {
					[_subscribers addObject:[HONUserVO userWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																		   [NSString stringWithFormat:@"%d", vo.userID], @"id",
																		   [NSString stringWithFormat:@"%d", 0], @"points",
																		   [NSString stringWithFormat:@"%d", 0], @"votes",
																		   [NSString stringWithFormat:@"%d", 0], @"pokes",
																		   [NSString stringWithFormat:@"%d", 0], @"pics",
																		   [NSString stringWithFormat:@"%d", 0], @"age",
																		   vo.username, @"username",
																		   vo.fbID, @"fb_id",
																		   vo.avatarURL, @"avatar_url", nil]]];
					[_subscriberIDs addObject:[NSNumber numberWithInt:vo.userID]];
				}
			}
		}
	}
	
	
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
    imagePickerController.sourceType = sourceType;
    imagePickerController.delegate = self;
    
    if (sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePickerController.showsCameraControls = NO;
//		imagePickerController.cameraViewTransform = CGAffineTransformScale(imagePickerController.cameraViewTransform, ([HONAppDelegate isRetina5]) ? 1.65f : 1.25f, ([HONAppDelegate isRetina5]) ? 1.65f : 1.25f);
		imagePickerController.cameraDevice = ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
		
		_cameraOverlayView = [[HONSnapCameraOverlayView alloc] initWithFrame:[UIScreen mainScreen].bounds];
		_cameraOverlayView.delegate = self;
    }
	
    self.imagePickerController = imagePickerController;
    [self presentViewController:self.imagePickerController animated:YES completion:^(void) {
		if (sourceType == UIImagePickerControllerSourceTypeCamera)
			[self _showOverlay];
	}];
}

- (void)_showOverlay {
	int camera_total = 0;
	if (![[NSUserDefaults standardUserDefaults] objectForKey:@"camera_total"])
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:camera_total] forKey:@"camera_total"];
	
	else {
		camera_total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"camera_total"] intValue];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:++camera_total] forKey:@"camera_total"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	_isFirstCamera = (camera_total == 0);
	self.imagePickerController.cameraOverlayView = _cameraOverlayView;
	[_cameraOverlayView introWithTutorial:_isFirstCamera];
	
	if (_volleySubmitType == HONVolleySubmitTypeJoin) {
		[_cameraOverlayView updateChallengers:[_subscribers copy] asJoining:(_volleySubmitType == HONVolleySubmitTypeJoin)];
	
	} else
		[self _retrieveUser];
}


#pragma mark - CameraOverlay Delegates
- (void)cameraOverlayViewShowCameraRoll:(HONSnapCameraOverlayView *)cameraOverlayView {
	self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
}

- (void)cameraOverlayViewChangeCamera:(HONSnapCameraOverlayView *)cameraOverlayView {
	[[Mixpanel sharedInstance] track:@"Create Volley - Flip Camera"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
									  (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront) ? @"rear" : @"front", @"type", nil]];
	
	self.imagePickerController.cameraDevice = (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceFront) ? UIImagePickerControllerCameraDeviceRear : UIImagePickerControllerCameraDeviceFront;
	
	if (self.imagePickerController.cameraDevice == UIImagePickerControllerCameraDeviceRear)
		self.imagePickerController.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
}

- (void)cameraOverlayViewCameraBack:(HONSnapCameraOverlayView *)cameraOverlayView {
	[[Mixpanel sharedInstance] track:@"Create Volley - Back"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	for (S3PutObjectRequest *por in _s3Uploads)
		[por.urlConnection cancel];
}

- (void)cameraOverlayViewCloseCamera:(HONSnapCameraOverlayView *)cameraOverlayView {
	NSLog(@"cameraOverlayViewCloseCamera");
	[[Mixpanel sharedInstance] track:@"Create Volley - Cancel"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	for (S3PutObjectRequest *por in _s3Uploads)
		[por.urlConnection cancel];
	
	[self.imagePickerController dismissViewControllerAnimated:NO completion:^(void) {
		///[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
		[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:nil];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
	}];
}

- (void)cameraOverlayViewTakePhoto:(HONSnapCameraOverlayView *)cameraOverlayView {
	[[Mixpanel sharedInstance] track:@"Create Volley - Take Photo"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[self.imagePickerController takePicture];
}


#pragma mark - PreviewView Delegates
- (void)previewView:(HONCreateChallengePreviewView *)previewView removeChallenger:(HONUserVO *)userVO {
	[[Mixpanel sharedInstance] track:@"Create Volley - Remove Opponent"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
									  [NSString stringWithFormat:@"%d - %@", userVO.userID, userVO.username], @"challenger", nil]];
	
	NSMutableArray *removeVOs = [NSMutableArray array];
	for (HONUserVO *vo in _subscribers) {
		if (vo.userID == userVO.userID) {
			[removeVOs addObject:vo];
			break;
		}
	}
	
	[_subscribers removeObjectsInArray:removeVOs];
	removeVOs = nil;
	
	[_previewView setOpponents:[_subscribers copy] asJoining:(_volleySubmitType == HONVolleySubmitTypeJoin) redrawTable:YES];
}

- (void)previewViewBackToCamera:(HONCreateChallengePreviewView *)previewView {
	NSLog(@"previewViewBackToCamera");
	
	[[Mixpanel sharedInstance] track:@"Create Volley - Retake Photo"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	for (S3PutObjectRequest *por in _s3Uploads)
		[por.urlConnection cancel];
}

- (void)previewView:(HONCreateChallengePreviewView *)previewView changeSubject:(NSString *)subject {
	NSLog(@"previewView:changeSubject:[%@]", subject);
	_subjectName = subject;
}

- (void)previewViewClose:(HONCreateChallengePreviewView *)previewView {
	[[Mixpanel sharedInstance] track:@"Create Volley - Close"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	for (S3PutObjectRequest *por in _s3Uploads)
		[por.urlConnection cancel];
	
	[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:nil];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
}

- (void)previewViewSubmit:(HONCreateChallengePreviewView *)previewView {
	[[Mixpanel sharedInstance] track:@"Create Volley - Submit"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	_hasSubmitted = NO;
	int friend_total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"friend_total"] intValue];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:++friend_total] forKey:@"friend_total"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	//if ([[HONAppDelegate friendsList] count] > 1) {
	if ([[HONAppDelegate friendsList] count] == 1 && friend_total == 0) {
		UIAlertView *alertView = [[UIAlertView alloc]
								  initWithTitle:@"Find Friends"
								  message:@"Volley is more fun with friends! Find some now?"
								  delegate:self
								  cancelButtonTitle:@"Yes"
								  otherButtonTitles:@"No", nil];
		[alertView setTag:2];
		[alertView show];
		
	} else {
		if ([_subjectName length] == 0)
			_subjectName = [[HONAppDelegate defaultSubjects] objectAtIndex:(arc4random() % [[HONAppDelegate defaultSubjects] count])];
		
		NSMutableDictionary *params = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									   [NSString stringWithFormat:@"%@/%@", [HONAppDelegate s3BucketForType:@"challenges"], _filename], @"imgURL",
									   [NSString stringWithFormat:@"%d", _volleySubmitType], @"action",
									   [[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
									   [NSString stringWithFormat:@"%d", 1], @"expires",
									   _subjectName, @"subject",
									   @"", @"username",
									   @"N", @"isPrivate",
									   @"0", @"challengerID",
									   @"0", @"fbID", nil];
		
		NSString *usernames = @"";
		if ([_subscribers count] > 0) {
			for (HONUserVO *vo in _subscribers)
				usernames = [usernames stringByAppendingFormat:@"%@|", vo.username];
		}
		[params setObject:[usernames substringToIndex:([usernames length] > 0) ? [usernames length] - 1 : 0] forKey:@"usernames"];
		
		
		if (_challengeVO != nil)
			[params setObject:[NSString stringWithFormat:@"%d", _challengeVO.challengeID] forKey:@"challengeID"];
		
		_challengeParams = [params copy];
		NSLog(@"PARAMS:[%@]", _challengeParams);
		
		[self _submitChallenge];
	}
}


#pragma mark - AWS Delegates
- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
	//NSLog(@"\nAWS didCompleteWithResponse:\n%@", response);
	
	_uploadCounter++;
	if (_uploadCounter == [_s3Uploads count]) {
		if (_submitImageView != nil) {
			[UIView animateWithDuration:0.5 animations:^(void) {
				_submitImageView.alpha = 0.0;
			} completion:^(BOOL finished) {
				[_submitImageView removeFromSuperview];
				_submitImageView = nil;
			}];
		}
		
		[_previewView uploadComplete];
		if (_hasSubmitted) {
//			if (_isFirstCamera) {
//				UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Share Volley"
//																	message:@"Great! You have just completed your first Volley update, would you like to share Volley with friends on Instagram?"
//																   delegate:self
//														  cancelButtonTitle:@"No"
//														  otherButtonTitles:@"Yes", nil];
//				[alertView show];
//			
//			} else {
				[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:^(void) {
					[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_ALL_TABS" object:@"Y"];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
					
//					if (_isFirstCamera && [HONAppDelegate switchEnabledForKey:@"share_volley"])
//						[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_SHARE_SELF" object:(_rawImage.size.width >= 1936.0) ? [HONImagingDepictor scaleImage:_rawImage toSize:CGSizeMake(960.0, 1280.0)] : _rawImage];
				}];
//			}
		}
	}
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
	NSLog(@"AWS didFailWithError:\n%@", error);
}


#pragma mark - ImagePicker Delegates
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	_rawImage = [info objectForKey:UIImagePickerControllerOriginalImage];
	
	if (_rawImage.imageOrientation != 0)
		_rawImage = [_rawImage fixOrientation];
	
	NSLog(@"RAW IMAGE:[%@]", NSStringFromCGSize(_rawImage.size));
	
	// image is wider than tall (800x600)
	if (_rawImage.size.width > _rawImage.size.height) {
		_isMainCamera = (_rawImage.size.height > 1000);
//		if (_isMainCamera)
			_processedImage = [HONImagingDepictor cropImage:[HONImagingDepictor scaleImage:_rawImage toSize:CGSizeMake(1707.0, 1280.0)] toRect:CGRectMake(374.0, 0.0, 960.0, 1280.0)];//_processedImage = [HONImagingDepictor scaleImage:_rawImage toSize:CGSizeMake(1280.0, 960.0)];
		
	// image is taller than wide (600x800)
	} else if (_rawImage.size.width < _rawImage.size.height) {
		_isMainCamera = (_rawImage.size.width > 1000);
//		if (_isMainCamera)
			_processedImage = [HONImagingDepictor scaleImage:_rawImage toSize:CGSizeMake(960.0, 1280.0)];
	}
	
	NSLog(@"PROCESSED IMAGE:[%@]", NSStringFromCGSize(_processedImage.size));
	
//	CIImage *ciImage = [CIImage imageWithCGImage:workingImage.CGImage];
//	CIDetector *detctor = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
//	NSArray *features = [detctor featuresInImage:ciImage];
//	
//	NSLog(@"FEATURES:[%d]", [features count]);
	
//	if ([features count] > 0) {
		_usernames = [NSMutableArray array];
		for (HONUserVO *vo in _subscribers)
			[_usernames addObject:vo.username];
		
	
		_previewView = (_isMainCamera) ? [[HONCreateChallengePreviewView alloc] initWithFrame:[UIScreen mainScreen].bounds withSubject:_subjectName withImage:_processedImage] : [[HONCreateChallengePreviewView alloc] initWithFrame:[UIScreen mainScreen].bounds withSubject:_subjectName withMirroredImage:_processedImage];
		_previewView.delegate = self;
		_previewView.isFirstCamera = _isFirstCamera;
		[_previewView setOpponents:[_subscribers copy] asJoining:(_volleySubmitType == HONVolleySubmitTypeJoin) redrawTable:YES];
		[_previewView showKeyboard];
		
		[_cameraOverlayView submitStep:_previewView];
		
		[self _uploadPhotos];
		
		
		int friend_total = 0;
		if (![[NSUserDefaults standardUserDefaults] objectForKey:@"friend_total"]) {
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:friend_total] forKey:@"friend_total"];
			[[NSUserDefaults standardUserDefaults] synchronize];
			
		} else {
			friend_total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"friend_total"] intValue];
			[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:++friend_total] forKey:@"friend_total"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
	
//	} else {
//		_selfieAttempts++;
//		
//		if (_selfieAttempts < 3) {
//			[[[UIAlertView alloc] initWithTitle:@"No selfie detected!"
//										message:@"Please retake your photo"
//									   delegate:self
//							  cancelButtonTitle:@"OK"
//							  otherButtonTitles:nil] show];
//			
//		} else {
//			[[[UIAlertView alloc] initWithTitle:@"No selfie detected!"
//										message:@"You may get flagged by the community."
//									   delegate:nil
//							  cancelButtonTitle:@"OK"
//							  otherButtonTitles:nil] show];
//			
//			_usernames = [NSMutableArray array];
//			for (HONUserVO *vo in _subscribers)
//				[_usernames addObject:vo.username];
//			
//			_previewView = (_isMainCamera) ? [[HONCreateChallengePreviewView alloc] initWithFrame:[UIScreen mainScreen].bounds withSubject:_subjectName withImage:_processedImage] : [[HONCreateChallengePreviewView alloc] initWithFrame:[UIScreen mainScreen].bounds withSubject:_subjectName withMirroredImage:_processedImage];
//			_previewView.delegate = self;
//			_previewView.isFirstCamera = _isFirstCamera;
//			[_previewView setOpponents:[_subscribers copy] asJoining:(_volleySubmitType == HONVolleySubmitTypeJoin) redrawTable:YES];
//			[_previewView showKeyboard];
//			
//			[_cameraOverlayView submitStep:_previewView];
//			
//			[self _uploadPhotos];
//			
//			
//			int friend_total = 0;
//			if (![[NSUserDefaults standardUserDefaults] objectForKey:@"friend_total"]) {
//				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:friend_total] forKey:@"friend_total"];
//				[[NSUserDefaults standardUserDefaults] synchronize];
//				
//			} else {
//				friend_total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"friend_total"] intValue];
//				[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:++friend_total] forKey:@"friend_total"];
//				[[NSUserDefaults standardUserDefaults] synchronize];
//			}
//		}
//	}
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	NSLog(@"imagePickerControllerDidCancel");
	
	if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
	
	else {
		[self dismissViewControllerAnimated:YES completion:^(void) {
			///[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
			[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:NO completion:nil];
		}];
	}
}


#pragma mark - AlertView Delegates
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 1) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
		
		[[Mixpanel sharedInstance] track:@"Create Volley - Promote Instagram"
							  properties:[NSDictionary dictionaryWithObjectsAndKeys:
										  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
		
		[self performSelector:@selector(_sendToInstagram) withObject:Nil afterDelay:2.0];
	}
	
	[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:^(void) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_ALL_TABS" object:@"Y"];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
	}];
}

- (void)_sendToInstagram {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SEND_TO_INSTAGRAM"
														object:[NSDictionary dictionaryWithObjectsAndKeys:
																[HONAppDelegate instagramShareComment], @"caption",
																[HONImagingDepictor prepImageForSharing:[UIImage imageNamed:@"share_template"]
																							avatarImage:[HONAppDelegate avatarImage]
																							   username:[[HONAppDelegate infoForUser] objectForKey:@"name"]], @"image", nil]];
}


@end