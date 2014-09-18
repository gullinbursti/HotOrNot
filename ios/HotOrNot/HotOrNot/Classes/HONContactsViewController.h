//
//  HONContactsViewController.h
//  HotOrNot
//
//  Created by Matt Holcombe on 05/01/2014 @ 19:07 .
//  Copyright (c) 2014 Built in Menlo, LLC. All rights reserved.
//

#import <AddressBook/AddressBook.h>

#import "CKRefreshControl.h"

#import "HONViewController.h"
#import "HONTableView.h"
#import "HONHeaderView.h"
#import "HONClubViewCell.h"
#import "HONContactUserVO.h"
#import "HONTrivialUserVO.h"
#import "HONUserClubVO.h"
#import "HONSearchBarView.h"

typedef NS_OPTIONS(NSInteger, HONContactsTableViewDataSource) {
	HONContactsTableViewDataSourceEmpty			= 0 << 0,
	HONContactsTableViewDataSourceMatchedUsers	= 1 << 0,
	HONContactsTableViewDataSourceAddressBook	= 1 << 1,
	HONContactsTableViewDataSourceSearchResults	= 1 << 2
};

typedef NS_OPTIONS(NSUInteger, HONContactsSendType) {
	HONContactsSendTypeNone		= 0 << 0,
	HONContactsSendTypePhone	= 1 << 0,
	HONContactsSendTypeEmail	= 1 << 1,
	HONContactsSendTypeSMS		= 1 << 2
};

@interface HONContactsViewController : HONViewController <UIAlertViewDelegate, UITableViewDataSource, UITableViewDelegate> {
	HONContactsTableViewDataSource _tableViewDataSource;
	HONContactsSendType _contactsSendType;
	
	NSMutableArray *_headRows;
	NSMutableArray *_recentClubs;
	NSMutableArray *_deviceContacts;
	NSMutableArray *_inAppUsers;
	NSMutableArray *_searchUsers;
	HONUserClubVO *_userClubVO;
	
	HONTableView *_tableView;
	UIRefreshControl *_refreshControl;
	HONHeaderView *_headerView;
	HONSearchBarView *_searchBarView;
}

- (void)_goDataRefresh:(CKRefreshControl *)sender;
- (void)_didFinishDataRefresh;

- (void)_promptForAddressBookAccess;
- (void)_promptForAddressBookPermission;

- (void)_submitPhoneNumberForMatching;
- (void)_retrieveRecentClubs;
- (void)_retrieveDeviceContacts;
- (void)_sendEmailContacts;
- (void)_sendPhoneContacts;
- (void)_searchUsersWithUsername:(NSString *)username;

- (void)_updateDeviceContactsWithMatchedUsers;


- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectClub:(HONUserClubVO *)clubVO;
- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectContactUser:(HONContactUserVO *)contactUserVO;
- (void)clubViewCell:(HONClubViewCell *)viewCell didSelectTrivialUser:(HONTrivialUserVO *)trivialUserVO;

@end
