//
//  HONRegisterViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 03.02.13.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import <AWSiOSSDK/S3/AmazonS3Client.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "MBProgressHUD.h"
#import "UIImage+fixOrientation.h"
#import "UIImageView+AFNetworking.h"

#import "HONRegisterViewController.h"
#import "HONHeaderView.h"
#import "HONRegisterCameraViewController.h"
#import "HONImagingDepictor.h"


@interface HONRegisterViewController () <AmazonServiceRequestDelegate>
@property (nonatomic, strong) UIImagePickerController *previewPicker;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) HONHeaderView *headerView;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *email;
@property (nonatomic, strong) UIView *plCameraIrisAnimationView;  // view that animates the opening/closing of the iris
@property (nonatomic, strong) UIImageView *cameraIrisImageView;  // static image of the closed iris
@property (nonatomic, strong) UIView *usernameHolderView;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UILabel *usernameLabel;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, retain) UIButton *submitButton;
@property (nonatomic, retain) UIButton *usernameButton;
@property (nonatomic, retain) UIButton *emailButton;
@property (nonatomic, retain) UIButton *birthdayButton;
@property (nonatomic, strong) UIView *tutorialHolderView;
@property (nonatomic, strong) UIDatePicker *datePicker;
@property (nonatomic, strong) UILabel *birthdayLabel;
@property (nonatomic, strong) NSString *birthday;
@property (nonatomic, strong) NSTimer *clockTimer;
@property (nonatomic, strong) UIView *cameraOverlayView;

@property (nonatomic) int uploadCounter;
@property (nonatomic) BOOL isFirstAppearance;
@end

@implementation HONRegisterViewController

- (id)init {
	if ((self = [super init])) {
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didShowViewController:) name:@"UINavigationControllerDidShowViewControllerNotification" object:nil];
		_username = [[HONAppDelegate infoForUser] objectForKey:@"name"];
		
		[[Mixpanel sharedInstance] track:@"Register - Show"
							  properties:[NSDictionary dictionaryWithObjectsAndKeys:
										  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
		
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
- (void)_uploadPhoto:(UIImage *)image {
	AmazonS3Client *s3 = [[AmazonS3Client alloc] initWithAccessKey:[[HONAppDelegate s3Credentials] objectForKey:@"key"] withSecretKey:[[HONAppDelegate s3Credentials] objectForKey:@"secret"]];
	
	_uploadCounter = 0;
	_filename = [NSString stringWithFormat:@"%@-%d",[HONAppDelegate deviceToken], (int)[[NSDate date] timeIntervalSince1970]];
	NSLog(@"FILENAME: %@/%@", [HONAppDelegate s3BucketForType:@"avatars"], _filename);
	
	@try {
		float avatarSize = kSnapLargeDim;
		CGSize ratio = CGSizeMake(image.size.width / image.size.height, image.size.height / image.size.width);
		
		UIImage *oImage = image;
		UIImage *lImage = [HONImagingDepictor cropImage:[HONImagingDepictor scaleImage:image toSize:CGSizeMake(640.0, 854.0)] toRect:CGRectMake(0.0, 202.0, 640.0, 450.0)];
		UIImage *tImage = (ratio.height >= 1.0) ? [HONImagingDepictor scaleImage:image toSize:CGSizeMake(avatarSize, avatarSize * ratio.height)] : [HONImagingDepictor scaleImage:image toSize:CGSizeMake(avatarSize * ratio.width, avatarSize)];
		tImage = [HONImagingDepictor cropImage:tImage toRect:CGRectMake(0.0, 0.0, avatarSize, avatarSize)];
		
		[s3 createBucket:[[S3CreateBucketRequest alloc] initWithName:@"hotornot-avatars"]];
		
		S3PutObjectRequest *por1 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@.jpg", _filename] inBucket:@"hotornot-avatars"];
		por1.contentType = @"image/jpeg";
		por1.data = UIImageJPEGRepresentation(tImage, kSnapJPEGCompress);
		por1.delegate = self;
		[s3 putObject:por1];
		
		S3PutObjectRequest *por2 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@_l.jpg", _filename] inBucket:@"hotornot-avatars"];
		por2.contentType = @"image/jpeg";
		por2.data = UIImageJPEGRepresentation(lImage, kSnapJPEGCompress);
		por2.delegate = self;
		[s3 putObject:por2];
		
		S3PutObjectRequest *por3 = [[S3PutObjectRequest alloc] initWithKey:[NSString stringWithFormat:@"%@_o.jpg", _filename] inBucket:@"hotornot-avatars"];
		por3.contentType = @"image/jpeg";
		por3.data = UIImageJPEGRepresentation(oImage, kSnapJPEGCompress);
		por3.delegate = self;
		[s3 putObject:por3];
		
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

/*
- (void)_submitUsername {
	if ([[_username substringToIndex:1] isEqualToString:@"@"])
		_username = [_username substringFromIndex:1];
	
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 7], @"action",
									[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
									_username, @"username",
									nil];
	
	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_checkUsername", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	VolleyJSONLog(@"%@ —/> (%@/%@?action=%@)", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [params objectForKey:@"action"]);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:kAPIUsers parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_updateFail", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			NSDictionary *userResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			VolleyJSONLog(@"AFNetworking [-] %@: %@", [[self class] description], userResult);
			
			if (![[userResult objectForKey:@"result"] isEqualToString:@"fail"]) {
				[_progressHUD hide:YES];
				_progressHUD = nil;
				
				[HONAppDelegate writeUserInfo:userResult];
				[self _presentCamera];
				
			} else {
				if (_progressHUD == nil)
					_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
				_progressHUD.minShowTime = kHUDTime;
				_progressHUD.mode = MBProgressHUDModeCustomView;
				_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
				_progressHUD.labelText = NSLocalizedString(@"hud_usernameTaken", nil);
				[_progressHUD show:NO];
				[_progressHUD hide:YES afterDelay:1.5];
				_progressHUD = nil;
				
				[_usernameTextField becomeFirstResponder];
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description],[HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
		
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
}*/

- (void)_finalizeUser {
	if ([[_username substringToIndex:1] isEqualToString:@"@"])
		_username = [_username substringFromIndex:1];
	
	_filename = ([[[HONAppDelegate infoForUser] objectForKey:@"token"] isEqualToString:@"0000000000000000000000000000000000000000000000000000000000000000"]) ? @"https://graph.facebook.com/1149169958/picture?type=square" : [NSString stringWithFormat:@"%@/%@.jpg", [HONAppDelegate s3BucketForType:@"avatars"], _filename];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"%d", 9], @"action",
							[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
							_username, @"username",
							_email, @"password",
							_birthday, @"age",
							_filename, @"imgURL",
							nil];
	
	//NSLog(@"PARAMS:[%@]", params);
	NSMutableString *avatarURL = [_filename mutableCopy];
	[avatarURL replaceOccurrencesOfString:@".jpg" withString:@"_o.jpg" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [avatarURL length])];
	[avatarURL replaceOccurrencesOfString:@".png" withString:@"_o.png" options:NSCaseInsensitiveSearch range:NSMakeRange(0, [avatarURL length])];
	[HONImagingDepictor writeImageFromWeb:avatarURL withDimensions:CGSizeMake(480.0, 640.0) withUserDefaultsKey:@"avatar_image"];
	
	VolleyJSONLog(@"%@ —/> (%@/%@)", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsersFirstRunComplete);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:kAPIUsersFirstRunComplete parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_updateFail", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			NSDictionary *userResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			VolleyJSONLog(@"AFNetworking [-] %@: %@", [[self class] description], userResult);
			
			if (![[userResult objectForKey:@"result"] isEqualToString:@"fail"]) {
				if (_progressHUD != nil) {
					[_progressHUD hide:YES];
					_progressHUD = nil;
				}
				
				[HONAppDelegate writeUserInfo:userResult];
				[TestFlight passCheckpoint:@"PASSED REGISTRATION"];
				
				[[Mixpanel sharedInstance] track:@"Register - Pass Fist Run"
									  properties:[NSDictionary dictionaryWithObjectsAndKeys:
												  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
				
				[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"passed_registration"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				
				[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:^(void) {
					[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_PROFILE" object:nil];
				}];
				
				
			} else {
				if (_progressHUD == nil)
					_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
				_progressHUD.minShowTime = kHUDTime;
				_progressHUD.mode = MBProgressHUDModeCustomView;
				_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
				_progressHUD.labelText = NSLocalizedString(@"hud_usernameTaken", nil);
				[_progressHUD show:NO];
				[_progressHUD hide:YES afterDelay:1.5];
				_progressHUD = nil;
				
				[_usernameTextField becomeFirstResponder];
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@ ) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
		
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


#pragma mark - View Lifecycle
- (void)loadView {
	[super loadView];
	
	self.view.backgroundColor = [UIColor whiteColor];
	
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	
	_headerView = [[HONHeaderView alloc] initAsModalWithTitle:@""];
	_headerView.frame = CGRectOffset(_headerView.frame, 0.0, -20.0);
	_headerView.backgroundColor = [UIColor blackColor];
	[_headerView hideRefreshing];
	[self.view addSubview:_headerView];
	
	UILabel *headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(60.0, 48.0, 200.0, 24.0)];
	headerTitleLabel.backgroundColor = [UIColor clearColor];
	headerTitleLabel.font = [[HONAppDelegate helveticaNeueFontMedium] fontWithSize:19];
	headerTitleLabel.textColor = [UIColor whiteColor];
	headerTitleLabel.textAlignment = NSTextAlignmentCenter;
	headerTitleLabel.text = @"Register for Volley";
	[_headerView addSubview:headerTitleLabel];
	
	_usernameHolderView = [[UIView alloc] initWithFrame:CGRectMake(0.0, -[UIScreen mainScreen].bounds.size.height, 320.0, [UIScreen mainScreen].bounds.size.height)];
	[self.view addSubview:_usernameHolderView];
	
	_usernameButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_usernameButton.frame = CGRectMake(0.0, 44.0, 320.0, 64.0);
	[_usernameButton setBackgroundImage:[UIImage imageNamed:@"registerSelected"] forState:UIControlStateSelected];
	[_usernameButton addTarget:self action:@selector(_goUsername) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_usernameButton];
	
	_usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 65.0, 308.0, 26.0)];
	_usernameLabel.font = [[HONAppDelegate helveticaNeueFontMedium] fontWithSize:18];
	_usernameLabel.textColor = [HONAppDelegate honGrey710Color];
	_usernameLabel.backgroundColor = [UIColor clearColor];
	_usernameLabel.text = @"Enter username";
	[self.view addSubview:_usernameLabel];
	
	_usernameTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 65.0, 308.0, 30.0)];
	//[_usernameTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[_usernameTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[_usernameTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
	_usernameTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
	[_usernameTextField setReturnKeyType:UIReturnKeyDone];
	[_usernameTextField setTextColor:[UIColor blackColor]];
	[_usernameTextField addTarget:self action:@selector(_onTextEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
	[_usernameTextField addTarget:self action:@selector(_onTextEditingDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
	_usernameTextField.font = [[HONAppDelegate helveticaNeueFontMedium] fontWithSize:18];
	_usernameTextField.keyboardType = UIKeyboardTypeAlphabet;
	_usernameTextField.text = @"";
	[_usernameTextField setTag:0];
	_usernameTextField.delegate = self;
	[self.view addSubview:_usernameTextField];
	
	UIImageView *divider1ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"firstRunDivider"]];
	divider1ImageView.frame = CGRectOffset(divider1ImageView.frame, 0.0, 108.0);
	[self.view addSubview:divider1ImageView];
	
	_emailButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_emailButton.frame = CGRectMake(0.0, 109.0, 320.0, 64.0);
	[_emailButton setBackgroundImage:[UIImage imageNamed:@"registerSelected"] forState:UIControlStateSelected];
	[_emailButton addTarget:self action:@selector(_goEmail) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_emailButton];
	
	_emailTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 131.0, 230.0, 30.0)];
	//[_usernameTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	[_emailTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[_emailTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
	_emailTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
	[_emailTextField setReturnKeyType:UIReturnKeyDone];
	[_emailTextField setTextColor:[UIColor blackColor]];
	[_emailTextField addTarget:self action:@selector(_onTextEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
	[_emailTextField addTarget:self action:@selector(_onTextEditingDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
	_emailTextField.font = [[HONAppDelegate helveticaNeueFontMedium] fontWithSize:18];
	_emailTextField.keyboardType = UIKeyboardTypeAlphabet;
	_emailTextField.placeholder = @"Enter email";
	_emailTextField.text = @"";
	[_emailTextField setTag:1];
	_emailTextField.delegate = self;
	[self.view addSubview:_emailTextField];
	
	UIImageView *divider2ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"firstRunDivider"]];
	divider2ImageView.frame = CGRectOffset(divider2ImageView.frame, 0.0, 173.0);
	[self.view addSubview:divider2ImageView];
	
	_birthdayLabel = [[UILabel alloc] initWithFrame:CGRectMake(12.0, 191.0, 296.0, 30.0)];
	_birthdayLabel.font = [[HONAppDelegate helveticaNeueFontMedium] fontWithSize:18];
	_birthdayLabel.textColor = [HONAppDelegate honGrey710Color];
	_birthdayLabel.backgroundColor = [UIColor clearColor];
	_birthdayLabel.text = @"What is your birthday?";
	[self.view addSubview:_birthdayLabel];
	
	_birthdayButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_birthdayButton.frame = CGRectMake(0.0, 174.0, 320.0, 64.0);
	[_birthdayButton setBackgroundImage:[UIImage imageNamed:@"registerSelected"] forState:UIControlStateSelected];
	[_birthdayButton addTarget:self action:@selector(_goPicker) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_birthdayButton];
	
	UIImageView *divider3ImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"firstRunDivider"]];
	divider3ImageView.frame = CGRectOffset(divider3ImageView.frame, 0.0, 238.0);
	[self.view addSubview:divider3ImageView];
	
	_submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_submitButton.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 53.0, 320.0, 53.0);
	[_submitButton setBackgroundImage:[UIImage imageNamed:@"submitUsernameButton_nonActive"] forState:UIControlStateNormal];
	[_submitButton setBackgroundImage:[UIImage imageNamed:@"submitUsernameButton_Active"] forState:UIControlStateHighlighted];
	[_submitButton addTarget:self action:@selector(_goSubmit) forControlEvents:UIControlEventTouchUpInside];
	_submitButton.hidden = YES;
	[self.view addSubview:_submitButton];
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd"];
	
	NSDateFormatter *dateFormat2 = [[NSDateFormatter alloc] init];
	[dateFormat2 setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	
	_datePicker = [[UIDatePicker alloc] initWithFrame:CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height, 320.0, 216.0)];
	_datePicker.date = [dateFormat2 dateFromString:[[HONAppDelegate infoForUser] objectForKey:@"age"]];
	_datePicker.datePickerMode = UIDatePickerModeDate;
	_datePicker.minimumDate = [dateFormat dateFromString:@"1970-01-01"];
	_datePicker.maximumDate = [NSDate date];
	[_datePicker addTarget:self action:@selector(_pickerValueChanged) forControlEvents:UIControlEventValueChanged];
	[self.view addSubview:_datePicker];
	_birthday = [[HONAppDelegate infoForUser] objectForKey:@"age"];
	
	_tutorialHolderView = [[UIView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_tutorialHolderView.backgroundColor = [UIColor blackColor];
	[self.view addSubview:_tutorialHolderView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	if (_isFirstAppearance) {
		_isFirstAppearance = NO;
		
		if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
			UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
			imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
			imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
			imagePickerController.delegate = self;
		
			imagePickerController.showsCameraControls = NO;
			imagePickerController.cameraViewTransform = CGAffineTransformScale(imagePickerController.cameraViewTransform, ([HONAppDelegate isRetina5]) ? 1.65f : 1.25f, ([HONAppDelegate isRetina5]) ? 1.65f : 1.25f);
			imagePickerController.cameraDevice = ([UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront]) ? UIImagePickerControllerCameraDeviceFront : UIImagePickerControllerCameraDeviceRear;
			
			_cameraOverlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, [UIScreen mainScreen].bounds.size.height * 2.0)];
			UIButton *signupButton = [UIButton buttonWithType:UIButtonTypeCustom];
			signupButton.frame = CGRectMake(53.0, [UIScreen mainScreen].bounds.size.height - 129.0, 214.0, 49.0);
			[signupButton setBackgroundImage:[UIImage imageNamed:@"signUpButton_nonActive"] forState:UIControlStateNormal];
			[signupButton setBackgroundImage:[UIImage imageNamed:@"signUpButton_Active"] forState:UIControlStateHighlighted];
			[signupButton addTarget:self action:@selector(_goProfileCamera) forControlEvents:UIControlEventTouchUpInside];
			[_cameraOverlayView addSubview:signupButton];
			
			UIButton *takePhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
			takePhotoButton.frame = CGRectMake(113.0, ([UIScreen mainScreen].bounds.size.height * 2.0) - 114.0, 94.0, 94.0);
			[takePhotoButton setBackgroundImage:[UIImage imageNamed:@"cameraButton_nonActive"] forState:UIControlStateNormal];
			[takePhotoButton setBackgroundImage:[UIImage imageNamed:@"cameraButton_Active"] forState:UIControlStateHighlighted];
			[takePhotoButton addTarget:self action:@selector(_goTakePhoto) forControlEvents:UIControlEventTouchUpInside];
			[_cameraOverlayView addSubview:takePhotoButton];
			imagePickerController.cameraOverlayView = _cameraOverlayView;
		
			self.previewPicker = imagePickerController;
			[self presentViewController:self.previewPicker animated:NO completion:nil];
		
		} else {
			UIImageView *page1ImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 0.0, 320.0, _tutorialHolderView.frame.size.height)];
			page1ImageView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"fue_dynamicImage_A-568h@2x" : @"fue_dynamicImage_A"];
			page1ImageView.userInteractionEnabled = YES;
			page1ImageView.backgroundColor = [UIColor whiteColor];
			[_tutorialHolderView addSubview:page1ImageView];
			
			UIButton *closeTutorialButton = [UIButton buttonWithType:UIButtonTypeCustom];
			closeTutorialButton.frame = CGRectMake(53.0, 371.0, 214.0, 49.0);
			[closeTutorialButton setBackgroundImage:[UIImage imageNamed:@"signUpButton_nonActive"] forState:UIControlStateNormal];
			[closeTutorialButton setBackgroundImage:[UIImage imageNamed:@"signUpButton_Active"] forState:UIControlStateHighlighted];
			[closeTutorialButton addTarget:self action:@selector(_goCloseTutorial) forControlEvents:UIControlEventTouchUpInside];
			[_tutorialHolderView addSubview:closeTutorialButton];
		}
	}
}


#pragma mark - Navigation
- (void)_goProfileCamera {
	[UIView animateWithDuration:0.33 animations:^(void) {
		_cameraOverlayView.frame = CGRectOffset(_cameraOverlayView.frame, 0.0, -self.view.frame.size.height);
	}];
}

- (void)_goTakePhoto {
	[self.previewPicker takePicture];
	_tutorialHolderView.frame = CGRectOffset(_tutorialHolderView.frame, 0.0, [UIScreen mainScreen].bounds.size.height);
	
	[_usernameTextField becomeFirstResponder];
	[_usernameButton setSelected:YES];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelay:0.33];
	_usernameHolderView.frame = CGRectOffset(_usernameHolderView.frame, 0.0, [UIScreen mainScreen].bounds.size.height);
	[UIView commitAnimations];
}

- (void)_goCloseTutorial {
	[[Mixpanel sharedInstance] track:@"Register - Close Splash"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[self.previewPicker dismissViewControllerAnimated:NO completion:^(void) {}];
	
	[_usernameTextField becomeFirstResponder];
	[_usernameButton setSelected:YES];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelay:0.33];
	_tutorialHolderView.frame = CGRectOffset(_tutorialHolderView.frame, 0.0, [UIScreen mainScreen].bounds.size.height);
	[UIView commitAnimations];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.5];
	[UIView setAnimationDelay:0.33];
	_usernameHolderView.frame = CGRectOffset(_usernameHolderView.frame, 0.0, [UIScreen mainScreen].bounds.size.height);
	[UIView commitAnimations];
}

- (void)_goUsername {
	[_usernameTextField becomeFirstResponder];
}

- (void)_goEmail {
	[_emailTextField becomeFirstResponder];
}

- (void)_goPicker {
	[_usernameButton setSelected:NO];
	[_emailButton setSelected:NO];
	[_birthdayButton setSelected:YES];
	[_usernameTextField resignFirstResponder];
	[_emailTextField resignFirstResponder];
	
	_submitButton.hidden = NO;
	[UIView animateWithDuration:0.25 animations:^(void) {
		_submitButton.frame = CGRectMake(0.0, ([UIScreen mainScreen].bounds.size.height - 216.0) - _submitButton.frame.size.height, _submitButton.frame.size.width, _submitButton.frame.size.height);
		_datePicker.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 216.0, 320.0, 216.0);
	} completion:^(BOOL finished) {
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateStyle:NSDateFormatterLongStyle];
		[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
		_birthdayLabel.text = [dateFormatter stringFromDate:_datePicker.date];
	}];
}

- (void)_goSubmit {
	if ([_usernameTextField.text isEqualToString:@""] || [_usernameTextField.text isEqualToString:@"@"]) {
		[[[UIAlertView alloc] initWithTitle:@"No Username!"
									message:@"You need to enter a username to start snapping"
								   delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil] show];
		[_usernameTextField becomeFirstResponder];
	
	} else {
		if ([[NSDate date] timeIntervalSinceDate:_datePicker.date] > ((60 * 60 * 24) * 365) * 20) {
			[[[UIAlertView alloc] initWithTitle:@""
										message:@"Volley is intended for young adults 13-19, you may get flagged by the userbase."
									   delegate:nil
							  cancelButtonTitle:@"OK"
							  otherButtonTitles:nil] show];
			
			[self _finalizeUser];
		
		} else {
			if ([_emailTextField.text length] == 0) {
				[[[UIAlertView alloc] initWithTitle:@"No Password!"
											message:@"You need to enter a password to start snapping"
										   delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
				[_emailTextField becomeFirstResponder];
			
			} else
				[self _finalizeUser];
		}
	}
}

#pragma mark - UI Presentation
- (void)_presentCamera {
	[self.navigationController pushViewController:[[HONRegisterCameraViewController alloc] initWithPassword:_email andBirthday:_birthday] animated:NO];
}

- (void)_pickerValueChanged {
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterLongStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	_birthdayLabel.text = [dateFormatter stringFromDate:_datePicker.date];
	
	NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
	[dateFormat setDateFormat:@"yyyy-MM-dd"];
	_birthday = [dateFormat stringFromDate:_datePicker.date];
	
	
	//NSLog(@"DIFF:[%f]", [[NSDate date] timeIntervalSinceDate:_datePicker.date]);
}


#pragma mark - ImagePicker Delegates
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
	NSLog(@"imagePickerController:didFinishPickingMediaWithInfo");
	
	UIImage *image = [[info objectForKey:UIImagePickerControllerOriginalImage] fixOrientation];
	[self _uploadPhoto:image];
	
	[self dismissViewControllerAnimated:YES completion:^(void) {
	}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
	NSLog(@"imagePickerControllerDidCancel");
	
	[self dismissViewControllerAnimated:YES completion:^(void) {
		[TestFlight passCheckpoint:@"PASSED REGISTRATION"];
		
		[[Mixpanel sharedInstance] track:@"Register - Pass Fist Run"
							  properties:[NSDictionary dictionaryWithObjectsAndKeys:
										  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
		
		[[NSUserDefaults standardUserDefaults] setObject:@"YES" forKey:@"passed_registration"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:^(void) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_PROFILE" object:nil];
		}];
	}];
}


#pragma mark - TextField Delegates
-(void)textFieldDidBeginEditing:(UITextField *)textField {
	if (textField.tag == 0) {
		[_usernameButton setSelected:YES];
		[_emailButton setSelected:NO];
		[_birthdayButton setSelected:NO];
	
	} else {
		[_usernameButton setSelected:NO];
		[_emailButton setSelected:YES];
		[_birthdayButton setSelected:NO];
	}
	
	[UIView animateWithDuration:0.25 animations:^(void) {
		_datePicker.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height, 320.0, 216.0);
		_submitButton.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - _submitButton.frame.size.height, _submitButton.frame.size.width, _submitButton.frame.size.height);
	} completion:^(BOOL finished) {
		_submitButton.hidden = YES;
	}];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return (YES);
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	if (textField.tag == 0) {
		if ([textField.text isEqualToString:@""])
			textField.text = @"@";
		
		_usernameLabel.hidden = (textField.tag == 0);
	}
	
	return (YES);
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
	[textField resignFirstResponder];
	
	_usernameLabel.hidden = ([_usernameTextField.text length] > 0);
	
	_submitButton.hidden = NO;
	[UIView animateWithDuration:0.25 animations:^(void) {
		_submitButton.frame = CGRectMake(0.0, ([UIScreen mainScreen].bounds.size.height - 216.0) - _submitButton.frame.size.height, _submitButton.frame.size.width, _submitButton.frame.size.height);
		_datePicker.frame = CGRectMake(0.0, [UIScreen mainScreen].bounds.size.height - 216.0, 320.0, 216.0);
	} completion:^(BOOL finished) {
	}];
}

- (void)_onTextEditingDidEnd:(id)sender {
	_username = ([_usernameTextField.text length] > 0 && [[_usernameTextField.text substringToIndex:1] isEqualToString:@"@"]) ? [_usernameTextField.text substringFromIndex:1] : _usernameTextField.text;
	_email = _emailTextField.text;
}

- (void)_onTextEditingDidEndOnExit:(id)sender {
}


#pragma mark - AWS Delegates
- (void)request:(AmazonServiceRequest *)request didCompleteWithResponse:(AmazonServiceResponse *)response {
	//NSLog(@"\nAWS didCompleteWithResponse:\n%@", response);
	
	_uploadCounter++;
	if (_uploadCounter == 3) {
		[_progressHUD hide:YES];
		_progressHUD = nil;
	}
}

- (void)request:(AmazonServiceRequest *)request didFailWithError:(NSError *)error {
	NSLog(@"AWS didFailWithError:\n%@", error);
}
@end
