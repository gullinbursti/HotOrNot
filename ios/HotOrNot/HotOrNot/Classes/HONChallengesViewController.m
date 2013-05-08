//
//  HONChallengesViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import <MessageUI/MFMessageComposeViewController.h>
#import <MessageUI/MFMailComposeViewController.h>

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "Mixpanel.h"
#import "MBProgressHUD.h"

#import "HONAppDelegate.h"
#import "HONChallengesViewController.h"
#import "HONChallengeViewCell.h"
#import "HONChallengeVO.h"
#import "HONImagePickerViewController.h"
#import "HONTimelineViewController.h"
#import "HONHeaderView.h"
#import "HONChallengePreviewViewController.h"
#import "HONSearchBarHeaderView.h"


@interface HONChallengesViewController() <MFMessageComposeViewControllerDelegate, MFMailComposeViewControllerDelegate, UIAlertViewDelegate, UIGestureRecognizerDelegate>
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
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showEmailComposer:) name:@"SHOW_EMAIL_COMPOSER" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showSMSComposer:) name:@"SHOW_SMS_COMPOSER" object:nil];
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
	_isMoreLoadable = NO;
	
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"%d", 2], @"action",
							[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
							nil];
	
	[httpClient postPath:kAPIChallenges parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
			NSArray *parsedLists = [NSMutableArray arrayWithArray:[unsortedChallenges sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"updated" ascending:NO]]]];
			//NSLog(@"HONChallengesViewController AFNetworking: %@", unsortedChallenges);
			
			_challenges = [NSMutableArray array];
			for (NSDictionary *serverList in parsedLists) {
				HONChallengeVO *vo = [HONChallengeVO challengeWithDictionary:serverList];
				
				if (vo != nil)
					[_challenges addObject:vo];
			}
			

			_lastDate = ((HONChallengeVO *)[_challenges lastObject]).addedDate;
			_emptySetImgView.hidden = ([_challenges count] > 0);
			[_tableView reloadData];
			
			_isMoreLoadable = ([_challenges count] % 10 == 0 || [_challenges count] > 0);
			HONChallengeViewCell *cell = (HONChallengeViewCell *)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:([_challenges count] - 1) inSection:0]];
			[cell toggleLoadMore:_isMoreLoadable];
			
			NSLog(@"CELL%@", cell);
			
			
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
		
		[httpClient postPath:kAPIUsers parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
	
	_isMoreLoadable = NO;
	
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
	bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h@2x" : @"mainBG"];
	[self.view addSubview:bgImgView];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:NSLocalizedString(@"header_activity", nil)];
	[[_headerView refreshButton] addTarget:self action:@selector(_goRefresh) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:_headerView];
	
	UIButton *createChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	createChallengeButton.frame = CGRectMake(266.0, 0.0, 54.0, 44.0);
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"createChallengeButton_nonActive"] forState:UIControlStateNormal];
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"createChallengeButton_Active"] forState:UIControlStateHighlighted];
	[createChallengeButton addTarget:self action:@selector(_goCreateChallenge) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addSubview:createChallengeButton];
	
	_emptySetImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 88.0, 320.0, 285.0)];
	_emptySetImgView.image = [UIImage imageNamed:@"noSnapsAvailable"];
	_emptySetImgView.hidden = YES;
	_emptySetImgView.userInteractionEnabled = YES;
	[self.view addSubview:_emptySetImgView];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, kNavBarHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavBarHeaderHeight + 81.0)) style:UITableViewStylePlain];
	[_tableView setBackgroundColor:[UIColor clearColor]];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.rowHeight = 70.0;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.userInteractionEnabled = YES;
	_tableView.scrollsToTop = NO;
	_tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:_tableView];
}

- (void)viewDidLoad {
	[super viewDidLoad];
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
- (void)_goCreateChallenge {
	[[Mixpanel sharedInstance] track:@"Activity - Create Snap"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] init]];
		[navigationController setNavigationBarHidden:YES];
		[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)_goRefresh {
	_isMoreLoadable = NO;
	
	[[Mixpanel sharedInstance] track:@"Activity - Refresh"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[_headerView toggleRefresh:YES];
	[self _retrieveChallenges];
	[self _retrieveUser];
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
	_progressHUD.labelText = NSLocalizedString(@"hud_loading", nil);
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	NSString *prevIDs = @"";
	for (HONChallengeVO *vo in _challenges)
		prevIDs = [prevIDs stringByAppendingString:[NSString stringWithFormat:@"%d|", ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] == vo.creatorID) ? vo.challengerID : vo.creatorID]];
	
	
	//NSLog(@"NEXT\n%@\n%@", [prevIDs substringToIndex:[prevIDs length] - 1], _lastDate);
	
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 12], @"action",
									[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
									[prevIDs substringToIndex:[prevIDs length] - 1], @"prevIDs", 
									_lastDate, @"datetime",
									nil];
	
	[httpClient postPath:kAPIChallenges parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
			NSArray *parsedLists = [NSMutableArray arrayWithArray:[unsortedChallenges sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"updated" ascending:NO]]]];
			//NSLog(@"HONChallengesViewController AFNetworking: %@", unsortedChallenges);
			
			//[_challenges removeLastObject];
			for (NSDictionary *serverList in parsedLists) {
				HONChallengeVO *vo = [HONChallengeVO challengeWithDictionary:serverList];
				
				if (vo != nil)
					[_challenges addObject:vo];
			}
			
			_lastDate = ((HONChallengeVO *)[_challenges lastObject]).addedDate;
			[_tableView reloadData];
			
			_isMoreLoadable = ([_challenges count] % 10 == 0 || [parsedLists count] > 0);
			HONChallengeViewCell *cell = (HONChallengeViewCell *)[_tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:([_challenges count] - 1) inSection:0]];
			[cell toggleLoadMore:_isMoreLoadable];
			
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
	[_headerView toggleRefresh:YES];
	[self _retrieveChallenges];
	[self _retrieveUser];
}

- (void)_tabsDropped:(NSNotification *)notification {
	_tableView.frame = CGRectMake(0.0, kNavBarHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavBarHeaderHeight + 29.0));
}

- (void)_tabsRaised:(NSNotification *)notification {
	_tableView.frame = CGRectMake(0.0, kNavBarHeaderHeight, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - (kNavBarHeaderHeight + 81.0));
}

- (void)_showEmailComposer:(NSNotification *)notification {
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

- (void)_showSMSComposer:(NSNotification *)notification {
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



#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_challenges count] + 1);
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
		if (indexPath.row == [_challenges count]) {
			cell = [[HONChallengeViewCell alloc] initAsBottomCell:YES];
			[cell toggleLoadMore:_isMoreLoadable];
				
		} else
			cell = [[HONChallengeViewCell alloc] initAsBottomCell:NO];
	}
	
	if (indexPath.row < [_challenges count])
		cell.challengeVO = [_challenges objectAtIndex:indexPath.row];
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return ((indexPath.row < [_challenges count]) ? kDefaultCellHeight : 64.0);
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
		[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithChallenge:vo] animated:YES];
		
	} else if ([vo.status isEqualToString:@"Waiting"]) {
//		_previewViewController = [[HONChallengePreviewViewController alloc] initAsCreator:vo];
//		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_previewViewController];
//		[navigationController setNavigationBarHidden:YES];
//		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
//		[self presentViewController:navigationController animated:NO completion:nil];
		
		[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithUserID:_challengeVO.creatorID challengerID:_challengeVO.challengerID] animated:YES];
		//[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithChallenge:vo] animated:YES];
		
	} else if ([vo.status isEqualToString:@"Accept"]) {
//		_previewViewController = [[HONChallengePreviewViewController alloc] initAsChallenger:vo];
//		UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:_previewViewController];
//		[navigationController setNavigationBarHidden:YES];
//		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
//		[self presentViewController:navigationController animated:NO completion:nil];
		
		[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithUserID:_challengeVO.challengerID challengerID:_challengeVO.creatorID] animated:YES];
		//[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithChallenge:vo] animated:YES];
			
	} else if ([vo.status isEqualToString:@"Started"] || [vo.status isEqualToString:@"Completed"]) {
		//[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithChallenge:vo] animated:YES];
		[self.navigationController pushViewController:[[HONTimelineViewController alloc] initWithUserID:_challengeVO.creatorID challengerID:_challengeVO.challengerID] animated:YES];
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


#pragma mark - MailCompose Delegates
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
				
				[httpClient postPath:kAPIChallenges parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
				
				[httpClient postPath:kAPIChallenges parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
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
