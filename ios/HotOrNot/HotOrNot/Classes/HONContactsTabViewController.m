//
//  HONContactsTabViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 03/26/2014 @ 18:21 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import <KakaoOpenSDK/KakaoOpenSDK.h>

#import "NSDate+Operations.h"

#import "KeychainItemWrapper.h"

#import "HONContactsTabViewController.h"
#import "HONRegisterViewController.h"
#import "HONComposeViewController.h"
#import "HONActivityViewController.h"
#import "HONTableView.h"
#import "HONTableHeaderView.h"
#import "HONRefreshControl.h"
#import "HONClubPhotoViewCell.h"
#import "HONClubPhotoVO.h"

@interface HONContactsTabViewController () <HONClubPhotoViewCellDelegate>
//@property (nonatomic, strong) HONUserClubVO *selectedClubVO;
@property (nonatomic, strong) NSMutableArray *seenClubs;
@property (nonatomic, strong) NSMutableArray *unseenClubs;
@property (nonatomic, strong) NSMutableArray *clubPhotos;
@property (nonatomic, strong) UIButton *activityButton;
@property (nonatomic, strong) UILabel *emptyLabel;
@property (nonatomic, strong) HONTableView *tableView;
@property (nonatomic, strong) HONRefreshControl *refreshControl;
@property (nonatomic) int joinedTotalClubs;

@property (nonatomic, strong) CLLocationManager *locationManager;
@end


@implementation HONContactsTabViewController

- (id)init {
	if ((self = [super init])) {
		_totalType = HONStateMitigatorTotalTypeFriendsTab;
		_viewStateType = HONStateMitigatorViewStateTypeFriends;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_selectedContactsTab:)
													 name:@"SELECTED_CONTACTS_TAB" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_tareContactsTab:)
													 name:@"TARE_CONTACTS_TAB" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_refreshContactsTab:)
													 name:@"REFRESH_CONTACTS_TAB" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_refreshContactsTab:)
													 name:@"REFRESH_ALL_TABS" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_showFirstRun:)
													 name:@"SHOW_FIRST_RUN" object:nil];
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(_completedFirstRun:)
													 name:@"COMPLETED_FIRST_RUN" object:nil];
	}
	
	return (self);
}

- (void)dealloc {
	_locationManager.delegate = nil;
	
	_tableView.dataSource = nil;
	_tableView.delegate = nil;
	
	[self destroy];
}


#pragma mark - Public APIs
- (void)destroy {
	[super destroy];
}

#pragma mark - Data Calls
- (void)_retrieveClubs {
	[_tableView.visibleCells enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		HONClubPhotoViewCell *cell = (HONClubPhotoViewCell *)obj;
		[UIView animateKeyframesWithDuration:0.125 delay:0.000 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseOut) animations:^(void) {
			cell.alpha = 0.0;
		} completion:^(BOOL finished) {
		}];
	}];
	
	[[HONAPICaller sharedInstance] retrieveClubsForUserByUserID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
//		[[HONClubAssistant sharedInstance] writeUserClubs:result];
		
//		_joinedTotalClubs = (_joinedTotalClubs == 0) ? (int)[[result objectForKey:@"pending"] count] : _joinedTotalClubs;
		
		for (NSString *key in [[HONClubAssistant sharedInstance] clubTypeKeys]) {
			if ([key isEqualToString:@"owned"] || [key isEqualToString:@"member"]) {
				for (NSDictionary *dict in [result objectForKey:key]) {
//					if ([[dict objectForKey:@"submissions"] count] == 0 && [[dict objectForKey:@"pending"] count] == 0)
//						continue;
					
					HONUserClubVO *clubVO = [HONUserClubVO clubWithDictionary:dict];
//					if ([clubVO.submissions count] == 0)
//						continue;
					
					[clubVO.submissions enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						HONClubPhotoVO *clubPhotoVO = (HONClubPhotoVO *)obj;
						
						if ([clubPhotoVO.addedDate timeIntervalSinceNow] >= (3600 * 24))
							return;
						
						[_clubPhotos addObject:clubPhotoVO];
					}];
					
//					NSLog(@"SEEN UPDATES:[%@]", [[NSUserDefaults standardUserDefaults] objectForKey:@"seen_updates"]);
//					if ([clubVO.updatedDate timeIntervalSinceNow] >= (3600 * 12)) {
//					if ([[[[NSUserDefaults standardUserDefaults] objectForKey:@"seen_updates"] objectForKey:NSStringFromInt(clubPhotoVO.challengeID)] intValue] == [[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue]) {
//						[_seenClubs addObject:[HONUserClubVO clubWithDictionary:dict]];
//					
//					} else {
//						[_unseenClubs addObject:[HONUserClubVO clubWithDictionary:dict]];
//					}
				}
				
//			} else if ([key isEqualToString:@"pending"]) {
//				for (NSDictionary *dict in [result objectForKey:key]) {
//					[[HONAPICaller sharedInstance] joinClub:[HONUserClubVO clubWithDictionary:dict] withMemberID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
//						
//						if ([[result objectForKey:@"pending"] count] == 0)
//							[self _retrieveClubs];
//					}];
//				}
				
			} else
				continue;
		}
		
		NSLog(@"WITHIN RANGE:[%@]", NSStringFromBOOL([[HONGeoLocator sharedInstance] isWithinOrthodoxClub]));
		NSLog(@"MEMBER OF:[%d] =-= (%@)", [[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue], NSStringFromBOOL([[HONClubAssistant sharedInstance] isMemberOfClubWithClubID:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue] includePending:YES]));
		if ([[HONGeoLocator sharedInstance] isWithinOrthodoxClub] && ![[HONClubAssistant sharedInstance] isMemberOfClubWithClubID:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue] includePending:YES]) {
//			[[HONAPICaller sharedInstance] joinClub:[[HONClubAssistant sharedInstance] orthodoxMemberClub] withMemberID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
//				
//				if ((BOOL)[[result objectForKey:@"result"] intValue]) {
//					[[HONAPICaller sharedInstance] retrieveClubsForUserByUserID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
//						[[HONClubAssistant sharedInstance] writeUserClubs:result];
//						[self _didFinishDataRefresh];
//					}];
//				}
//			}];
		
		} else {
			[[HONClubAssistant sharedInstance] writeUserClubs:result];
			[self _didFinishDataRefresh];
		}
	}];
}

- (void)_retrieveActivityItems {
	[[HONAPICaller sharedInstance] retrieveActivityTotalForUserByUserID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSString *result) {
		NSLog(@"ACTIVITY:[%@]", result);
//		//int total = MIN(MAX(0, [result count]), 10);
		[_activityButton setTitle:NSStringFromInt([result intValue]) forState:UIControlStateNormal];
		[_activityButton setTitle:NSStringFromInt([result intValue]) forState:UIControlStateHighlighted];
	}];
}



#pragma mark - Data Handling
- (void)_goDataRefresh:(HONRefreshControl *)sender {
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Refresh"];
	[[HONStateMitigator sharedInstance] incrementTotalCounterForType:HONStateMitigatorTotalTypeFriendsTabRefresh];
	
	[self _goReloadTableViewContents];
}

- (void)_goReloadTableViewContents {
	if (![_refreshControl isRefreshing])
		[_refreshControl beginRefreshing];
	
	_clubPhotos = [NSMutableArray array];
	_seenClubs = [NSMutableArray array];
	_unseenClubs = [NSMutableArray array];
	[_tableView reloadData];
	
	[self _retrieveClubs];
}

- (void)_didFinishDataRefresh {
	if (_joinedTotalClubs > 0) {
		_joinedTotalClubs = 0;
	
	} else {
		_clubPhotos = [[[[_clubPhotos sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			HONClubPhotoVO *vo1 = (HONClubPhotoVO *)obj1;
			HONClubPhotoVO *vo2 = (HONClubPhotoVO *)obj2;
			
			if ([vo1.addedDate didDateAlreadyOccur:vo2.addedDate])
				return ((NSComparisonResult)NSOrderedAscending);
			
			if ([vo2.addedDate didDateAlreadyOccur:vo1.addedDate])
				return ((NSComparisonResult)NSOrderedDescending);
			
			return ((NSComparisonResult)NSOrderedSame);
		}] reverseObjectEnumerator] allObjects] mutableCopy];
	}
	
	_emptyLabel.hidden = ([_clubPhotos count] > 0);
	
	_tableView.contentSize = CGSizeMake(_tableView.frame.size.width, _tableView.frame.size.height * ([_clubPhotos count]));
	[_tableView reloadData];
	[_refreshControl endRefreshing];
	[_tableView setContentOffset:CGPointZero animated:YES];
	
	NSLog(@"%@._didFinishDataRefresh - CLAuthorizationStatus() = [%@]", self.class, NSStringFromCLAuthorizationStatus([CLLocationManager authorizationStatus]));
}

- (void)_updateScoreForClubPhoto:(HONClubPhotoVO *)clubPhotoVO isIncrement:(BOOL)isIncrement {
	[_clubPhotos enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		HONClubPhotoVO *vo = (HONClubPhotoVO *)obj;
		
		if (vo.challengeID == vo.challengeID) {
			vo.score += (isIncrement) ? 1 : -1;
			*stop = YES;
		}
	}];
}


#pragma mark - View lifecycle
- (void)loadView {
	ViewControllerLog(@"[:|:] [%@ loadView] [:|:]", self.class);
	[super loadView];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	self.view.hidden = YES;
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	_seenClubs = [NSMutableArray array];
	_unseenClubs = [NSMutableArray array];
	
	_tableView = [[HONTableView alloc] initWithFrame:[UIScreen mainScreen].bounds];
	_tableView.contentSize = CGSizeMake(_tableView.frame.size.width, _tableView.frame.size.height * ([_clubPhotos count]));
//	[_tableView setContentInset:kOrthodoxTableViewEdgeInsets];
	[_tableView setContentInset:UIEdgeInsetsMake(_tableView.contentInset.top + 44.0, _tableView.contentInset.left, _tableView.contentInset.bottom + (44.0), _tableView.contentInset.right)];
	[_tableView setContentOffset:CGPointZero];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.pagingEnabled = YES;
	[self.view addSubview:_tableView];
	
	_refreshControl = [[HONRefreshControl alloc] init];
	[_refreshControl addTarget:self action:@selector(_goDataRefresh:) forControlEvents:UIControlEventValueChanged];
	[_tableView addSubview: _refreshControl];
	
	_headerView = [[HONHeaderView alloc] initWithBranding];
	[_headerView addComposeButtonWithTarget:self action:@selector(_goCreateChallenge)];
//	[self.view addSubview:_headerView];
	
//	UILongPressGestureRecognizer *lpGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(_goLongPress:)];
//	lpGestureRecognizer.minimumPressDuration = 0.5;
//	lpGestureRecognizer.delegate = self;
//	[_tableView addGestureRecognizer:lpGestureRecognizer];
	
	
	_emptyLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 18.0, 300, (_tableView.frame.size.height - 22.0) * 0.5)];
	_emptyLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:20];
	_emptyLabel.textColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
	_emptyLabel.backgroundColor = [UIColor clearColor];
	_emptyLabel.textAlignment = NSTextAlignmentCenter;
	_emptyLabel.text = NSLocalizedString(@"no_results", @"");
	_emptyLabel.hidden = YES;
	[_tableView addSubview:_emptyLabel];
	
	UIImageView *headerImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"clubsHeaderText"]];
	headerImageView.frame = CGRectMake(0.0, 0.0, 320.0, 44.0);
	[self.view addSubview:headerImageView];
	
	UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.0, 18.0, 300, 22.0)];
	headerLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:14];
	headerLabel.textColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
	headerLabel.backgroundColor = [UIColor clearColor];
	headerLabel.textAlignment = NSTextAlignmentCenter;
	headerLabel.text = NSLocalizedString(@"header_home", @"");
	[headerImageView addSubview:headerLabel];
	
//	UIButton *composeButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	composeButton.frame = CGRectMake(0.0, self.view.frame.size.height - 84.0, 320.0, 44.0);
//	[composeButton setBackgroundImage:[UIImage imageNamed:@"takePhotoButton_nonActive"] forState:UIControlStateNormal];
//	[composeButton setBackgroundImage:[UIImage imageNamed:@"takePhotoButton_Active"] forState:UIControlStateHighlighted];
//	[composeButton addTarget:self action:@selector(_goCreateChallenge) forControlEvents:UIControlEventTouchUpInside];
//	[self.view addSubview:composeButton];
	
	_activityButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_activityButton.frame = CGRectMake(10.0, 54.0, 35.0, 35.0);
	_activityButton.backgroundColor = [UIColor colorWithRed:0 green:0.365 blue:0.914 alpha:1.0];
	[_activityButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
	[_activityButton setTitleColor:[[HONColorAuthority sharedInstance] honGreyTextColor] forState:UIControlStateHighlighted];
	_activityButton.titleLabel.font = [[[HONFontAllocator sharedInstance] helveticaNeueFontMedium] fontWithSize:16];
	[_activityButton setTitle:@"0" forState:UIControlStateNormal];
	[_activityButton setTitle:@"0" forState:UIControlStateHighlighted];
	[_activityButton addTarget:self action:@selector(_goActivity) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_activityButton];
}

- (void)viewDidLoad {
	ViewControllerLog(@"[:|:] [%@ viewDidLoad] [:|:]", self.class);
	[super viewDidLoad];
	
	KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier] accessGroup:nil];
	if ([[keychain objectForKey:CFBridgingRelease(kSecAttrAccount)] length] != 0) {
		self.view.hidden = NO;
		
		if ([[UIApplication sharedApplication] respondsToSelector:@selector(isRegisteredForRemoteNotifications)]) {
			[[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
			[[UIApplication sharedApplication] registerForRemoteNotifications];
		
		} else
			[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert)];
		
		if (![_refreshControl isRefreshing])
			[_refreshControl beginRefreshing];
		
		_locationManager = [[CLLocationManager alloc] init];
		_locationManager.delegate = self;
		_locationManager.distanceFilter = 10000;
		if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
			[_locationManager requestWhenInUseAuthorization];
		[_locationManager startUpdatingLocation];
		
		[[HONAnalyticsReporter sharedInstance] trackEvent:@"HOME - enter"];
	
	} else {
		[self _goRegistration];
	}
	
	[self _retrieveActivityItems];
	[[HONStateMitigator sharedInstance] resetTotalCounterForType:_totalType withValue:([[HONStateMitigator sharedInstance] totalCounterForType:_totalType] - 1)];
//	NSLog(@"[:|:] [%@]:[%@]-=(%d)=-", self.class, [[HONStateMitigator sharedInstance] _keyForTotalType:_totalType], [[HONStateMitigator sharedInstance] totalCounterForType:_totalType]);
}

- (void)viewWillAppear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewWillAppear:animated:%@] [:|:]", self.class, NSStringFromBOOL(animated));
	[super viewWillAppear:animated];
	
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationFade];
	
//	if ([[[[KeychainItemWrapper alloc] initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier] accessGroup:nil] objectForKey:CFBridgingRelease(kSecAttrAccount)] length] != 0) {
//		HONTimelineMapViewController *timelineMapViewController = [[HONTimelineMapViewController alloc] init];
//		timelineMapViewController.view.frame = CGRectOffset(timelineMapViewController.view.frame, 0.0, -([UIScreen mainScreen].bounds.size.height - 190.0));
//		timelineMapViewController.delegate = self;
//		
//		[self addChildViewController:timelineMapViewController];
//		[self.view addSubview:timelineMapViewController.view];
//		[timelineMapViewController didMoveToParentViewController:self];
//	}
}


#pragma mark - Navigation
- (void)_goRegistration {
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONRegisterViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:^(void) {
		self.view.hidden = NO;
	}];
}

- (void)_goActivity {
//	KakaoTalkLinkObject *label = [KakaoTalkLinkObject createLabel:@"Test Label"];
//	[KOAppCall openKakaoTalkAppLink:@[label]];
	
	
//	[KOSessionTask talkProfileTaskWithCompletionHandler:^(KOTalkProfile *result, NSError *error) {
//		if (result) {
//			NSLog(@"result:[%@]", result);
//		} else {
//			NSLog(@"%@", error);
//		}
//	}];
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Activity"];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONActivityViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:^(void) {
	}];
}

- (void)_goCreateChallenge {
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Create Status Update"
//									 withProperties:@{@"src"	: @"header"}];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONComposeViewController alloc] initWithClub:[[HONClubAssistant sharedInstance] clubWithClubID:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue]]]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)_goReplyToClubPhoto:(HONClubPhotoVO *)clubPhotoVO forClub:(HONUserClubVO *)clubVO {
	NSLog(@"[*:*] _goReply:(%d - %@)", clubPhotoVO.userID, clubPhotoVO.username);
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab	- Reply"
//										withClubPhoto:clubPhotoVO];
	
	[[_tableView visibleCells] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		HONClubPhotoViewCell *viewCell = (HONClubPhotoViewCell *)obj;
		[viewCell destroy];
	}];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONComposeViewController alloc] initWithClub:clubVO]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:[[HONAnimationOverseer sharedInstance] isSegueAnimationEnabledForModalViewController:navigationController.presentingViewController] completion:^(void) {
	}];
}

-(void)_goLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
	NSLog(@"gestureRecognizer.state:[%@]", NSStringFromUIGestureRecognizerState(gestureRecognizer.state));
	if (gestureRecognizer.state != UIGestureRecognizerStateBegan && gestureRecognizer.state != UIGestureRecognizerStateCancelled && gestureRecognizer.state != UIGestureRecognizerStateEnded)
		return;
	
	NSIndexPath *indexPath = [_tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:_tableView]];
	
	if (indexPath != nil) {
//		HONClubPhotoViewCell *cell = (HONClubPhotoViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
		
		if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
//			NSLog(@"STATUS UPDATE:[%@]", cell.statusUpdateVO.subjectNames);
//			HONClubTimelineViewController *clubTimelineViewController = [[HONClubTimelineViewController alloc] initWithClub:cell.clubVO atPhotoIndex:0];
//			[self.view addSubview:clubTimelineViewController.view];
		
		} else if (gestureRecognizer.state == UIGestureRecognizerStateEnded) {
			[[self.view.subviews lastObject] removeFromSuperview];
		}
	}
}

- (void)_goSelectClub:(HONUserClubVO *)clubVO {
	if (!_isPushing) {
		_isPushing = YES;
		
		//[[HONAnalyticsReporter sharedInstance] trackEvent:[NSString stringWithFormat:@"Friends Tab - %@", ([clubVO.submissions count] > 0) ? @"Club Timeline" : @"Create Status Update"]
//											 withUserClub:clubVO];
		
		if ([clubVO.submissions count] > 0) {
//			HONClubTimelineViewController *clubTimelineViewController = [[HONClubTimelineViewController alloc] initWithClub:clubVO atPhotoIndex:0];
//			[self.navigationController pushViewController:[[HONClubTimelineViewController alloc] initWithClub:clubVO atPhotoIndex:0] animated:[[HONAnimationOverseer sharedInstance] isSegueAnimationEnabledForPushViewController:clubTimelineViewController]];
		
		} else {
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONComposeViewController alloc] initWithClub:clubVO]];
			[navigationController setNavigationBarHidden:YES];
			[self presentViewController:navigationController animated:[[HONAnimationOverseer sharedInstance] isSegueAnimationEnabledForModalViewController:navigationController.presentingViewController] completion:nil];
		}
	}
}

- (void)_goPanGesture:(UIPanGestureRecognizer *)gestureRecognizer {
	//	NSLog(@"[:|:] _goPanGesture:[%@]-=(%@)=-", NSStringFromCGPoint([gestureRecognizer velocityInView:self.view]), (gestureRecognizer.state == UIGestureRecognizerStateBegan) ? @"BEGAN" : (gestureRecognizer.state == UIGestureRecognizerStateCancelled) ? @"CANCELED" : (gestureRecognizer.state == UIGestureRecognizerStateEnded) ? @"ENDED" : (gestureRecognizer.state == UIGestureRecognizerStateFailed) ? @"FAILED" : (gestureRecognizer.state == UIGestureRecognizerStatePossible) ? @"POSSIBLE" : (gestureRecognizer.state == UIGestureRecognizerStateChanged) ? @"CHANGED" : (gestureRecognizer.state == UIGestureRecognizerStateRecognized) ? @"RECOGNIZED" : @"N/A");
	[super _goPanGesture:gestureRecognizer];
	HONClubPhotoViewCell *cell = (HONClubPhotoViewCell *)[_tableView cellForRowAtIndexPath:[_tableView indexPathForRowAtPoint:[gestureRecognizer locationInView:_tableView]]];
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Club Row Swipe"
//										 withUserClub:cell.clubVO];
	
	if ([gestureRecognizer velocityInView:self.view].x <= -1500) {
		[self _goSelectClub:cell.clubVO];
	}
}


#pragma mark - Notifications
- (void)_showFirstRun:(NSNotification *)notification {
	NSLog(@"::|> _showFirstRun <|::");
	
	[self _goRegistration];
}

- (void)_completedFirstRun:(NSNotification *)notification {
	NSLog(@"::|> _completedFirstRun <|::");
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"HOME - enter"];
	
	_locationManager = [[CLLocationManager alloc] init];
	_locationManager.delegate = self;
	_locationManager.distanceFilter = 100;
	if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
		[_locationManager requestWhenInUseAuthorization];
	[_locationManager startUpdatingLocation];
	
	NSLog(@"%@._completedFirstRun - CLAuthorizationStatus = [%@]", self.class, NSStringFromCLAuthorizationStatus([CLLocationManager authorizationStatus]));
//	if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
//		[self _promptForAddressBookPermission];
//	
//	else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
//		[self _promptForAddressBookAccess];
	
	[self _goReloadTableViewContents];
}

- (void)_selectedContactsTab:(NSNotification *)notification {
	NSLog(@"::|> _selectedContactsTab <|::");
	
	[[HONStateMitigator sharedInstance] incrementTotalCounterForType:_totalType];
	NSLog(@"[:|:] [%@]:[%@]-=(%d)=-", self.class, [[HONStateMitigator sharedInstance] _keyForTotalType:_totalType], [[HONStateMitigator sharedInstance] totalCounterForType:_totalType]);
	
	[self _goReloadTableViewContents];
	
	if ([notification.object isEqualToString:@"Y"] && [_tableView.visibleCells count] > 0)
		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)_refreshContactsTab:(NSNotification *)notification {
	NSLog(@"::|> _refreshContactsTab <|::");
	
	[self _goReloadTableViewContents];
	
	if ([notification.object isEqualToString:@"Y"] && [_tableView.visibleCells count] > 0)
		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)_tareContactsTab:(NSNotification *)notification {
	NSLog(@"::|> tareContactsTab <|::");
	
	if ([_tableView.visibleCells count] > 0)
		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


#pragma mark - UI Presentation
- (void)_advanceTimelineFromCell:(HONClubPhotoViewCell *)cell byAmount:(int)amount {
	int rows = MIN(amount, (((int)[_tableView numberOfSections] - 1) - (int)[_tableView indexPathForCell:cell].section));
	
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Next Update"
//										withClubPhoto:cell.clubPhotoVO];
	
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"HOME - next_image"];
	
	[_tableView setContentInset:kOrthodoxTableViewEdgeInsets];
	int index = MIN(MAX(0, (int)[_tableView indexPathForCell:(UITableViewCell *)cell].section + rows), ((int)[_clubPhotos count] - 1));
	[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}

//- (void)_promptForAddressBookAccess {
//	[[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"ok_access", @"We need your OK to access the address book.")
//								message:NSLocalizedString(@"grant_access", @"Flip the switch in Settings -> Privacy -> Contacts -> Selfieclub to grant access.")
//							   delegate:nil
//					  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
//					  otherButtonTitles:nil] show];
//}
//
//- (void)_promptForAddressBookPermission {
//	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"allow_access", @"Allow Access to contacts?")
//														message:nil
//													   delegate:self
//											  cancelButtonTitle:NSLocalizedString(@"alert_no", nil)
//											  otherButtonTitles:NSLocalizedString(@"alert_yes", nil), nil];
//	[alertView setTag:0];
//	[alertView show];
//}


#pragma mark - ClubPhotoViewCell Delegates
- (void)clubPhotoViewCell:(HONClubPhotoViewCell *)cell advancePhoto:(HONClubPhotoVO *)clubPhotoVO {
	NSLog(@"[*:*] clubPhotoViewCell:advancePhoto:(%d - %@)", clubPhotoVO.userID, clubPhotoVO.username);
	[self _advanceTimelineFromCell:cell byAmount:1];
}

- (void)clubPhotoViewCell:(HONClubPhotoViewCell *)cell showUserProfileForClubPhoto:(HONClubPhotoVO *)clubPhotoVO {
	NSLog(@"[*:*] clubPhotoViewCell:showUserProfileForClubPhoto:(%d - %@)", clubPhotoVO.userID, clubPhotoVO.username);
//	[self.navigationController pushViewController:[[HONUserProfileViewController alloc] initWithUserID:clubPhotoVO.userID] animated:YES];
}

- (void)clubPhotoViewCell:(HONClubPhotoViewCell *)cell replyToPhoto:(HONClubPhotoVO *)clubPhotoVO {
	NSLog(@"[*:*] clubPhotoViewCell:replyToPhoto:(%d - %@)", clubPhotoVO.userID, clubPhotoVO.username);
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Reply"
//										withClubPhoto:clubPhotoVO];
	
	[self _goReplyToClubPhoto:clubPhotoVO forClub:cell.clubVO];
}

- (void)clubPhotoViewCell:(HONClubPhotoViewCell *)cell upVotePhoto:(HONClubPhotoVO *)clubPhotoVO {
	NSLog(@"[*:*] clubPhotoViewCell:upvotePhoto:(%d - %@)", clubPhotoVO.userID, clubPhotoVO.username);
	//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Upvote"
//										withClubPhoto:clubPhotoVO];
	
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"HOME - up"];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PLAY_OVERLAY_ANIMATION" object:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"likeOverlay"]]];
	[self _advanceTimelineFromCell:cell byAmount:1];
	
	[[HONAPICaller sharedInstance] voteStatusUpdateWithStatusUpdateID:clubPhotoVO.challengeID isUpVote:YES completion:^(NSDictionary *result) {
		[self _updateScoreForClubPhoto:clubPhotoVO isIncrement:YES];
		[self _retrieveActivityItems];
		
		NSMutableArray *votes = [[[NSUserDefaults standardUserDefaults] objectForKey:@"votes"] mutableCopy];
		[votes addObject:@{@"id"	: @(clubPhotoVO.challengeID),
						   @"act"	: @(1)}];
		[[NSUserDefaults standardUserDefaults] setObject:[votes copy] forKey:@"votes"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_LIKE_COUNT" object:[HONChallengeVO challengeWithDictionary:result]];
	}];
}

- (void)clubPhotoViewCell:(HONClubPhotoViewCell *)cell downVotePhoto:(HONClubPhotoVO *)clubPhotoVO {
	NSLog(@"[*:*] clubPhotoViewCell:downVotePhoto:(%d - %@)", clubPhotoVO.userID, clubPhotoVO.username);
		//[[HONAnalyticsReporter sharedInstance] trackEvent:@"Friends Tab - Down Vote"
//										  withClubPhoto:clubPhotoVO];
	
	[[HONAnalyticsReporter sharedInstance] trackEvent:@"HOME - down"];
	[self _advanceTimelineFromCell:cell byAmount:1];
	[[HONAPICaller sharedInstance] voteStatusUpdateWithStatusUpdateID:clubPhotoVO.challengeID isUpVote:NO completion:^(NSDictionary *result) {
		[self _updateScoreForClubPhoto:clubPhotoVO isIncrement:NO];
		
		NSMutableArray *votes = [[[NSUserDefaults standardUserDefaults] objectForKey:@"votes"] mutableCopy];
		[votes addObject:@{@"id"	: @(clubPhotoVO.challengeID),
						   @"act"	: @(-1)}];
		[[NSUserDefaults standardUserDefaults] setObject:[votes copy] forKey:@"votes"];
		[[NSUserDefaults standardUserDefaults] synchronize];
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_LIKE_COUNT" object:[HONChallengeVO challengeWithDictionary:result]];
	}];
}


#pragma mark - LocationManager Delegates
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"**_[%@ locationManager:didFailWithError:(%@)]_**", self.class, error.description);
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
	NSLog(@"**_[%@ locationManager:didChangeAuthorizationStatus:(%@)]_**", self.class, NSStringFromCLAuthorizationStatus(status));// (status == kCLAuthorizationStatusAuthorized) ? @"Authorized" : (status == kCLAuthorizationStatusAuthorizedAlways) ? @"AuthorizedAlways" : (status == kCLAuthorizationStatusAuthorizedWhenInUse) ? @"AuthorizedWhenInUse" : (status == kCLAuthorizationStatusDenied) ? @"Denied" : (status == kCLAuthorizationStatusRestricted) ? @"Restricted" : (status == kCLAuthorizationStatusNotDetermined) ? @"NotDetermined" : @"UNKNOWN");
}

- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations {
	NSLog(@"**_[%@ locationManager:didUpdateLocations:(%@)]_**", self.class, locations);
	[_locationManager stopUpdatingLocation];
	
	[[HONDeviceIntrinsics sharedInstance] updateDeviceLocation:[locations firstObject]];
	
	NSLog(@"WITHIN RANGE:[%@]", NSStringFromBOOL([[HONGeoLocator sharedInstance] isWithinOrthodoxClub]));
	NSLog(@"MEMBER OF:[%d] =-= (%@)", [[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue], NSStringFromBOOL([[HONClubAssistant sharedInstance] isMemberOfClubWithClubID:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue] includePending:YES]));
	if ([[HONGeoLocator sharedInstance] isWithinOrthodoxClub] && ![[HONClubAssistant sharedInstance] isMemberOfClubWithClubID:[[[[NSUserDefaults standardUserDefaults] objectForKey:@"orthodox_club"] objectForKey:@"club_id"] intValue] includePending:YES]) {
//		[[HONAPICaller sharedInstance] joinClub:[[HONClubAssistant sharedInstance] orthodoxMemberClub] withMemberID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
//			
//			if ((BOOL)[[result objectForKey:@"result"] intValue]) {
//				[self _goReloadTableViewContents];
//			}
//		}];
	}
//	} else
//		[self _goReloadTableViewContents];
}


#pragma mark - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return ([_clubPhotos count]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (1);//(section == 0) ? [_unseenClubs count] : [_seenClubs count]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONClubPhotoViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HONClubPhotoViewCell alloc] init];
	[cell setSize:[tableView rectForRowAtIndexPath:indexPath].size];
	[cell setIndexPath:indexPath];
	cell.delegate = self;
	
//	HONUserClubVO *clubVO = (indexPath.section == 0) ? (HONUserClubVO *)[_unseenClubs objectAtIndex:indexPath.row] : (HONUserClubVO *)[_seenClubs objectAtIndex:indexPath.row];
	HONClubPhotoVO *clubPhotoVO = (HONClubPhotoVO *)[_clubPhotos objectAtIndex:indexPath.section];//[clubVO.submissions firstObject];
//	cell.clubVO = clubVO;
	cell.clubPhotoVO = clubPhotoVO;
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
//	if (!tableView.decelerating)
//		[cell toggleImageLoading:YES];
	
	return (cell);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return (nil);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return ([UIScreen mainScreen].bounds.size.height);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return (0.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (nil);
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
//	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
//	HONClubPhotoViewCell *cell = (HONClubPhotoViewCell *)[tableView cellForRowAtIndexPath:indexPath];
//	
//	NSLog(@"-[- cell.clubVO.clubID:[%d]", cell.clubVO.clubID);
//	
//	if (indexPath.section == 0) {
//		HONUserClubVO *clubVO = (HONUserClubVO *)[_unseenClubs objectAtIndex:indexPath.row];
//		NSLog(@"UNSEEN CLUB:[%@]", clubVO.clubName);
//		
//	} else {
//		HONUserClubVO *clubVO = (HONUserClubVO *)[_seenClubs objectAtIndex:indexPath.row];
//		NSLog(@"SEEN CLUB:[%@]", clubVO.clubName);
//	}
//	
//	[self _goSelectClub:cell.clubVO];
//}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	cell.alpha = 1.0;
//	cell.alpha = 0.0;
//	[UIView animateKeyframesWithDuration:0.125 delay:0.050 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseOut) animations:^(void) {
//		cell.alpha = 1.0;
//	} completion:^(BOOL finished) {
//	}];
}


#pragma mark - ScrollView Delegates
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//	[[_tableView visibleCells] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//		HONClubPhotoViewCell *cell = (HONClubPhotoViewCell *)obj;
//		[cell toggleImageLoading:YES];
//	}];
}


#pragma mark - AlertView Delegates
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 0) {
		NSLog(@"CONTACTS:[%ld]", (long)buttonIndex);
		if (buttonIndex == 1) {
			if (ABAddressBookRequestAccessWithCompletion) {
				ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
				NSLog(@"ABAddressBookGetAuthorizationStatus() = [%@]", NSStringFromABAuthorizationStatus(ABAddressBookGetAuthorizationStatus()));
				
				if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
					ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
					});
					
				} else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
					ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
					});
					
				} else {
				}
				
				[self _goReloadTableViewContents];
			}
		}
		
	} else if (alertView.tag == 1) {
	} else if (alertView.tag == 2) {
		[self _goReloadTableViewContents];
	}
}

@end
