//
//  HONClubsTimelineViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 04/25/2014 @ 10:58 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "NSString+DataTypes.h"

#import "CKRefreshControl.h"
#import "MBProgressHUD.h"
#import "PCCandyStoreSearchController.h"
#import "PicoManager.h"

#import "HONClubsNewsFeedViewController.h"
#import "HONClubTimelineViewController.h"
#import "HONUserProfileViewController.h"
#import "HONSelfieCameraViewController.h"
#import "HONCreateClubViewController.h"
#import "HONUserClubsViewController.h"
#import "HONInviteContactsViewController.h"
#import "HONClubNewsFeedViewCell.h"
#import "HONTableView.h"
#import "HONTutorialView.h"
#import "HONHeaderView.h"
#import "HONActivityHeaderButtonView.h"
#import "HONCreateSnapButtonView.h"
#import "HONTableHeaderView.h"


@interface HONClubsNewsFeedViewController () <HONClubNewsFeedViewCellDelegate, HONTutorialViewDelegate>
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) HONTableView *tableView;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) HONUserClubVO *selectedClubVO;

@property (nonatomic, strong) NSMutableDictionary *clubIDs;
@property (nonatomic, strong) NSMutableArray *ownedClubs;
@property (nonatomic, strong) NSMutableArray *allClubs;
@property (nonatomic, strong) NSMutableArray *dictClubs;
@property (nonatomic, strong) NSMutableArray *autoGenItems;
@property (nonatomic, strong) NSMutableArray *timelineItems;
@property (nonatomic, strong) UIImageView *overlayImageView;
@property (nonatomic, strong) HONTutorialView *tutorialView;
@property (nonatomic) BOOL isFromCreateClub;
@end


@implementation HONClubsNewsFeedViewController


- (id)init {
	if ((self = [super init])) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_selectedNewsTab:) name:@"SELECTED_NEWS_TAB" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tareNewsTab:) name:@"TARE_NEWS_TAB" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshNewsTab:) name:@"REFRESH_NEWS_TAB" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshNewsTab:) name:@"REFRESH_ALL_TABS" object:nil];
		
		
		_ownedClubs = [[NSMutableArray alloc] init];
		_allClubs = [[NSMutableArray alloc] init];
		_dictClubs = [[NSMutableArray alloc] init];
		_autoGenItems = [[NSMutableArray alloc] init];
		_timelineItems = [[NSMutableArray alloc] init];
		_clubIDs = [NSMutableDictionary dictionaryWithObjects:@[[NSMutableArray array],
																[NSMutableArray array],
																[NSMutableArray array],
																[NSMutableArray array]]
													  forKeys:[[HONClubAssistant sharedInstance] clubTypeKeys]];
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
- (void)_retrieveTimeline {
//	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
//	_progressHUD.labelText = NSLocalizedString(@"hud_loading", nil);
//	_progressHUD.mode = MBProgressHUDModeIndeterminate;
//	_progressHUD.minShowTime = kHUDTime;
//	_progressHUD.taskInProgress = YES;
	
	
	_ownedClubs = [[NSMutableArray alloc] init];
	_allClubs = [[NSMutableArray alloc] init];
	_dictClubs = [[NSMutableArray alloc] init];
	_timelineItems = [[NSMutableArray alloc] init];
	_autoGenItems = [[NSMutableArray alloc] init];
	_clubIDs = [NSMutableDictionary dictionaryWithObjects:@[[NSMutableArray array],
															[NSMutableArray array],
															[NSMutableArray array],
															[NSMutableArray array]]
												  forKeys:[[HONClubAssistant sharedInstance] clubTypeKeys]];
	
	[[HONAPICaller sharedInstance] retrieveClubsForUserByUserID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
		for (NSString *key in [[HONClubAssistant sharedInstance] clubTypeKeys]) {
			NSMutableArray *clubIDs = [_clubIDs objectForKey:key];
			
			for (NSDictionary *dict in [result objectForKey:key]) {
				HONUserClubVO *vo = [HONUserClubVO clubWithDictionary:dict];
				if ([key isEqualToString:@"owned"])
					[_ownedClubs addObject:vo];
				
				[_allClubs addObject:vo];
				if ([vo.submissions count] > 0 || vo.clubEnrollmentType == HONClubEnrollmentTypePending) {
					[clubIDs addObject:[NSNumber numberWithInt:vo.clubID]];
					[_dictClubs addObject:dict];
				}
			}
			
			[_clubIDs setValue:clubIDs forKey:key];
		}
		
		_timelineItems = nil;
		_timelineItems = [NSMutableArray array];
		for (NSDictionary *dict in [NSMutableArray arrayWithArray:[_dictClubs sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"updated" ascending:NO]]]])
			[_timelineItems addObject:[HONUserClubVO clubWithDictionary:dict]];
		
		[self _suggestClubs];
//		_feedContentType = HONFeedContentTypeEmpty;
//		_feedContentType += (((int)[[_clubIDs objectForKey:@"other"] count] > 0) * HONFeedContentTypeAutoGenClubs);
//		_feedContentType += (((int)[[_clubIDs objectForKey:@"owned"] count] > 0) * HONFeedContentTypeOwnedClubs);
//		_feedContentType += (((int)[[_clubIDs objectForKey:@"member"] count] > 0) * HONFeedContentTypeJoinedClubs);
//		_feedContentType += (((int)[[_clubIDs objectForKey:@"pending"] count] > 0) * HONFeedContentTypeClubInvites);
		
		[self _didFinishDataRefresh];
		
//		if (_overlayImageView != nil) {
//			[_overlayImageView removeFromSuperview];
//			_overlayImageView = nil;
//		}
		
//		if ([[_clubIDs objectForKey:@"owned"] count] == 0 && [[_clubIDs objectForKey:@"member"] count] == 0) {
//			_overlayImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"newsFeedOverlay"]];
//			_overlayImageView.frame = CGRectOffset(_overlayImageView.frame, 3.0, 210.0);
//			[_tableView addSubview:_overlayImageView];
//			
//			[self _cycleOverlay:_overlayImageView];
//		}
	}];
}

- (void)_joinClub:(HONUserClubVO *)userClubVO {
	[[HONAPICaller sharedInstance] joinClub:userClubVO withMemberID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
		_selectedClubVO = [HONUserClubVO clubWithDictionary:result];
	}];
}


- (void)_createClubWithProtoVO:(HONUserClubVO *)userClubVO {
	[[HONAPICaller sharedInstance] createClubWithTitle:userClubVO.clubName withDescription:userClubVO.blurb withImagePrefix:userClubVO.coverImagePrefix completion:^(NSDictionary *result) {
		_selectedClubVO = [HONUserClubVO clubWithDictionary:result];
		[self _retrieveTimeline];
	}];
}

#pragma mark - Data Manip
- (void)_suggestClubs {
	
	_autoGenItems = nil;
	_autoGenItems = [NSMutableArray array];
	
	NSMutableArray *segmentedKeys = [[NSMutableArray alloc] init];
	NSMutableDictionary *segmentedDict = [[NSMutableDictionary alloc] init];
	NSMutableArray *unsortedContacts = [NSMutableArray array];
	NSString *clubName = @"";
	
	ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, NULL);
	CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
	CFIndex nPeople = MIN(100, ABAddressBookGetPersonCount(addressBook));
	
	for (int i=0; i<nPeople; i++) {
		ABRecordRef ref = CFArrayGetValueAtIndex(allPeople, i);
		
		NSString *fName = (__bridge NSString *)ABRecordCopyValue(ref, kABPersonFirstNameProperty);
		NSString *lName = (__bridge NSString *)ABRecordCopyValue(ref, kABPersonLastNameProperty);
		
		if ([fName length] == 0)
			continue;
		
		if ([lName length] == 0)
			lName = @"";
		
		
		ABMultiValueRef phoneProperties = ABRecordCopyValue(ref, kABPersonPhoneProperty);
		CFIndex phoneCount = ABMultiValueGetCount(phoneProperties);
		
		NSString *phoneNumber = @"";
		if (phoneCount > 0)
			phoneNumber = (__bridge NSString *)ABMultiValueCopyValueAtIndex(phoneProperties, 0);
		
		CFRelease(phoneProperties);
		
		
		NSString *email = @"";
		ABMultiValueRef emailProperties = ABRecordCopyValue(ref, kABPersonEmailProperty);
		CFIndex emailCount = ABMultiValueGetCount(emailProperties);
		
		if (emailCount > 0)
			email = (__bridge NSString *)ABMultiValueCopyValueAtIndex(emailProperties, 0);
		
		CFRelease(emailProperties);
		
		if ([email length] == 0)
			email = @"";
		
		if ([phoneNumber length] > 0 || [email length] > 0) {
			[unsortedContacts addObject:[HONContactUserVO contactWithDictionary:@{@"f_name"	: fName,
																				  @"l_name"	: lName,
																				  @"phone"	: phoneNumber,
																				  @"email"	: email,
																				  @"image"	: UIImagePNGRepresentation([UIImage imageNamed:@"avatarPlaceholder"])}]];
		}
	}
	
	// sand hill
	NSArray *emailDomains = @[@"dcm.com",
							  @"500.co",
							  @"firstround.com",
							  @"a16z.com",
							  @"ggvc.com",
							  @"yomorrowvc.com",
							  @"hcp.com",
							  @"sequoiacap.com",
							  @"cyberagentventures.com",
							  @"accel.com",
							  @"idgvc.com",
							  @"nhninv.com",
							  @"menloventures.com",
							  @"svangel.com",
							  @"sherpavc.com",
							  @"techcrunch.com"];
	
	for (HONContactUserVO *vo in unsortedContacts) {
		if ([vo.email length] == 0)
			continue;
		
		for (NSString *domain in emailDomains) {
			//NSLog(@"vo.email:[%@] >> [%@]", [vo.email lowercaseString], domain);
			if ([[vo.email lowercaseString] rangeOfString:domain].location != NSNotFound) {
				clubName = @"Sand Hill Bros";
				break;
			}
		}
	}
	
	if ([clubName length] > 0) {
		NSMutableDictionary *dict = [[[HONClubAssistant sharedInstance] emptyClubDictionaryWithOwner:@{}] mutableCopy];
		[dict setValue:@"0" forKey:@"id"];
		[dict setValue:clubName forKey:@"name"];
		[dict setValue:[[HONClubAssistant sharedInstance] defaultCoverImagePrefix] forKey:@"img"];
		[dict setValue:@"AUTO_GEN" forKey:@"club_type"];
		
		HONUserClubVO *vo = [HONUserClubVO clubWithDictionary:[dict copy]];
		[_autoGenItems addObject:vo];
		clubName = @"";
	}
	
	
	// family
	NSArray *deviceName = [[[HONDeviceIntrinsics sharedInstance] deviceName] componentsSeparatedByString:@" "];
	if ([[deviceName lastObject] isEqualToString:@"iPhone"] || [[deviceName lastObject] isEqualToString:@"iPod"]) {
		NSString *familyName = [deviceName objectAtIndex:1];
		familyName = [familyName substringToIndex:[familyName length] - 2];
		clubName = [NSString stringWithFormat:@"%@ Family", [[[familyName substringToIndex:1] uppercaseString] stringByAppendingString:[familyName substringFromIndex:1]]];
	}
	
	else {
		for (HONContactUserVO *vo in unsortedContacts) {
			if (![segmentedKeys containsObject:vo.lastName]) {
				[segmentedKeys addObject:vo.lastName];
				
				NSMutableArray *newSegment = [[NSMutableArray alloc] initWithObjects:vo, nil];
				[segmentedDict setValue:newSegment forKey:vo.lastName];
				
			} else {
				NSMutableArray *prevSegment = (NSMutableArray *)[segmentedDict valueForKey:vo.lastName];
				[prevSegment addObject:vo];
				[segmentedDict setValue:prevSegment forKey:vo.lastName];
			}
		}
	
		for (NSString *key in segmentedDict) {
			if ([[segmentedDict objectForKey:key] count] >= 2) {
				clubName = [NSString stringWithFormat:@"%@ Family", key];
				break;
			}
		}
	}
	
	
	for (HONUserClubVO *vo in _allClubs) {
		if ([vo.clubName isEqualToString:clubName]) {
			clubName = @"";
			break;
		}
	}
	
	
	if ([clubName length] > 0) {
		NSMutableDictionary *dict = [[[HONClubAssistant sharedInstance] emptyClubDictionaryWithOwner:@{}] mutableCopy];
		[dict setValue:@"0" forKey:@"id"];
		[dict setValue:clubName forKey:@"name"];
		[dict setValue:[[HONClubAssistant sharedInstance] defaultCoverImagePrefix] forKey:@"img"];
		[dict setValue:@"AUTO_GEN" forKey:@"club_type"];

		HONUserClubVO *vo = [HONUserClubVO clubWithDictionary:[dict copy]];
		[_autoGenItems addObject:vo];
	}
	
	// area code
	if ([[HONAppDelegate phoneNumber] length] > 0) {
		NSString *clubName = [[[HONAppDelegate phoneNumber] substringWithRange:NSMakeRange(2, 3)] stringByAppendingString:@" club"];
		for (HONUserClubVO *vo in _allClubs) {
			if ([vo.clubName isEqualToString:clubName]) {
				clubName = @"";
				break;
			}
		}
		
		if ([clubName length] > 0) {
			NSMutableDictionary *dict = [[[HONClubAssistant sharedInstance] emptyClubDictionaryWithOwner:@{}] mutableCopy];
			[dict setValue:@"0" forKey:@"id"];
			[dict setValue:clubName forKey:@"name"];
			[dict setValue:[[HONClubAssistant sharedInstance] defaultCoverImagePrefix] forKey:@"img"];
			[dict setValue:@"AUTO_GEN" forKey:@"club_type"];

			HONUserClubVO *vo = [HONUserClubVO clubWithDictionary:[dict copy]];
			[_autoGenItems addObject:vo];
		}
	}
	
	
	// email domain
	[segmentedDict removeAllObjects];
	[segmentedKeys removeAllObjects];
	
	for (HONContactUserVO *vo in unsortedContacts) {
		if ([vo.email length] > 0) {
			NSString *emailDomain = [[vo.email componentsSeparatedByString:@"@"] lastObject];
			
			
			BOOL isValid = YES;
			for (NSString *domain in [HONAppDelegate excludedClubDomains]) {
				if ([emailDomain isEqualToString:domain]) {
					isValid = NO;
					break;
				}
			}
			
			if (isValid) {
				if (![segmentedKeys containsObject:emailDomain]) {
					[segmentedKeys addObject:emailDomain];
					
					NSMutableArray *newSegment = [[NSMutableArray alloc] initWithObjects:vo, nil];
					[segmentedDict setValue:newSegment forKey:emailDomain];
					
				} else {
					NSMutableArray *prevSegment = (NSMutableArray *)[segmentedDict valueForKey:emailDomain];
					[prevSegment addObject:vo];
					[segmentedDict setValue:prevSegment forKey:emailDomain];
				}
			}
		}
	}
	
	clubName = @"";
	for (NSString *key in segmentedDict) {
		if ([[segmentedDict objectForKey:key] count] >= 2) {
			clubName = [key stringByAppendingString:@" Club"];
			break;
		}
	}
	
	if ([clubName length] > 0) {
		NSMutableDictionary *dict = [[[HONClubAssistant sharedInstance] emptyClubDictionaryWithOwner:@{}] mutableCopy];
		[dict setValue:@"0" forKey:@"id"];
		[dict setValue:clubName forKey:@"name"];
		[dict setValue:[[HONClubAssistant sharedInstance] defaultCoverImagePrefix] forKey:@"img"];
		[dict setValue:@"AUTO_GEN" forKey:@"club_type"];

		HONUserClubVO *vo = [HONUserClubVO clubWithDictionary:[dict copy]];
		[_autoGenItems addObject:vo];
	}
}


#pragma mark - Data Handling
- (void)_goDataRefresh:(CKRefreshControl *)sender {
	[self _retrieveTimeline];
}

- (void)_didFinishDataRefresh {
	if (_progressHUD != nil) {
		[_progressHUD hide:YES];
		_progressHUD = nil;
	}
	
	[_tableView reloadData];
	[_refreshControl endRefreshing];
}


#pragma mark - View lifecycle
- (void)loadView {
	ViewControllerLog(@"[:|:] [%@ loadView] [:|:]", self.class);
	[super loadView];
	
	_isFromCreateClub = NO;
	self.view.backgroundColor = [UIColor whiteColor];
	
	HONHeaderView *headerView = [[HONHeaderView alloc] initWithTitle:@"News"];
	[headerView addButton:[[HONActivityHeaderButtonView alloc] initWithTarget:self action:@selector(_goProfile)]];
	[headerView addButton:[[HONCreateSnapButtonView alloc] initWithTarget:self action:@selector(_goCreateChallenge) asLightStyle:NO]];
	[self.view addSubview:headerView];
	
	_tableView = [[HONTableView alloc] initWithFrame:CGRectMake(0.0, kNavHeaderHeight, 320.0, self.view.frame.size.height - kNavHeaderHeight) style:UITableViewStylePlain];
	[_tableView setContentInset:kOrthodoxTableViewEdgeInsets];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[self.view addSubview:_tableView];
	
	_refreshControl = [[UIRefreshControl alloc] init];
	[_refreshControl addTarget:self action:@selector(_goDataRefresh:) forControlEvents:UIControlEventValueChanged];
	[_tableView addSubview: _refreshControl];
	
	[self _retrieveTimeline];
}

- (void)viewDidLoad {
	ViewControllerLog(@"[:|:] [%@ viewDidLoad] [:|:]", self.class);
	[super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewWillAppear:%@] [:|:]", self.class, [@"" stringFromBOOL:animated]);
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewDidAppear:%@] [:|:]", self.class, [@"" stringFromBOOL:animated]);
	[super viewDidAppear:animated];
	
	NSLog(@"newsTab_total:[%d]", [HONAppDelegate totalForCounter:@"newsTab"]);
	if ([HONAppDelegate incTotalForCounter:@"newsTab"] == 1) {
//		[[[UIAlertView alloc] initWithTitle:@"News Tip"
//									message:@"The more clubs you join the more your feed fills up!"
//								   delegate:nil
//						  cancelButtonTitle:@"OK"
//						  otherButtonTitles:nil] show];
	}
	
	if (_isFromCreateClub) {
		_isFromCreateClub = NO;
		
		_tutorialView = [[HONTutorialView alloc] initWithBGImage:[UIImage imageNamed:@"tutorial_resume"]];
		_tutorialView.delegate = self;
		
		[[HONScreenManager sharedInstance] appWindowAdoptsView:_tutorialView];
		[_tutorialView introWithCompletion:nil];
	}
}

- (void)viewWillDisappear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewWillDisappear:%@] [:|:]", self.class, [@"" stringFromBOOL:animated]);
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewDidDisappear:%@] [:|:]", self.class, [@"" stringFromBOOL:animated]);
	[super viewDidDisappear:animated];
}

- (void)viewDidUnload {
	ViewControllerLog(@"[:|:] [%@ viewDidUnload] [:|:]", self.class);
	[super viewDidUnload];
}


#pragma mark - Navigation
- (void)_goProfile {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Timeline - Profile"];
	[self.navigationController pushViewController:[[HONUserProfileViewController alloc] initWithUserID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue]] animated:YES];
}

- (void)_goCreateChallenge {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Clubs Timeline - Create Challenge"];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONSelfieCameraViewController alloc] initAsNewChallenge]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)_goRefresh {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Refresh"];
	[self _retrieveTimeline];
}

- (void)_goConfirmClubs {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Confirm Clubs"];
	
//	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONCreateClubViewController alloc] init]];
//	[navigationController setNavigationBarHidden:YES];
//	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_goCreateClub {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Create Club"];
	
	_isFromCreateClub = YES;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONCreateClubViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - Notifications
- (void)_selectedNewsTab:(NSNotification *)notification {
	NSLog(@"::|> _selectedNewsTab <|::");
//	[self _retrieveTimeline];
}

- (void)_refreshNewsTab:(NSNotification *)notification {
	NSLog(@"::|> _refreshNewsTab <|::");
	[self _goRefresh];
}

- (void)_tareNewsTab:(NSNotification *)notification {
	NSLog(@"::|> _tareNewsTab <|::");
	
	if (_tableView.contentOffset.y > 0) {
		_tableView.pagingEnabled = NO;
		[_tableView setContentOffset:CGPointZero animated:YES];
	}
}


#pragma mark - ClubNewsFeedItemViewCell Delegates
- (void)clubNewsFeedViewCell:(HONClubNewsFeedViewCell *)viewCell createClubWithProtoVO:(HONUserClubVO *)userClubVO {
	NSLog(@"[*:*] clubNewsFeedViewCell:createClubWithProtoVO:(%@ - %@)", userClubVO.clubName, userClubVO.blurb);
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Create Club"];
	
	_selectedClubVO = userClubVO;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
														message:[NSString stringWithFormat:@"Would you like to join the %@ Selfieclub?", _selectedClubVO.clubName]
													   delegate:self
											  cancelButtonTitle:@"Yes"
											  otherButtonTitles:@"No", nil];
	
	[alertView setTag:2];
	[alertView show];
}

- (void)clubNewsFeedViewCell:(HONClubNewsFeedViewCell *)viewCell enterTimelineForClub:(HONUserClubVO *)userClubVO {
	NSLog(@"[*:*] clubNewsFeedViewCell:enterTimelineForClub:(%@ - %@)", userClubVO.clubName, userClubVO.blurb);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Enter Club"
									   withUserClub:userClubVO];
	
	//[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
	[self.navigationController pushViewController:[[HONClubTimelineViewController alloc] initWithClub:userClubVO] animated:YES];
}

- (void)clubNewsFeedViewCell:(HONClubNewsFeedViewCell *)viewCell joinClub:(HONUserClubVO *)userClubVO {
	NSLog(@"[*:*] clubNewsFeedViewCell:joinClub:(%d - %@)", userClubVO.clubID, userClubVO.clubName);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Join Club"
									   withUserClub:userClubVO];
	
	_selectedClubVO = userClubVO;
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
														message:[NSString stringWithFormat:@"Would you like to join the %@ Selfieclub?", _selectedClubVO.clubName]
													   delegate:self
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:@"Cancel", nil];
	
	[alertView setTag:0];
	[alertView show];
}

- (void)clubNewsFeedViewCell:(HONClubNewsFeedViewCell *)viewCell replyToClubPhoto:(HONUserClubVO *)userClubVO {
	NSLog(@"[*:*] clubNewsFeedViewCell:replyToClubPhoto:(%d - %@)", userClubVO.clubID, userClubVO.clubName);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Reply"
									   withUserClub:userClubVO];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONSelfieCameraViewController alloc] initWithClub:userClubVO]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)clubNewsFeedViewCell:(HONClubNewsFeedViewCell *)viewCell upvoteClubPhoto:(HONUserClubVO *)userClubVO {
	NSLog(@"[*:*] clubNewsFeedViewCell:likeClubChallenge:(%d - %@)", userClubVO.clubID, userClubVO.clubName);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Liked"
									   withUserClub:userClubVO];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PLAY_OVERLAY_ANIMATION" object:[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"likeOverlay"]]];
	[[HONAPICaller sharedInstance] verifyUserWithUserID:((HONClubPhotoVO *)[userClubVO.submissions lastObject]).userID asLegit:YES completion:^(NSDictionary *result) {
		[[HONAPICaller sharedInstance] retrieveUserByUserID:((HONClubPhotoVO *)[userClubVO.submissions lastObject]).userID completion:^(NSDictionary *result) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_LIKE_COUNT" object:[HONChallengeVO challengeWithDictionary:result]];
		}];
	}];
}

- (void)clubNewsFeedViewCell:(HONClubNewsFeedViewCell *)viewCell showUserProfileForClubPhoto:(HONClubPhotoVO *)clubPhotoVO {
	NSLog(@"[*:*] clubNewsFeedViewCell:showUserProfileForClubPhoto:(%d - %@)", clubPhotoVO.clubID, clubPhotoVO.username);
	
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - User Profile"
									   withClubPhoto:clubPhotoVO];
	
	[self.navigationController pushViewController:[[HONUserProfileViewController alloc] initWithUserID:clubPhotoVO.userID] animated:YES];
}


#pragma mark - TutorialView Delegates
- (void)tutorialViewClose:(HONTutorialView *)tutorialView {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Tutorial Close"];
	
	[_tutorialView outroWithCompletion:^(BOOL finished) {
		[_tutorialView removeFromSuperview];
		_tutorialView = nil;
	}];
}

- (void)tutorialViewInvite:(HONTutorialView *)tutorialView {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Tutorial Invite"];
	
	[_tutorialView outroWithCompletion:^(BOOL finished) {
		[_tutorialView removeFromSuperview];
		_tutorialView = nil;
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONInviteContactsViewController alloc] initWithClub:_selectedClubVO viewControllerPushed:NO]];
		[navigationController setNavigationBarHidden:YES];
		[self presentViewController:navigationController animated:YES completion:nil];
	}];
}

- (void)tutorialViewSkip:(HONTutorialView *)tutorialView {
	[[HONAnalyticsParams sharedInstance] trackEvent:@"Club News - Tutorial Skip"];
	
	[_tutorialView outroWithCompletion:^(BOOL finished) {
		[_tutorialView removeFromSuperview];
		_tutorialView = nil;
	}];
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ((section == 0) ? 1 : (section == 1) ? [_autoGenItems count] : [_timelineItems count]);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (3);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return (nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONClubNewsFeedViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HONClubNewsFeedViewCell alloc] init];
	
	
	if (indexPath.section == 0) {
		cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"createPostNewsFeedBG"]];
			
	} else if (indexPath.section == 1) {
		cell.clubVO = (HONUserClubVO *)[_autoGenItems objectAtIndex:indexPath.row];
	
	} else {
		cell.clubVO = (HONUserClubVO *)[_timelineItems objectAtIndex:indexPath.row];
	}
	
	cell.delegate = self;
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
//		return (0.0);
		if ([_allClubs count] == 0)
			return (0.0);
		
		else
			return (([[_clubIDs objectForKey:@"owned"] count] == 0 && [[_clubIDs objectForKey:@"member"] count] == 0) ? 160.0 : 0.0);
	}
	
	else if (indexPath.section == 1)
		return (kOrthodoxTableCellHeight);
	
	else {
		HONUserClubVO *vo = (HONUserClubVO *)[_timelineItems objectAtIndex:indexPath.row];
		HONClubPhotoVO *photoVO = (HONClubPhotoVO *)[vo.submissions lastObject];
		int emotionRows = (MIN([[[HONClubAssistant sharedInstance] emotionsForClubPhoto:photoVO] count], 14) / 5) + 1;
		NSLog(@"emotionRows:[%d]", emotionRows);
		
		NSString *emotions = @"";
		for (NSString *subject in photoVO.subjectNames)
			emotions = [emotions stringByAppendingFormat:@"%@, ", subject];
		emotions = ([emotions length] > 0) ? [emotions substringToIndex:[emotions length] - 2] : emotions;
		
		
		CGSize maxSize = CGSizeMake(238.0, 38.0);
		CGSize size = [[NSString stringWithFormat:@"%@ is feeling %@", photoVO.username, emotions] boundingRectWithSize:maxSize
																												options:NSStringDrawingTruncatesLastVisibleLine
																											 attributes:@{NSFontAttributeName:[[[HONFontAllocator sharedInstance] helveticaNeueFontRegular] fontWithSize:16]}
																												context:nil].size;
		
		
		return ((vo.clubEnrollmentType == HONClubEnrollmentTypeMember || (vo.clubEnrollmentType == HONClubEnrollmentTypeOwner && [vo.submissions count] > 0)) ? 135.0 + ((int)(size.width > maxSize.width) * 25.0) + (emotionRows * 50.0) : kOrthodoxTableCellHeight);
		//return ((vo.clubEnrollmentType == HONClubEnrollmentTypeMember || (vo.clubEnrollmentType == HONClubEnrollmentTypeOwner && [vo.submissions count] > 0)) ? 310.0 : kOrthodoxTableCellHeight);
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return (0.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	
	HONClubNewsFeedViewCell *cell = (HONClubNewsFeedViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
	
	if (indexPath.section == 0) {
		NSLog(@"OWNED:[%@]", [_ownedClubs firstObject]);
		
		[[HONAPICaller sharedInstance] retrieveClubByClubID:((HONUserClubVO *)[_ownedClubs firstObject]).clubID withOwnerID:[[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] completion:^(NSDictionary *result) {
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONSelfieCameraViewController alloc] initWithClub:[HONUserClubVO clubWithDictionary:result]]];
			[navigationController setNavigationBarHidden:YES];
			[self presentViewController:navigationController animated:NO completion:nil];
		}];
	
	} else if (indexPath.section == 1) {
		_selectedClubVO = (HONUserClubVO *)[_autoGenItems objectAtIndex:indexPath.row];
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
															message:[NSString stringWithFormat:@"Would you like to join the %@ Selfieclub?", _selectedClubVO.clubName]
														   delegate:self
												  cancelButtonTitle:@"Yes"
												  otherButtonTitles:@"No", nil];
		
		[alertView setTag:2];
		[alertView show];
	
	} else {
		_selectedClubVO = (HONUserClubVO *)[_timelineItems objectAtIndex:indexPath.row];
		
		if (cell.clubVO.clubEnrollmentType == HONClubEnrollmentTypeOwner || cell.clubVO.clubEnrollmentType == HONClubEnrollmentTypeMember) {
			NSLog(@"/// SHOW CLUB TIMELINE:(%d - %@)", _selectedClubVO.clubID, _selectedClubVO.clubName);
			//[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
			[self.navigationController pushViewController:[[HONClubTimelineViewController alloc] initWithClub:_selectedClubVO] animated:YES];
		
		} else {
			NSLog(@"/// JOIN CLUB:(%d - %@)", _selectedClubVO.clubID, _selectedClubVO.clubName);
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
																message:[NSString stringWithFormat:@"Would you like to join the %@ Selfieclub?", _selectedClubVO.clubName]
															   delegate:self
													  cancelButtonTitle:@"OK"
													  otherButtonTitles:@"Cancel", nil];
			
			[alertView setTag:0];
			[alertView show];
		}
	}
}


#pragma mark - AlertView Delegates
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 0) {
		if (buttonIndex == 0) {
			[self _joinClub:_selectedClubVO];
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
																message:[NSString stringWithFormat:@"Want to invite friends to %@?", _selectedClubVO.clubName]
															   delegate:self
													  cancelButtonTitle:@"Yes"
													  otherButtonTitles:@"Not Now", nil];
			
			[alertView setTag:1];
			[alertView show];
		}
	
	} else if (alertView.tag == 1) {
		if (buttonIndex == 0) {
			UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONInviteContactsViewController alloc] initWithClub:_selectedClubVO viewControllerPushed:NO]];
			[navigationController setNavigationBarHidden:YES];
			[self presentViewController:navigationController animated:YES completion:nil];
		
		} else
			[self _retrieveTimeline];
	
	} else if (alertView.tag == 2) {
		[self _createClubWithProtoVO:_selectedClubVO];
		if (buttonIndex == 0) {
			UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@""
																message:[NSString stringWithFormat:@"Want to invite friends to %@?", _selectedClubVO.clubName]
															   delegate:self
													  cancelButtonTitle:@"Yes"
													  otherButtonTitles:@"Not Now", nil];
			
			[alertView setTag:1];
			[alertView show];
		}
	}
}


- (void)_cycleOverlay:(UIView *)overlayView {
	[UIView animateWithDuration:0.33 animations:^(void) {
		overlayView.alpha = 0.0;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.33 animations:^(void) {
			overlayView.alpha = 1.0;
		} completion:^(BOOL finished) {
			[self _cycleOverlay:overlayView];
		}];
	}];
}

@end
