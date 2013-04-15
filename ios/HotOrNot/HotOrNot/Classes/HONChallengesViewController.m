//
//  HONChallengesViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <KiipSDK/KiipSDK.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "Mixpanel.h"
#import "MBProgressHUD.h"
#import "TapForTap.h"

#import "HONAppDelegate.h"
#import "HONChallengesViewController.h"
#import "HONChallengeViewCell.h"
#import "HONChallengeVO.h"
#import "HONSettingsViewController.h"
#import "HONImagePickerViewController.h"
#import "HONLoginViewController.h"
#import "HONTimelineViewController.h"
#import "HONHeaderView.h"
#import "HONFacebookCaller.h"
#import "HONChallengePreviewViewController.h"
#import "HONSearchBarHeaderView.h"


@interface HONChallengesViewController() <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate, TapForTapAdViewDelegate>
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *challenges;
@property(nonatomic, strong) MBProgressHUD *progressHUD;
@property(nonatomic) BOOL isMoreLoadable;
@property(nonatomic, strong) NSDate *lastDate;
@property(nonatomic, strong) HONChallengeVO *challengeVO;
@property(nonatomic, strong) NSIndexPath *idxPath;
@property(nonatomic, strong) HONHeaderView *headerView;
@property(nonatomic, strong) UIImageView *emptySetImgView;
@property(nonatomic, strong) NSMutableArray *friends;
@property(nonatomic, retain) HONChallengePreviewViewController *previewViewController;
@property(nonatomic) int blockCounter;

- (void)_retrieveChallenges;
- (void)_retrieveUser;
@end

@implementation HONChallengesViewController

- (id)init {
	if ((self = [super init])) {
		_challenges = [NSMutableArray array];
		_blockCounter = 0;
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_acceptChallenge:) name:@"ACCEPT_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_nextChallengeBlock:) name:@"NEXT_CHALLENGE_BLOCK" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshChallengesTab:) name:@"REFRESH_CHALLENGES_TAB" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshChallengesTab:) name:@"REFRESH_ALL_TABS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabsDropped:) name:@"TABS_DROPPED" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_tabsRaised:) name:@"TABS_RAISED" object:nil];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showSearchTable:) name:@"SHOW_SEARCH_TABLE" object:nil];
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hideSearchTable:) name:@"HIDE_SEARCH_TABLE" object:nil];
	}
	
	return (self);
}
							
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)dealloc {
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (NO);
}

#pragma mark - Data Calls
- (void)_retrieveChallenges {
	_isMoreLoadable = YES;
	
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"%d", 2], @"action",
							[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
							nil];
	
	[httpClient postPath:kChallengesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"HONChallengesViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
			[_headerView toggleRefresh:NO];
			if (_progressHUD != nil) {
				[_progressHUD hide:YES];
				_progressHUD = nil;
			}
			
		} else {
			NSArray *unsortedChallenges = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			NSArray *parsedLists = [NSMutableArray arrayWithArray:[unsortedChallenges sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"added" ascending:NO]]]];
			//NSLog(@"HONChallengesViewController AFNetworking: %@", unsortedChallenges);
			
			_challenges = [NSMutableArray array];
			for (NSDictionary *serverList in parsedLists) {
				HONChallengeVO *vo = [HONChallengeVO challengeWithDictionary:serverList];
				
				if (vo != nil)
					[_challenges addObject:vo];
			}
			
			if ([parsedLists count] == 0 || [parsedLists count] % 10 != 0)
				_isMoreLoadable = NO;
			
			_lastDate = ((HONChallengeVO *)[_challenges lastObject]).addedDate;
			_emptySetImgView.hidden = ([_challenges count] > 0);
			[_tableView reloadData];
			
			[_headerView toggleRefresh:NO];
			if (_progressHUD != nil) {
				[_progressHUD hide:YES];
				_progressHUD = nil;
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"ChallengesViewController AFNetworking %@", [error localizedDescription]);
		
		[_headerView toggleRefresh:NO];
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

- (void)_retrieveUser {
	if ([HONAppDelegate infoForUser]) {
		
		AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
		NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
								[NSString stringWithFormat:@"%d", 5], @"action",
								[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
								nil];
		
		[httpClient postPath:kUsersAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
			NSError *error = nil;
			if (error != nil) {
				NSLog(@"HONChallengesViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
				
				[_headerView toggleRefresh:NO];
				if (_progressHUD != nil) {
					[_progressHUD hide:YES];
					_progressHUD = nil;
				}
				
			} else {
				NSDictionary *userResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
				//NSLog(@"HONChallengesViewController AFNetworking: %@", userResult);
				
				if ([userResult objectForKey:@"id"] != [NSNull null])
					[HONAppDelegate writeUserInfo:userResult];
				
				[_tableView reloadData];
				
				[_headerView toggleRefresh:NO];
				if (_progressHUD != nil) {
					[_progressHUD hide:YES];
					_progressHUD = nil;
				}
			}
			
		} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
			NSLog(@"ChallengesViewController AFNetworking %@", [error localizedDescription]);
			
			[_headerView toggleRefresh:NO];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:1.5];
			_progressHUD = nil;
		}];
	}
}


#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
	//NSLog(@"self.view.bounds:[%fx%f][%fx%f]", self.view.bounds.origin.x, self.view.bounds.origin.y, self.view.bounds.size.width, self.view.bounds.size.height);
	
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
	bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h@2x" : @"mainBG"];
	[self.view addSubview:bgImgView];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:NSLocalizedString(@"header_activity", nil)];
	[[_headerView refreshButton] addTarget:self action:@selector(_goRefresh) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_headerView];
	
	UIButton *inviteButton = [UIButton buttonWithType:UIButtonTypeCustom];
	inviteButton.frame = CGRectMake(270.0, 0.0, 44.0, 44.0);
	[inviteButton setBackgroundImage:[UIImage imageNamed:@"refreshButton_nonActive"] forState:UIControlStateNormal];
	[inviteButton setBackgroundImage:[UIImage imageNamed:@"refreshButton_Active"] forState:UIControlStateHighlighted];
	[inviteButton addTarget:self action:@selector(_goInvite) forControlEvents:UIControlEventTouchUpInside];
	inviteButton.hidden = (FBSession.activeSession.state != 513);
	//[_headerView addSubview:inviteButton];
	
	UIButton *createChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	createChallengeButton.frame = CGRectMake(270.0, 0.0, 44.0, 44.0);
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"createChallengeButton_nonActive"] forState:UIControlStateNormal];
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"createChallengeButton_Active"] forState:UIControlStateHighlighted];
	[createChallengeButton addTarget:self action:@selector(_goCreateChallenge) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addSubview:createChallengeButton];
	
	_emptySetImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 88.0, 320.0, 285.0)];
	_emptySetImgView.image = [UIImage imageNamed:@"noSnapsAvailable"];
	_emptySetImgView.hidden = YES;
	_emptySetImgView.userInteractionEnabled = YES;
	[self.view addSubview:_emptySetImgView];
	
	UIButton *inviteSMSButton = [UIButton buttonWithType:UIButtonTypeCustom];
	inviteSMSButton.frame = CGRectMake(73.0, 190.0, 174.0, 34.0);
	[inviteSMSButton setBackgroundImage:[UIImage imageNamed:@"inviteSMS_nonActive"] forState:UIControlStateNormal];
	[inviteSMSButton setBackgroundImage:[UIImage imageNamed:@"inviteSMS_Active"] forState:UIControlStateHighlighted];
	[inviteSMSButton addTarget:self action:@selector(_goInviteSMS) forControlEvents:UIControlEventTouchUpInside];
	[_emptySetImgView addSubview:inviteSMSButton];
	
	UIButton *inviteEmailButton = [UIButton buttonWithType:UIButtonTypeCustom];
	inviteEmailButton.frame = CGRectMake(73.0, 250.0, 174.0, 34.0);
	[inviteEmailButton setBackgroundImage:[UIImage imageNamed:@"inviteEMAIL_nonActive"] forState:UIControlStateNormal];
	[inviteEmailButton setBackgroundImage:[UIImage imageNamed:@"inviteEMAIL_Active"] forState:UIControlStateHighlighted];
	[inviteEmailButton addTarget:self action:@selector(_goInviteEmail) forControlEvents:UIControlEventTouchUpInside];
	[_emptySetImgView addSubview:inviteEmailButton];
	
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, kNavHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavHeaderHeight + 78.0)) style:UITableViewStylePlain];
	[_tableView setBackgroundColor:[UIColor clearColor]];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.rowHeight = 70.0;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.userInteractionEnabled = YES;
	_tableView.scrollsToTop = NO;
	_tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:_tableView];
	
	//[self _populateFriends];
	
//	[[Kiip sharedInstance] saveMoment:@"Test Moment" withCompletionHandler:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	// banner
//	if ([HONAppDelegate isTapForTapEnabled])
//		[self.view addSubview:[[TapForTapAdView alloc] initWithFrame:CGRectMake(0.0, self.view.frame.size.height - 50.0, 320.0, 50.0) delegate:self]];
	
	// ad modal
//	[TapForTapInterstitial prepare];
//	[TapForTapInterstitial showWithRootViewController: self]; // or possibly self.navigationController
	
	// app wall
//	[TapForTapAppWall prepare];
//	[TapForTapAppWall showWithRootViewController: self]; // or possibly self.navigationController
}

- (void)viewDidUnload {
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self _retrieveChallenges];
	[self _retrieveUser];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


#pragma mark - Navigation
- (void)_goLogin {
	NSLog(@"_goLogin");
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONLoginViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_goCreateChallenge {
	[[Mixpanel sharedInstance] track:@"Activity - Create Snap"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] init]];
		[navigationController setNavigationBarHidden:YES];
		[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)_populateFriends {
	_friends = [NSMutableArray array];
	[FBRequestConnection startWithGraphPath:@"me/friends" completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
		//NSLog(@"FRIENDS:[%@]", (NSDictionary *)result);
		for (NSDictionary *friend in [(NSDictionary *)result objectForKey:@"data"])
			[_friends addObject: [friend objectForKey:@"id"]];
		
		NSLog(@"RETRIEVED (%d) FRIENDS", [_friends count]);
	}];
}

- (void)_goInvite {
	NSRange range;
	range.length = 50;
	range.location = _blockCounter * range.length;
	
	if (range.location >= [_friends count])
		range.location = 0;
	
	if (range.location + range.length > [_friends count])
		range.length = [_friends count] - range.location;
	
	NSLog(@"INVITING (%d-%d)/%d", range.location, range.location + range.length, [_friends count]);
	[HONFacebookCaller sendAppRequestBroadcastWithIDs:[_friends subarrayWithRange:range]];
	_blockCounter++;
}

- (void)_goRefresh {
	_isMoreLoadable = NO;
	
	[[Mixpanel sharedInstance] track:@"Activity - Refresh"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[_headerView toggleRefresh:YES];
	[self _retrieveChallenges];
	[self _retrieveUser];
	
//	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
//	_progressHUD.labelText = NSLocalizedString(@"hud_refresh", nil);
//	_progressHUD.mode = MBProgressHUDModeIndeterminate;
//	_progressHUD.minShowTime = kHUDTime;
//	_progressHUD.taskInProgress = YES;
}

- (void)_goInviteEmail {
	if ([MFMailComposeViewController canSendMail]) {
		MFMailComposeViewController *mailComposeViewController = [[MFMailComposeViewController alloc] init];
		mailComposeViewController.mailComposeDelegate = self;
		//[mailComposeViewController setToRecipients:[NSArray arrayWithObject:@"matt.holcombe@gmail.com"]];
		[mailComposeViewController setMessageBody:[NSString stringWithFormat:[HONAppDelegate emailInviteFormat], [[HONAppDelegate infoForUser] objectForKey:@"name"]] isHTML:NO];
		
		[self presentViewController:mailComposeViewController animated:YES completion:^(void) {}];
		
	} else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Error"
																			 message:@"Cannot send email from this device!"
																			delegate:nil
																cancelButtonTitle:@"OK"
																otherButtonTitles:nil];
		[alertView show];
	}
}

- (void)_goInviteSMS {
	if ([MFMessageComposeViewController canSendText]) {
		MFMessageComposeViewController *messageComposeViewController = [[MFMessageComposeViewController alloc] init];
		messageComposeViewController.messageComposeDelegate = self;
		//messageComposeViewController.recipients = [NSArray arrayWithObject:@"2393709811"];
		messageComposeViewController.body = [NSString stringWithFormat:[HONAppDelegate smsInviteFormat], [[HONAppDelegate infoForUser] objectForKey:@"name"]];
		
		[self presentViewController:messageComposeViewController animated:YES completion:^(void) {}];
	
	} else {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Email Error"
																			 message:@"Cannot send SMS from this device!"
																			delegate:nil
																cancelButtonTitle:@"OK"
																otherButtonTitles:nil];
		[alertView show];
	}
}


#pragma mark - Notifications
- (void)_acceptChallenge:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithChallenge:vo]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_nextChallengeBlock:(NSNotification *)notification {	
	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = NSLocalizedString(@"hud_getSnaps", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 12], @"action",
									[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
									_lastDate, @"datetime",
									nil];
	
	[httpClient postPath:kChallengesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"HONChallengesViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
			[_headerView toggleRefresh:NO];
			if (_progressHUD != nil) {
				[_progressHUD hide:YES];
				_progressHUD = nil;
			}
			
		} else {
			NSArray *unsortedChallenges = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			NSArray *parsedLists = [NSMutableArray arrayWithArray:[unsortedChallenges sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"added" ascending:NO]]]];
			//NSLog(@"HONChallengesViewController AFNetworking: %@", unsortedChallenges);
			
			[_challenges removeLastObject];
			for (NSDictionary *serverList in parsedLists) {
				HONChallengeVO *vo = [HONChallengeVO challengeWithDictionary:serverList];
				
				if (vo != nil)
					[_challenges addObject:vo];
			}
			
			if ([parsedLists count] == 0 || [parsedLists count] % 10 != 0)
				_isMoreLoadable = NO;
			
			if (!_isMoreLoadable) {
				HONChallengeViewCell *cell = (HONChallengeViewCell *)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:[_challenges count] inSection:0]];
				[cell disableLoadMore];
			}
			
			_lastDate = ((HONChallengeVO *)[_challenges lastObject]).addedDate;
			[_tableView reloadData];
			
			[_headerView toggleRefresh:NO];
			if (_progressHUD != nil) {
				[_progressHUD hide:YES];
				_progressHUD = nil;
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"ChallengesViewController AFNetworking %@", [error localizedDescription]);
		
		[_headerView toggleRefresh:NO];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:1.5];
		_progressHUD = nil;
	}];
}

- (void)_refreshChallengesTab:(NSNotification *)notification {
	[_tableView setContentOffset:CGPointZero animated:YES];
	[self _retrieveChallenges];
	[self _retrieveUser];
}

- (void)_showSearchTable:(NSNotification *)notification {
	[UIView animateWithDuration:0.25 animations:^(void) {
		self.view.frame = CGRectMake(self.view.frame.origin.x, -44.0, self.view.frame.size.width, self.view.frame.size.height);
	}];
}

- (void)_hideSearchTable:(NSNotification *)notification {
	[UIView animateWithDuration:0.25 animations:^(void) {
		self.view.frame = CGRectMake(self.view.frame.origin.x, 0.0, self.view.frame.size.width, self.view.frame.size.height);
	}];
}

- (void)_tabsDropped:(NSNotification *)notification {
	_tableView.frame = CGRectMake(0.0, kNavHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavHeaderHeight + 29.0));
}

- (void)_tabsRaised:(NSNotification *)notification {
	_tableView.frame = CGRectMake(0.0, kNavHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavHeaderHeight + 78.0));
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_challenges count] + (int)_isMoreLoadable);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (1);
}

//- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
//	HONSearchBarHeaderView *headerView = [[HONSearchBarHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 71.0)];
//	return (headerView);
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONChallengeViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];

	if (cell == nil) {
		if (indexPath.row == [_challenges count])
			cell = [[HONChallengeViewCell alloc] initAsBottomCell:YES];
				
		else
			cell = [[HONChallengeViewCell alloc] initAsBottomCell:NO];
	}
	
	if (indexPath.row < [_challenges count])
		cell.challengeVO = [_challenges objectAtIndex:indexPath.row];
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (kRowHeight);
}

//- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
//	return (kSearchHeaderHeight);
//}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [_challenges count]) {
		
		HONChallengeVO *vo = [_challenges objectAtIndex:indexPath.row];
		if ([vo.status isEqualToString:@"Created"] || [vo.status isEqualToString:@"Waiting"] || [vo.status isEqualToString:@"Accept"] || [vo.status isEqualToString:@"Started"] || [vo.status isEqualToString:@"Completed"])
			return (indexPath);
		
		else
			return (nil);
	}
	
	return (nil);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:YES];
	//[(HONChallengeViewCell *)[tableView cellForRowAtIndexPath:indexPath] didSelect];
	
	HONChallengeVO *vo = [_challenges objectAtIndex:indexPath.row];
	_challengeVO = vo;
	
	NSLog(@"STATUS:[%@]", vo.status);
	if ([vo.status isEqualToString:@"Created"]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Waiting Challenge"
																			 message:@"No game matches yet, try another hashtag!"
																			delegate:self
																cancelButtonTitle:@"OK"
																otherButtonTitles:nil];
		[alertView setTag:1];
		[alertView show];
		
	} else if ([vo.status isEqualToString:@"Waiting"]) {
		_previewViewController = [[HONChallengePreviewViewController alloc] initAsCreator:vo];
		//[self.view addSubview:_previewViewController.view];
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_previewViewController];
		[navigationController setNavigationBarHidden:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self presentViewController:navigationController animated:NO completion:nil];
		
	} else if ([vo.status isEqualToString:@"Accept"]) {
		_previewViewController = [[HONChallengePreviewViewController alloc] initAsChallenger:vo];
		//[self.view addSubview:_previewViewController.view];
		
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_previewViewController];
		[navigationController setNavigationBarHidden:YES];
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self presentViewController:navigationController animated:NO completion:nil];
			
	} else if ([vo.status isEqualToString:@"Started"] || [vo.status isEqualToString:@"Completed"]) {
		[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithChallenge:vo] animated:YES];
	}
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	// Return YES if you want the specified item to be editable.
	
	//return (indexPath.row > 0 && indexPath.row < [_challenges count] + 1);
	return (indexPath.row < [_challenges count]);
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		
		HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:indexPath.row];
		
		[[Mixpanel sharedInstance] track:@"Activity - Swipe Row"
									 properties:[NSDictionary dictionaryWithObjectsAndKeys:
													 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
													 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"challenge", nil]];
		
		_idxPath = indexPath;
		
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Delete Challenge"
																		message:@"Do you want to remove this challenge?"
																	  delegate:self
														  cancelButtonTitle:@"Report Abuse"
														  otherButtonTitles:@"Yes", @"No", nil];
		[alertView setTag:0];
		[alertView show];
	}
}


#pragma mark - ScrollView Delegates
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"HIDE_TABS" object:nil];
}


#pragma mark - MessageCompose Delegates
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result {
	
	switch (result) {
		case MessageComposeResultCancelled:
			NSLog(@"SMS: canceled");
			break;
			
		case MessageComposeResultSent:
			NSLog(@"SMS: sent");
			break;
			
		case MessageComposeResultFailed:
			NSLog(@"SMS: failed");
			break;
			
		default:
			NSLog(@"SMS: not sent");
			break;
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - MessageCompose Delegates
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
	switch (result) {
		case MFMailComposeResultCancelled:
			NSLog(@"EMAIL: canceled");
			break;
			
		case MFMailComposeResultFailed:
			NSLog(@"EMAIL: failed");
			break;
			
		case MFMailComposeResultSaved:
			NSLog(@"EMAIL: saved");
			break;
			
		case MFMailComposeResultSent:
			NSLog(@"EMAIL: sent");
			break;
			
		default:
			NSLog(@"EMAIL: not sent");
			break;
	}
	
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - AlerView Delegates
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:_idxPath.row];
	
	NSLog(@"BUTTON INDEX:[%d]", buttonIndex);
	
	// delete
	if (alertView.tag == 0) {
		switch(buttonIndex) {
			case 0: {
				[[Mixpanel sharedInstance] track:@"Activity - Flag"
											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
															 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"challenge", nil]];
				
				[_challenges removeObjectAtIndex:_idxPath.row];
				[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:_idxPath] withRowAnimation:UITableViewRowAnimationFade];
				
				AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
				NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSString stringWithFormat:@"%d", 11], @"action",
												[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
												[NSString stringWithFormat:@"%d", vo.challengeID], @"challengeID",
												nil];
				
				[httpClient postPath:kChallengesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
					NSError *error = nil;
					if (error != nil) {
						NSLog(@"HONChallengesViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
						
					} else {
						[self _goRefresh];
					}
					
				} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					NSLog(@"ChallengesViewController AFNetworking %@", [error localizedDescription]);
					
					_progressHUD.minShowTime = kHUDTime;
					_progressHUD.mode = MBProgressHUDModeCustomView;
					_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
					_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
					[_progressHUD show:NO];
					[_progressHUD hide:YES afterDelay:1.5];
					_progressHUD = nil;
				}];
				break;}
				
			case 1:
				[[Mixpanel sharedInstance] track:@"Activity - Delete"
											 properties:[NSDictionary dictionaryWithObjectsAndKeys:
															 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
															 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"challenge", nil]];
				
				[_challenges removeObjectAtIndex:_idxPath.row];
				[_tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:_idxPath] withRowAnimation:UITableViewRowAnimationFade];
				
				AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
				NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
												[NSString stringWithFormat:@"%d", 10], @"action",
												[NSString stringWithFormat:@"%d", vo.challengeID], @"challengeID",
												nil];
				
				[httpClient postPath:kChallengesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
					NSError *error = nil;
					if (error != nil) {
						NSLog(@"HONChallengesViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
						
					} else {
					}
					
				} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
					NSLog(@"ChallengesViewController AFNetworking %@", [error localizedDescription]);
					
					_progressHUD.minShowTime = kHUDTime;
					_progressHUD.mode = MBProgressHUDModeCustomView;
					_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
					_progressHUD.labelText = NSLocalizedString(@"hud_connectionError", nil);
					[_progressHUD show:NO];
					[_progressHUD hide:YES afterDelay:1.5];
					_progressHUD = nil;
				}];
				break;
		}
	
	} else if (alertView.tag == 1) {
		switch (buttonIndex) {
			case 0:
				break;
		}
	}
}


#pragma mark - AdView Delegates
- (UIViewController *)rootViewController {
	return (self);
}

@end
