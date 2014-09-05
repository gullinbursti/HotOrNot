//
//  HONContactsViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 05/01/2014 @ 19:07 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import "NSString+DataTypes.h"

#import "MBProgressHUD.h"
#import "KeychainItemWrapper.h"
#import "TSTapstream.h"

#import "HONContactsViewController.h"
#import "HONUserProfileViewController.h"
#import "HONInviteClubsViewController.h"
#import "HONCreateSnapButtonView.h"
#import "HONHeaderView.h"
#import "HONTableHeaderView.h"
#import "HONSearchBarView.h"
#import "HONContactUserVO.h"
#import "HONTrivialUserVO.h"

@interface HONContactsViewController () <HONSearchBarViewDelegate, HONUserToggleViewCellDelegate>
@property (nonatomic, strong) NSString *smsRecipients;
@property (nonatomic, strong) NSString *emailRecipients;
@property (nonatomic, strong) NSMutableArray *cells;
@property (nonatomic, strong) NSMutableArray *clubInviteContacts;
@property (nonatomic, strong) NSMutableArray *matchedUserIDs;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) UIImageView *noAccessImageView;
@property (nonatomic) int currentMatchStateCounter;
@property (nonatomic) int totalMatchStateCounter;

@property (nonatomic, strong) UITableViewController *refreshControlTableViewController;
@end


@implementation HONContactsViewController

- (id)init {
	if ((self = [super init])) {
		_cells = [NSMutableArray array];
	}
	
	return (self);
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
			
			[_matchedUserIDs addObject:vo.phoneNumber];
			[_inAppContacts addObject:vo];
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
//			NSLog(@"PHONE CONTACT:[%@]", dict);
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
																		  @"alt_id"		: [HONAppDelegate normalizedPhoneNumber:[dict objectForKey:@"phone"]],
																		  @"img_url"	: ([dict objectForKey:@"avatar_url"] != nil) ? [dict objectForKey:@"avatar_url"] : [NSString stringWithFormat:@"%@/defaultAvatar", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeAvatarsCloudFront]]}];
				[_matchedUserIDs addObject:vo.altID];
				[_inAppContacts addObject:vo];
		}
		
		_currentMatchStateCounter++;
		if (_currentMatchStateCounter == _totalMatchStateCounter)
			[self _didFinishDataRefresh];
	}];
}

- (void)_submitPhoneNumberForMatching {
	NSLog(@":/: _submitPhoneNumberForMatching :/:");
	
	[_searchBarView backgroundingReset];
	
	if (_progressHUD == nil)
		_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_loading", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	[UIView animateWithDuration:0.125 animations:^(void) {
		_tableView.alpha = 0.0;
	}];
	
	_inAppUsers = [NSMutableArray array];
	_inAppUsers = [NSMutableArray arrayWithObjects:[HONTrivialUserVO userWithDictionary:@{@"id"				: @"-2", // share shelf
																						  @"username"		: @"..",
																						  @"img_url"		: @"",
																						  @"is_verified"	: @"N",
																						  @"abuse_ct"		: @"0"}],  [HONTrivialUserVO userWithDictionary:@{@"id"				: @"-1",
																																							  @"username"		: @".",
																																							  @"img_url"		: @"",
																																							  @"is_verified"	: @"N",
																																							  @"abuse_ct"		: @"0"}], nil];
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
				
				[_inAppUsers addObject:[HONTrivialUserVO userWithDictionary:@{@"id"			: [dict objectForKey:@"id"],
																			  @"username"	: [dict objectForKey:@"username"],
																			  @"img_url"	: ([dict objectForKey:@"avatar_url"] != nil) ? [dict objectForKey:@"avatar_url"] : [[NSString stringWithFormat:@"%@/defaultAvatar", [HONAppDelegate s3BucketForType:HONAmazonS3BucketTypeAvatarsSource]] stringByAppendingString:kSnapThumbSuffix]}]];
			}
		}
		
		if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers)
			[self _didFinishDataRefresh];
	}];
}

- (void)_searchUsersWithUsername:(NSString *)username {
	_tableViewDataSource = HONContactsTableViewDataSourceSearchResults;
	
	if (_progressHUD == nil)
		_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_searchUsers", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	[UIView animateWithDuration:0.125 animations:^(void) {
		_tableView.alpha = 0.0;
	}];
	
	_searchUsers = [NSMutableArray array];
	[[HONAPICaller sharedInstance] searchForUsersByUsername:username completion:^(NSArray *result) {
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
		
		for (NSDictionary *dict in result) {
			//NSLog(@"SEARCH USER:[%@]", dict);
			BOOL isDuplicate = NO;
			for (HONTrivialUserVO *vo in _inAppUsers) {
				if ([vo.username isEqualToString:[dict objectForKey:@"username"]]) {
					isDuplicate = YES;
					break;
				}
			}
			
			if (isDuplicate)
				continue;
			
			if([[dict objectForKey:@"id"] intValue] != [[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue]){
				[_searchUsers addObject:[HONTrivialUserVO userWithDictionary:@{@"id"		: [dict objectForKey:@"id"],
																			   @"username"	: [dict objectForKey:@"username"],
																			   @"img_url"	: [dict objectForKey:@"avatar_url"]}]];
			}
		}
		
		if ([_searchUsers count] == 0) {
			[[[UIAlertView alloc] initWithTitle:@""
										message:NSLocalizedString(@"hud_noResults", nil)
									   delegate:nil
							  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
							  otherButtonTitles:nil] show];
			
		} else {
			_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
			_tableView.separatorInset = UIEdgeInsetsZero;
			
			[self _didFinishDataRefresh];
		}
	}];
}


#pragma mark - Device Functions
- (void)_retrieveDeviceContacts {
	NSLog(@":/: _retrieveDeviceContacts :/:");
	
	_deviceContacts = [NSMutableArray arrayWithObject:[HONContactUserVO contactWithDictionary:@{@"id"			: @"-1", // share shelf
																								@"f_name"		: @".",
																								@"l_name"		: @".",
																								@"raw_number"	: @"+00000000000"}]];
	
	for (HONContactUserVO *vo in [[HONContactsAssistant sharedInstance] deviceContactsSortedByName:YES]) {
		[_deviceContacts addObject:vo];
		
		if (vo.isSMSAvailable)
			_smsRecipients = [_smsRecipients stringByAppendingFormat:@"%@|", vo.mobileNumber];
		
		else
			_emailRecipients = [_emailRecipients stringByAppendingFormat:@"%@|", vo.email];
	}
	
	NSLog(@"EMAIL:[%d] SMS:[%d]", [_emailRecipients length], [_smsRecipients length]);
	if ([_smsRecipients length] == 0 && [_emailRecipients length] == 0)
		[self _didFinishDataRefresh];
	
	else {
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.labelText = NSLocalizedString(@"hud_loading", nil);
		_progressHUD.mode = MBProgressHUDModeIndeterminate;
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.taskInProgress = YES;
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
	_cells = [NSMutableArray array];

	[self _submitPhoneNumberForMatching];
	if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
		[self _retrieveDeviceContacts];
}

- (void)_didFinishDataRefresh {
	if (_tableViewDataSource != HONContactsTableViewDataSourceSearchResults)
		[self _updateDeviceContactsWithMatchedUsers];
	
	_segmentedContacts = [self _populateSegmentedDictionary];
	NSLog(@"_segmentedContacts:[%d]", [_segmentedContacts count]);
	
	if (_progressHUD != nil) {
		[_progressHUD hide:YES];
		_progressHUD = nil;
	}
	
	_tableView.alpha = 1.0;
	
	for (HONUserToggleViewCell *cell in _cells)
		[cell toggleSelected:NO];
	
	[_tableView reloadData];
	[_refreshControl endRefreshing];
}



#pragma mark - View lifecycle
- (void)loadView {
	ViewControllerLog(@"[:|:] [%@ loadView] [:|:]", self.class);
	[super loadView];
	
	NSLog(@"%@.loadView - ABAddressBookGetAuthorizationStatus() = [%@]", self.class, (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) ? @"NotDetermined" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ? @"StatusDenied" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? @"Authorized" : @"UNKNOWN");
	
	self.view.backgroundColor = [UIColor whiteColor];
	self.edgesForExtendedLayout = UIRectEdgeNone;
	
	_smsRecipients = @"";
	_emailRecipients = @"";
	_cells = [NSMutableArray array];
	_inAppContacts = [NSMutableArray array];
	_clubInviteContacts = [NSMutableArray array];
	_matchedUserIDs = [NSMutableArray array];

	_tableView = [[HONTableView alloc] initWithFrame:CGRectMake(0.0, (kNavHeaderHeight), 320.0, self.view.frame.size.height - (kNavHeaderHeight))];
	[_tableView setContentInset:kOrthodoxTableViewEdgeInsets];
	_tableView.sectionIndexColor = [[HONColorAuthority sharedInstance] honGreyTextColor];
	_tableView.sectionIndexBackgroundColor = [UIColor clearColor];
	_tableView.sectionIndexTrackingBackgroundColor = [UIColor colorWithWhite:0.40 alpha:0.33];
	_tableView.sectionIndexMinimumDisplayRowCount = 1;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	[self.view addSubview:_tableView];
	
	_refreshControl = [[UIRefreshControl alloc] init];
	[_refreshControl addTarget:self action:@selector(_goDataRefresh:) forControlEvents:UIControlEventValueChanged];
	[_tableView addSubview: _refreshControl];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:@"" hasBackground:YES];
	[self.view addSubview:_headerView];
	
	//_searchBarView = [[HONSearchBarView alloc] initWithFrame:CGRectMake(0.0, kNavHeaderHeight, 320.0, kSearchHeaderHeight)];
	//_searchBarView.delegate = self;
	//[self.view addSubview:_searchBarView];
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


#pragma mark - Navigation


#pragma mark - UI Presentation
- (void)_promptForAddressBookAccess {
	[[[UIAlertView alloc] initWithTitle: NSLocalizedString(@"ok_access", @"We need your OK to access the address book.")
								message:NSLocalizedString(@"grant_access", @"Flip the switch in Settings -> Privacy -> Contacts -> Selfieclub to grant access.")
							   delegate:nil
					  cancelButtonTitle:NSLocalizedString(@"alert_ok", nil)
					  otherButtonTitles:nil] show];
}

- (void)_promptForAddressBookPermission {
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle: NSLocalizedString(@"allow_access", @"Allow Access to your contacts?")
														message:nil
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"alert_no", nil)
											  otherButtonTitles:@"Yes", nil];
	[alertView setTag:0];
	[alertView show];
}


#pragma mark - SearchBarHeader Delegates
- (void)searchBarViewHasFocus:(HONSearchBarView *)searchBarView {
	_tableViewDataSource = HONContactsTableViewDataSourceSearchResults;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLineEtched;
	_searchUsers = [NSMutableArray array];
	[_tableView reloadData];
}

- (void)searchBarViewCancel:(HONSearchBarView *)searchBarView {
	_tableViewDataSource = (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? HONContactsTableViewDataSourceAddressBook : HONContactsTableViewDataSourceMatchedUsers;
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

	[self _submitPhoneNumberForMatching];
	if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook)
		[self _retrieveDeviceContacts];
}

- (void)searchBarView:(HONSearchBarView *)searchBarView enteredSearch:(NSString *)searchQuery {
	[self _searchUsersWithUsername:searchQuery];
}


#pragma mark - UserToggleViewCell Delegates
- (void)userToggleViewCell:(HONUserToggleViewCell *)viewCell showProfileForTrivialUser:(HONTrivialUserVO *)trivialUserVO {
	NSLog(@"[*:*] userToggleViewCell:showProfileForTrivialUser");
}

- (void)userToggleViewCell:(HONUserToggleViewCell *)viewCell didDeselectContactUser:(HONContactUserVO *)contactUserVO {
	NSLog(@"[*:*] userToggleViewCell:didDeselectContactUser");
}

- (void)userToggleViewCell:(HONUserToggleViewCell *)viewCell didDeselectTrivialUser:(HONTrivialUserVO *)trivialUserVO {
	NSLog(@"[*:*] userToggleViewCell:didDeselectTrivialUser");
}

- (void)userToggleViewCell:(HONUserToggleViewCell *)viewCell didSelectContactUser:(HONContactUserVO *)contactUserVO {
	NSLog(@"[*:*] userToggleViewCell:didSelectContactUser");
}

- (void)userToggleViewCell:(HONUserToggleViewCell *)viewCell didSelectTrivialUser:(HONTrivialUserVO *)trivialUserVO {
	NSLog(@"[*:*] userToggleViewCell:didSelectTrivialUser");
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return ((_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) ? 1 : [_segmentedKeys count]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ((_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) ? [_searchUsers count] : [[_segmentedContacts valueForKey:[_segmentedKeys objectAtIndex:section]] count]);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return ([[HONTableHeaderView alloc] initWithTitle:(_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) ? @"SEARCH RESULTS" : [_segmentedKeys objectAtIndex:section]]);
	
	//return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
	return ((_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) ? nil : [[UILocalizedIndexedCollation currentCollation] sectionIndexTitles]);
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
	return ((_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) ? 0 : [[UILocalizedIndexedCollation currentCollation] sectionForSectionIndexTitleAtIndex:index]);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONUserToggleViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HONUserToggleViewCell alloc] init];
	
	if (_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) {
		cell.trivialUserVO = (HONTrivialUserVO *)[_searchUsers objectAtIndex:indexPath.row];
//		[cell toggleSelected:[[HONContactsAssistant sharedInstance] isTrivialUserInvitedToClubs:cell.trivialUserVO]];
		
	} else if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers) {
		HONTrivialUserVO *vo = (HONTrivialUserVO *)[[_segmentedContacts valueForKey:[_segmentedKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
		
		cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(vo.userID == -2) ? @"shareFriends" : (vo.userID == -1) ? @"addContacts" : @"contactsCellBG_normal"]];
		if (vo.userID > 0) {
			cell.trivialUserVO = (HONTrivialUserVO *)[[_segmentedContacts valueForKey:[_segmentedKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
			[cell toggleSelected:NO];
//			[cell toggleSelected:[[HONContactsAssistant sharedInstance] isTrivialUserInvitedToClubs:cell.trivialUserVO]];
		}
		
		[cell setSelectionStyle:(vo.userID > 0) ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone];
		[cell toggleUI:(vo.userID > 0)];
		
	} else if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
		HONContactUserVO *vo = (HONContactUserVO *)[[_segmentedContacts valueForKey:[_segmentedKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
		
		cell.backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:(vo.userID == -1) ? @"shareFriends" : @"contactsCellBG_normal"]];
		cell.contactUserVO = vo;
		if (cell.contactUserVO.contactType == HONContactTypeMatched)
			cell.trivialUserVO = (HONTrivialUserVO *)[[_segmentedContacts valueForKey:[_segmentedKeys objectAtIndex:indexPath.section]] objectAtIndex:indexPath.row];
		
		[cell toggleUI:(vo.userID != -1)];
		[cell setSelectionStyle:(vo.userID > 0) ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone];
//		[cell toggleSelected:[[HONContactsAssistant sharedInstance] isContactUserInvitedToClubs:cell.contactUserVO]];
	}
	
	cell.delegate = self;
	
	if (![_cells containsObject:cell])
		[_cells addObject:cell];
	
	cell.alpha = 0.0;
	[UIView animateKeyframesWithDuration:0.125 delay:indexPath.row * 0.1 options:(UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationCurveEaseOut) animations:^(void) {
		cell.alpha = 1.0;
	} completion:^(BOOL finished) {
	}];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	//return ((_tableViewDataSource != HONContactsTableViewDataSourceSearchResults && indexPath.section == 0) ? 74.0 : kOrthodoxTableCellHeight);

	if(indexPath.section == 0)
	{
		return 0;
	}
	else
	{
		return kOrthodoxTableCellHeight;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	//return ((_tableViewDataSource != HONContactsTableViewDataSourceSearchResults && section == 0) ? 0.0 : kOrthodoxTableHeaderHeight);

	return 0;

}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	HONUserToggleViewCell *cell = (HONUserToggleViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	
//	NSLog(@"-[- cell.contactUserVO.userID:[%d]", cell.contactUserVO.userID);
//	NSLog(@"-[- cell.trivialUserVO.userID:[%d]", cell.trivialUserVO.userID);
	
	if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers) {
		if (indexPath.section == 0 && indexPath.row == 0) {
			HONUserClubVO *clubVO = (_userClubVO == nil) ? [[HONClubAssistant sharedInstance] userSignupClub] : _userClubVO;
			NSString *igCaption = [NSString stringWithFormat:[HONAppDelegate instagramShareMessageForIndex:1], clubVO.ownerName, clubVO.clubName];
			NSString *twCaption = [NSString stringWithFormat:[HONAppDelegate twitterShareCommentForIndex:1], clubVO.ownerName, clubVO.clubName];
			NSString *smsCaption = [NSString stringWithFormat:[HONAppDelegate smsShareCommentForIndex:1], clubVO.ownerName, clubVO.clubName];
			NSString *emailCaption = [[[[HONAppDelegate emailShareCommentForIndex:1] objectForKey:@"subject"] stringByAppendingString:@"|"] stringByAppendingString:[NSString stringWithFormat:[[HONAppDelegate emailShareCommentForIndex:1] objectForKey:@"body"], clubVO.ownerName, clubVO.clubName]];
			NSString *clipboardCaption = [NSString stringWithFormat:[HONAppDelegate smsShareCommentForIndex:1], clubVO.ownerName, clubVO.clubName];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_SHARE_SHELF" object:@{@"caption"			: @[igCaption, twCaption, @"", smsCaption, emailCaption, clipboardCaption],
																									@"image"			: ([[[HONAppDelegate infoForUser] objectForKey:@"avatar_url"] rangeOfString:@"defaultAvatar"].location == NSNotFound) ? [HONAppDelegate avatarImage] : [[HONImageBroker sharedInstance] shareTemplateImageForType:HONImageBrokerShareTemplateTypeDefault],
																									@"url"				: [[HONAppDelegate infoForUser] objectForKey:@"avatar_url"],
																									@"club"				: clubVO.dictionary,
																									@"mp_event"			: @"User Profile - Share",
																									@"view_controller"	: self}];
			
		} else if (indexPath.section == 0 && indexPath.row == 1) {
			if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined)
				[self _promptForAddressBookPermission];
			
			else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized)
				[self _retrieveDeviceContacts];
			
			else
				[self _promptForAddressBookAccess];
		
		} else
			[cell invertSelected];
			
	} else if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
		if (indexPath.section == 0 && indexPath.row == 0) {
			HONUserClubVO *clubVO = (_userClubVO == nil) ? [[HONClubAssistant sharedInstance] userSignupClub] : _userClubVO;
			NSString *igCaption = [NSString stringWithFormat:[HONAppDelegate instagramShareMessageForIndex:1], clubVO.ownerName, clubVO.clubName];
			NSString *twCaption = [NSString stringWithFormat:[HONAppDelegate twitterShareCommentForIndex:1], clubVO.ownerName, clubVO.clubName];
			NSString *smsCaption = [NSString stringWithFormat:[HONAppDelegate smsShareCommentForIndex:1], clubVO.ownerName, clubVO.clubName];
			NSString *emailCaption = [[[[HONAppDelegate emailShareCommentForIndex:1] objectForKey:@"subject"] stringByAppendingString:@"|"] stringByAppendingString:[NSString stringWithFormat:[[HONAppDelegate emailShareCommentForIndex:1] objectForKey:@"body"], clubVO.ownerName, clubVO.clubName]];
			NSString *clipboardCaption = [NSString stringWithFormat:[HONAppDelegate smsShareCommentForIndex:1], clubVO.ownerName, clubVO.clubName];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"SHOW_SHARE_SHELF" object:@{@"caption"			: @[igCaption, twCaption, @"", smsCaption, emailCaption, clipboardCaption],
																									@"image"			: ([[[HONAppDelegate infoForUser] objectForKey:@"avatar_url"] rangeOfString:@"defaultAvatar"].location == NSNotFound) ? [HONAppDelegate avatarImage] : [[HONImageBroker sharedInstance] shareTemplateImageForType:HONImageBrokerShareTemplateTypeDefault],
																									@"url"				: [[HONAppDelegate infoForUser] objectForKey:@"avatar_url"],
																									@"club"				: clubVO.dictionary,
																									@"mp_event"			: @"User Profile - Share",
																									@"view_controller"	: self.parentViewController}];
		
		} else
			[cell invertSelected];
		
	} else
		[cell invertSelected];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
	HONUserToggleViewCell *viewCell = (HONUserToggleViewCell *)[tableView cellForRowAtIndexPath:indexPath];
	if ([_cells containsObject:viewCell])
		[_cells removeObject:viewCell];
}


#pragma mark - AlertView Delegates
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 0) {
		NSLog(@"CONTACTS:[%d]", buttonIndex);
		if (buttonIndex == 1) {
			if (ABAddressBookRequestAccessWithCompletion) {
				ABAddressBookRef addressBookRef = ABAddressBookCreateWithOptions(NULL, NULL);
				NSLog(@"ABAddressBookGetAuthorizationStatus() = [%@]", (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) ? @"kABAuthorizationStatusNotDetermined" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusDenied) ? @"kABAuthorizationStatusDenied" : (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) ? @"kABAuthorizationStatusAuthorized" : @"OTHER");
				
				[self _submitPhoneNumberForMatching];
				if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusAuthorized) {
					ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
						_tableViewDataSource = HONContactsTableViewDataSourceAddressBook;
						[self _retrieveDeviceContacts];
					});
				
				} else if (ABAddressBookGetAuthorizationStatus() == kABAuthorizationStatusNotDetermined) {
					ABAddressBookRequestAccessWithCompletion(addressBookRef, ^(bool granted, CFErrorRef error) {
						_tableViewDataSource = HONContactsTableViewDataSourceMatchedUsers;
					});
				
				} else {
				}
			}
		}
		
		[[UIApplication sharedApplication] registerForRemoteNotificationTypes:(UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound | UIRemoteNotificationTypeAlert)];
	}
}

#pragma mark - Data Manip
-(NSDictionary *)_populateSegmentedDictionary {
	_segmentedKeys = [[NSMutableArray alloc] init];
	[_segmentedKeys removeAllObjects];
	
	NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
	if (_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) {
		NSLog(@"(( _tableViewDataSource == HONContactsTableViewDataSourceSearchResults ))");
		
	} else if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers) {
		NSLog(@"(( _tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers ))");
		for (HONTrivialUserVO *vo in _inAppUsers) {
			if ([vo.username length] > 0) {
				NSString *charKey = [[vo.username substringToIndex:1] lowercaseString];
				NSLog(@"charKey:[%@]", charKey);
				
				if (![_segmentedKeys containsObject:charKey]) {
					[_segmentedKeys addObject:charKey];
					
					NSMutableArray *newSegment = [[NSMutableArray alloc] initWithObjects:vo, nil];
					[dict setValue:newSegment forKey:charKey];
					
				} else {
					NSMutableArray *prevSegment = (NSMutableArray *)[dict valueForKey:charKey];
					[prevSegment addObject:vo];
					[dict setValue:prevSegment forKey:charKey];
				}
			}
		}
		
//		for (NSString *key in dict) {
//			for (HONTrivialUserVO *vo in [dict objectForKey:key])
//				NSLog(@"_segmentedKeys[%@] = [%@]", key, vo.username);
//		}

	} else if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
		NSLog(@"(( _tableViewDataSource == HONContactsTableViewDataSourceAddressBook ))");
		for (HONContactUserVO *vo in _deviceContacts) {
			if (vo.contactType == HONContactTypeMatched) {
				
				NSString *charKey = [vo.username substringToIndex:1];
				if (![_segmentedKeys containsObject:charKey]) {
					[_segmentedKeys addObject:charKey];
					
					NSMutableArray *newSegment = [[NSMutableArray alloc] initWithObjects:vo, nil];
					[dict setValue:newSegment forKey:charKey];
					
				} else {
					NSMutableArray *prevSegment = (NSMutableArray *)[dict valueForKey:charKey];
					[prevSegment addObject:vo];
					[dict setValue:prevSegment forKey:charKey];
				}
				
			} else {
				NSString *charKey = (ABPersonGetSortOrdering() == kABPersonCompositeNameFormatFirstNameFirst) ? vo.firstName : vo.lastName;
				charKey = ([charKey length] == 0) ? (ABPersonGetSortOrdering() == kABPersonCompositeNameFormatFirstNameFirst) ? vo.lastName : vo.firstName : charKey;
				charKey = [charKey substringToIndex:1];
				if (![_segmentedKeys containsObject:charKey]) {
					[_segmentedKeys addObject:charKey];
					
					NSMutableArray *newSegment = [[NSMutableArray alloc] initWithObjects:vo, nil];
					[dict setValue:newSegment forKey:charKey];
					
				} else {
					NSMutableArray *prevSegment = (NSMutableArray *)[dict valueForKey:charKey];
					[prevSegment addObject:vo];
					[dict setValue:prevSegment forKey:charKey];
				}
			}
		}
		
		for (NSString *key in dict) {
//			[[[UIAlertView alloc] initWithTitle:@"Contacts"
//										message:[NSString stringWithFormat:@"(%d) - %@", [[dict objectForKey:key] count], key]
//									   delegate:nil
//							  cancelButtonTitle:@"YES"
//							  otherButtonTitles:nil] show];
			
			for (HONTrivialUserVO *vo in [dict objectForKey:key])
				NSLog(@"_segmentedKeys[%@] = [%@]", key, vo.username);

		}
	}
	
	_segmentedKeys = [[_segmentedKeys sortedArrayUsingDescriptors:@[[[NSSortDescriptor alloc] initWithKey:@"" ascending:YES comparator:^NSComparisonResult(id obj1, id obj2) {
		return ([(NSString *)obj1 compare:(NSString *)obj2
								  options:(NSCaseInsensitiveSearch|NSNumericSearch|NSAnchoredSearch)
									range:NSMakeRange(0, 1)
								   locale:[NSLocale currentLocale]]);
	}]]] mutableCopy];
	
	return (dict);
}

- (void)_updateDeviceContactsWithMatchedUsers {
	for (HONContactUserVO *deviceContactVO in _deviceContacts) {
		for (HONTrivialUserVO *inAppContactVO in _inAppContacts) {
			if ([(deviceContactVO.isSMSAvailable) ? deviceContactVO.mobileNumber : deviceContactVO.email isEqualToString:inAppContactVO.altID]) {
				
				__block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
				for (NSString *sectionKey in _segmentedKeys) {
					indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
					
					[[_segmentedContacts valueForKey:sectionKey] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
						if (indexPath != nil) {
							HONUserToggleViewCell *cell = (HONUserToggleViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
							if ([cell.contactUserVO.mobileNumber isEqual:[NSNull null]] || [deviceContactVO.mobileNumber isEqual:[NSNull null]])
								return;
								
							NSLog(@"cell.contactUserVO.mobileNumber:[%@] </|/> deviceContactVO.mobileNumber:[%@] inAppContactVO.username:[%@]", cell.contactUserVO.mobileNumber, deviceContactVO.mobileNumber, inAppContactVO.username);
							
							if ([cell.contactUserVO.mobileNumber isEqualToString:deviceContactVO.mobileNumber]) {
								cell.contactUserVO.contactType = HONContactTypeMatched;
								cell.trivialUserVO = inAppContactVO;
							}
						}
						
						indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
					}];
					
					indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + 1];
				}
			}
		}
	}
	
//	__block NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
//	for (NSString *sectionKey in _segmentedKeys) {
//		indexPath = [NSIndexPath indexPathForRow:0 inSection:indexPath.section + ((int)HONContactsTableViewDataSourceMatchedUsers)];
//		
//		if (_tableViewDataSource == HONContactsTableViewDataSourceSearchResults) {
//		} else if (_tableViewDataSource == HONContactsTableViewDataSourceMatchedUsers || _tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
//			[[_segmentedContacts valueForKey:sectionKey] enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
//				if (indexPath != nil) {
/*					HONUserToggleViewCell *cell = (HONUserToggleViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
//					
//					if ([obj isKindOfClass:[HONContactUserVO class]]) {
//						[cell toggleSelected:[[HONContactsAssistant sharedInstance] isContactUserInvitedToClubs:(HONContactUserVO *)obj]];
//					}
//					
//					if ([obj isKindOfClass:[HONTrivialUserVO class]]) {
//						[cell toggleSelected:[[HONContactsAssistant sharedInstance] isTrivialUserInvitedToClubs:(HONTrivialUserVO *)obj]];
//					}
*/
//				}
//				
//				indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
//			}];
//			
//			for (HONTrivialUserVO *vo in [_segmentedContacts valueForKey:sectionKey]) {
//				NSLog(@"USER:[%@] INDEXPATH:[%@]", vo.username, indexPath);
//			}
//			
//		} else if (_tableViewDataSource == HONContactsTableViewDataSourceAddressBook) {
//			for (HONContactUserVO *vo in [_segmentedContacts valueForKey:sectionKey]) {
//				NSLog(@"CONTACT:[%@] INDEXPATH:[%@]", vo.mobileNumber, indexPath);
//
//				if (indexPath != nil) {
//					HONUserToggleViewCell *cell = (HONUserToggleViewCell *)[_tableView cellForRowAtIndexPath:indexPath];
//					[cell toggleSelected:[[HONContactsAssistant sharedInstance] isContactUserInvitedToClubs:vo]];
//				}
//				
//				indexPath = [NSIndexPath indexPathForRow:indexPath.row + 1 inSection:indexPath.section];
//			}
//		}
//	}
}

@end
