//
//  HONVoteViewController
//  HotOrNot
//
//  Created by Matthew Holcombe on 09.06.12.
//  Copyright (c) 2012 Built in Menlo, LLC. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "MBProgressHUD.h"
#import "Mixpanel.h"

#import "HONVoteViewController.h"
#import "HONVoteItemViewCell.h"
#import "HONAppDelegate.h"
#import "HONChallengeVO.h"
#import "HONFacebookCaller.h"
#import "HONImagePickerViewController.h"
#import "HONHeaderView.h"
#import "HONChallengeTableHeaderView.h"
#import "HONVotersViewController.h"
#import "HONLoginViewController.h"
#import "HONVoteDetailsViewController.h"

@interface HONVoteViewController()
@property(nonatomic) int subjectID;
@property(nonatomic, strong) UIImageView *tutorialOverlayImgView;
@property(nonatomic, strong) UIImageView *toggleImgView;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong) NSMutableArray *challenges;
@property(nonatomic) BOOL isPushView;
@property(nonatomic, strong) HONChallengeVO *challengeVO;
@property(nonatomic, strong) MBProgressHUD *progressHUD;
@property(nonatomic, strong)  UIButton *refreshButton;
@property(nonatomic) int submitAction;
@property(nonatomic, strong) HONHeaderView *headerView;
@property(nonatomic, strong) UIImageView *emptySetImgView;
@end

@implementation HONVoteViewController

- (id)init {
	if ((self = [super init])) {
		_subjectID = 0;
		_submitAction = 4;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showTutorial:) name:@"SHOW_TUTORIAL" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshList:) name:@"REFRESH_LIST" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showNotInSessionDetails:) name:@"SHOW_NOT_IN_SESSION_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionCreatorDetails:) name:@"SHOW_IN_SESSION_CREATOR_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionChallengerDetails:) name:@"SHOW_IN_SESSION_CHALLENGER_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newCreatorChallenge:) name:@"NEW_CREATOR_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newChallengerChallenge:) name:@"NEW_CHALLENGER_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newSubjectChallenge:) name:@"NEW_SUBJECT_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_shareChallenge:) name:@"SHARE_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showVoters:) name:@"SHOW_VOTERS" object:nil];
	}
	
	return (self);
}

- (id)initWithSubject:(int)subjectID {
	if ((self = [super init])) {
		_isPushView = YES;
		[HONAppDelegate toggleViewPushed:YES];
		
		_subjectID = subjectID;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showTutorial:) name:@"SHOW_TUTORIAL" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshList:) name:@"REFRESH_LIST" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showNotInSessionDetails:) name:@"SHOW_NOT_IN_SESSION_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionCreatorDetails:) name:@"SHOW_IN_SESSION_CREATOR_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionChallengerDetails:) name:@"SHOW_IN_SESSION_CHALLENGER_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newCreatorChallenge:) name:@"NEW_CREATOR_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newChallengerChallenge:) name:@"NEW_CHALLENGER_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newSubjectChallenge:) name:@"NEW_SUBJECT_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_shareChallenge:) name:@"SHARE_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showVoters:) name:@"SHOW_VOTERS" object:nil];
	}
	
	return (self);
}

- (id)initWithChallenge:(HONChallengeVO *)vo {
	if ((self = [super init])) {
		_isPushView = YES;
		
		_subjectID = 0;
		_challengeVO = vo;
		
		self.view.backgroundColor = [UIColor whiteColor];
		_challenges = [NSMutableArray new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showTutorial:) name:@"SHOW_TUTORIAL" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_refreshList:) name:@"REFRESH_LIST" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showNotInSessionDetails:) name:@"SHOW_NOT_IN_SESSION_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionCreatorDetails:) name:@"SHOW_IN_SESSION_CREATOR_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showInSessionChallengerDetails:) name:@"SHOW_IN_SESSION_CHALLENGER_DETAILS" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newCreatorChallenge:) name:@"NEW_CREATOR_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newChallengerChallenge:) name:@"NEW_CHALLENGER_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_newSubjectChallenge:) name:@"NEW_SUBJECT_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_shareChallenge:) name:@"SHARE_CHALLENGE" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_showVoters:) name:@"SHOW_VOTERS" object:nil];
	}
	
	return (self);
}
							
- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return (NO);//interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
	
	//NSLog(@"SUBJECT:[%d][%d]", _subjectID, _isPushView);
	
	UIImageView *bgImgView = [[UIImageView alloc] initWithFrame:self.view.bounds];
	bgImgView.image = [UIImage imageNamed:([HONAppDelegate isRetina5]) ? @"mainBG-568h" : @"mainBG"];
	[self.view addSubview:bgImgView];
	
	_headerView = [[HONHeaderView alloc] initWithTitle:(_isPushView) ? _challengeVO.subjectName : @"HOME"];
	[self.view addSubview:_headerView];
		
	if (_isPushView) {
		UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
		backButton.frame = CGRectMake(0.0, 0.0, 74.0, 44.0);
		[backButton setBackgroundImage:[UIImage imageNamed:@"backButton_nonActive"] forState:UIControlStateNormal];
		[backButton setBackgroundImage:[UIImage imageNamed:@"backButton_Active"] forState:UIControlStateHighlighted];
		[backButton addTarget:self action:@selector(_goBack) forControlEvents:UIControlEventTouchUpInside];
		[_headerView addSubview:backButton];
	}
	
	UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	activityIndicatorView.frame = CGRectMake(284.0, 10.0, 24.0, 24.0);
	[activityIndicatorView startAnimating];
	[_headerView addSubview:activityIndicatorView];
	
	_refreshButton = [UIButton buttonWithType:UIButtonTypeCustom];
	_refreshButton.frame = CGRectMake(270.0, 0.0, 50.0, 45.0);
	[_refreshButton setBackgroundImage:[UIImage imageNamed:@"refreshButton_nonActive"] forState:UIControlStateNormal];
	[_refreshButton setBackgroundImage:[UIImage imageNamed:@"refreshButton_Active"] forState:UIControlStateHighlighted];
	[_refreshButton addTarget:self action:@selector(_goRefresh) forControlEvents:UIControlEventTouchUpInside];
	[_headerView addSubview:_refreshButton];
	
	_emptySetImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 120.0, 320.0, 285.0)];
	_emptySetImgView.image = [UIImage imageNamed:@"noChallengesOverlay"];
	_emptySetImgView.hidden = YES;
	[self.view addSubview:_emptySetImgView];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 45.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 113.0) style:UITableViewStylePlain];
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
	
	if (_challengeVO == nil)
		[self _retrieveChallenges];
	
	else {
		[self _retrieveSingleChallenge:_challengeVO];
	}
	
	
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"boot_total"] intValue] == 0)
		[self performSelector:@selector(_goTutorial) withObject:self afterDelay:1.0];
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
	
	NSLog(@"viewDidAppear %d", _isPushView);
	
	if (_isPushView)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"FB_SWITCH_HIDDEN" object:@"Y"];
	
	if ([_challenges count] == 0)
		[[[UIAlertView alloc] initWithTitle:@"Nothing Here!" message:@"No PicChallenges in session. You should start one." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


#pragma mark - Data Calls
- (void)_retrieveChallenges {
	AFHTTPClient *httpClient = [[AFHTTPClient alloc] initWithBaseURL:[NSURL URLWithString:[HONAppDelegate apiServerPath]]];
	
	NSMutableDictionary *params = [NSMutableDictionary dictionary];
	[params setObject:[[HONAppDelegate infoForUser] objectForKey:@"id"] forKey:@"userID"];
	
	if (_subjectID == 0)
		[params setObject:[NSString stringWithFormat:@"%d", _submitAction] forKey:@"action"];
	
	else {
		[params setObject:[NSString stringWithFormat:@"%d", 2] forKey:@"action"];
		[params setObject:[NSString stringWithFormat:@"%d", _subjectID] forKey:@"subjectID"];
	}
		
	[httpClient postPath:kVotesAPI parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		if (error != nil) {
			NSLog(@"Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
		} else {
			NSArray *parsedLists = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			//NSLog(@"HONVoteViewController AFNetworking: %@", parsedLists);
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
		}
		
		_refreshButton.hidden = NO;
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"%@", [error localizedDescription]);
		
		_refreshButton.hidden = NO;
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
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
			NSLog(@"Failed to parse job list JSON: %@", [error localizedFailureReason]);
			
		} else {
			NSArray *parsedLists = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
			//NSLog(@"HONVoteViewController AFNetworking: %@", parsedLists);
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
		}
		
		_refreshButton.hidden = NO;
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		NSLog(@"%@", [error localizedDescription]);
		
		_refreshButton.hidden = NO;
		if (_progressHUD != nil) {
			[_progressHUD hide:YES];
			_progressHUD = nil;
		}
	}];
}

#pragma mark - Navigation
- (void)_goBack {
	[HONAppDelegate toggleViewPushed:NO];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FB_SWITCH_HIDDEN" object:@"N"];
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
	
	
	//	if (FBSession.activeSession.state == 513) {
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[HONImagePickerViewController alloc] init]];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
	
	//	} else
	//		[self _goLogin];
}

- (void)_goInviteFriends {
	[[Mixpanel sharedInstance] track:@"Invite Friends - Vote Wall"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"INVITE_FRIENDS" object:nil];
}

- (void)_goTutorialInviteFriends {
	[[Mixpanel sharedInstance] track:@"Tutorial Invite Friends"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[self _goTutorialClose];
	[self _goInviteFriends];
}

- (void)_goTutorialDailyChallenge {
	[[Mixpanel sharedInstance] track:@"Tutorial Daily Challenge"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[self _goTutorialClose];
	[self _goDailyChallenge];
}

- (void)_goTutorialChallenge {
	[[Mixpanel sharedInstance] track:@"Tutorial Challenge Button"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	[self _goTutorialClose];
	[self _goCreateChallenge];
}

- (void)_goTutorialClose {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FB_SWITCH_HIDDEN" object:@"N"];
	
	_tutorialOverlayImgView.hidden = YES;
	[_tutorialOverlayImgView removeFromSuperview];
}


#pragma mark - Notifications
- (void)_goTutorial {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FB_SWITCH_HIDDEN" object:@"Y"];
	
	[[Mixpanel sharedInstance] track:@"Tutorial"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	
	NSString *buttonImage = ([HONAppDelegate isRetina5]) ? @"tutorial-568h" : @"tutorial";
	
	_tutorialOverlayImgView = [[UIImageView alloc] initWithFrame:CGRectMake(0.0, 20.0, 320.0, ([HONAppDelegate isRetina5]) ? 548.0 : 460.0)];
	_tutorialOverlayImgView.image = [UIImage imageNamed:buttonImage];
	_tutorialOverlayImgView.userInteractionEnabled = YES;
	[[[UIApplication sharedApplication] delegate].window addSubview:_tutorialOverlayImgView];
	
	UIButton *closeTutorialButton = [UIButton buttonWithType:UIButtonTypeCustom];
	closeTutorialButton.frame = _tutorialOverlayImgView.frame;
	[closeTutorialButton addTarget:self action:@selector(_goTutorialClose) forControlEvents:UIControlEventTouchUpInside];
	[_tutorialOverlayImgView addSubview:closeTutorialButton];

	UIButton *inviteFriendsButton = [UIButton buttonWithType:UIButtonTypeCustom];
	inviteFriendsButton.frame = CGRectMake(0.0, 45.0, 91.0, 70.0);
	[inviteFriendsButton setBackgroundImage:[UIImage imageNamed:@"inviteFriends_nonActive"] forState:UIControlStateNormal];
	[inviteFriendsButton setBackgroundImage:[UIImage imageNamed:@"inviteFriends_Active"] forState:UIControlStateHighlighted];
	[inviteFriendsButton addTarget:self action:@selector(_goTutorialInviteFriends) forControlEvents:UIControlEventTouchUpInside];
	[_tutorialOverlayImgView addSubview:inviteFriendsButton];

	UIButton *dailyChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	dailyChallengeButton.frame = CGRectMake(91.0, 45.0, 229.0, 70.0);
	[dailyChallengeButton setBackgroundImage:[UIImage imageNamed:@"startDailyChallenge_nonActive"] forState:UIControlStateNormal];
	[dailyChallengeButton setBackgroundImage:[UIImage imageNamed:@"startDailyChallenge_Active"] forState:UIControlStateHighlighted];
	dailyChallengeButton.titleLabel.font = [[HONAppDelegate freightSansBlack] fontWithSize:15];
	[dailyChallengeButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
	dailyChallengeButton.titleEdgeInsets = UIEdgeInsetsMake(10.0, -30.0, -10.0, 30.0);
	[dailyChallengeButton setTitle:[HONAppDelegate dailySubjectName] forState:UIControlStateNormal];
	[dailyChallengeButton addTarget:self action:@selector(_goTutorialDailyChallenge) forControlEvents:UIControlEventTouchUpInside];
	[_tutorialOverlayImgView addSubview:dailyChallengeButton];
	
	UIButton *createChallengeButton = [UIButton buttonWithType:UIButtonTypeCustom];
	createChallengeButton.frame = CGRectMake(128.0, _tutorialOverlayImgView.frame.size.height - 48.0, 64.0, 48.0);
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"tabbar_003_nonActive"] forState:UIControlStateNormal];
	[createChallengeButton setBackgroundImage:[UIImage imageNamed:@"tabbar_003_active"] forState:UIControlStateHighlighted];
	[createChallengeButton addTarget:self action:@selector(_goTutorialChallenge) forControlEvents:UIControlEventTouchUpInside];
	[_tutorialOverlayImgView addSubview:createChallengeButton];
}

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

- (void)_refreshList:(NSNotification *)notification {
	[_tableView setContentOffset:CGPointZero animated:YES];
	[self _retrieveChallenges];
}

- (void)_showNotInSessionDetails:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Details"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
		
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONVoteDetailsViewController alloc] initAsNotInSession:vo]];
	[navController setNavigationBarHidden:YES];
	[self presentViewController:navController animated:NO completion:nil];
}

- (void)_showInSessionCreatorDetails:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Creator Details"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONVoteDetailsViewController alloc] initAsInSessionCreator:vo]];
	[navController setNavigationBarHidden:YES];
	[self presentViewController:navController animated:NO completion:nil];
}

- (void)_showInSessionChallengerDetails:(NSNotification *)notification {
	HONChallengeVO *vo = (HONChallengeVO *)[notification object];
	
	[[Mixpanel sharedInstance] track:@"Vote Wall - Challenger Details"
								 properties:[NSDictionary dictionaryWithObjectsAndKeys:
												 [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user",
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONVoteDetailsViewController alloc] initAsInSessionChallenger:vo]];
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
												 [NSString stringWithFormat:@"%d - %@", vo.challengeID, vo.subjectName], @"user", nil]];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FB_SWITCH_HIDDEN" object:@"Y"];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:[[HONVotersViewController alloc] initWithChallenge:vo]];
	[navController setNavigationBarHidden:YES];
	[self presentViewController:navController animated:NO completion:nil];
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_challenges count]);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (1);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	HONChallengeTableHeaderView *headerView = [[HONChallengeTableHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, tableView.frame.size.width, 71.0)];
	[headerView.inviteFriendsButton addTarget:self action:@selector(_goInviteFriends) forControlEvents:UIControlEventTouchUpInside];
	[headerView.dailyChallengeButton addTarget:self action:@selector(_goDailyChallenge) forControlEvents:UIControlEventTouchUpInside];
		
	return (headerView);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONVoteItemViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil) {
		HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:indexPath.row];
		cell = (vo.statusID == 1 || vo.statusID == 2) ? [[HONVoteItemViewCell alloc] initAsWaitingCell] : [[HONVoteItemViewCell alloc] initAsStartedCell];
		cell.challengeVO = vo;
	}
	
	[cell setSelectionStyle:UITableViewCellSelectionStyleNone];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONChallengeVO *vo = (HONChallengeVO *)[_challenges objectAtIndex:indexPath.row];
	return ((vo.statusID == 1 || vo.statusID == 2) ? 352.0 : 244.0);//346.0 : 244.0);
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


@end