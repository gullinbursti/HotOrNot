//
//  HONTimelineViewController.m
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "MBProgressHUD.h"
#import "Mixpanel.h"

#import "HONTimelineViewController.h"
#import "HONTimelineItemViewCell.h"
#import "HONUserProfileViewCell.h"
#import "HONAppDelegate.h"
#import "HONChallengeVO.h"
#import "HONPopularUserVO.h"
#import "HONFacebookCaller.h"
#import "HONRegisterViewController.h"
#import "HONImagePickerViewController.h"
#import "HONHeaderView.h"
#import "HONSearchHeaderView.h"
#import "HONVotersViewController.h"
#import "HONCommentsViewController.h"
#import "HONLoginViewController.h"
#import "HONTimelineItemDetailsViewController.h"
#import "HONUsernameViewController.h"

@interface HONTimelineViewController()
@property(nonatomic) int subjectID;
@property(nonatomic, strong) NSString *subjectName;
@property(nonatomic, strong) NSString *username;
@property(nonatomic, strong) UIImageView *tutorialOverlayImgView;
@property(nonatomic, strong) UIImageView *toggleImgView;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *challenges;
@property(nonatomic) BOOL isPushView;
@property(nonatomic, strong) HONChallengeVO *challengeVO;
@property(nonatomic, strong) MBProgressHUD *progressHUD;
@property(nonatomic, strong) UIButton *refreshButton;
@property(nonatomic) int submitAction;
@property(nonatomic, strong) HONHeaderView *headerView;
@property(nonatomic, strong) UIImageView *emptySetImgView;
@property(nonatomic, strong) HONPopularUserVO *userVO;
@end

@implementation HONTimelineViewController

- (id)init {
	if ((self = [super init])) {
		_subjectID = 0;
		_submitAction = 4;
		_isPushView = NO;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[self _registerNotifications];
	}
	
	return (self);
}

- (id)initWithSubjectID:(int)subjectID {
	if ((self = [super init])) {
		_isPushView = YES;
		
		_subjectID = subjectID;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[self _registerNotifications];
	}
	
	return (self);
}

- (id)initWithSubjectName:(NSString *)subjectName {
	if ((self = [super init])) {
		_isPushView = YES;
		_subjectName = subjectName;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[self _registerNotifications];
	}
	
	return (self);
}


- (id)initWithUsername:(NSString *)username {
	if ((self = [super init])) {
		_isPushView = YES;
		
		_subjectID = 0;
		_challengeVO = nil;
		_subjectName = nil;
		_username = username;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[self _registerNotifications];
	}
	
	return (self);
}

- (id)initWithChallenge:(HONChallengeVO *)vo {
	if ((self = [super init])) {
		_isPushView = YES;
		
		_subjectID = 0;
		_challengeVO = vo;
		_subjectName = _challengeVO.subjectName;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[self _registerNotifications];
	}
	
	return (self);
}

- (void)_registerNotifications {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showTutorial:) name:@"SHOW_TUTORIAL" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshVoteTab:) name:@"REFRESH_VOTE_TAB" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshVoteTab:) name:@"REFRESH_ALL_TABS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showNotInSessionDetails:) name:@"SHOW_NOT_IN_SESSION_DETAILS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionCreatorDetails:) name:@"SHOW_IN_SESSION_CREATOR_DETAILS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionChallengerDetails:) name:@"SHOW_IN_SESSION_CHALLENGER_DETAILS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newCreatorChallenge:) name:@"NEW_CREATOR_CHALLENGE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newChallengerChallenge:) name:@"NEW_CHALLENGER_CHALLENGE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newSubjectChallenge:) name:@"NEW_SUBJECT_CHALLENGE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_shareChallenge:) name:@"SHARE_CHALLENGE" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showVoters:) name:@"SHOW_VOTERS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showComments:) name:@"SHOW_COMMENTS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showSearchResults:) name:@"SHOW_SEARCH_RESULTS" object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_hideSearchResults:) name:@"HIDE_SEARCH_RESULTS" object:nil];
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
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
	
	if (_subjectID == 0) {
		if (_subjectName != nil) {
			[params setObject:[NSString stringWithFormat:@"%d", 8] forKey:@"action"];
			[params setObject:_subjectName forKey:@"subjectName"];
			
		} else {
			if (_username != nil) {
				[params setObject:_username forKey:@"username"];
				[params setObject:[NSString stringWithFormat:@"%d", 9] forKey:@"action"];
				
			} else
				[params setObject:[NSString stringWithFormat:@"%d", _submitAction] forKey:@"action"];
		}
	} else {
		[params setObject:[NSString stringWithFormat:@"%d", 2] forKey:@"action"];
		[params setObject:[NSString stringWithFormat:@"%d", _subjectID] forKey:@"subjectID"];
	}
	
	[httpClient postPath:kVotesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"HONHONTimelineViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
		} else {
			NSArray *parsedLists = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			//NSLog(@"HONHONTimelineViewController AFNetworking: %@", parsedLists);
			_challenges = [NSMutableArray new];
			
			int cnt = 0;
			for (NSDictionary *serverList in parsedLists) {
				HONChallengeVO *vo = [HONChallengeVO challengeWithDictionary:serverList];
				
				if (vo != nil) {
					//NSLog(@"%d)--> ADDING CHALLENGE[%@]", cnt, vo.dictionary);
					[_challenges addObject:vo];
					cnt++;
				}
			}
			
			_emptySetImgView.hidden = ([_challenges count] > 0);
			[_tableView reloadData];
			
			if ([_challenges count] == 0) {
				[[[UIAlertView alloc] initWithTitle:@"Nothing Here!"
											message:@"No PicChallenges in session. You should start one."
										   delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
			}
		}
		
		_refreshButton.hidden = NO;
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"HONTimelineViewController AFNetworking %@", [error localizedDescription]);
		
		_refreshButton.hidden = NO;
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"Connection Error!", @"Status message when no network detected");
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:1.5];
		_progressHUD = nil;
	}];
}

- (void)_retrieveSingleChallenge:(HONChallengeVO *)vo {
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
							[NSString stringWithFormat:@"%d", 3], @"action",
							[[HONAppDelegate infoForUser] objectForKey:@"id"], @"userID",
							[NSString stringWithFormat:@"%d", vo.challengeID], @"challengeID",
							nil];
	
	[httpClient postPath:kVotesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"HONHONTimelineViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
		} else {
			NSArray *parsedLists = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			//NSLog(@"HONHONTimelineViewController AFNetworking: %@", parsedLists);
			_challenges = [NSMutableArray new];
			
			int cnt = 0;
			for (NSDictionary *serverList in parsedLists) {
				HONChallengeVO *vo = [HONChallengeVO challengeWithDictionary:serverList];
				
				if (vo != nil) {
					//NSLog(@"%d)--> ADDING CHALLENGE[%@]", cnt, vo.dictionary);
					[_challenges addObject:vo];
					cnt++;
				}
			}
			
			_emptySetImgView.hidden = ([_challenges count] > 0);
			[_tableView reloadData];
			
			if ([_challenges count] == 0) {
				[[[UIAlertView alloc] initWithTitle:@"Nothing Here!"
											message:@"No PicChallenges in session. You should start one."
										   delegate:nil
								  cancelButtonTitle:@"OK"
								  otherButtonTitles:nil] show];
			}
		}
		
		_refreshButton.hidden = NO;
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"HONTimelineViewController AFNetworking %@", [error localizedDescription]);
		
		_refreshButton.hidden = NO;
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"Connection Error!", @"Status message when no network detected");
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:1.5];
		_progressHUD = nil;
	}];
}


- (void)_retrieveUser {
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:
									[NSString stringWithFormat:@"%d", 8], @"action",
									_username, @"username",
									nil];
	
	[httpClient postPath:kUsersAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSDictionary *userResult = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			NSLog(@"HONTimelineViewController AFNetworking - Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
		} else {
			NSLog(@"HONTimelineViewController AFNetworking: %@", userResult);
			
			if ([userResult objectForKey:@"id"] != [NSNull null]) {
				_userVO = [HONPopularUserVO userWithDictionary:userResult];
				
				if (_challengeVO == nil)
					[self _retrieveChallenges];
				
				else
					[self _retrieveSingleChallenge:_challengeVO];
			}
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"HONTimelineViewController AFNetworking %@", [error localizedDescription]);
	}];
}

#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
	
	//NSLog(@"SUBJECT:[%d][%d]", _subjectID, _isPushView);
	
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
	bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h" : @"mainBG"];
	[self.view addSubview:bgImgView];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:(_isPushView) ? (_username != nil) ? _username : _subjectName : @"HOME"];
	[self.view addSubview:_headerView];
	
	if (_isPushView) {
		UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
		backButton.frame = CGRectMake(3.0, 0.0, 64.0, 44.0);
		[backButton setBackgroundImage:[UIImage imageNamed:@"backButton_nonActive"] forState:UIControlStateNormal];
		[backButton setBackgroundImage:[UIImage imageNamed:@"backButton_Active"] forState:UIControlStateHighlighted];
		[backButton addTarget:self action:@selector(_goBack) forControlEvents:UIControlEventTouchUpInside];
		[_headerView addSubview:backButton];
	
	} else {
		
	}
	
	if (!_isPushView) {
		UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityIndicatorView.frame = CGRectMake(14.0, 10.0, 24.0, 24.0);
		[activityIndicatorView startAnimating];
		[_headerView addSubview:activityIndicatorView];
		
		_refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
		_refreshButton.frame = CGRectMake(0.0, 0.0, 50.0, 45.0);
		[_refreshButton setBackgroundImage:[UIImage imageNamed:@"refreshButton_nonActive"] forState:UIControlStateNormal];
		[_refreshButton setBackgroundImage:[UIImage imageNamed:@"refreshButton_Active"] forState:UIControlStateHighlighted];
		[_refreshButton addTarget:self action:@selector(_goRefresh) forControlEvents:UIControlEventTouchUpInside];
		[_headerView addSubview:_refreshButton];
	}
	
	UIButton *createChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	createChallengeButton.frame = CGRectMake(270.0, 0.0, 50.0, 45.0);
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"tabbar_003_nonActive"] forState:UIControlStateNormal];
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"tabbar_003_onTap"] forState:UIControlStateHighlighted];
	[createChallengeButton addTarget:self action:@selector(_goCreateChallenge) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addSubview:createChallengeButton];
	
	_emptySetImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 115.0, 320.0, 285.0)];
	_emptySetImgView.image = [UIImage imageNamed:@"noChallengesOverlay"];
	_emptySetImgView.hidden = YES;
	[self.view addSubview:_emptySetImgView];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 45.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 45.0) style:UITableViewStylePlain];
	[_tableView setBackgroundColor:[UIColor clearColor]];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.rowHeight = 249.0;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.userInteractionEnabled = YES;
	_tableView.scrollsToTop = NO;
	_tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:_tableView];
	
	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = @"Getting Challenges…";
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	if ([_username length] > 0) {
		[self _retrieveUser];
	
	} else {
		if (_challengeVO == nil)
			[self _retrieveChallenges];
		
		else
			[self _retrieveSingleChallenge:_challengeVO];
	}
	
	//if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"boot_total"] intValue] == 0)
		[self performSelector:@selector(_goTutorial) withObject:self afterDelay:1.0];
}

- (void)viewDidLoad {
	[super viewDidLoad];
}

- (void)viewDidUnload {
	[super viewDidUnload];
}


#pragma mark - Navigation
- (void)_goBack {
	[self.navigationController popViewControllerAnimated:YES];
}

- (void)_goRefresh {
	[[Mixpanel sharedInstance] track:@"Vote Wall - Refresh"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	_refreshButton.hidden = YES;
	
	_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
	_progressHUD.labelText = @"Refreshing…";
	_progressHUD.mode = MBProgressHUDModeIndeterminate;
	_progressHUD.minShowTime = kHUDTime;
	_progressHUD.taskInProgress = YES;
	
	if (_isPushView)
		[self _retrieveSingleChallenge:_challengeVO];
	
	else
		[self _retrieveChallenges];
}

- (void)_goDailyChallenge {
	[[Mixpanel sharedInstance] track:@"Daily Challenge - Vote Wall"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithSubject:[HONAppDelegate dailySubjectName]]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_goCreateChallenge {
	[[Mixpanel sharedInstance] track:@"Create Challenge Button - Vote Wall"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:NO completion:nil];
}

- (void)_goInviteFriends {
	[[Mixpanel sharedInstance] track:@"Invite Friends - Vote Wall"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"INVITE_FRIENDS" object:nil];
}

- (void)_goTutorial {
	[[Mixpanel sharedInstance] track:@"Tutorial"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	int boot_total = [[[NSUserDefaults standardUserDefaults] objectForKey:@"boot_total"] intValue];
	[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:++boot_total] forKey:@"boot_total"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
//	NSString *buttonImage = ([HONAppDelegate isRetina5]) ? @"tutorial-568h" : @"tutorial";
//	
//	_tutorialOverlayImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 20.0, 320.0, ([HONAppDelegate isRetina5]) ? 548.0 : 460.0)];
//	_tutorialOverlayImgView.image = [UIImage imageNamed:buttonImage];
//	_tutorialOverlayImgView.userInteractionEnabled = YES;
//	[[[UIApplication sharedApplication] delegate].window addSubview:_tutorialOverlayImgView];
//	
//	UIButton *closeTutorialButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	closeTutorialButton.frame = _tutorialOverlayImgView.frame;
//	[closeTutorialButton addTarget:self action:@selector(_goTutorialClose) forControlEvents:UIControlEventTouchUpInside];
//	[_tutorialOverlayImgView addSubview:closeTutorialButton];
//	
//	UILabel *usernameLabel = [[UILabel alloc] initWithFrame:CGRectMake(20.0, 145.0, 280.0, 16.0)];
//	usernameLabel.font = [[HONAppDelegate honHelveticaNeueFontBold] fontWithSize:14];
//	usernameLabel.textColor = [UIColor whiteColor];
//	usernameLabel.backgroundColor = [UIColor clearColor];
//	usernameLabel.textAlignment = NSTextAlignmentCenter;
//	usernameLabel.text = [NSString stringWithFormat:@"Your username is %@", [[HONAppDelegate infoForUser] objectForKey:@"name"]];
//	[_tutorialOverlayImgView addSubview:usernameLabel];
//	
//	UIButton *submitButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	submitButton.frame = CGRectMake(18.0, 150.0, 283.0, 78.0);
//	[submitButton setBackgroundImage:[UIImage imageNamed:@"submitUserNameButton_nonActive"] forState:UIControlStateNormal];
//	[submitButton setBackgroundImage:[UIImage imageNamed:@"submitUserNameButton_Active"] forState:UIControlStateHighlighted];
//	[submitButton addTarget:self action:@selector(_goChangeUsername) forControlEvents:UIControlEventTouchUpInside];
//	[_tutorialOverlayImgView addSubview:submitButton];
//	
//	UIButton *createChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
//	createChallengeButton.frame = CGRectMake(128.0, _tutorialOverlayImgView.frame.size.height - 48.0, 64.0, 48.0);
//	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"tabbar_003_nonActive"] forState:UIControlStateNormal];
//	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"tabbar_003_active"] forState:UIControlStateHighlighted];
//	[createChallengeButton addTarget:self action:@selector(_goTutorialChallenge) forControlEvents:UIControlEventTouchUpInside];
//	[_tutorialOverlayImgView addSubview:createChallengeButton];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONRegisterViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:^(void) {
	}];
	
}


- (void)_goTutorialChallenge {
	[[Mixpanel sharedInstance] track:@"Tutorial Challenge Button"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[self _goTutorialClose];
	[self _goCreateChallenge];
}

- (void)_goTutorialClose {
	_tutorialOverlayImgView.hidden = YES;
	[_tutorialOverlayImgView removeFromSuperview];
}

- (void)_goChangeUsername {
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONUsernameViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:^(void) {
		[self _goTutorialClose];
	}];
}


#pragma mark - Notifications
- (void)_shareChallenge:(NSNotification *)notification {
	_challengeVO = (HONChallengeVO *)[notification object];
	
	if (FBSession.activeSession.state == 513)
		[HONFacebookCaller postToTimeline:_challengeVO];
	
	else {
		UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONLoginViewController alloc] init]];
		[navController setNavigationBarHidden:YES];
		[self presentViewController:navController animated:YES completion:nil];
	}

}

- (void)_refreshVoteTab:(NSNotification *)notification {
	[_tableView setContentOffset:CGPointZero animated:YES];
	
	if (_isPushView)
		[self _retrieveSingleChallenge:_challengeVO];
	
	else
		[self _retrieveChallenges];
}

- (void)_showNotInSessionDetails:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Details"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
		
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONTimelineItemDetailsViewController alloc] initAsNotInSession:vo]];
	[navController setNavigationBarHidden:YES];
	[self presentViewController:navController animated:NO completion:nil];
}

- (void)_showInSessionCreatorDetails:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Creator Details"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONTimelineItemDetailsViewController alloc] initAsInSessionCreator:vo]];
	[navController setNavigationBarHidden:YES];
	[self presentViewController:navController animated:NO completion:nil];
}

- (void)_showInSessionChallengerDetails:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Challenger Details"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONTimelineItemDetailsViewController alloc] initAsInSessionChallenger:vo]];
	[navController setNavigationBarHidden:YES];
	[self presentViewController:navController animated:NO completion:nil];
}

- (void)_newCreatorChallenge:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Challenge Creator"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	UINavigationController *navigationController = (vo.statusID == 1 || ([[[HONAppDelegate infoForUser] objectForKey:@"id"] intValue] == vo.challengerID && vo.statusID == 2)) ? [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithChallenge:vo]] : [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithUser:vo.creatorID withSubject:vo.subjectName]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_newChallengerChallenge:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Challenge Challenger"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithUser:vo.challengerID withSubject:vo.subjectName]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_newSubjectChallenge:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Challenge Subject"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] initWithSubject:vo.subjectName]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}

- (void)_showVoters:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Voters"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"challenge", nil]];
	
//	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONVotersViewController alloc] initWithChallenge:vo]];
//	[navigationController setNavigationBarHidden:YES];
//	[self presentViewController:navigationController animated:NO completion:nil];
	
	[self.navigationController pushViewController:[[HONVotersViewController alloc] initWithChallenge:vo] animated:YES];
}

- (void)_showComments:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Comments"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"challenge", nil]];
	
//	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONCommentsViewController alloc] initWithChallenge:vo]];
//	[navigationController setNavigationBarHidden:YES];
//	[self presentViewController:navigationController animated:NO completion:nil];
	
	[self.navigationController pushViewController:[[HONCommentsViewController alloc] initWithChallenge:vo] animated:YES];
}

- (void)_showSearchResults:(NSNotification *)notification {
	[UIView animateWithDuration:0.25 animations:^(void) {
		self.view.frame = CGRectMake(self.view.frame.origin.x, -44.0, self.view.frame.size.width, self.view.frame.size.height);
	}];
}

- (void)_hideSearchResults:(NSNotification *)notification {
	[UIView animateWithDuration:0.25 animations:^(void) {
		self.view.frame = CGRectMake(self.view.frame.origin.x, 0.0, self.view.frame.size.width, self.view.frame.size.height);
	}];
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_challenges count] + ([_username length] > 0));
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (1);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	HONSearchHeaderView *headerView = [[HONSearchHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 71.0)];
	[headerView.inviteFriendsButton addTarget:self action:@selector(_goInviteFriends) forControlEvents:UIControlEventTouchUpInside];
	[headerView.dailyChallengeButton addTarget:self action:@selector(_goDailyChallenge) forControlEvents:UIControlEventTouchUpInside];
		
	return (headerView);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	if ([_username length] > 0) {
		if (indexPath.row == 0) {
			HONUserProfileViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
			
			if (cell == nil) {
				cell = [[HONUserProfileViewCell alloc] init];
				cell.userVO = _userVO;
			}
			
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			return (cell);
		
		} else {
			HONTimelineItemViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
			
			if (cell == nil) {
				HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:indexPath.row - 1];
				cell = (vo.statusID == 1 || vo.statusID == 2) ? [[HONTimelineItemViewCell alloc] initAsWaitingCell] : [[HONTimelineItemViewCell alloc] initAsStartedCell];
				cell.challengeVO = vo;
			}
			
			[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
			return (cell);
		}
	} else {
		HONTimelineItemViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
		
		if (cell == nil) {
			HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:indexPath.row];
			cell = (vo.statusID == 1 || vo.statusID == 2) ? [[HONTimelineItemViewCell alloc] initAsWaitingCell] : [[HONTimelineItemViewCell alloc] initAsStartedCell];
			cell.challengeVO = vo;
		}
		
		[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
		return (cell);
	}
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if ([_username length] > 0 && indexPath.row == 0)
		return (70.0);
	
	else {
		HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:indexPath.row];
		
		if ([vo.rechallengedUsers length] == 0)
			return ((vo.statusID == 1 || vo.statusID == 2) ? 445.0 : 290.0);//346.0 : 244.0);
		
		else
			return ((vo.statusID == 1 || vo.statusID == 2) ? 490.0 : 335.0);//346.0 : 244.0);
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return (71.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (nil);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
}


#pragma mark - ScrollView Delegates
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"HIDE_TABS" object:nil];
}

@end