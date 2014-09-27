//
//  HONEnterPINViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 02/28/2014 @ 16:36 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSString+DataTypes.h"

#import "KeychainItemWrapper.h"
#import "MBProgressHUD.h"

#import "HONEnterPINViewController.h"
#import "HONHeaderView.h"

@interface HONEnterPINViewController ()
@property (nonatomic, strong) NSString *pin;
@property (nonatomic, strong) UIButton *pinButton;
@property (nonatomic, strong) UITextField *pinTextField;
@property (nonatomic, strong) UIImageView *pinCheckImageView;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic) int validateCounter;
@property (nonatomic) BOOL isPopping;
@end


@implementation HONEnterPINViewController

- (id)init {
	if ((self = [super init])) {
		_validateCounter = 0;
	}
	
	return (self);
}


#pragma mark - Data Calls
- (void)_generateClub:(HONUserClubVO *)vo {
	[[HONAPICaller sharedInstance] createClubWithTitle:vo.clubName withDescription:vo.blurb withImagePrefix:vo.coverImagePrefix completion:^(NSDictionary *result) {
	}];
}

- (void)_validatePinCode {
	if (_progressHUD == nil)
		_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_loading", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	[[HONAPICaller sharedInstance] validatePhoneNumberForUser:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] usingPINCode:_pin completion:^(NSDictionary *result) {
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
		
		[[HONAnalyticsParams sharedInstance] trackEvent:[NSString stringWithFormat:@"Registration - PIN Validation %@", ([[result objectForKey:@"result"] intValue] == 0) ? @"Failed" : @"Pass"]];
		
		if ([[result objectForKey:@"result"] intValue] == 0) {
			[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"invalid_pin", @"Invalid Pin!")
										message: NSLocalizedString(@"try_again", @"Please try again or press the resend button")
									   delegate:nil
							  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
							  otherButtonTitles:nil] show];
			_pin = @"";
			_pinTextField.text = @"";
			[_pinTextField becomeFirstResponder];
			
//			_pinCheckImageView.image = [UIImage imageNamed:@"xIcon"];
//			_pinCheckImageView.alpha = 1.0;
			
		} else
			[self _finishFirstRun];
	}];
}


#pragma mark - Data Manip
- (void)_finishFirstRun {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Registration - Pass First Run"];
	
//	[[HONAPICaller sharedInstance] retrieveLocalSchoolTypeClubsWithAreaCode:[[HONDeviceIntrinsics sharedInstance] areaCodeFromPhoneNumber] completion:^(NSDictionary *result) {
//		NSMutableArray *schools = [NSMutableArray array];
//		for (NSDictionary *club in [result objectForKey:@"clubs"]) {
//			NSMutableDictionary *dict = [club mutableCopy];
//			[dict setValue:@"HIGH_SCHOOL" forKey:@"club_type"];
//			HONUserClubVO *vo = [HONUserClubVO clubWithDictionary:dict];
//			
//			NSLog(@"vo:[%@]", vo.clubName);
//			[schools addObject:dict];
//		}
//		
//		if ([[NSUserDefaults standardUserDefaults] objectForKey:@"high_schools"] != nil)
//			[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"high_schools"];
//		
//		[[NSUserDefaults standardUserDefaults] setObject:[schools copy] forKey:@"high_schools"];
//		[[NSUserDefaults standardUserDefaults] synchronize];
//	}];
	
	[[[UIApplication sharedApplication] delegate].window.rootViewController dismissViewControllerAnimated:YES completion:^(void) {
		KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier] accessGroup:nil];
		[keychain setObject:@"YES" forKey:CFBridgingRelease(kSecAttrAccount)];
		
		[[HONClubAssistant sharedInstance] copyUserSignupClubToClipboardWithAlert:NO];
		[[NSNotificationCenter defaultCenter] postNotificationName:@"COMPLETED_FIRST_RUN" object:nil];
		
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	}];
}


#pragma mark - View lifecycle
- (void)loadView {
	ViewControllerLog(@"[:|:] [%@ loadView] [:|:]", self.class);
	[super loadView];
	
	HONHeaderView *headerView = [[HONHeaderView alloc] initWithTitleImage:[UIImage imageNamed:@"enterPinTitle"]];
	[self.view addSubview:headerView];
	
	UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	backButton.frame = CGRectMake(-6.0, 2.0, 44.0, 44.0);
	[backButton setBackgroundImage:[UIImage imageNamed:@"StatusBackButton_nonActive"] forState:UIControlStateNormal];
	[backButton setBackgroundImage:[UIImage imageNamed:@"StatusBackButton_Active"] forState:UIControlStateHighlighted];
	[backButton addTarget:self action:@selector(_goBack) forControlEvents:UIControlEventTouchUpInside];
	[headerView addButton:backButton];
		 
	_pinButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_pinButton.frame = CGRectMake(0.0, kNavHeaderHeight, 320.0, 64.0);
	[_pinButton setBackgroundImage:[UIImage imageNamed:@"pinRowBG_normal"] forState:UIControlStateNormal];
	[_pinButton setBackgroundImage:[UIImage imageNamed:@"pinRowBG_normal"] forState:UIControlStateHighlighted];
	[_pinButton setBackgroundImage:[UIImage imageNamed:@"pinRowBG_normal"] forState:UIControlStateSelected];
	[_pinButton setBackgroundImage:[UIImage imageNamed:@"pinRowBG_normal"] forState:(UIControlStateHighlighted|UIControlStateSelected)];
	[self.view addSubview:_pinButton];
	
	_pinTextField = [[UITextField alloc] initWithFrame:CGRectMake(12.0, 82.0, 77.0, 30.0)];
	[_pinTextField setAutocapitalizationType:UITextAutocapitalizationTypeNone];
	[_pinTextField setAutocorrectionType:UITextAutocorrectionTypeNo];
	_pinTextField.keyboardAppearance = UIKeyboardAppearanceDefault;
	[_pinTextField setReturnKeyType:UIReturnKeyDone];
	[_pinTextField setTextColor:[UIColor blackColor]];
	[_pinTextField addTarget:self action:@selector(_onTextEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
	[_pinTextField addTarget:self action:@selector(_onTextEditingDidEndOnExit:) forControlEvents:UIControlEventEditingDidEndOnExit];
	_pinTextField.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontMedium] fontWithSize:18];
	_pinTextField.keyboardType = UIKeyboardTypeDecimalPad;
	_pinTextField.text = @"";
	_pinTextField.delegate = self;
	[self.view addSubview:_pinTextField];
	
	_pinCheckImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"checkmarkIcon"]];
	_pinCheckImageView.frame = CGRectOffset(_pinCheckImageView.frame, 258.0, 65.0);
	_pinCheckImageView.alpha = 0.0;
	[self.view addSubview:_pinCheckImageView];
	
	UIImageView *footerTextImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"pinText"]];
	footerTextImageView.frame = CGRectOffset(footerTextImageView.frame, 0.0, 129.0);
	[self.view addSubview:footerTextImageView];
	
	UIButton *resendButton = [UIButton buttonWithType:UIButtonTypeCustom];
	resendButton.frame = CGRectMake(200.0, 160.0, 55.0, 24.0);
	[resendButton addTarget:self action:@selector(_goResend) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:resendButton];
	
	
#if __APPSTORE_BUILD__ == 0
	UIButton *cheatButton = [UIButton buttonWithType:UIButtonTypeCustom];
	cheatButton.frame = CGRectMake(152.0, kNavHeaderHeight - 8.0, 16.0, 16.0);
	[cheatButton addTarget:self action:@selector(_goCheat) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:cheatButton];
#endif
}

- (void)viewDidLoad {
	ViewControllerLog(@"[:|:] [%@ viewDidLoad] [:|:]", self.class);
	[super viewDidLoad];
}

- (void)viewDidAppear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewDidAppear:%@] [:|:]", self.class, [@"" stringFromBool:animated]);
	[super viewDidAppear:animated];
	
	_isPopping = NO;
	[_pinTextField becomeFirstResponder];
}



#pragma mark - Navigation
- (void)_goBack {
	_pin = @"";
	_isPopping = YES;
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)_goResend {
	[[HONAPICaller sharedInstance] updatePhoneNumberForUserWithCompletion:^(NSDictionary *result) {
		_pinTextField.text = @"";
		[_pinTextField becomeFirstResponder];
	}];
}

- (void)_goCheat {
	_pinTextField.text = @"0000";
	_pin = _pinTextField.text;
	
	_isPopping = YES;
	[self _finishFirstRun];
}

#pragma mark - Notifications
- (void)_textFieldTextDidChangeChange:(NSNotification *)notification {
	_pinCheckImageView.image = [UIImage imageNamed:@"checkmarkIcon"];
//	_pinCheckImageView.alpha = (int)([_pinTextField.text length] == 4);
	
	if ([_pinTextField.text length] == 4) {
//		_pin = _pinTextField.text;
		[_pinTextField resignFirstResponder];
	}
}


#pragma mark - TextField Delegates
-(void)textFieldDidBeginEditing:(UITextField *)textField {
	[_pinButton setSelected:YES];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(_textFieldTextDidChangeChange:)
												 name:UITextFieldTextDidChangeNotification
											   object:textField];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return (YES);
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return (!([textField.text length] > 3 && [string length] > range.length));
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
	[textField resignFirstResponder];
	[_pinButton setSelected:NO];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:@"UITextFieldTextDidChangeNotification"
												  object:textField];
	_pin = _pinTextField.text;
	
	if (!_isPopping) {
		if ([_pin length] < 4) {
			[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"invalid_pin", @"Invalid Pin!")
										message:NSLocalizedString(@"invalid_pin_msg", @"Pin numbers need to be 4 numbers")
									   delegate:nil
							  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
							  otherButtonTitles:nil] show];
			_pin = @"";
			_pinTextField.text = @"";
			[_pinTextField becomeFirstResponder];
			
		} else
			[self _validatePinCode];
	}
}

- (void)_onTextEditingDidEnd:(id)sender {
	_pin = _pinTextField.text;
}

- (void)_onTextEditingDidEndOnExit:(id)sender {
}

@end
