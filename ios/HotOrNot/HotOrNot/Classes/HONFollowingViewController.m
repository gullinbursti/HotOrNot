//
//  HONFollowingViewController.m
//  HotOrNot
//
//  Created by Matt Holcombe on 10/4/13 @ 5:47 PM.
//  Copyright (c) 2013 Built in Menlo, LLC. All rights reserved.
//

#import "AFHTTPClient.h"
#import "AFHTTPRequestOperation.h"
#import "MBProgressHUD.h"

#import "HONFollowingViewController.h"
#import "HONUserVO.h"
#import "HONHeaderView.h"
#import "HONFollowUserViewCell.h"
#import "HONUserProfileViewController.h"


@interface HONFollowingViewController () <HONFollowUserViewCellDelegate>
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) HONUserVO *userVO;
@property (nonatomic, strong) NSMutableArray *subscribees;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) int userID;
@property (nonatomic) BOOL hasUpdated;
@end


@implementation HONFollowingViewController


- (id)initWithUserID:(int)userID {
	if ((self = [super init])) {
		_userID = userID;
		_hasUpdated = NO;
		_subscribees = [NSMutableArray array];
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
- (void)_retrieveUser {
	NSDictionary *params = @{@"action"	: [NSString stringWithFormat:@"%d", 5],
							 @"userID"	: [NSString stringWithFormat:@"%d", _userID]};
	
	VolleyJSONLog(@"_/:[%@]—//> (%@/%@) %@\n\n", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, params);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:kAPIUsers parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			VolleyJSONLog(@"//—> AFNetworking -{%@}- (%@) %@", [[self class] description], [[operation request] URL], result);
			
			_userVO = [HONUserVO userWithDictionary:result];
			[self _retreiveSubscribees];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:kHUDErrorTime];
		_progressHUD = nil;
	}];
}

- (void)_retreiveSubscribees {
	NSDictionary *params = @{@"userID"	: [NSString stringWithFormat:@"%d", _userID]};
	
	VolleyJSONLog(@"_/:[%@]—//> (%@/%@) %@\n\n", [[self class] description], [HONAppDelegate apiServerPath], kAPIGetSubscribees, params);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	
	[httpClient postPath:kAPIGetSubscribees parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSArray *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			
			NSMutableArray *users = [NSMutableArray arrayWithCapacity:[result count]];
			for (NSDictionary *dict in result)
				[users addObject:[dict objectForKey:@"user"]];
			
			VolleyJSONLog(@"//—> AFNetworking -{%@}- (%@) %@", [[self class] description], [[operation request] URL], users);
			NSArray *following = [NSArray arrayWithArray:[users sortedArrayUsingDescriptors:[NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"username" ascending:YES selector:@selector(localizedCaseInsensitiveCompare:)]]]];
			for (NSDictionary *dict in following) {
				[_subscribees addObject:[HONUserVO userWithDictionary:[NSDictionary dictionaryWithObjectsAndKeys:
																	   [NSString stringWithFormat:@"%d", [[dict objectForKey:@"id"] intValue]], @"id",
																	   [NSString stringWithFormat:@"%d", 0], @"points",
																	   [NSString stringWithFormat:@"%d", 0], @"total_votes",
																	   [NSString stringWithFormat:@"%d", 0], @"pokes",
																	   [NSString stringWithFormat:@"%d", 0], @"pics",
																	   [NSString stringWithFormat:@"%d", 0], @"age",
																	   [dict objectForKey:@"username"], @"username",
																	   @"", @"fb_id",
																	   [HONAppDelegate cleanImagePrefixURL:[dict objectForKey:@"avatar_url"]], @"avatar_url", nil]]];
			}
			
			[_tableView reloadData];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:kHUDErrorTime];
		_progressHUD = nil;
	}];
}

- (void)_addFriend:(int)userID {
	NSDictionary *params = @{@"userID"	: [[HONAppDelegate infoForUser] objectForKey:@"id"],
							 @"target"	: [NSString stringWithFormat:@"%d", userID],
							 @"auto"	: @"0"};
	
	VolleyJSONLog(@"%@ —/> (%@/%@)", [[self class] description], [HONAppDelegate apiServerPath], kAPIAddFriend);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:kAPIAddFriend parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSArray *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			VolleyJSONLog(@"//—> AFNetworking -{%@}- (%@) %@", [[self class] description], [[operation request] URL], result);
			
			if (result != nil)
				[HONAppDelegate writeFollowingList:result];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:kHUDErrorTime];
		_progressHUD = nil;
	}];
}

- (void)_removeFriend:(int)userID {
	NSDictionary *params = @{@"userID"	: [[HONAppDelegate infoForUser] objectForKey:@"id"],
							 @"target"	: [NSString stringWithFormat:@"%d", userID]};
	
	VolleyJSONLog(@"%@ —/> (%@/%@)", [[self class] description], [HONAppDelegate apiServerPath], kAPIRemoveFriend);
	AFHTTPClient *httpClient = [HONAppDelegate getHttpClientWithHMAC];
	[httpClient postPath:kAPIRemoveFriend parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
		NSError *error = nil;
		NSArray *result = [NSJSONSerialization JSONObjectWithData:responseObject options:0 error:&error];
		
		if (error != nil) {
			VolleyJSONLog(@"AFNetworking [-] %@ - Failed to parse JSON: %@", [[self class] description], [error localizedFailureReason]);
			
			if (_progressHUD == nil)
				_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
			_progressHUD.minShowTime = kHUDTime;
			_progressHUD.mode = MBProgressHUDModeCustomView;
			_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
			_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
			[_progressHUD show:NO];
			[_progressHUD hide:YES afterDelay:kHUDErrorTime];
			_progressHUD = nil;
			
		} else {
			VolleyJSONLog(@"//—> AFNetworking -{%@}- (%@) %@", [[self class] description], [[operation request] URL], result);
			
			if (result != nil)
				[HONAppDelegate writeFollowingList:result];
		}
		
	} failure:^(AFHTTPRequestOperation *operation, NSError *error) {
		VolleyJSONLog(@"AFNetworking [-] %@: (%@/%@) Failed Request - %@", [[self class] description], [HONAppDelegate apiServerPath], kAPIUsers, [error localizedDescription]);
		
		if (_progressHUD == nil)
			_progressHUD = [MBProgressHUD showHUDAddedTo:[[UIApplication sharedApplication] delegate].window animated:YES];
		_progressHUD.minShowTime = kHUDTime;
		_progressHUD.mode = MBProgressHUDModeCustomView;
		_progressHUD.customView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"error"]];
		_progressHUD.labelText = NSLocalizedString(@"hud_loadError", nil);
		[_progressHUD show:NO];
		[_progressHUD hide:YES afterDelay:kHUDErrorTime];
		_progressHUD = nil;
	}];
}


#pragma mark - View lifecycle
- (void)loadView {
	[super loadView];
	self.view.backgroundColor = [UIColor whiteColor];
	
	UIButton *doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
	doneButton.frame = CGRectMake(252.0, 0.0, 64.0, 44.0);
	[doneButton setBackgroundImage:[UIImage imageNamed:@"doneButton_nonActive"] forState:UIControlStateNormal];
	[doneButton setBackgroundImage:[UIImage imageNamed:@"doneButton_Active"] forState:UIControlStateHighlighted];
	[doneButton addTarget:self action:@selector(_goDone) forControlEvents:UIControlEventTouchUpInside];
	
	HONHeaderView *headerView = [[HONHeaderView alloc] initAsModalWithTitle:@"Following" hasTranslucency:NO];
	[headerView addButton:doneButton];
	[self.view addSubview:headerView];
	
	_tableView = [[UITableView alloc] initWithFrame:CGRectMake(0.0, 64.0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height - 64.0) style:UITableViewStylePlain];
	[_tableView setBackgroundColor:[UIColor whiteColor]];
	_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	_tableView.delegate = self;
	_tableView.dataSource = self;
	_tableView.userInteractionEnabled = YES;
	_tableView.scrollsToTop = NO;
	_tableView.showsVerticalScrollIndicator = YES;
	[self.view addSubview:_tableView];
	
	[self _retrieveUser];
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
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}


#pragma mark - Navigation
- (void)_goDone {
	[[Mixpanel sharedInstance] track:@"Following - Done"
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	if (_hasUpdated)
		[[NSNotificationCenter defaultCenter] postNotificationName:@"REFRESH_PROFILE" object:nil];
	
	[self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark - TableView DataSource Delegates
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return ([_subscribees count]);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return (1);
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	return (nil);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	HONFollowUserViewCell *cell = [tableView dequeueReusableCellWithIdentifier:nil];
	
	if (cell == nil)
		cell = [[HONFollowUserViewCell alloc] init];
	
	HONUserVO *vo = (HONUserVO *)[_subscribees objectAtIndex:indexPath.row];
	
	cell.userVO = vo;
	cell.delegate = self;
	[cell toggleSelected:[HONAppDelegate isFollowingUser:vo.userID]];
	[cell setSelectionStyle:UITableViewCellSelectionStyleGray];
	
	return (cell);
}


#pragma mark - TableView Delegates
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return (kOrthodoxTableCellHeight);
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	return (0.0);
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	return (indexPath);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:[tableView indexPathForSelectedRow] animated:NO];
	
	UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:self.view.frame];
	bgImageView.backgroundColor = [UIColor whiteColor];
	
	HONUserProfileViewController *userPofileViewController = [[HONUserProfileViewController alloc] init];
	userPofileViewController.userID = ((HONUserVO *)[_subscribees objectAtIndex:indexPath.row]).userID;
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:userPofileViewController];
	[navigationController setNavigationBarHidden:YES];
	[self presentViewController:navigationController animated:YES completion:nil];
}


#pragma mark - SubscriberCell Delegates
- (void)followViewCell:(HONFollowUserViewCell *)cell user:(HONUserVO *)userVO toggleSelected:(BOOL)isSelected {
	[[Mixpanel sharedInstance] track:[NSString stringWithFormat:@"Subscribers List - %@ User", (isSelected) ? @"Select" : @"Deselect"]
						  properties:[NSDictionary dictionaryWithObjectsAndKeys:
									  [NSString stringWithFormat:@"%@ - %@", [[HONAppDelegate infoForUser] objectForKey:@"id"], [[HONAppDelegate infoForUser] objectForKey:@"name"]], @"user", nil]];
	
	_hasUpdated = YES;
	
	if (isSelected)
		[self _addFriend:userVO.userID];
	
	else
		[self _removeFriend:userVO.userID];
}


@end
