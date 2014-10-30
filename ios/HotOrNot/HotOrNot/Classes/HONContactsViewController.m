//
//  HONContactsViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 05/01/2014 @ 19:07 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSString+DataTypes.h"
#import "NSString+Formatting.h"

#import "MBProgressHUD.h"
#import "KeychainItemWrapper.h"
#import "TSTapstream.h"

#import "HONContactsViewController.h"
#import "HONUserProfileViewController.h"
#import "HONComposeViewController.h"
#import "HONCreateSnapButtonView.h"
#import "HONHeaderView.h"
#import "HONContactUserVO.h"
#import "HONTrivialUserVO.h"

@interface HONContactsViewController () <HONTableViewBGViewDelegate, HONClubViewCellDelegate>
@property (nonatomic, strong) NSString *smsRecipients;
@property (nonatomic, strong) NSString *emailRecipients;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) UIImageView *noAccessImageView;
@property (nonatomic) int currentMatchStateCounter;
@property (nonatomic) int totalMatchStateCounter;


@property (nonatomic, strong) UITableViewController *refreshControlTableViewController;
@end


@implementation HONContactsViewController

- (id)init {
	if ((self = [super init])) {
	}
	
	return (self);
}

- (void)dealloc {
	_tableView.dataSource = nil;
	_tableView.delegate = nil;
	
	[super destroy];
}


#pragma mark - Data Calls
- (void)_sendEmailContacts {
	NSLog(@":/: _sendEmailContacts :/:");
	
	[UIView animateWithDuration:0.125 animations:^(void) {
		_tableView.alpha = 0.0;
	}];
	
	[[HONAPICaller sharedInstance] submitDelimitedEmailContacts:[_emailRecipients substringToIndex:[_emailRecipients length] - 1] completion:^(NSArray *result) {
		for (NSDictionary *dict in result) {
			NSLog(@"EMAIL CONTACT:[%@]", dict);
			BOOL isDuplicate = NO;
			for (HONTrivialUserVO *vo in _inAppUsers) {
				if ([vo.username isEqualToString:[dict objectForKey:@"username"]]) {
					isDuplicate = YES;
					break;
				}
			}
			
			if (isDuplicate)
				continue;
			
			HONTrivialUserVO *vo = [HONTrivialUserVO userWithDictionary:@{@"id"			: [dict objectForKey:@"id"],
																		  @"username"	: [dict objectForKey:@"username"],
																		  @"img_url"	: ([dict objectForKey:@"avatar_url"] != nil) ? [dict objectForKey:@"avatar_url"] : [[NSString stringWithFormat:@"%@/defaultAvatar", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeAvatarsSource]] stringByAppendingString:kSnapThumbSuffix]}];
			
			[_inAppUsers addObject:vo];
		}
		
		_currentMatchStateCounter++;
		if (_currentMatchStateCounter == _totalMatchStateCounter)
			[self _didFinishDataRefresh];
	}];
}

- (void)_sendPhoneContacts {
	NSLog(@":/: _sendPhoneContacts :/:");
	
	[UIView animateWithDuration:0.125 animations:^(void) {
		_tableView.alpha = 0.0;
	}];
	
	[[HONAPICaller sharedInstance] submitDelimitedPhoneContacts:[_smsRecipients substringToIndex:[_smsRecipients length] - 1] completion:^(NSArray *result) {
		for (NSDictionary *dict in result) {
			NSLog(@"PHONE CONTACT:[%@]", dict);
			BOOL isDuplicate = NO;
			for (HONTrivialUserVO *vo in _inAppUsers) {
				if ([vo.username isEqualToString:[dict objectForKey:@"username"]] || vo.userID == [[dict objectForKey:@"id"] intValue]) {
					isDuplicate = YES;
					break;
				}
			}
			
			if (isDuplicate)
				continue;
			
			HONTrivialUserVO *vo = [HONTrivialUserVO userWithDictionary:@{@"id"			: [dict objectForKey:@"id"],
																		  @"username"	: [dict objectForKey:@"username"],
																		  @"alt_id"		: [[dict objectForKey:@"phone"] normalizedPhoneNumber],
																		  @"img_url"	: ([dict objectForKey:@"avatar_url"] != nil) ? [dict objectForKey:@"avatar_url"] : [NSString stringWithFormat:@"%@/defaultAvatar", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeAvatarsCloudFront]]}];
				[_matchedUserIDs addObject:vo.altID];
				[_inAppUsers addObject:vo];
		}
		
		_currentMatchStateCounter++;
		if (_currentMatchStateCounter == _totalMatchStateCounter)
			[self _didFinishDataRefresh];
	}];
}

- (void)_submitPhoneNumberForMatching {
	NSLog(@":/: _submitPhoneNumberForMatching :/:");
	
	[_searchBarView backgroundingReset];
	
	[UIView animateWithDuration:0.125 animations:^(void) {
		_tableView.alpha = 0.0;
	}];
	
	_headRows = [NSMutableArray array];
	[[HONAPICaller sharedInstance] submitPhoneNumberForUserMatching:[[HONDeviceIntrinsics sharedInstance] phoneNumber] completion:^(NSArray *result) {
//		NSLog(@"(MATCHED USERS *result[%@]", (NSArray *)result);
		if ([(NSArray *)result count] > 1) {
			for (NSDictionary *dict in [NSArray arrayWithArray:[result sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]]]) {
				BOOL isDuplicate = NO;
				for (HONTrivialUserVO *vo in _inAppUsers) {
					if ([vo.username isEqualToString:[dict objectForKey:@"username"]]) {
						isDuplicate = YES;
						break;
					}
				}
				
				if (isDuplicate)
					continue;
				
				HONTrivialUserVO *vo = [HONTrivialUserVO userWithDictionary:@{@"id"			: [dict objectForKey:@"id"],
																			  @"username"	: [dict objectForKey:@"username"],
																			  @"alt_id"		: [[dict objectForKey:@"phone"] normalizedPhoneNumber],
																			  @"img_url"	: ([dict objectForKey:@"avatar_url"] != nil) ? [dict objectForKey:@"avatar_url"] : [NSString stringWithFormat:@"%@/defaultAvatar", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeAvatarsCloudFront]]}];
				[_matchedUserIDs addObject:vo.altID];
				[_inAppUsers addObject:vo];
			}
		}
		
		if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers)
			[self _didFinishDataRefresh];
	}];
}


#pragma mark - Device Functions
- (void)_retrieveDeviceContacts {
	NSLog(@":/: _retrieveDeviceContacts :/:");
	
	_tableViewDataSource = HONContactsTableViewDataSourceAddressBook;
	
	_smsRecipients = @"";
	_emailRecipients = @"";
	_allDeviceContacts = [NSMutableArray array];
	_omittedDeviceContacts = [NSMutableArray array];
	_shownDeviceContacts = [NSMutableArray array];
	for (HONContactUserVO *vo in [[HONContactsAssistant sharedInstance] deviceContactsSortedByName:YES]) {
		[_allDeviceContacts addObject:vo];
		[_shownDeviceContacts addObject:vo];
		
		if (vo.isSMSAvailable)
			_smsRecipients = [_smsRecipients stringByAppendingFormat:@"%@|", vo.mobileNumber];
		
		else
			_emailRecipients = [_emailRecipients stringByAppendingFormat:@"%@|", vo.email];
	}
	
	NSLog(@"EMAIL:[%d] SMS:[%d]", [_emailRecipients length], [_smsRecipients length]);
	if ([_smsRecipients length] == 0 && [_emailRecipients length] == 0)
		[self _didFinishDataRefresh];
	
	else {
	}
	
	_currentMatchStateCounter = 0;
	_totalMatchStateCounter = (int)([_smsRecipients length] > 0) + (int)([_emailRecipients length] > 0);
	
	if ([_smsRecipients length] > 0) {
		NSLog(@"SMS CONTACTS:[%@]", [_smsRecipients substringToIndex:[_smsRecipients length] - 1]);
		[self _sendPhoneContacts];
	}
	
	if ([_emailRecipients length] > 0) {
		NSLog(@"EMAIL CONTACTS:[%@]", [_emailRecipients substringToIndex:[_emailRecipients length] - 1]);
		[self _sendEmailContacts];
	}
}


#pragma mark - Data Handling
- (void)_goDataRefresh:(CKRefreshControl *)sender {
	
	_tableView.hidden = YES;
	
	[self _submitPhoneNumberForMatching];
	if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
		[self _retrieveDeviceContacts];
}

- (void)_didFinishDataRefresh {
	
	if (_progressHUD == nil)
		_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_loading", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
//	_recentClubs = [[[[_recentClubs sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
//		HONUserClubVO *club1VO = (HONUserClubVO *)obj1;
//		HONUserClubVO *club2VO = (HONUserClubVO *)obj2;
//		
//		if ([[HONDateTimeAlloter sharedInstance] didDate:club1VO.updatedDate occurBerforeDate:club2VO.updatedDate])
//			return ((NSComparisonResult)NSOrderedAscending);
//		
//		if ([[HONDateTimeAlloter sharedInstance] didDate:club2VO.updatedDate occurBerforeDate:club1VO.updatedDate])
//			return ((NSComparisonResult)NSOrderedDescending);
//		
//		return ((NSComparisonResult)NSOrderedSame);
//	}] reverseObjectEnumerator] allObjects] mutableCopy];
	
	[_omittedDeviceContacts enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		HONContactUserVO *vo = (HONContactUserVO *)obj;
		[_shownDeviceContacts removeObject:vo];
	}];
	
	_emptyContactsBGView.hidden = ([_recentClubs count] > 0);
	_accessContactsBGView.hidden = (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized);
	
	if (_progressHUD != nil) {
		[_progressHUD hide:YES];
		_progressHUD = nil;
	}

	_tableView.alpha = 1.0;
	
	_tableView.hidden = NO;
	[_tableView reloadData];
	[_refreshControl endRefreshing];
	
	if (!_emptyContactsBGView.hidden || !_accessContactsBGView.hidden) {
		_accessContactsBGView.frame = CGRectMake(_accessContactsBGView.frame.origin.x, _tableView.contentSize.height + 5.0, _accessContactsBGView.frame.size.width, _accessContactsBGView.frame.size.height);
		_emptyContactsBGView.frame = _accessContactsBGView.frame;
		[_tableView setContentInset:UIEdgeInsetsMake(_tableView.contentInset.top, _tableView.contentInset.left, kOrthodoxTableCellHeight + kTabSize.height, _tableView.contentInset.right)];
	}
	
	NSLog(@"%@._didFinishDataRefresh - ABAddressBookGetAuthorizationStatus() = [%@]", self.class, (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) ? @"NotDetermined" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ? @"StatusDenied" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? @"Authorized" : @"UNKNOWN");
	
//	if ([_tableView.visibleCells count] > 0)
//		[_tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}



#pragma mark - View lifecycle
- (void)loadView {
	ViewControllerLog(@"[:|:] [%@ loadView] [:|:]", self.class);
	[super loadView];
	
	NSLog(@"%@.loadView - ABAddressBookGetAuthorizationStatus() = [%@]", self.class, (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) ? @"NotDetermined" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ? @"StatusDenied" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? @"Authorized" : @"UNKNOWN");
	
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	_smsRecipients = @"";
	_emailRecipients = @"";
	_headRows = [NSMutableArray array];
	_inAppUsers = [NSMutableArray array];
	_matchedUserIDs = [NSMutableArray array];
	_recentClubs = [NSMutableArray array];

	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.minimumLineHeight = 26.0;
	paragraphStyle.maximumLineHeight = paragraphStyle.minimumLineHeight;
	paragraphStyle.alignment = NSTextAlignmentCenter;
	
	
	_tableView = [[HONTableView alloc] initWithFrame:CGRectMake(0.0, kNavHeaderHeight, 320.0, self.view.frame.size.height - (kNavHeaderHeight))];
	[_tableView setContentInset:kOrthodoxTableViewEdgeInsets];
	_tableView.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, _tableView.frame.size.width, _tableView.frame.size.height)];
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[self.view addSubview:_tableView];
	
	_refreshControl = [[UIRefreshControl alloc] init];
	[_refreshControl addTarget:self action:@selector(_goDataRefresh:) forControlEvents:UIControlEventValueChanged];
	[_tableView addSubview: _refreshControl];
	
	_accessContactsBGView = [[HONTableViewBGView alloc] initAsType:HONTableViewBGViewTypeAccessContacts withCaption:NSLocalizedString(@"access_contacts", @"Access your contacts.\nFind friends") usingTarget:self action:@selector(_goTableBGSelected:)];
	_accessContactsBGView.viewType = HONTableViewBGViewTypeAccessContacts;
	[_tableView addSubview:_accessContactsBGView];
	
	_emptyContactsBGView = [[HONTableViewBGView alloc] initAsType:HONTableViewBGViewTypeCreateStatusUpdate withCaption:NSLocalizedString(@"empty_contacts", @"No results found.\nCompose") usingTarget:self action:@selector(_goTableBGSelected:)];
	_accessContactsBGView.viewType = HONTableViewBGViewTypeCreateStatusUpdate;
	[_tableView addSubview:_emptyContactsBGView];

	
	_headerView = [[HONHeaderView alloc] initWithTitleUsingCartoGothic:@""];
	[self.view addSubview:_headerView];
}

- (void)viewDidLoad {
	ViewControllerLog(@"[:|:] [%@ viewDidLoad] [:|:]", self.class);
	[super viewDidLoad];
	
	KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:[[NSBundle mainBundle] bundleIdentifier] accessGroup:nil];
	NSString *passedRegistration = [keychain objectForKey:CFBridgingRelease(kSecAttrAccount)];
	
	if ([passedRegistration length] != 0) {
		[self _submitPhoneNumberForMatching];
		
		if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
			_tableViewDataSource = HONContactsTableViewDataSourceAddressBook;
			[self _retrieveDeviceContacts];
			
		} else
			_tableViewDataSource = HONContactsTableViewDataSourceMatchedUsers;
		
	} else
		_tableViewDataSource = (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? HONContactsTableViewDataSourceAddressBook : HONContactsTableViewDataSourceMatchedUsers;
	
}

- (void)viewDidAppear:(BOOL)animated {
	ViewControllerLog(@"[:|:] [%@ viewDidAppear:animated:%@] [:|:]", self.class, [@"" stringFromBOOL:animated]);
	[super viewDidAppear:animated];
}


#pragma mark - Navigation
- (void)_goCreateChallenge {
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONComposeViewController alloc] initAsNewStatusUpdate]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)_goTableBGSelected:(id)sender {
	NSLog(@"[:|:] _goTableBGSelected:");
	
	UIButton *button = (UIButton *)sender;
	
//	button.alpha = 0.0;
//	button.backgroundColor = [UIColor whiteColor];
//	[UIView animateWithDuration:0.25 animations:^(void) {
//		button.alpha = 0.5;
//	} completion:^(BOOL finished) {
//		button.backgroundColor = [UIColor clearColor];
//		button.alpha = 1.0;
//	}];
	
	if (button.tag == HONTableViewBGViewTypeAccessContacts) {
		if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
			[self _promptForAddressBookPermission];
		
		else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
			[self _promptForAddressBookAccess];
		
	} else if (button.tag == HONTableViewBGViewTypeCreateStatusUpdate) {
		[self _goCreateChallenge];
	}
}


#pragma mark - UI Presentation
- (void)_promptForAddressBookAccess {
	[[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"ok_access", @"We need your OK to access the address book.")
								message:NSLocalizedString(@"grant_access", @"Flip the switch in Settings -> Privacy -> Contacts -> Selfieclub to grant access.")
							   delegate:nil
					  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
					  otherButtonTitles:nil] show];
}

- (void)_promptForAddressBookPermission {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"allow_access", @"Allow Access to contacts?")
														message:nil
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"alert_no", nil)
											  otherButtonTitles:NSLocalizedString(@"alert_yes", nil), nil];
	[alertView setTag:0];
	[alertView show];
}


#pragma mark - TableViewBGView Delegates
- (void)tableViewBGViewDidSelect:(HONTableViewBGView *)bgView {
	NSLog(@"[[*:*]] tableViewBGViewDidSelect [[*:*]]");
	
	if (bgView.viewType == HONTableViewBGViewTypeAccessContacts) {
		if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
			[self _promptForAddressBookPermission];
		
		else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied)
			[self _promptForAddressBookAccess];
	
	} else if (bgView.viewType == HONTableViewBGViewTypeCreateStatusUpdate) {
		[self _goCreateChallenge];
	}
}


#pragma mark - ClubViewCell Delegates
- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectClub:(HONUserClubVO *)clubVO {
	NSLog(@"[[*:*]] clubViewCell:didSelectClub");
}

- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectContactUser:(HONContactUserVO *)contactUserVO {
	NSLog(@"[[*:*]] clubViewCell:didSelectContactUser");
}

- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectTrivialUser:(HONTrivialUserVO *)trivialUserVO {
	NSLog(@"[[*:*]] clubViewCell:didSelectTrivialUser");
}


#pragma mark - ScrollView Delegates
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	[[_tableView visibleCells] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
		HONClubViewCell *cell = (HONClubViewCell *)obj;
		[cell toggleImageLoading:YES];
	}];
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (4);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ((section == 0) ? 1 : (section == 1) ? [_recentClubs count] : (section == 2) ? [_inAppUsers count] : [_shownDeviceContacts count]);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return ([[HONTableHeaderView alloc] initWithTitle:(section == 1) ? @"Recent" : (section == 2) ? @"Suggestions" : @"Contacts"]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONClubViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HONClubViewCell alloc] initAsCellType:HONClubViewCellTypeBlank];
	[cell setSize:[tableView rectForRowAtIndexPath:indexPath].size];
	[cell setIndexPath:indexPath];
	
	if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers) {
		if (indexPath.section == 0) {
//			cell.caption = @"Access contacts";
			[cell accVisible:NO];
			[cell toggleChevron];
			
		} else if (indexPath.section == 1) {
			HONUserClubVO *vo = (HONUserClubVO *)[_recentClubs objectAtIndex:indexPath.row];
			cell.clubVO = vo;
			
		} else if (indexPath.section == 2) {
			HONTrivialUserVO *vo = (HONTrivialUserVO *)[_inAppUsers objectAtIndex:indexPath.row];
			cell.trivialUserVO = vo;
		
		} else if (indexPath.section == 3) {
			NSLog(@"_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers -- section 3");
			NSLog(@"%@.cellForRowAtIndexPath - ABAddressBookGetAuthorizationStatus() = [%@]", self.class, (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) ? @"NotDetermined" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ? @"StatusDenied" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? @"Authorized" : @"UNKNOWN");
		}
		
	} else if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
		if (indexPath.section == 1) {
			HONUserClubVO *vo = (HONUserClubVO *)[_recentClubs objectAtIndex:indexPath.row];
			cell.clubVO = vo;
			
		} else if (indexPath.section == 2) {
			HONTrivialUserVO *vo = (HONTrivialUserVO *)[_inAppUsers objectAtIndex:indexPath.row];
			cell.trivialUserVO = vo;
			
		} else if (indexPath.section == 3) {
			HONContactUserVO *vo = (HONContactUserVO *)[_shownDeviceContacts objectAtIndex:indexPath.row];
			cell.contactUserVO = vo;
		}
	}
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	cell.delegate = self;
	
	if (!tableView.decelerating)
		[cell toggleImageLoading:YES];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (((indexPath.section == 0 && indexPath.row == 0)) ? 0.0 : kOrthodoxTableCellHeight);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return ((section != 0) ? kOrthodoxTableHeaderHeight : 0.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	HONClubViewCell *cell = (HONClubViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	
	NSLog(@"-[- cell.contactUserVO.userID:[%d]", cell.contactUserVO.userID);
	NSLog(@"-[- cell.trivialUserVO.userID:[%d]", cell.trivialUserVO.userID);
	NSLog(@"-[- cell.clubVO.clubID:[%d]", cell.clubVO.clubID);
	
	if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers) {
		if (indexPath.section == 0) {
			if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
				[self _promptForAddressBookPermission];
			
			else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
				[self _retrieveDeviceContacts];
			
			else
				[self _promptForAddressBookAccess];
		
		} else if (indexPath.section == 1) {
//			HONUserClubVO *vo = (HONUserClubVO *)[_recentClubs objectAtIndex:indexPath.row];
//			NSLog(@"RECENT CLUB:[%@]", vo.clubName);
		
		} else if (indexPath.section == 2) {
//			HONTrivialUserVO *vo = (HONTrivialUserVO *)[_inAppUsers objectAtIndex:indexPath.row];
//			NSLog(@"IN-APP USER:[%@]", vo.username);
		}
			
	} else if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
		if (indexPath.section == 0) {
			if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
				[self _promptForAddressBookPermission];
			
			else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
				[self _retrieveDeviceContacts];
			
			else
				[self _promptForAddressBookAccess];
			
			
		} else if (indexPath.section == 1) {
//			HONUserClubVO *vo = (HONUserClubVO *)[_recentClubs objectAtIndex:indexPath.row];
//			NSLog(@"RECENT CLUB:[%@]", vo.clubName);
			
		} else if (indexPath.section == 2) {
//			HONTrivialUserVO *vo = (HONTrivialUserVO *)[_inAppUsers objectAtIndex:indexPath.row];
//			NSLog(@"IN-APP USER:[%@]", vo.username);
		
		} else if (indexPath.section == 3) {
//			HONContactUserVO *vo = (HONContactUserVO *)[_deviceContacts objectAtIndex:indexPath.row];
//			NSLog(@"DEVICE CONTACT:[%@]", vo.fullName);
		}
	}
}

//- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//	cell.alpha = 0.0;
//	[UIView animateKeyframesWithDuration:0.125 delay:0.050 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseOut) animations:^(void) {
//		cell.alpha = 1.0;
//	} completion:^(BOOL finished) {
//	}];
//}


#pragma mark - AlertView Delegates
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 0) {
		NSLog(@"CONTACTS:[%d]", buttonIndex);
		if (buttonIndex == 1) {
			if (ABAddressBookRequestAccessWithCompletion) {
				ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
				NSLog(@"ABAddressBookGetAuthorizationStatus() = [%@]", (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) ? @"kABAuthorizationStatusNotDetermined" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ? @"kABAuthorizationStatusDenied" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? @"kABAuthorizationStatusAuthorized" : @"OTHER");
//				[self _goDataRefresh:nil];
				
				if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
					ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
						_tableViewDataSource = HONContactsTableViewDataSourceAddressBook;
//						[self _goDataRefresh:nil];
					});
				
				} else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
					ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
						_tableViewDataSource = HONContactsTableViewDataSourceMatchedUsers;
//						[self _goDataRefresh:nil];
					});
				
				} else {
//					[self _goDataRefresh:nil];
				}
				
				[self _goDataRefresh:nil];
			}
		}
		
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	}
}

#pragma mark - Data Manip
@end
