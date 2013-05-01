//
//  HONAppDelegate.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <KiipSDK/KiipSDK.h>
#import <Parse/Parse.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "AFJSONRequestOperation.h"
#import "UAirship.h"
#import "UAPush.h"
#import "HONAppDelegate.h"
#import "Parse/Parse.h"
#import "Mixpanel.h"
#import "MBProgressHUD.h"
#import "Reachability.h"
#import "TapForTap.h"
#import "Chartboost.h"

#import "HONTabBarController.h"
#import "HONChallengesViewController.h"
#import "HONTimelineViewController.h"
#import "HONDiscoveryViewController.h"
#import "HONImagePickerViewController.h"
#import "HONProfileViewController.h"
#import "HONLoginViewController.h"
#import "HONChallengeVO.h"
#import "HONUsernameViewController.h"
#import "HONWebCTAViewController.h"
#import "HONInviteFriendsViewController.h"
#import "HONSearchViewController.h"

NSString *const HONSessionStateChangedNotification = @"com.builtinmenlo.hotornot:HONSessionStateChangedNotification";
NSString *const FacebookAppID = @"529054720443694";

@interface HONAppDelegate() <UIAlertViewDelegate, KiipDelegate>
@property (nonatomic, strong) AVAudioPlayer *mp3Player;
@property (nonatomic) BOOL isFromBackground;
@property (nonatomic, strong) UIImageView *bgImgView;
@property(nonatomic, strong) MBProgressHUD *progressHUD;
@property(nonatomic, strong) HONSearchViewController *searchViewController;
- (void)_registerUser;
@end

@implementation HONAppDelegate

@synthesize window = _window;
@synthesize tabBarController = _tabBarController;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize client = _client;

+ (NSString *)apiServerPath {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"server_api"]);
}

+ (NSString *)dailySubjectName {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"daily_challenge"]);
}

+ (NSDictionary *)s3Credentials {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"s3_creds"]);
}

+ (NSString *)facebookCanvasURL {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"facebook_url"]);
}

+ (NSDictionary *)facebookFriendPosting {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"fb_network"]);
}

+ (BOOL)isInviteCodeValid:(NSString *)code {
	
	for (NSString *validCode in [[NSUserDefaults standardUserDefaults] objectForKey:@"invite_codes"]) {
		if ([code isEqualToString:validCode])
			return (YES);
	}
	
	return (NO);
}

+ (NSString *)smsInviteFormat {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"invite_sms"]);
}
+ (NSString *)emailInviteFormat {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"invite_email"]);
}

+ (int)createPointMultiplier {
	return ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"point_mult"] objectAtIndex:2] intValue]);
}
+ (int)votePointMultiplier {
	return ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"point_mult"] objectAtIndex:0] intValue]);
}
+ (int)pokePointMultiplier {
	return ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"point_mult"] objectAtIndex:1] intValue]);
}

+ (BOOL)isCharboostEnabled {
	return ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"ad_networks"] objectForKey:@"chartboost"] isEqualToString:@"Y"]);
}

+ (BOOL)isKiipEnabled {
	return ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"ad_networks"] objectForKey:@"kiip"] isEqualToString:@"Y"]);
}

+ (BOOL)isTapForTapEnabled {
	return ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"ad_networks"] objectForKey:@"tapfortap"] isEqualToString:@"Y"]);
}

+ (NSString *)rndDefaultSubject {
	NSArray *subjects = [[NSUserDefaults standardUserDefaults] objectForKey:@"default_subjects"];
	return ([subjects objectAtIndex:(arc4random() % [subjects count])]);
}

+ (BOOL)isLocaleEnabled {
	//return (NO);
	
	if ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"enabled_locales"] objectAtIndex:0] isEqualToString:@""])
		return (YES);
	
	for (NSString *locale in [[NSUserDefaults standardUserDefaults] objectForKey:@"enabled_locales"]) {
		if ([[[NSLocale preferredLanguages] objectAtIndex:0] isEqualToString:locale]) {
			return (YES);
		}
	}
	
	return (NO);
}

+ (NSArray *)searchSubjects {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"search_subjects"]);
}

+ (NSArray *)searchUsers {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"search_users"]);
}

+ (void)writeDeviceToken:(NSString *)token {
	[[NSUserDefaults standardUserDefaults] setObject:token forKey:@"device_token"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString *)deviceToken {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"device_token"]);
}

+ (void)writeUserInfo:(NSDictionary *)userInfo {
	[[NSUserDefaults standardUserDefaults] setObject:userInfo forKey:@"user_info"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *)infoForUser {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"user_info"]);
}

+ (void)writeFBProfile:(NSDictionary *)profile {
	if (profile != nil)
		[[NSUserDefaults standardUserDefaults] setObject:profile forKey:@"fb_profile"];
	
	else
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"fb_profile"];
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSDictionary *)fbProfileForUser {
	return ([[NSUserDefaults standardUserDefaults] objectForKey:@"fb_profile"]);
}

+ (void)setAllowsFBPosting:(BOOL)canPost {
	[[NSUserDefaults standardUserDefaults] setObject:(canPost) ? @"YES" : @"NO" forKey:@"fb_posting"];	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

+ (BOOL)allowsFBPosting {
	return ([[[NSUserDefaults standardUserDefaults] objectForKey:@"fb_posting"] isEqualToString:@"YES"]);
}

+ (int)hasVoted:(int)challengeID {
	NSArray *voteArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"votes"];
	
	for (NSNumber *cID in voteArray) {
		if ([cID intValue] == challengeID || -[cID intValue] == challengeID) {
			return ([cID intValue]);
		}
	}
	
	return (0);
}

+ (void)setVote:(int)challengeID forCreator:(BOOL)isCreator {
	NSMutableArray *voteArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"votes"] mutableCopy];
	[voteArray addObject:[NSNumber numberWithInt:(isCreator) ? challengeID : -challengeID]];
	
	[[NSUserDefaults standardUserDefaults] setObject:voteArray forKey:@"votes"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}


+ (UIViewController *)appTabBarController {
	return ([[UIApplication sharedApplication] keyWindow].rootViewController);
}

+ (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
	UIGraphicsBeginImageContext(size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.0, size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), image.CGImage);
	
	UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return (scaledImage);
}


+ (UIImage *)scaleImage:(UIImage *)image byFactor:(float)factor {
	CGSize size = CGSizeMake(image.size.width * factor, image.size.height * factor);
	
	UIGraphicsBeginImageContext(size);
	
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextTranslateCTM(context, 0.0, size.height);
	CGContextScaleCTM(context, 1.0, -1.0);
	CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, size.width, size.height), image.CGImage);
	
	UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	
	return (scaledImage);
}

+ (UIImage *)cropImage:(UIImage *)image toRect:(CGRect)rect {
	CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
	
	UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
	CGImageRelease(imageRef);
	
	return (croppedImage);
}

+ (UIImage *)editImage:(UIImage *)image toSize:(CGSize)size thenCrop:(CGRect)rect {
	CGContextRef                context;
	CGImageRef                  imageRef;
	CGSize                      inputSize;
	UIImage                     *outputImage = nil;
	CGFloat                     scaleFactor, width;
	
	
	// resize, maintaining aspect ratio:
	inputSize = image.size;
	scaleFactor = size.height / inputSize.height;
	width = roundf(inputSize.width * scaleFactor);
	
	if (width > size.width) {
		scaleFactor = size.width / inputSize.width;
		size.height = roundf(inputSize.height * scaleFactor);
		
	} else {
		size.width = width;
	}
	
	UIGraphicsBeginImageContext(size);
	
	context = UIGraphicsGetCurrentContext();
	CGContextDrawImage(context, CGRectMake(0.0, 0.0, size.width, size.height), image.CGImage);
	outputImage = UIGraphicsGetImageFromCurrentImageContext();
	
	UIGraphicsEndImageContext();
	
	inputSize = size;
	
	// constrain crop rect to legitimate bounds
	if (rect.origin.x >= inputSize.width || rect.origin.y >= inputSize.height) return (outputImage);
	if (rect.origin.x + rect.size.width >= inputSize.width) rect.size.width = inputSize.width - rect.origin.x;
	if (rect.origin.y + rect.size.height >= inputSize.height) rect.size.height = inputSize.height - rect.origin.y;
	
	// crop
	if ((imageRef = CGImageCreateWithImageInRect(outputImage.CGImage, rect))) {
		outputImage = [[UIImage alloc] initWithCGImage: imageRef];
		CGImageRelease(imageRef);
	}
	
	return (outputImage);
}

+ (NSArray *)fbPermissions {
	return ([NSArray arrayWithObjects:@"publish_actions", @"publish_stream", nil]); //@"status_update",
}

+ (BOOL)isRetina5 {
	return ([UIScreen mainScreen].scale == 2.f && [UIScreen mainScreen].bounds.size.height == 568.0f);
}

+ (BOOL)hasNetwork {
	//Reachability *wifiReachability = [Reachability reachabilityForLocalWiFi];
	//[[Reachability reachabilityForLocalWiFi] startNotifier];
	
	//return ([wifiReachability currentReachabilityStatus] == kReachableViaWiFi);
	
	[[Reachability reachabilityForInternetConnection] startNotifier];
	NetworkStatus networkStatus = [[Reachability reachabilityForInternetConnection] currentReachabilityStatus];
	
	return !(networkStatus == NotReachable);
}

+ (BOOL)canPingAPIServer {
	return (!([[Reachability reachabilityWithHostName:[[[HONAppDelegate apiServerPath] componentsSeparatedByString: @"/"] objectAtIndex:2]] currentReachabilityStatus] == NotReachable));
}

+ (BOOL)canPingParseServer {
	return (!([[Reachability reachabilityWithHostName:@"api.parse.com"] currentReachabilityStatus] == NotReachable));
}

+ (BOOL)audioMuted {
	return ([[[NSUserDefaults standardUserDefaults] objectForKey:@"audio_muted"] isEqualToString:@"YES"]);
}

+ (NSString *)deviceLocale {
	return ([[NSLocale preferredLanguages] objectAtIndex:0]);
}

+ (NSString *)timeSinceDate:(NSDate *)date {
	NSString *timeSince = @"";
	
	NSDateFormatter *utcFormatter = [[NSDateFormatter alloc] init];
	[utcFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
	[utcFormatter setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
	
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy-MM-ddHH:mm:ss"];
	NSDate *utcDate = [dateFormatter dateFromString:[utcFormatter stringFromDate:[NSDate new]]];
	
	int secs = [[utcDate dateByAddingTimeInterval:90] timeIntervalSinceDate:date];
	int mins = secs / 60;
	int hours = mins / 60;
	int days = hours / 24;
	
	//NSLog(@"[%d][%d][%d][%d]", days, hours, mins, secs);
	
	if (days > 0) {
		timeSince = [NSString stringWithFormat:@"%dd", days];
		
	} else {
		if (hours > 0)
			timeSince = [NSString stringWithFormat:@"%dh", hours];
		
		else {
			if (mins > 0)
				timeSince = [NSString stringWithFormat:@"%dm", mins];
			
			else
				timeSince = [NSString stringWithFormat:@"%ds", secs];
		}
	}
	
	if ([[timeSince substringToIndex:[timeSince length] - 1] intValue] < 0)
		timeSince = @"0s";
	
	return (timeSince);
}


+ (UIFont *)helveticaNeueFontBold {
	return ([UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0]);
}

+ (UIFont *)helveticaNeueFontBoldItalic {
	return ([UIFont fontWithName:@"HelveticaNeue-BoldItalic" size:18.0]);
}

+ (UIFont *)helveticaNeueFontMedium {
	return ([UIFont fontWithName:@"HelveticaNeue-Medium" size:18.0]);
}

+ (UIFont *)cartoGothicBold {
	return ([UIFont fontWithName:@"CartoGothicStd-Bold" size:18.0]);
}

+ (UIFont *)cartoGothicBoldItalic {
	return ([UIFont fontWithName:@"CartoGothicStd-BoldItalic" size:18.0]);
}

+ (UIFont *)cartoGothicBook {
	return ([UIFont fontWithName:@"CartoGothicStd-Book" size:18.0]);
}

+ (UIFont *)cartoGothicItalic {
	return ([UIFont fontWithName:@"CartoGothicStd-Italic" size:18.0]);
}

+ (UIColor *)honBlueTxtColor {
	return ([UIColor colorWithRed:0.161 green:0.498 blue:1.0 alpha:1.0]);
}

+ (UIColor *)honGreyTxtColor {
	return ([UIColor colorWithWhite:0.635 alpha:1.0]);
}

+ (UIColor *)honGreyInputColor {
	return ([UIColor colorWithWhite:0.518 alpha:1.0]);
}

+ (UIColor *)honGreyDarkerColor {
	return ([UIColor colorWithWhite:0.455 alpha:1.0]);
}


- (BOOL)openSession {
	NSLog(@"openSession");
	return ([FBSession openActiveSessionWithPublishPermissions:[HONAppDelegate fbPermissions]
															 defaultAudience:FBSessionDefaultAudienceEveryone
																 allowLoginUI:NO
														  completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
															  NSLog(@"STATE:%d", state);
															  [self sessionStateChanged:session state:state error:error];
														  }]);
}

- (void)sessionStateChanged:(FBSession *)session state:(FBSessionState)state error:(NSError *)error {
	// FBSample logic
	// Any time the session is closed, we want to display the login controller (the user
	// cannot use the application unless they are logged in to Facebook). When the session
	// is opened successfully, hide the login controller and show the main UI.
	
	NSLog(@"sessionStateChanged:[%d]", state);
	
	switch (state) {
		case FBSessionStateOpen: {
			NSLog(@"--FBSessionStateOpen--AppDelegate");
			[self.loginViewController dismissViewControllerAnimated:YES completion:nil];
						
			// FBSample logic
			// Pre-fetch and cache the friends for the friend picker as soon as possible to improve
			// responsiveness when the user tags their friends.
			FBCacheDescriptor *cacheDescriptor = [FBFriendPickerViewController cacheDescriptor];
			[cacheDescriptor prefetchAndCacheForSession:session];
		} break;
		
		case FBSessionStateClosed:
			NSLog(@"--FBSessionStateClosed--AppDelegate");
			break;
			
		case FBSessionStateClosedLoginFailed: {
			NSLog(@"--FBSessionStateClosedLoginFailed--AppDelegate");
			
			[FBSession.activeSession closeAndClearTokenInformation];
		} break;
		
		default:
			break;
	}
	
	[[NSNotificationCenter defaultCenter] postNotificationName:HONSessionStateChangedNotification
														object:session];
	if (error) {
		[self _showOKAlert:@"Error"
			   withMessage:error.localizedDescription];
	}
}


#pragma mark - Notifications
- (void)_inviteFriends:(NSNotification *)notification {
	
	if (FBSession.activeSession.state == 513) {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONInviteFriendsViewController alloc] init]];
		[navigationController setNavigationBarHidden:YES];
		[self.tabBarController presentViewController:navigationController animated:YES completion:nil];
		
	} else {
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONLoginViewController alloc] init]];
		[navigationController setNavigationBarHidden:YES];
		[self.tabBarController presentViewController:navigationController animated:YES completion:nil];
	}
}

- (void)_webCTA:(NSNotification *)notification {
	NSString *url = [[notification object] objectForKey:@"url"];
	NSString *title = [[notification object] objectForKey:@"title"];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONWebCTAViewController alloc] initWithURL:url andTitle:title]];
	[navigationController setNavigationBarHidden:YES];
	[self.tabBarController presentViewController:navigationController animated:YES completion:nil];
}

- (void)_showSearchTable:(NSNotification *)notification {
	if (_searchViewController != nil) {
		[_searchViewController.view removeFromSuperview];
		_searchViewController = nil;
	}
	
	_searchViewController = [[HONSearchViewController alloc] init];
	_searchViewController.view.frame = CGRectMake(0.0, 20.0 + kSearchHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 188.0);
	[self.window addSubview:_searchViewController.view];
}

- (void)_hideSearchTable:(NSNotification *)notification {
	if (_searchViewController != nil) {
		[_searchViewController.view removeFromSuperview];
		_searchViewController = nil;
	}
}

- (void)_showSubjectSearchTimeline:(NSNotification *)notification {
	[_searchViewController.view removeFromSuperview];
	
	UINavigationController *navigationController = (UINavigationController *)[self.tabBarController selectedViewController];
	[navigationController pushViewController:[[HONTimelineViewController alloc] initWithSubjectName:[notification object]] animated:YES];
}

- (void)_showUserSearchTimeline:(NSNotification *)notification {
	[_searchViewController.view removeFromSuperview];
	
	UINavigationController *navigationController = (UINavigationController *)[self.tabBarController selectedViewController];
	[navigationController pushViewController:[[HONTimelineViewController alloc] initWithUsername:[notification object]] animated:YES];
}

- (void)_pokeUser:(NSNotification *)notification {
	HONUserVO *vo = (HONUserVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Timeline - Poke User"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.userID, vo.username], @"challenger", nil]];
	
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 6], @"action",
									[[HONAppDelegate infoForUser] objectForKey:@"id"], @"pokerID",
									[NSString stringWithFormat:@"%d", vo.userID], @"pokeeID",
									nil];
	
	[httpClient postPath:kUsersAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil)
			NSLog(@"AFNetworking HONChallengePreviewViewController - Failed to parse job list JSON: %@", [error localizedFailureReason]);
		
		else {
			NSLog(@"AFNetworking HONChallengePreviewViewController: %@", result);
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"ChallengePreviewViewController AFNetworking %@", [error localizedDescription]);
		
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:1.5];
		_progressHUD = nil;
	}];
}


#pragma mark - UI Presentation
- (void)_dropTabs {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"HIDE_TABS" object:nil];
}

- (void)_showOKAlert:(NSString *)title withMessage:(NSString *)message {
	UIAlertView *alertView = [[UIAlertView alloc]
									  initWithTitle:title
									  message:message
									  delegate:nil
									  cancelButtonTitle:@"OK"
									  otherButtonTitles:nil];
	[alertView show];
}


#pragma mark - Application Delegates
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	
	NSLog(@"LANGUAGE:[%@]", [[NSLocale preferredLanguages] objectAtIndex:0]);
	
	_isFromBackground = NO;
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_inviteFriends:) name:@"INVITE_FRIENDS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_webCTA:) name:@"WEB_CTA" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showSearchTable:) name:@"SHOW_SEARCH_TABLE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hideSearchTable:) name:@"HIDE_SEARCH_TABLE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showSubjectSearchTimeline:) name:@"SHOW_SUBJECT_SEARCH_TIMELINE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showUserSearchTimeline:) name:@"SHOW_USER_SEARCH_TIMELINE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_pokeUser:) name:@"POKE_USER" object:nil];
	
	//[self _testParseCloudCode];
	//[self _showFonts];
	
	if ([HONAppDelegate hasNetwork]) {
		if (![[NSUserDefaults standardUserDefaults] objectForKey:@"votes"])
			[[NSUserDefaults standardUserDefaults] setObject:[NSArray array] forKey:@"votes"];
		
		if (![[NSUserDefaults standardUserDefaults] objectForKey:@"audio_muted"])
			[[NSUserDefaults standardUserDefaults] setObject:@"NO" forKey:@"audio_muted"];
		
		if (![[NSUserDefaults standardUserDefaults] objectForKey:@"local_challenges"])
			[[NSUserDefaults standardUserDefaults] setValue:[NSArray array] forKey:@"local_challenges"];
		
		NSMutableDictionary *takeOffOptions = [[NSMutableDictionary alloc] init];
		[takeOffOptions setValue:launchOptions forKey:UAirshipTakeOffOptionsLaunchOptionsKey];
		[UAirship takeOff:takeOffOptions];
		[[UAPush shared] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
		
		// parse is down!!
		if (![HONAppDelegate canPingParseServer]) {
			[self _showOKAlert:@"Connection Error"
				   withMessage:@"Could not connect to Volley initialization servers, please try again."];
		}
		
		[Parse setApplicationId:@"Gi7eI4v6r9pEZmSQ0wchKKelOgg2PIG9pKE160uV" clientKey:@"Bv82pH4YB8EiXZG4V0E2KjEVtpLp4Xds25c5AkLP"];
		[PFUser enableAutomaticUser];
		PFACL *defaultACL = [PFACL ACL];
		[defaultACL setPublicReadAccess:YES];
		[PFACL setDefaultACL:defaultACL withAccessForCurrentUser:YES];
		
		PFQuery *apiActiveQuery = [PFQuery queryWithClassName:@"APIs"];
		PFObject *apiActiveObject = [apiActiveQuery getObjectWithId:@"eFLGKQWRzD"];
		
		// parse is down!!
		if (apiActiveObject == nil) {
			[self _showOKAlert:@"Connection Error"
				   withMessage:@"Could not connect to Volley endpoint servers, please try again."];
		
		} else {
			if ([[apiActiveObject objectForKey:@"active"] isEqualToString:@"Y"]) {
			
				int boot_total = 0;
				if (![[NSUserDefaults standardUserDefaults] objectForKey:@"boot_total"])
					[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:boot_total] forKey:@"boot_total"];
				
				else {
					boot_total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"boot_total"] intValue];
					[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:++boot_total] forKey:@"boot_total"];
				}
				
				if (![[NSUserDefaults standardUserDefaults] objectForKey:@"install_date"])
					[[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:@"install_date"];
				
				if (boot_total == 5) {
					UIAlertView *alertView = [[UIAlertView alloc]
												 initWithTitle:@"Rate Volley"
												 message:@"Why not rate Volley in the app store!"
												 delegate:self
												 cancelButtonTitle:nil
												 otherButtonTitles:@"No Thanks", @"Ask Me Later", @"Visit App Store", nil];
					[alertView setTag:2];
					[alertView show];
				}
				
				if (![[NSUserDefaults standardUserDefaults] objectForKey:@"fb_posting"])
					[HONAppDelegate setAllowsFBPosting:NO];
				
				[self _retrieveParseObj];
				[[NSUserDefaults standardUserDefaults] synchronize];
			
//				[TapForTap initializeWithAPIKey:@"13654ee85567a679c190698d04ee87e2"];
//
//				Kiip *kiip = [[Kiip alloc] initWithAppKey:@"app_key" andSecret:@"app_secret"];
//				kiip.delegate = self;
//				[Kiip setSharedInstance:kiip];
			
				[Mixpanel sharedInstanceWithToken:@"c7bf64584c01bca092e204d95414985f"];
				[[Mixpanel sharedInstance] track:@"App Boot"
											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
				
							
				self.tabBarController = [[HONTabBarController alloc] init];
				self.tabBarController.delegate = self;
				
				_bgImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 20.0, 320.0, ([HONAppDelegate isRetina5]) ? 548.0 : 470.0)];
				_bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h@2x" : @"mainBG"];
				[self.tabBarController.view addSubview:_bgImgView];
				
				self.window.rootViewController = self.tabBarController;
				[self.window makeKeyAndVisible];
				
				//[[Kiip sharedInstance] saveMoment:@"Test Moment" withCompletionHandler:nil];
						
			} else {
				[self _showOKAlert:@"Upgrade Needed"
					   withMessage:@"Please update to the latest version from the App Store to continue playing Volley."];
			}
		}
	
	} else {
		[self _showOKAlert:@"No Network Connection"
			   withMessage:@"This app requires a network connection to work."];
	}
	
	return (YES);
}

- (void)applicationWillResignActive:(UIApplication *)application {
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
	[[Mixpanel sharedInstance] track:@"App Entering Background"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"APP_ENTERING_BACKGROUND" object:nil];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
	_isFromBackground = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
	[FBSession.activeSession handleDidBecomeActive];
	
	if (_isFromBackground && [HONAppDelegate hasNetwork]) {
		[[Mixpanel sharedInstance] track:@"App Leaving Background"
									 properties:[NSDictionary dictionaryWithObjectsAndKeys:
													 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
		
		if (![HONAppDelegate canPingParseServer]) {
			[self _showOKAlert:@"Connection Error"
				   withMessage:@"Could not connect to the Volley initialization servers, please try again."];
		
		} else {
			PFQuery *apiActiveQuery = [PFQuery queryWithClassName:@"APIs"];
			PFObject *apiActiveObject = [apiActiveQuery getObjectWithId:@"eFLGKQWRzD"];
			
			if (apiActiveObject != nil) {
				if ([[apiActiveObject objectForKey:@"active"] isEqualToString:@"Y"]) {
					[self _retrieveParseObj];
					
					//[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_ALL_TABS" object:nil];
					[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_VOTE_TAB" object:nil];
				
				} else {
					[self _showOKAlert:@"Upgrade Needed"
						   withMessage:@"Please update to the latest version from the App Store to continue playing Volley."];
				}
				
			} else {
				[self _showOKAlert:@"Connection Error"
					   withMessage:@"Could not connect to the Volley endpoint servers, please try again."];
			}
		}
	}
	
//	Chartboost *cb = [Chartboost sharedChartboost];
//	cb.appId = @"50ba9e2717ba47d426000002";
//	cb.appSignature = @"8526c7d52c380c02cc8e59c1c29e8cf4bf779646";
//	[cb startSession];
//	
//	if ([HONAppDelegate isCharboostEnabled])
//		[cb showInterstitial];
	
	if (_isFromBackground && [[[[[NSUserDefaults standardUserDefaults] objectForKey:@"web_ctas"] objectAtIndex:0] objectForKey:@"enabled"] isEqualToString:@"Y"])
		[[NSNotificationCenter defaultCenter] postNotificationName:@"WEB_CTA" object:[[[NSUserDefaults standardUserDefaults] objectForKey:@"web_ctas"] objectAtIndex:0]];
}

- (void)applicationWillTerminate:(UIApplication *)application {
	[UAirship land];
	[FBSession.activeSession close];
}


- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
	[[UAPush shared] registerDeviceToken:deviceToken];
	
	NSString *deviceID = [[deviceToken description] substringFromIndex:1];
	deviceID = [deviceID substringToIndex:[deviceID length] - 1];
	deviceID = [deviceID stringByReplacingOccurrencesOfString:@" " withString:@""];
	
	NSLog(@"didRegisterForRemoteNotificationsWithDeviceToken:[%@]", deviceID);
	
	[HONAppDelegate writeDeviceToken:deviceID];
	//if (![[HONAppDelegate infoForUser] objectForKey:@"id"])
		[self _registerUser];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *) error {
	UALOG(@"Failed To Register For Remote Notifications With Error: %@", error);
	
	NSString *deviceID = [NSString stringWithFormat:@"%064d", 0];
	NSLog(@"didFailToRegisterForRemoteNotificationsWithError:[%@]", deviceID);
	
	[HONAppDelegate writeDeviceToken:deviceID];
	[self _registerUser];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
	UALOG(@"Received remote notification: %@", userInfo);
	
	// Get application state for iOS4.x+ devices, otherwise assume active
	UIApplicationState appState = UIApplicationStateActive;
	if ([application respondsToSelector:@selector(applicationState)]) {
		appState = application.applicationState;
	}
	
	[[UAPush shared] handleNotification:userInfo applicationState:appState];
	[[UAPush shared] resetBadge]; // zero badge after push received
	
	NSLog(@"alert: [%@]", [[userInfo objectForKey:@"aps"] objectForKey:@"alert"]);
	
	// sms sound
	AudioServicesPlaySystemSound(1007);
	
	int type_id = [[userInfo objectForKey:@"type"] intValue];
	switch (type_id) {
		
		// challenge update
		case 1:
			[self _showOKAlert:@"Challenge Update"
				   withMessage:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]];
			break;
			
		// poke
		case 2:
			[self _showOKAlert:@"Poke"
				   withMessage:[[userInfo objectForKey:@"aps"] objectForKey:@"alert"]];
			break;
	}
	 	
	UILocalNotification *localNotification = [[UILocalNotification alloc] init];
	localNotification.fireDate = [[NSDate alloc] initWithTimeIntervalSinceNow:1];
	localNotification.alertBody = [NSString stringWithFormat:@"%d", [[userInfo objectForKey:@"type"] intValue]];;
	localNotification.soundName = UILocalNotificationDefaultSoundName;
	 
//	NSDictionary *infoDict = [NSDictionary dictionaryWithObjectsAndKeys:@"Object 1", @"Key 1", @"Object 2", @"Key 2", nil];
//	localNotification.userInfo = infoDict;
	 
	[[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
	return [FBSession.activeSession handleOpenURL:url];
}


#pragma mark - Startup Operations
- (void)_retrieveParseObj {
	PFQuery *dailyQuery = [PFQuery queryWithClassName:@"DailyChallenges"];
	PFObject *dailyObject = [dailyQuery getObjectWithId:@"obmVTq3VHr"];
	[[NSUserDefaults standardUserDefaults] setObject:[dailyObject objectForKey:@"subject_name"] forKey:@"daily_challenge"];
	
	
	PFQuery *appDataQuery = [PFQuery queryWithClassName:@"Volley"];
	PFObject *appDataObject = [appDataQuery getObjectWithId:@"fICB044MKB"];
	
	NSError *error = nil;
	NSDictionary *appDict = [NSJSONSerialization JSONObjectWithData:[[appDataObject objectForKey:@"data"] dataUsingEncoding:NSUTF8StringEncoding]
															options:NSJSONReadingMutableContainers
															  error:&error];
	
	if (error != nil)
		NSLog(@"Failed to parse app data list JSON: %@", [error localizedFailureReason]);
	
	else {
		//NSLog(@"appDict:\n%@", appDict);
		
		NSMutableArray *locales = [NSMutableArray array];
		for (NSString *locale in [appDict objectForKey:@"enabled_locales"])
			[locales addObject:locale];
		
		NSMutableArray *inviteCodes = [NSMutableArray array];
		for (NSString *code in [appDict objectForKey:@"invite_codes"])
			[inviteCodes addObject:code];
		
		NSMutableArray *hashtags = [NSMutableArray array];
		for (NSString *hashtag in [appDict objectForKey:@"default_hashtags"])
			[hashtags addObject:hashtag];
		
		NSMutableArray *subjects = [NSMutableArray array];
		for (NSString *hashtag in [appDict objectForKey:@"search_hashtags"])
			[subjects addObject:hashtag];
		
		NSMutableArray *users = [NSMutableArray array];
		for (NSString *user in [appDict objectForKey:@"search_users"])
			[users addObject:user];
		
		[[NSUserDefaults standardUserDefaults] setObject:[appDict objectForKey:@"appstore_id"] forKey:@"appstore_id"];
		[[NSUserDefaults standardUserDefaults] setObject:[[appDict objectForKey:@"endpts"] objectForKey:@"data_api"] forKey:@"server_api"];
		[[NSUserDefaults standardUserDefaults] setObject:[[appDict objectForKey:@"endpts"] objectForKey:@"fb_path"] forKey:@"facebook_url"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
														  [[appDict objectForKey:@"fb_posting_rules"] objectForKey:@"friend_wall"], @"friend_wall",
														  [[appDict objectForKey:@"fb_posting_rules"] objectForKey:@"invite"], @"invite", nil] forKey:@"fb_network"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
														  [[appDict objectForKey:@"s3_creds"] objectForKey:@"key"], @"key",
														  [[appDict objectForKey:@"s3_creds"] objectForKey:@"secret"], @"secret", nil] forKey:@"s3_creds"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:
														  [[appDict objectForKey:@"point_multipliers"] objectForKey:@"vote"],
														  [[appDict objectForKey:@"point_multipliers"] objectForKey:@"poke"],
														  [[appDict objectForKey:@"point_multipliers"] objectForKey:@"create"], nil] forKey:@"point_mult"];
		[[NSUserDefaults standardUserDefaults] setObject:[appDict objectForKey:@"invite_sms"] forKey:@"invite_sms"];
		[[NSUserDefaults standardUserDefaults] setObject:[appDict objectForKey:@"invite_email"] forKey:@"invite_email"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:
														  [NSDictionary dictionaryWithObjectsAndKeys:
														   [[[appDict objectForKey:@"web_ctas"] objectAtIndex:0] objectForKey:@"title"], @"title",
														   [[[appDict objectForKey:@"web_ctas"] objectAtIndex:0] objectForKey:@"url"], @"url",
														   [[[appDict objectForKey:@"web_ctas"] objectAtIndex:0] objectForKey:@"enabled"], @"enabled", nil],
														  [NSDictionary dictionaryWithObjectsAndKeys:
														   [[[appDict objectForKey:@"web_ctas"] objectAtIndex:1] objectForKey:@"title"], @"title",
														   [[[appDict objectForKey:@"web_ctas"] objectAtIndex:1] objectForKey:@"url"], @"url",
														   [[[appDict objectForKey:@"web_ctas"] objectAtIndex:1] objectForKey:@"enabled"], @"enabled", nil], nil] forKey:@"web_ctas"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSArray arrayWithObjects:
														  [[appDict objectForKey:@"vote_wall_ctas"] objectForKey:@"waiting"],
														  [[appDict objectForKey:@"vote_wall_ctas"] objectForKey:@"accepted"],
														  [[appDict objectForKey:@"vote_wall_ctas"] objectForKey:@"created"], nil] forKey:@"ctas"];
		[[NSUserDefaults standardUserDefaults] setObject:[NSDictionary dictionaryWithObjectsAndKeys:
														  [[appDict objectForKey:@"ad_networks"] objectForKey:@"chartboost"], @"chartboost",
														  [[appDict objectForKey:@"ad_networks"] objectForKey:@"kiip"], @"kiip",
														  [[appDict objectForKey:@"ad_networks"] objectForKey:@"tapfortap"], @"tapfortap", nil] forKey:@"ad_networks"];
		[[NSUserDefaults standardUserDefaults] setObject:[locales copy] forKey:@"enabled_locales"];
		[[NSUserDefaults standardUserDefaults] setObject:[inviteCodes copy] forKey:@"invite_codes"];
		[[NSUserDefaults standardUserDefaults] setObject:[hashtags copy] forKey:@"default_subjects"];
		[[NSUserDefaults standardUserDefaults] setObject:[subjects copy] forKey:@"search_subjects"];
		[[NSUserDefaults standardUserDefaults] setObject:[users copy] forKey:@"search_users"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}

- (void)_registerUser {
	//if (![[NSUserDefaults standardUserDefaults] objectForKey:@"user"]) {
	
//	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.parse.com/1/functions/"]];
//	[httpClient setDefaultHeader:@"X-Parse-Application-Id" value:@"Gi7eI4v6r9pEZmSQ0wchKKelOgg2PIG9pKE160uV"];
//	[httpClient setDefaultHeader:@"X-Parse-REST-API-Key" value:@"Lf7cT3m2EC8JsXzubpfhD28phm2gA7Y86kiTnAb6"];
//	[httpClient setDefaultHeader:@"Content-Type" value:@"application/json"];
//	[httpClient registerHTTPOperationClass:[AFJSONRequestOperation class]];
		
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 1], @"action",
									[HONAppDelegate deviceToken], @"token",
									nil];
	
	[httpClient postPath:kUsersAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSDictionary *userResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			NSLog(@"AppDelegate AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
		
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:1.5];
			_progressHUD = nil;
		
		} else {
			NSLog(@"HONAppDelegate AFNetworking: %@", userResult);
			
			if ([userResult objectForKey:@"id"] != [NSNull null])
				[HONAppDelegate writeUserInfo:userResult];
			
			[self _initTabs];
		}
				
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"AppDelegate AFNetworking %@", [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:1.5];
		_progressHUD = nil;
	}];
}


- (void)_initTabs {
	[_bgImgView removeFromSuperview];
	
	UIViewController *challengesViewController, *voteViewController, *discoveryViewController, *profileViewController;
	challengesViewController = [[HONChallengesViewController alloc] init];
	voteViewController = [[HONTimelineViewController alloc] init];//[[HONVoteSubjectsViewController alloc] init];//
	discoveryViewController = [[HONDiscoveryViewController alloc] init];
	profileViewController = [[HONProfileViewController alloc] init];
	
	UINavigationController *navController1 = [[UINavigationController alloc] initWithRootViewController:voteViewController];
	UINavigationController *navController2 = [[UINavigationController alloc] initWithRootViewController:discoveryViewController];
	UINavigationController *navController3 = [[UINavigationController alloc] initWithRootViewController:challengesViewController];
	UINavigationController *navController4 = [[UINavigationController alloc] initWithRootViewController:profileViewController];
	
	[navController1 setNavigationBarHidden:YES];
	[navController2 setNavigationBarHidden:YES];
	[navController3 setNavigationBarHidden:YES];
	[navController4 setNavigationBarHidden:YES];
	
	self.tabBarController.viewControllers = [NSArray arrayWithObjects:navController1, navController2, navController3, navController4, nil];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_TABS" object:nil];
	//[self performSelector:@selector(_dropTabs) withObject:nil afterDelay:2.0];
}


#pragma mark - Debug Calls
- (void)_testParseCloudCode {
	// http://stackoverflow.com/questions/10795710/converting-a-curl-request-with-data-urlencode-into-afnetworking-get-request
	/*
	NSDictionary *jsonDictionary = [[NSDictionary alloc] initWithObjectsAndKeys:@"app_name", @"PicChallenge", nil];
	 
	NSError *error = nil;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDictionary options:0 error:&error];
	 
	if (!jsonData) {
		NSLog(@"NSJSONSerialization failed %@", error);
	}
	 
	NSString *json = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:json, @"where", nil];
	*/
	// ////////////////////////////////////////////////////////////////////////////////////////////////////////////// //
	
	NSDictionary *parameters = [[NSDictionary alloc] initWithObjectsAndKeys:
										 //@"PicChallenge", @"app_name",
										 [NSString stringWithFormat:@"%d", 2], @"user_id",
										 nil];
	
	AFHTTPClient *client = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:@"https://api.parse.com/1/functions/"]];
//	[client setDefaultHeader:@"X-Parse-Application-Id" value:@"Gi7eI4v6r9pEZmSQ0wchKKelOgg2PIG9pKE160uV"];
//	[client setDefaultHeader:@"X-Parse-REST-API-Key" value:@"Lf7cT3m2EC8JsXzubpfhD28phm2gA7Y86kiTnAb6"];
	[client setDefaultHeader:@"X-Parse-Application-Id" value:@"avNXwB6BSTKdSeD5lDRVM71Bglq3mY78ORBQvV2i"];
	[client setDefaultHeader:@"X-Parse-REST-API-Key" value:@"yNUthh5WRYuAoKMv2Gyv6vwmg7D0YnvJ83RZWmXr"];
	[client setDefaultHeader:@"Content-Type" value:@"application/json"];
	[client registerHTTPOperationClass:[AFJSONRequestOperation class]];
	
	NSLog(@"%@", parameters);
	
	//[client postPath:@"duration"
	[client postPath:@"getUser"
			parameters:parameters
			  success:^(AFHTTPRequestOperation *operation, id responseObject) {
				  NSError *error = nil;
				  NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
				  NSLog(@"SUCCESS\n%@", result);
				  
			  } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
				  NSLog(@"FAILED\n%@", error);
			  }
	 ];
}

- (void)_showFonts {
	for (NSString *familyName in [UIFont familyNames]) {
		NSLog(@"Font Family Name = %@", familyName);
		
		NSArray *names = [UIFont fontNamesForFamilyName:familyName];
		NSLog(@"Font Names = %@", names);
	}
}

#pragma mark - TabBarController Delegates
- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController {
	//NSLog(@"shouldSelectViewController:[%@]", viewController);
	
	if (tabBarController.selectedViewController == [[tabBarController viewControllers] objectAtIndex:1])
		[tabBarController.selectedViewController.navigationController popToRootViewControllerAnimated:NO];
		
	return (YES);
}


- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
	//NSLog(@"didSelectViewController:[%@]", viewController);
}

- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed {
}


#pragma mark - AlertView delegates
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	NSLog(@"BUTTON:[%d]", buttonIndex);
	
	if (alertView.tag == 0)
		NSLog(@"EXIT APP");//exit(0);
	
	else if (alertView.tag == 1) {
		UINavigationController *navigationController;
		
		switch (buttonIndex) {
			case 0:
				navigationController = [[UINavigationController alloc] initWithRootViewController:self.loginViewController];
				break;
				
			case 1:
				navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONUsernameViewController alloc] init]];
				break;
		}
		
		[navigationController setNavigationBarHidden:YES];
		[self.tabBarController presentViewController:navigationController animated:YES completion:nil];
	}
	
	else if (alertView.tag == 2) {
		switch(buttonIndex) {
			case 0:
				break;
				
			case 1:
				[[NSUserDefaults standardUserDefaults] setObject:[NSDate new] forKey:@"install_date"];
				[[NSUserDefaults standardUserDefaults] synchronize];
				break;
				
			case 2:
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"itms://itunes.apple.com/us/app/id%@?mt=8", [[NSUserDefaults standardUserDefaults] objectForKey:@"appstore_id"]]]];
				break;
		}
	}
	
	else if (alertView.tag == 5) {
		switch (buttonIndex) {
			case 0:
				[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_ALL_TABS" object:nil];
				break;
				
			case 1:
				break;
		}
	}
}

@end
